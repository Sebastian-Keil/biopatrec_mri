% ---------------------------- Copyright Notice ---------------------------
% This file is part of BioPatRec � which is open and free software under 
% the GNU Lesser General Public License (LGPL). See the file "LICENSE" for 
% the full license governing this code and copyrights.
%
% BioPatRec was initially developed by Max J. Ortiz C. at Integrum AB and 
% Chalmers University of Technology. All authors� contributions must be kept
% acknowledged below in the section "Updates % Contributors". 
%
% Would you like to contribute to science and sum efforts to improve 
% amputees� quality of life? Join this project! or, send your comments to:
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
% 2017-02-28 / Simon Nilsson / Separated the acquisition modes for RHA2216
                            % and RHA2132. The RHA2132 now uses a higher
                            % baudrate and a buffered acquisition mode to
                            % handle the higher data flow of HD-EMG.                            

% 2018-01-18 / Eva Lendaro  / added BP_ExG_MR for Mannheim group



% it creates IP object and sets the buffersize depending on the device that has been chose
function obj = ConnectDevice(handles)

    deviceName  = handles.deviceName;
    ComPortType = handles.ComPortType;
    if strcmp(ComPortType, 'COM')
        ComPortName = handles.ComPortName;
    end
    sF          = handles.sF;
    sT          = handles.sT;
    nCh         = handles.nCh;
    sTall       = handles.sTall;

    %%%%% WiFi %%%%%
    if strcmp(ComPortType, 'WiFi')
        %%%%% TI ADS1299 %%%%%
        if strcmp(deviceName, 'ADS_BP')
            obj = tcpip('192.168.100.10',65100,'NetworkRole','client');        % ADS1299
            obj.InputBufferSize = sTall*sF*nCh*4;  
        end
        %%%%% INTAN RHA2216 %%%%%
        if strcmp(deviceName, 'RHA2216')
            obj = tcpip('192.168.100.10',65100,'NetworkRole','client');        % WIICOM
            obj.InputBufferSize = sT*sF*nCh*2;  
        end
    end

    %%%%% COM %%%%%
    if strcmp(ComPortType, 'COM')
        %%%%% TI ADS1299 %%%%%
        if strcmp(deviceName, 'ADS1299')
           obj = serial (ComPortName, 'baudrate', 2000000, 'databits', 8, 'byteorder', 'bigEndian');                       
           obj.InputBufferSize = sTall*sF*27;                                 % 27bytes data package
        end
        if strcmp(deviceName, 'ADS_BP')
           obj = serial (ComPortName, 'baudrate', 460800, 'databits', 8, 'byteorder', 'bigEndian');
           obj.InputBufferSize = sTall*sF*nCh*4;  
        end
        %%%%% INTAN RHA2216 %%%%%
        if strcmp(deviceName, 'RHA2216')
            obj = serial (ComPortName, 'baudrate', 1250000, 'databits', 8, 'byteorder', 'bigEndian');
            obj.InputBufferSize = sTall*sF*nCh*2;
        end
        %%%%% INTAN RHA2132 %%%%%
        if strcmp(deviceName, 'RHA2132')
            obj = serial (ComPortName, 'baudrate', 1500000, 'databits', 8, 'byteorder', 'bigEndian');
            obj.InputBufferSize = sTall*sF*nCh*2;
        end
    end  
    
    %%%%% BP_ExG_MR %%%%%
    if strcmp(deviceName, 'BP_ExG_MR')
        recorderip = '127.0.0.1';
        %obj = tcpip(recorderip, 51244, 'NetworkRole', 'client'); % not really needed but otherwise it will probably crash
        obj = pnet('tcpconnect', recorderip, 51244);
        stat = pnet(obj,'status');
        if stat > 0
           % disp('connection established'); %just for debug, check if you
            %get here in this row of code
            %handles.pnet = pnet;
            
        end
    end
    if strcmp(deviceName, 'BP_ExG_MR')==0
        % Open the connection
        fopen(obj);
        %make and if to avoid if it is the brain product thing
        % Read available data and discard it 
        
        if obj.BytesAvailable > 1
            fread(obj,obj.BytesAvailable,'uint8');       
        end
        disp(obj);
    end
    
end
