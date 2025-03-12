function data = CombFilter(Fs, data)
    % Input parameters
    TA = 0.8; % Slice acquisition time (seconds)
    
    % Calculate P for comb filtering
    P = round(TA * Fs); % Convert to samples

    % Create bandpass filter (20–250 Hz)
    [b_bp,a_bp] = butter(4, [20 250]/(Fs/2), 'bandpass');
    
    % Apply bandpass filter
    EMG_noisy = filtfilt(b_bp, a_bp, data);
    
    % Optional: Add bandstop filter at 50 Hz if needed
    [b_bs, a_bs] = butter(4, [45 55]/(Fs/2), 'stop');
    EMG_noisy = filtfilt(b_bs, a_bs, EMG_noisy);
    
    % Apply comb filter using convolution instead of loop
    comb_filter = [1, zeros(1, P-1), -1]; % Difference equation for periodic noise removal
    EMG_filt = filter(comb_filter, 1, EMG_noisy);

    % Return filtered signal
    data = EMG_filt;
    
    % Save final result (only once)
    save("FilteredData.mat", "data");  
end
