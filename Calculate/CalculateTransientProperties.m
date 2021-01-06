function [TransientProperties,varargout] = CalculateTransientProperties(RecInfoTable,varargin)
    % Read a table (RecInfoTable) containing time and traces information. Find peaks in traces
    % and output properties of peaks/transients, such as locations of rises and
    % their durations
    %   RecInfoTable: a table variable
    %		- 1st col: time infomation
    %		- 2nd-end col: traces
    %   varargin{1}: deconvoluted=1, not_deconvoluted=0
    %   varargin{2}: 'none', 'lowpass', 'smooth', 'highpass'
    %   varargin{3}: value in Hz for filter selected by varargin{2} or span if 'smooth' is choosen
    % 	example: input: not deconvoluted data, choose 'lowpass' with frequency 1 Hz. Return TransientProperties and lowpassed traces 
    %			 [TransientProperties,RecInfoTable_processed] = CalculateTransientProperties(RecInfoTable, 0, 'lowpass', 1)

    prominence_factor = 4;
    smooth_method = 'loess';
    pack_singlerow_table_in_cell = 0;
    TransientProperties_col_names = {'peak_loc', 'peak_mag', 'rise_loc', 'decay_loc','peak_time',...
	'rise_time', 'decay_time', 'rise_duration', 'decay_duration', 'peak_mag_relative',...
	'peak_loc_25percent', 'peak_mag_25percent', 'peak_time_25percent', 'peak_loc_75percent', 'peak_mag_75percent',...
	'peak_time_75percent', 'peak_slope', 'peak_zscore'};
	TransientProperties_col_names_highpass = {'std'};

    if nargin >= 2
    	decon = varargin{1}; % 1: deconvoluted trace. 0: not deconvoluted
    	if nargin >= 3
    		if strcmpi('none', varargin{2})
    			filter_name = 'none';
    			filter_parameter = NaN;  
    		elseif strcmpi('lowpass', varargin{2})
    			filter_name = 'lowpass';
			elseif strcmpi('smooth', varargin{2})
				filter_name = ['smooth_', smooth_method];
    		elseif strcmpi('highpass', varargin{2})
    			filter_name = 'highpass';
    		else
    			error('Specify filter name for input 3: lowpass or highpass')
    		end
    		if nargin >= 4 
    			filter_parameter = varargin{3};
    		elseif ~strcmpi('none', varargin{2})
    			error('Input filter frequency for input 4')
    		end
    	end
    end 
   
   	look_for_peaks = 1; % default: find peaks and calculate properties. When 'highpass' filter is applied, this will be changed to 0 automatically
   	roi_names = RecInfoTable.Properties.VariableNames(2:end);
    time_info = RecInfoTable{:, 1}; % RecInfoTable.Time
    roi_num = size(RecInfoTable, 2)-1; % number of rois/traces
    rec_fq = 1/(time_info(10)-time_info(9));
    TransientProperties = cell(1, roi_num);

   	RecInfoTable_processed = RecInfoTable; % allocate ram for RecInfoTable_processed
    for n = 1:roi_num % go through every roi
    	roi_trace = RecInfoTable{:, (n+1)};
    	if decon == 1
    		[peakMag, peakLoc, peakWidth, peakProm] = findpeaks(roi_trace);
    	elseif decon == 0
    		if strcmpi('highpass', varargin{2})
    			roi_trace = highpass(roi_trace, filter_parameter, rec_fq);
    			roi_trace_std = std(roi_trace);
    			look_for_peaks = 0; % Don't look for peak if traces are highpass filtered
    		else
    			if strcmpi('none', varargin{2})
    				roi_trace = roi_trace;
    				[peakMag, peakLoc, peakWidth, peakProm] = findpeaks(roi_trace);
    			else
	    			if strcmpi('lowpass', varargin{2})
	    				roi_trace = lowpass(roi_trace, filter_parameter, rec_fq);
	    			elseif strcmpi('smooth', varargin{2})
	    				roi_trace = smooth(time_info, roi_trace, filter_parameter, smooth_method);
	    			end
	    			prominence = (max(roi_trace)-min(roi_trace))/prominence_factor;
	    			[peakMag, peakLoc, peakWidth, peakProm] = findpeaks(roi_trace, 'MinPeakProminence', prominence);
    			end
    		end
    	end
    	RecInfoTable_processed{:, (n+1)} = roi_trace;

    	if look_for_peaks == 1
    		if ~isempty(peakLoc) % if there are peak(s) in the trace
    			peak_time = time_info(peakLoc);
    			[rise_decay_loc] = FindRiseandDecay(roi_trace,peakLoc); % find the locations of rise, decay, check_start and check_end for every peak
    			rise_loc = rise_decay_loc.rise_loc;
    			decay_loc = rise_decay_loc.decay_loc;
    			rise_time = time_info(rise_loc);
    			decay_time = time_info(decay_loc);
    			rise_duration = peak_time-rise_time;
    			decay_duration = decay_time-peak_time;

    			peakMag_delta = peakMag-roi_trace(rise_loc); % delta peakmag: subtract rising point value
    			peakMag_10per_target = peakMag_delta*0.1+roi_trace(rise_loc); % 10% peakmag value
    			peakMag_90per_target = peakMag_delta*0.9+roi_trace(rise_loc); % 90% peakmag value

    			peakLoc_10per = FindClosest(roi_trace, peakMag_10per_target, [rise_loc peakLoc]);
    			peakLoc_90per = FindClosest(roi_trace, peakMag_90per_target, [rise_loc peakLoc]);
    			peakMag_10per = roi_trace(peakLoc_10per);
    			peakMag_90per = roi_trace(peakLoc_90per);
    			peakTime_10per = time_info(peakLoc_10per);
    			peakTime_90per = time_info(peakLoc_90per);

    			value_diff_10_90per = peakMag_90per-peakMag_10per; % differences of 10per and 90per peak in magnitude
    			time_diff_10_90per = peakTime_90per-peakTime_10per; % differences of 10per and 90per peak in time
    			peakSlope = value_diff_10_90per./time_diff_10_90per;

    			TransientProperties{n} = [peakLoc, peakMag, rise_loc, decay_loc, peak_time,...
    			rise_time, decay_time, rise_duration, decay_duration, peakMag_delta,...
    			peakLoc_10per, peakMag_10per, peakTime_10per, peakLoc_90per, peakMag_90per,...
    			peakTime_90per, peakSlope];
    			% TransientProperties{n} = num2cell(TransientProperties{n});
    			if length(peakLoc) == 1
    				pack_singlerow_table_in_cell = 1;
    			else
    				pack_singlerow_table_in_cell = 0;
    			end
    		else
    			TransientProperties{n} = double.empty(0, 17);
    			TransientProperties{n} = num2cell(TransientProperties{n});
			end
			% if pack_singlerow_table_in_cell == 1 % the size of single row table is 1xn, the size of multi-row table is 1x1
			% 	TransientProperties_cellpkg = array2table(TransientProperties{n},...
   %  				'VariableNames', TransientProperties_col_names(1:17));
			% 	TransientProperties{n} = TransientProperties_cellpkg;
			% else
			% 	TransientProperties{n} = array2table(TransientProperties{n},...
   %  				'VariableNames', TransientProperties_col_names(1:17));
			% end

			TransientProperties{n} = array2table(TransientProperties{n},...
				'VariableNames', TransientProperties_col_names(1:17));
		elseif look_for_peaks == 0
			TransientProperties{n} = [roi_trace_std];
			TransientProperties{n} = array2table(TransientProperties(n),...
    				'VariableNames', TransientProperties_col_names_highpass);
    	end
    end
	TransientProperties = cell2table(TransientProperties, 'VariableNames', roi_names);
    if nargout >= 2
    	varargout{1}.processed_data = RecInfoTable_processed;
    	varargout{1}.method = filter_name;
    	varargout{1}.parameter = filter_parameter;
    end
end

