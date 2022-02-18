function [events_time,varargout] = get_events_time(event_spec_table,varargin)
% Output event time, such as 'rise_time' from an event_spec_table.
%   some parameters, such as event category, can be use to filter events
	% event_spec_table: In "recdata_organized" 5th column
	% cat_keywords: cell array. strings need to be exactly same to the ones in the [peak_category] to pick events. Case insensitive
	%				% options: 'nostimfar', 'interval', 'triggered_delay', 'triggered'

	% Defaults
	event_filter = 'none'; % options are: 'none', 'timeWin', 'event_cat'
	event_align_point = 'rise'; % options: 'rise', 'peak'

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('event_filter', varargin{ii})
	        event_filter = varargin{ii+1}; % options are: 'none', 'stim', 'event_cat'
	    elseif strcmpi('win_range', varargin{ii})
	        win_range = varargin{ii+1}; % nx2 array. stim_range in the gpio info (4th column of recdata_organized) can be used for this
	    elseif strcmpi('cat_keywords', varargin{ii})
	        cat_keywords = varargin{ii+1}; % can be a cell array containing multiple keywords
	    elseif strcmpi('event_align_point', varargin{ii})
	        event_align_point = varargin{ii+1}; % 'rise' or 'peak'
	    % elseif strcmpi('scale_data', varargin{ii})
	    %     scale_data = varargin{ii+1};
	    % elseif strcmpi('peaks_time', varargin{ii})
	    %     peaks_time = varargin{ii+1};
	    end
	end

	% ====================
	% Main contents
	switch event_align_point
		case 'rise'
			events_time = event_spec_table.rise_time;
		case 'peak'
			events_time = event_spec_table.peak_time;
		otherwise
			fprintf('Input "rise" or "peak" for the variable event_align_point\n')
	end
	events_idx = [1:length(events_time)];

	switch event_filter
		case 'timeWin'
			if exist('win_range', 'var')
				[events_info] = get_events_info(events_time,win_range,event_spec_table);
				events_time = events_info.events_time;
				events_idx = event_info.idx_in_peak_table;
			else
				fprintf('[win_range] is needed to screen events when [timeWin] is used as event_filter\n')
				return
			end
		case 'event_cat'
			if exist('cat_keywords', 'var') && ~isempty(cat_keywords)
				kw_num = numel(cat_keywords); % number of keywords
				cats = event_spec_table.peak_category;
				catPos_idx = [];
				for i = 1:kw_num
					spell = cat_keywords{i};
					catPos_cell = cellfun(@(x) strcmpi(x, spell), cats, 'UniformOutput', false);
					catPos_idx = [catPos_idx, find([catPos_cell{:}]==1)]; 
				end
				events_time = events_time(catPos_idx);
				events_idx = catPos_idx;
			else
				fprintf('[cat_keywords] is needed to screen events when [event_cat] is used as event_filter\n')
				return
			end
		case 'none'
	end

	varargout{1} = events_idx;
end

