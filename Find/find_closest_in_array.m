function [closestValue,varargout] = find_closest_in_array(ideal_value,target_array)
    % Compute and find the closest value in a single-column array target_array
    % for each element of "ideal_value"
    %   ideal_value: a single number or a single-column array
    %   target_array: a single-column array

    target_array_repmat = repmat(target_array, [1 length(ideal_value)]);
    [minValue, closestIndex] = min(abs(target_array_repmat-ideal_value'));
    closestIndex = closestIndex';
    closestValue = target_array(closestIndex);

    varargout{1} = closestIndex;
end

