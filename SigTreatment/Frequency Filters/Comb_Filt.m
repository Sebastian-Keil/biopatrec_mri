function [data] = Comb_Filt(Fs, data)
    disp(['Function called with input size: ', num2str(size(data))]);
    
    % Input parameters
    TA = 0.8; % Slice acquisition time (seconds)

    % Calculate P for comb filtering
    P = round(TA / Fs);

    % Create bandpass filter
    [b,a] = butter(4, [20 250]/(Fs/2), 'bandpass');
    
    % Apply bandpass filter
    EMG_noisy = filtfilt(b,a,data);
    
    disp(['Size of EMG_noisy before comb filtering: ', num2str(size(EMG_noisy))]);
    
    % Apply comb filter
    EMG_filt = zeros(size(data)); % Initialize with same size as input
    
    disp(['Size of EMG_filt before loop: ', num2str(size(EMG_filt))]);
    
    % Apply the filter to each column separately
    for col = 1:size(data, 2)
        disp(['Processing column ', num2str(col)]);
        
        start_idx = max(1, col-P+1);
        end_idx = min(col+P, size(data, 1));
        
        disp(['Indices for column ', num2str(col), ': start=', num2str(start_idx), ', end=', num2str(end_idx)]);
        
        % Ensure we don't exceed array bounds
        if start_idx <= end_idx
            EMG_filt(start_idx:end, col) = ...
                EMG_noisy(start_idx:end, col) - ...
                EMG_noisy(max(1, start_idx-P):min(end_idx+P, size(data, 1)), col);
        else
            disp('Warning: Skipping column due to index mismatch');
        end
    end
    
    disp(['Size of EMG_filt after loop: ', num2str(size(EMG_filt))]);
    
    % Apply filter to each column separately
    for col = 1:size(data, 2)
        data(:, col) = filter(EMG_filt(:, col), 1, data(:, col));
    end
    
    % Save filtered data
    save("EMG_Filt.mat","data");
    
    disp('Comb_Filt function completed');
end