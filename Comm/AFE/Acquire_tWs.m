% ---------------------------- Copyright Notice ---------------------------
% This file is part of BioPatRec © which is open and free software under 
% the GNU Lesser General Public License (LGPL). See the file "LICENSE" for 
% the full license governing this code and copyrights.
%
% BioPatRec was initially developed by Max J. Ortiz C. at Integrum AB and 
% Chalmers University of Technology. All authors’ contributions must be kept
% acknowledged below in the section "Updates % Contributors". 
%
% Would you like to contribute to science and sum efforts to improve 
% amputees’ quality of life? Join this project! or, send your comments to:
% maxo@chalmers.se.
%
% The entire copyright notice must be kept in this or any source file 
% linked to BioPatRec. This will ensure communication with all authors and
% acknowledge contributions here and in the project web page (optional).
% ------------------- Function Description ------------------
% Function to Record Exc Sessions
%
% --------------------------Updates--------------------------
% 2015-1-12 / Enzo Mastinu / Divided the RecordingSession function into
                            % several functions: ConnectDevice(),
                            % SetDeviceStartAcquisition(),
                            % Acquire_tWs(), StopAcquisition(). This functions 
                            % has been moved to COMM/AFE folder, into this new script.
% 2015-1-19 / Enzo Mastinu / The ADS1299 part has been modified in way to be 
                            % compatible with the new ADS1299 acquisition mode (DSP + FPU) 
% 2015-4-10 / Enzo Mastinu / The ADS1299_DSP acquisition has been optimized, only desired
                            % channels are transmitted to PC, not all as before
% 2016-7-08 / Enzo Mastinu / The ADS_DSP/Neuromotus acquisition has been
                            % optimized introducing the re-synchronization
                            % in case the signal got lost
% 2017-02-28 / Simon Nilsson / Separated the acquisition modes for RHA2216
                            % and RHA2132. The RHA2132 now uses a higher
                            % baudrate and a buffered acquisition mode to
                            % handle the higher data flow of HD-EMG.
                            
% 2019-01-18 / Eva Lendaro / Added BP_ExG_MR device for Mannheim group



% It acquire tWs samples from the selected device
function [cData, error] = Acquire_tWs(deviceName, obj, nCh, tWs)
 
    error = 0;
    cData = zeros(tWs,nCh);                                                % this is the data structure that the function must return
    
    % Set warnings to temporarily issue error (exceptions)
    s = warning('error', 'instrument:fread:unsuccessfulRead');
    try
        %%%%% ADS1299 %%%%%
        if strcmp(deviceName, 'ADS1299')
        %   LSBweight = double(4.5/(24*8388607));                            % ADS1299: we always use the gain of 24 V/V
            LSBweight = double(4.5/(8388607));                                 % It is better to plot data with gain scaling effect
            for sampleNr = 1:tWs
                % 27bytes package mode
                byteData = fread(obj,27,'char');                               % Acquire 27 bytes packet from Tiva (and from ADS1299), 3 status bytes + 3 byte (24bit) for each channel
                value = [65536 256 1]*reshape(byteData(4:end), 3, 8);          % all channels data are now available on value vector, byteData(4:end) means throw away status bytes
                for k = 1:nCh  
                    if value(k) > 8388607                                      % the data must be converted from 2's complement
                        value(k) = value(k) - 2^24;
                    end
                    cData(sampleNr,k) = value(k) * LSBweight;                  
                end 
            end
        end
        if strcmp(deviceName, 'ADS_BP')
            for sampleNr = 1:tWs
                go = 0;
                while go == 0
                    % nCh*4 bytes (float) mode
                    byteData = fread(obj,nCh,'float32');                             % float data mode (4bytes X nCh channels)
                    if byteData < 5
                        go = 1;
                    else
                        % Synchronize the device again
                        fwrite(obj,'T','char');
                        % Read available data and discard it
                        if obj.BytesAvailable > 1
                            fread(obj,obj.BytesAvailable,'uint8');        
                        end
                        fwrite(obj,'G','char');
                        fwrite(obj,nCh,'char');
                        fread(obj,1,'char');
                        disp('Communication issue: automatic resynchronization')
                        go = 0;
                    end
                end
                cData(sampleNr,:) = byteData(1:nCh,:)';
            end
        end

       %%%%% INTAN RHA2216 %%%%%
       if strcmp(deviceName, 'RHA2216')   
    %        LSBweight = double(2.5/(200*65535));                              % Intan differential gain is 200 V/V
            LSBweight = double(2.5/(65535));                                   % It is better to plot data with gain scaling effect
            for sampleNr = 1:tWs                  
                value16 = fread(obj,nCh,'uint16');
                for k = 1:nCh
    %                 cData(sampleNr,k) = value16(k) - 16384;                  % Centers data and scales it to fit the graphs
                    cData(sampleNr,k) = value16(k)*LSBweight;                  % Convert data into volt
                end
            end 
       end
       
       %%%%% INTAN RHA2132 %%%%%
       if strcmp(deviceName, 'RHA2132')   
            RequestSamplesRHA32(obj, tWs);
            cData = AcquireSamplesRHA32(obj, nCh, tWs);
       end
       
       %%%%% BP_ExG_MR %%%%%
       if strcmp(deviceName, 'BP_ExG_MR') 
           recorderip = '127.0.0.1';
           obj = pnet('tcpconnect', recorderip, 51244);
           stat = pnet(obj,'status');
