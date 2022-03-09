function [time_info_section,aligned_events,varargout] = align_events_roi(time_info,traceData,align_points,duration_pre,duration_post,varargin)
%Align the events in a ROI. 
% Use get_event_trace instead of this
%   Used for plotting the aligned events
	% time_info: time stamp covers the events
	% traceData: traceData covers the events
	% align_points: time points at which trace data is extracted and aligned to 
	% duration_pre/post: seconds. trace data between (align_points-duration_pre) and (align_points-duration_post) is extracted
	%						number of extracted traces equals the number of align_points
	% varargin: data can be scaled to make the amplitude of events the same. Input event peak time points for this
	% peak_points(in varargin): Time of event peaks. The same size as align_points


	% Default
	scale_data = false;
	align_on_y = true; % subtract data with the values at the align points

	% Optionals
	for ii = 1:2:(nargin-5)
	    if strcmpi('scale_data', varargin{ii})
	        scale_data = varargin{ii+1};
	    elseif strcmpi('peak_points', varargin{ii})
	        peak_points = varargin{ii+1};
	    elseif strcmpi('align_on_y', varargin{ii})
	        align_on_y = varargin{ii+1};
	    end
	end

	% ====================
	% Main content
	rec_freq = round(1/(time_info(5)-time_info(4))); % recording frequency. round it to get an integer
	aligned_events_size_row = round((duration_pre+duration_post)*rec_freq)+5; % last number 5 is to expand the length of data in case some sections are bigger than others
	time_info_section = [0:1/rec_freq:(aligned_events_size_row-1)/rec_freq]'; % time for the aligned event data. start from 0
	event_num = numel(align_points);
	aligned_events_size_col = event_num;

	aligned_events = NaN(aligned_events_size_row, aligned_events_size_col); 
	aligned_events_scaled = aligned_events;
	aligned_point_loc = 2+round(duration_pre*rec_freq)+1; % row location for aligned points in the "aligned_events"
	time_info_section = time_info_section-(aligned_point_loc-1)/rec_freq; % align the time info to the event-align point

	event_time_range = [align_points-duration_pre align_points+duration_post];
	event_loc_range = NaN(size(event_time_range));

	idx_before_start = find(event_time_range(:, 1)<time_info(1)); % Find time smaller than the first time stamp
	idx_after_end = find(event_time_range(:, 2)>time_info(end)); % Find time bigger than last recording point

	event_time_range(idx_before_start, 1) = time_info(1); 
	event_time_range(idx_after_end, 2) = time_info(end);

	[event_time_range(:, 1), event_loc_range(:, 1)] = find_closest_in_array(event_time_range(:, 1), time_info); 
	[event_time_range(:, 2), event_loc_range(:, 2)] = find_closest_in_array(event_time_range(:, 2), time_info);
	[aligned_event_time, aligned_event_loc] = find_closest_in_array(align_points, time_info); % aligned_event_time == align_points
	aligned_point_value = traceData(aligned_event_loc);
	if scale_data
		if exist('peak_points', 'var')
			[peak_time, peak_loc] = find_closest_in_array(peak_points, time_info); % peak_time == peak_points
			peak_point_value = traceData(peak_loc);
			peak_amp = peak_point_value-aligned_point_value;
		else
			fprintf('peak_points was not input, cannot scale data')
			return
		end
	end

	locDiff_start_alignPoint = aligned_event_loc-event_loc_range(:, 1); % index difference between event start points and align points in time and trace data
	locDiff_alignPoint_end = event_loc_range(:, 2)-aligned_event_loc; % index difference between event end points and align points

	aligned_events_range(:, 1) = aligned_point_loc-locDiff_start_alignPoint; % location of first event data points in the row of output "aligned_events"
	aligned_events_range(:, 2) = aligned_point_loc+locDiff_alignPoint_end; % location of last event data points in the row of output "aligned_events"

	for n = 1:event_num
		eventData = traceData(event_loc_range(n, 1): event_loc_range(n, 2));
		if align_on_y
			eventData = eventData-aligned_point_value(n);
		end
		aligned_events(aligned_events_range(n, 1):aligned_events_range(n, 2), n) = eventData;

		if scale_data
			eventData_scaled = eventData/peak_amp(n);
			aligned_events_scaled(aligned_events_range(n, 1):aligned_events_range(n, 2), n) = eventData_scaled;
		end
	end

	varargout{1} = aligned_events_scaled; % if scale_data==false, this var only contains NaNs  
end

