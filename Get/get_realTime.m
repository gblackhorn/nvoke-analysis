function [real_time,varargout] = get_realTime(ideal_time,timeInfo,varargin)
	% Return real_time using values from timeInfo

	% ideal_time: vector or array
	% timeInfo: column vector. Full time information of a trial recording

	real_time = ideal_time;
	for n = 1:size(ideal_time, 2);
		real_time(:, n) = find_closest_in_array(ideal_time(:, n),timeInfo);
	end
end