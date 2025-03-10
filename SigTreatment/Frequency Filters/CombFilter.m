function data = CombFilter(Fs, data)
    % Save initial data for debugging
    save('data.mat', 'data');
    
    % Input parameters
    TA = 0.8; % Slice acquisition time (seconds)
    
    % Calculate P for comb filtering
    P = round(TA * Fs); % Convert to samples
    
    % Create bandpass filter
    [b,a] = butter(4, [20 250]/(Fs/2), 'bandpass');
    save("bandpass.mat", "b", "a");
    
    % Apply bandpass filter
    EMG_noisy = filtfilt(b,a,data);
    save("EMG_Noisy_before.mat", "EMG_noisy");
    
    % Optional: Add bandstop filter at 50 Hz if needed
    [b,a] = butter(4, [45 55]/(Fs/2), 'stop');
    EMG_noisy = filtfilt(b,a,EMG_noisy);
    
    % Apply comb filter
    EMG_filt = zeros(size(data));
    for i = 1:length(data)
       delay = mod(i-1,P)+1;
        if i >= delay
            EMG_filt(i) = EMG_noisy(i) - EMG_noisy(delay);
        end
    end
    save("EMG_Filt.mat","EMG_filt");
    
    % Apply final filter
    Out = [EMG_filt(:,1)];
    Denom = ones(size(Out));
    Outout = horzcat(Out, Denom);
    save('Out.mat', "Out");
    
    % Ensure proper dimensions for filter
  %  if size(data,2) > 1
   %     data = reshape(data, [], 1);
    
    
    % Apply final filter operation
    data = filter(Out, Denom, data);
    
    % Final debug save
    save("Debug.mat")
end