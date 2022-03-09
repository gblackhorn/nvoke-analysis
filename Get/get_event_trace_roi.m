function [alignedTrace_timeInfo,alignedTrace,varargout] = get_event_trace_roi(full_time,roi_trace_data,roi_event_spec_table,varargin)
% Collect the event traces from a single ROI and align them. Return the aligned events and the time info for them 
%   Use func 'get_events_time' and 'get_event_trace'
%	time window (ex: events happened during stim or interval of stim) or event category can be used to screen events
	
	% Defaults
	event_filter = 'none'; % options are: 'none', 'timeWin', 'event_cat'
	event_align_point = 'rise'; % options: 'rise', 'peak'
	pre_event_time = 1; % unit: s. event trace starts at 1s before event onset
	post_event_time = 2; % unit: s. event trace ends at 2s after event onset
	scale_data = false;
	align_on_y = true; % subtract data with the values at the align points
	win_range = [];
	cat_keywords =[]; %cell array. strings need to be exactly same to the ones in the [peak_category] to pick events. Case insensitive
	%				% options: {}, {'noStim', 'beforeStim', 'interval', 'trigger', 'delay', 'rebound'}

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('event_filter', varargin{ii})
	        event_filter = varargin{ii+1}; % options are: 'none', 'stim', 'event_cat'
	    elseif strcmpi('win_range', varargin{ii})
	        win_range = varargin{ii+1}; % nx2 array. stim_range in the gpio info (4th column of recdata_organized) can be used for this
	    elseif strcmpi('cat_keywords', varargin{ii})
	        cat_keywords = varargin{ii+1}; % can be a cell array containing multiple keywords
	    elseif strcmpi('event_align_point', varargin{ii})
	        event_align_point = varargin{ii+1}; % 'rise' or 'peak'
	    elseif strcmpi('pre_event_time', varargin{ii})
	        pre_event_time = varargin{ii+1};
	    elseif strcmpi('post_event_time', varargin{ii})
	        post_event_time = varargin{ii+1};
	    elseif strcmpi('align_on_y', varargin{ii})
	        align_on_y = varargin{ii+1};
	    elseif strcmpi('scale_data', varargin{ii})
	        scale_data = varargin{ii+1};
	    end
	end


	% ====================
	% Main contents
	% Get events time and indexes from the [roi_event_spec_table]
	if ~isempty(roi_event_spec_table)
		[events_time,events_idx] = get_events_time(roi_event_spec_table,...
			'event_align_point', event_align_point, 'event_filter', event_filter,...
			'win_range', win_range, 'cat_keywords', cat_keywords,...
			'pre_event_time', pre_event_time, 'post_event_time', post_event_time,...
			'align_on_y', align_on_y, 'scale_data', scale_data);

		if ~isempty(events_time)
			peaks_time = roi_event_spec_table.peak_time(events_idx);

			% Get aligned data: time and traces
			[alignedTrace_timeInfo,alignedTrace,mean_val,std_val,alignedTrace_scaled] = get_event_trace(events_time,full_time,roi_trace_data,...
				'pre_event_time', pre_event_time, 'post_event_time', post_event_time,...
				'align_on_y', align_on_y, 'scale_data', scale_data, 'peaks_time', peaks_time);
			event_prop = get_events_info(events_time, [], roi_event_spec_table, 'style', 'event');
		else
			alignedTrace_timeInfo = [];
			alignedTrace = [];
			mean_val = [];
			std_val = [];
			event_prop = [];
			alignedTrace_scaled = [];
		end

		varargout{1} = mean_val;
		varargout{2} = std_val;
		% varargout{3} = roi_event_spec_table(events_idx, :);
		varargout{3} = event_prop;
		% varargout{4} = events_idx;
		varargout{4} = alignedTrace_scaled;
	else
		fprintf('Warning: var roi_event_spec_table is empty. No trace accquired\n')
		return
	end
end

