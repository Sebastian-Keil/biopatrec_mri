function [change_indices] = detect_changes(data, threshold)
    % DETECT_DRASTIC_CHANGES Detect significant changes in data
    %
    % Args:
    %   data: 500x2 double array containing the data to analyze
    %   threshold: scalar value defining what constitutes a drastic change
    %
    % Returns:
    %   change_indices: vector containing indices where drastic changes occur
    
    % Validate input size
    if size(data, 1) ~= 500 || size(data, 2) ~= 2
        error('Input must be exactly 500x2');
    end
    
    % Calculate absolute differences between consecutive rows
    diffs = abs(diff(data));
    
    % Find indices where either column exceeds threshold
    drastic_changes = any(diffs > threshold, 2);
    
    % Get indices (add 1 because diff reduces array size by 1)
    change_indices = find(drastic_changes) + 1;
end