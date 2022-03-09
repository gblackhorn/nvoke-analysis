function [alignedTraces,timeInfo,varargout] = collect_aligned_trace(alignedData,peakCat,varargin)
	% collect aligned trace
	% alignedData: structure
	% peakCat: a string from {'spon','trig', 'trig-AP', 'rebound'}

	%% Defaults
	% stims = {'GPIO-1-1s', 'OG-LED-5s', 'OG-LED-5s GPIO-1-1s'};
	% eventCats = {{'trigger'},...
	% 		{'trigger', 'rebound'},...
	% 		{'trigger-beforeStim', 'trigger-interval', 'delay-trigger', 'rebound-interval'}};
	% num_stims = numel(stims); 
	% num_eventCats = numel(eventCats); 
	% if num_stims~=num_eventCats
	% 	error('func discard_alignedData_roi: \nNumber of compnents in stims and eventCats must be same')
	% end

	%% Optionals
	% for ii = 1:2:(nargin-2)
	%     if strcmpi('stims', varargin{ii})
	%         stims = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
 %        elseif strcmpi('eventCats', varargin{ii})
	%         eventCats = varargin{ii+1};
 %        % elseif strcmpi('stimStart_err', varargin{ii})
 %        %     stimStart_err = varargin{ii+1};
 %        % elseif strcmpi('nonstimMean_pos', varargin{ii})
 %        %     nonstimMean_pos = varargin{ii+1};
	%     end
	% end	


	%% Content
	timeInfo = alignedData(1).time;
	trial_num = numel(alignedData);
	traceData_cell_trials = cell(1, trial_num); 
	for nt = 1:trial_num
		traceInfo_trial = alignedData(nt).traces;
		num_roi = numel(traceInfo_trial);
		traceData_cell_rois = cell(1, num_roi);
		for nr = 1:num_roi
			peakCat_roi = {traceInfo_trial(nr).eventProp.peak_category};
			tf_event = strcmpi(peakCat, peakCat_roi);
			IDX_event = find(tf_event);
			traceData_cell_rois{nr} = traceInfo_trial(nr).value(:, IDX_event);
		end
		traceData_cell_trials{nt} = [traceData_cell_rois{:}];
	end
	alignedTraces = [traceData_cell_trials{:}];
	alignedTraces_mean = mean(alignedTraces, 2, 'omitnan');
	alignedTraces_std = std(alignedTraces, 0, 2, 'omitnan');

	varargout{1} = alignedTraces_mean;
	varargout{2} = alignedTraces_std;
end