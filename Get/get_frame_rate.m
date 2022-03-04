function [frameRate,varargout] = get_frame_rate(timeInfo,varargin)
	% Return the frame rate

	% timeInfo: a vetor containing time points
	idx_timePoint = 5; % use the (idx_timePoint)th and (idx_timePoint-1)th points to calculate the interval time points

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('idx_timePoint', varargin{ii})
	        idx_timePoint = varargin{ii+1}; % label style. 'shape'/'text'
	    end
	end	

	%% Content
	sampleInt = timeInfo(idx_timePoint)-timeInfo(idx_timePoint-1);
	frameRate = round(1/sampleInt);
end