function [closestValue,varargout] = find_closest_in_array(ideal_value,target_array)
    % Compute and find the closest value in a vector, target_array, and output the closestValue as a single vector
    % for each element of "ideal_value"
    %   ideal_value: a single number or a vector
    %   target_array: a vector

    ideal_value = ideal_value(:); % make sure that ideal_value is a single column vector
    target_array = target_array(:); % make sure that ideal_value is a single column vector

    target_array_repmat = repmat(target_array, [1 length(ideal_value)]);
    [minValue, closestIndex] = min(abs(target_array_repmat-ideal_value'));
    closestIndex = closestIndex';
    closestValue = target_array(closestIndex);

    varargout{1} = closestIndex; % the locations of the closestValue in the target_array
end