%            if stat > 0
%                disp('connection established'); %just for debug, check if you
%            end
           header_size = 24;
           finish = false;
           while ~finish
               try
                   tryheader = pnet(obj, 'read', header_size, 'byte', 'network', 'view', 'noblock');
                   while ~isempty(tryheader)
                       hdr = ReadHeader(obj); 
                       switch hdr.type
                           case 1       
                               props = ReadStartMessage(obj, hdr);
                               lastBlock = -1;
                               data1s = [];
                           case 4       
                               [datahdr, data, markers] = ReadDataMessage(obj, hdr, props);
                               if lastBlock ~= -1 && datahdr.block > lastBlock + 1
                                   disp(['******* Overflow with ' int2str(datahdr.block - lastBlock) ' blocks ******']);
                               end
                               lastBlock = datahdr.block;
                               if datahdr.markerCount > 0
                                   for m = 1:datahdr.markerCount
                                disp(markers(m));
                                   end
                               end
                               EEGData = reshape(data, props.channelCount, length(data) / props.channelCount);
                               for k = 1:props.channelCount
                                   EEGData (k,:) = EEGData (k,:) * props.resolutions (k);
                               end  
                               data1s = [data1s EEGData];
                               dims = size(data1s);
                               if dims(2) > tWs
                                   data1s = data1s(:,  dims(2)-(tWs-1) : dims(2));
                                   current_data=zeros(tWs,props.channelCount);
                                   current_data=double(data1s');
                                   cData=current_data(:,1:nCh);
%                                    disp(['window acquired']); 
                                   data1s = [];
                                   finish = true;
                               end
                           case 3       
                               disp('Stop');
                               data = pnet(obj, 'read', hdr.size - header_size);
                               finish = true;
                           otherwise
                               data = pnet(obj, 'read', hdr.size - header_size);
                       end
                       tryheader = pnet(obj, 'read', header_size, 'byte', 'network', 'view', 'noblock');
                   end
               catch
                   er = lasterror;
                   disp(er.message);
               end
           end
           pnet('closeall');
%            disp('connection closed');
       end
   
    catch exception
       error = 1;
    end
    %Set warning back to normal state
    warning(s);
   
end

%% ***********************************************************************
% Read the message header
function hdr = ReadHeader(con)
    % con    tcpip connection object
    
    % define a struct for the header
    hdr = struct('uid',[],'size',[],'type',[]);

    % read id, size and type of the message
    % swapbytes is important for correct byte order of MATLAB variables
    % pnet behaves somehow strange with byte order option
    hdr.uid = pnet(con,'read', 16);
    hdr.size = swapbytes(pnet(con,'read', 1, 'uint32', 'network'));
    hdr.type = swapbytes(pnet(con,'read', 1, 'uint32', 'network'));
end

%% ***********************************************************************   
% Read the start message
function props = ReadStartMessage(con, hdr)
    % con    tcpip connection object    
    % hdr    message header
    % props  returned eeg properties

    % define a struct for the EEG properties
    props = struct('channelCount',[],'samplingInterval',[],'resolutions',[],'channelNames',[]);
    % read EEG properties
    props.channelCount = swapbytes(pnet(con,'read', 1, 'uint32', 'network'));
    props.samplingInterval = swapbytes(pnet(con,'read', 1, 'double', 'network'));
    props.resolutions = swapbytes(pnet(con,'read', props.channelCount, 'double', 'network'));
    allChannelNames = pnet(con,'read', hdr.size - 36 - props.channelCount * 8);
    props.channelNames = SplitChannelNames(allChannelNames);
end
    
%% ***********************************************************************   
% Read a data message
function [datahdr, data, markers] = ReadDataMessage(con, hdr, props)
    % con       tcpip connection object    
    % hdr       message header
    % props     eeg properties
    % datahdr   data header with information on datalength and number of markers
    % data      data as one dimensional arry
    % markers   markers as array of marker structs
    
    % Define data header struct and read data header
    datahdr = struct('block',[],'points',[],'markerCount',[]);

    datahdr.block = swapbytes(pnet(con,'read', 1, 'uint32', 'network'));
    datahdr.points = swapbytes(pnet(con,'read', 1, 'uint32', 'network'));
    datahdr.markerCount = swapbytes(pnet(con,'read', 1, 'uint32', 'network'));

    % Read data in float format
    data = swapbytes(pnet(con,'read', props.channelCount * datahdr.points, 'single', 'network'));


    % Define markers struct and read markers
    markers = struct('size',[],'position',[],'points',[],'channel',[],'type',[],'description',[]);
    for m = 1:datahdr.markerCount
        marker = struct('size',[],'position',[],'points',[],'channel',[],'type',[],'description',[]);

        % Read integer information of markers
        marker.size = swapbytes(pnet(con,'read', 1, 'uint32', 'network'));
        marker.position = swapbytes(pnet(con,'read', 1, 'uint32', 'network'));
        marker.points = swapbytes(pnet(con,'read', 1, 'uint32', 'network'));
        marker.channel = swapbytes(pnet(con,'read', 1, 'int32', 'network'));

        % type and description of markers are zero-terminated char arrays
        % of unknown length
        c = pnet(con,'read', 1);
        while c ~= 0
            marker.type = [marker.type c];
            c = pnet(con,'read', 1);
        end

        c = pnet(con,'read', 1);
        while c ~= 0
            marker.description = [marker.description c];
            c = pnet(con,'read', 1);
        end
        
        % Add marker to array
        markers(m) = marker;  
    end

end 
%% ***********************************************************************   
% Helper function for channel name splitting, used by function
% ReadStartMessage for extraction of channel names
 function channelNames = SplitChannelNames(allChannelNames)
    % allChannelNames   all channel names together in an array of char
    % channelNames      channel names splitted in a cell array of strings

    % cell array to return
    channelNames = {};
    
    % helper for actual name in loop
    name = [];
    
    % loop over all chars in array
    for i = 1:length(allChannelNames)
        if allChannelNames(i) ~= 0
            % if not a terminating zero, add char to actual name
            name = [name allChannelNames(i)];
        else
            % add name to cell array and clear helper for reading next name
            channelNames = [channelNames {name}];
            name = [];
        end
    end
 end