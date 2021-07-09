function [event_trace] = get_event_trace(events_time,full_trace_time,full_trace_data,varargin)
	% Return a table containing event trace aligned with event time
	% 	



	% Defaults
	pre_event_time = 1; % unit: s. event trace starts at 1s before event onset
	post_event_time = 2; % unit: s. event trace ends at 2s after event onset

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('pre_event_time', varargin{ii})
	        pre_event_time = varargin{ii+1};
	    elseif strcmpi('post_event_time', varargin{ii})
	        post_event_time = varargin{ii+1};
	    end
	end

	full_datapoint_num = numel(full_trace_data);

	fr = round(1/(full_trace_time(10)-full_trace_time(9))); % recording frequency
	datapoint_num_pre = ceil(pre_event_time*fr); % number of data points before event onset
	datapoint_num_post = ceil(post_event_time*fr); % number of data points after event onset

	trace_time_aligned = [-datapoint_num_pre:datapoint_num_post]'/fr;
	datapoint_num = numel(trace_time_aligned);

	event_num = numel(events_time);
	trace_aligned = NaN(datapoint_num, event_num);
	for n = 1:event_num
		idx = find(full_trace_time == events_time(n));
		idx_pre = idx-datapoint_num_pre;
		idx_post = idx+datapoint_num_post;

		pre_cb = 0;
		post_cb = 0;
		if idx_pre < 1
			pre_cb = 1-idx_pre; % cb: calibration
			idx_pre = 1;
		end

		if idx_post > full_datapoint_num
			post_cb = idx_post-full_datapoint_num;
			idx_post = full_datapoint_num;
		end
		trace_aligned(1+pre_cb:datapoint_num-post_cb, n) = full_trace_data(idx_pre:idx_post);
	end
	event_trace.time = trace_time_aligned;
	event_trace.value = trace_aligned;
	event_trace.value_mean = mean(event_trace.value, 2, 'omitnan');
	event_trace.value_std = std(event_trace.value, 0, 2, 'omitnan');

end