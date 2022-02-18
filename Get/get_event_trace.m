function [alignedTrace_timeInfo,alignedTrace,varargout] = get_event_trace(events_time,full_time,full_trace_data,varargin)
	% Align the events with giving time, traceData, and events' time
	% 
	% full_time: time stamp covers the events
	% full_trace_data: traceData covers the events
	% events_time: time points at which trace data is extracted and aligned to 
	% pre/post_event_time: seconds. trace data between (align_points-duration_pre) and (align_points-duration_post) is extracted
	%						number of extracted traces equals the number of align_points
	% varargin: data can be scaled to make the amplitude of events the same. Input event peak time points for this
	% peaks_time(in varargin): Time of event peaks. The same size as align_points

	% Defaults
	pre_event_time = 1; % unit: s. event trace starts at 1s before event onset
	post_event_time = 2; % unit: s. event trace ends at 2s after event onset
	scale_data = false;
	align_on_y = true; % subtract data with the values at the align points

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('pre_event_time', varargin{ii})
	        pre_event_time = varargin{ii+1};
	    elseif strcmpi('post_event_time', varargin{ii})
	        post_event_time = varargin{ii+1};
	    elseif strcmpi('align_on_y', varargin{ii})
	        align_on_y = varargin{ii+1};
	    elseif strcmpi('scale_data', varargin{ii})
	        scale_data = varargin{ii+1};
	    elseif strcmpi('peaks_time', varargin{ii})
	        peaks_time = varargin{ii+1};
	    end
	end


	% ====================
	% Main contents
	full_datapoint_num = numel(full_trace_data);

	fr = round(1/(full_time(10)-full_time(9))); % recording frequency. round it to an integer
	datapoint_num_pre = ceil(pre_event_time*fr); % number of data points before event onset
	datapoint_num_post = ceil(post_event_time*fr); % number of data points after event onset

	alignedTrace_timeInfo = [-datapoint_num_pre:datapoint_num_post]'/fr;
	datapoint_num = numel(alignedTrace_timeInfo);

	[events_time, events_loc] = find_closest_in_array(events_time, full_time); % aligned_event_time == align_points
	events_value = full_trace_data(events_loc);

	if scale_data
		if exist('peaks_time', 'var')
			[peaks_time, peaks_loc] = find_closest_in_array(peaks_time, full_time); % peaks_time == peaks_time
			peaks_value = full_trace_data(peaks_loc);
			peak_amp = peaks_value-events_value;
		else
			fprintf('peaks_time was not input, cannot scale data\n')
			return
		end
	end

	events_start = events_loc-datapoint_num_pre;
	events_end = events_loc+datapoint_num_post;
	events_cb_pre = zeros(size(events_start)); % calibration idx for data prior to event align points
	events_cb_post = zeros(size(events_end));

	idx_before_start = find(events_start<1); % locate the event range starting before the first data point
	idx_after_end = find(events_end>full_datapoint_num); % locate the event range ending after the last data point

	events_cb_pre(idx_before_start) = 1-events_start(idx_before_start); % get the calibration value for pre and post time of events
	events_cb_post(idx_after_end) = events_end(idx_after_end)-full_datapoint_num;
	events_start(idx_before_start) = 1;
	events_end(idx_after_end) = full_datapoint_num;


	event_num = numel(events_time);
	alignedTrace = NaN(datapoint_num, event_num);
	alignedTrace_scaled = NaN(datapoint_num, event_num);
	for n = 1:event_num
		single_event_data = full_trace_data(events_start(n):events_end(n));
		if align_on_y
			single_event_data = single_event_data-events_value(n);
		end
		alignedTrace(1+events_cb_pre(n):datapoint_num-events_cb_post(n), n) = single_event_data;

		if scale_data
			single_event_data_scaled = single_event_data/peak_amp(n);
			alignedTrace_scaled(1+events_cb_pre(n):datapoint_num-events_cb_post(n), n) = single_event_data_scaled;
		end
	end
	event_value_mean = mean(alignedTrace, 2, 'omitnan');
	event_value_std = std(alignedTrace, 0, 2, 'omitnan');
	
	varargout{1} = event_value_mean;
	varargout{2} = event_value_std;
	varargout{3} = alignedTrace_scaled;
end