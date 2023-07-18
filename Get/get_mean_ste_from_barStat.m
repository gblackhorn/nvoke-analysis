function [xData,meanVal,steVal,varargout] = get_mean_ste_from_barStat(barStat,stimName,varargin)
	% Get data from barStat (an output from function 'plot_event_freq_alignedData_allTrials')


	% Defaults

	% Optionals
	% for ii = 1:2:(nargin-3)
	%     if strcmpi('errorA', varargin{ii})
	%         errorA = varargin{ii+1}; % number array used to plot error bar for meanA
	%     elseif strcmpi('errorB', varargin{ii})
	%         errorB = varargin{ii+1}; % number array used to plot error bar for meanB
	%     end
	% end

	% Get the idx of entry by finding the stimName in barStat.stim
	stimNames = {barStat.stim};
	idx = find(strcmpi(stimNames,stimName));

	if ~isempty(idx)
		xData = {barStat(idx).data.group};
		xData = cellfun(@str2double, xData); % convert the string cell array to a number array
		rawData = {barStat(idx).data.group_data};

		meanVal = [barStat(idx).data.mean_val];
		steVal = [barStat(idx).data.ste_val];
		binEdges = barStat(idx).binEdges;

		periStimGroups = barStat(idx).periStimGroups;
	else
		error('stimName not found in the input structure var')
	end
	varargout{1} = binEdges;
	varargout{2} = rawData;
	varargout{3} = periStimGroups;
end
