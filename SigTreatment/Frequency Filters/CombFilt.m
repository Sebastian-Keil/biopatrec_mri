function [data] = CombFilt(Fs, data)
save('data.mat', 'data')
% Input parameters
TA = 0.8; % Slice acquisition time (seconds)

% Calculate P for comb filtering
P = TA / Fs;

% Create bandpass filter
[b,a] = butter(4, [20 250]/(Fs/2), 'bandpass');
save("bandpass.mat", "b", "a")

% Apply bandpass filter
EMG_noisy = filtfilt(b,a,data);

save("EMG_Noisy_before.mat", "EMG_noisy")

% Optional: Add bandstop filter at 50 Hz if needed
[b,a] = butter(4, [45 55]/(Fs/2), 'stop');
EMG_noisy = filtfilt(b,a,EMG_noisy);

% Apply comb filter
EMG_filt = zeros(size(data));

for i = 1:length(data)
    delay = mod(i-1,P)+1;
    EMG_filt(i) = EMG_noisy(i) - EMG_noisy(delay);
end

save("EMG_Filt.mat","EMG_filt");
save("Debug.mat");
% Apply filter
Denom = [0 0];
data = filter(EMG_filt, EMG_filt, data);


end