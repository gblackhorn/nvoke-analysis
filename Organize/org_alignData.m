function [alignedData_filtered] = org_alignData(alignedData,varargin)
	% Based on selected peak categories, filter the aligned trace (alignedData.traces.value),
	% and recalculate the mean and std of them
	% peak categories can be modified with func [mod_cat_name] before filtering


	% Defaults
	mod_pcn = true; % true/false modify the peak category names with func [mod_cat_name]
	keep_catNames = {'trig', 'trig-AP', 'rebound'}; % event will be kept if peak cat if one of these

	criteria_excitated = 0.5;
	criteria_rebound = 1;
	stim_time_error = 0;

	debug_mode = false;

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('keep_catNames', varargin{ii})
	        keep_catNames = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('criteria_excitated', varargin{ii})
	        criteria_excitated = varargin{ii+1};
        elseif strcmpi('criteria_rebound', varargin{ii})
            criteria_rebound = varargin{ii+1};
        elseif strcmpi('stim_time_error', varargin{ii})
            stim_time_error = varargin{ii+1};
	    elseif strcmpi('debug_mode', varargin{ii})
            debug_mode = varargin{ii+1};
	    elseif strcmpi('mod_pcn', varargin{ii})
            mod_pcn = varargin{ii+1};
	    end
	end	


	%% Content
	num_cat = numel(keep_catNames);
	num_trials = numel(alignedData);
	for nt = 1:num_trials
		if debug_mode
			fprintf('trial %d\n', nt) % debug line
		end

		event_type = alignedData(nt).event_type;
		stim_name = alignedData(nt).stim_name;
		stimInfo = alignedData(nt).stimInfo;

		traces = alignedData(nt).traces;
		dis_idx_roi = [];
		num_rois = numel(traces);
		for nr = 1:num_rois
			if debug_mode
				fprintf(' -roi %d\n', nr) % debug line
				if nt == 1 && nr == 2
					pause
				end
			end

			if mod_pcn
				[traces(nr).eventProp] = mod_cat_name(traces(nr).eventProp,'dis_extra',false);
			end

			peak_category = {traces(nr).eventProp.peak_category};
			dis_tf_event = ones(size(peak_category));
			switch event_type
				case 'detected_events'
					for nc = 1:num_cat
						tf = strcmpi(keep_catNames{nc}, peak_category);
						idx_keep = find(tf);
						dis_tf_event(idx_keep) = 0;
					end
					dis_idx_event = find(dis_tf_event);
					traces(nr).eventProp(dis_idx_event) = [];
					if isempty(traces(nr).eventProp)
						dis_idx_roi = [dis_idx_roi nr];
					else
						traces(nr).value(:, dis_idx_event) = [];
						trace.mean_val = mean(traces(nr).value, 2, 'omitnan');
						trace.std = std(traces(nr).value, 0, 2, 'omitnan');
					end
				case 'stimWin'
					% criteria_excitated and criteria_rebound are used in this part
					% check setting in func [organize_category_peaks]
					criteria_excitated = 2;
					criteria_rebound = 1;
					switch stim_name
						case 'OG-LED-5s GPIO-1-1s'
							stimWin = stimInfo(1).time_range_notAlign;
							stimWin_ext = stimInfo(2).time_range_notAlign;
						case 'no-stim'
							dis_idx_roi = [dis_idx_roi nr];
						otherwise
							stimWin = stimInfo(1).time_range_notAlign;
					end

					dis_tf_win = ones(size(traces(nr).value, 2), 1);
					for nc = 1:num_cat
						tf = strcmpi(keep_catNames{nc}, peak_category);
						idx_keep = find(tf);
						dis_tf_event(idx_keep) = 0;
						if ~isempty(idx_keep)
							for n = 1:numel(idx_keep) % event
								riseT = traces(nr).eventProp(idx_keep(n)).rise_time;
								switch keep_catNames{nc}
									case 'trig'
										Tdiff = riseT+stim_time_error-stimWin(:, 1); % diff between event rise time and stim window starts
										keep_stim_idx = find(Tdiff>=0 & Tdiff<criteria_excitated);
										dis_tf_win(keep_stim_idx) = 0;															
									case 'trig-AP'
										Tdiff = riseT+stim_time_error-stimWin_ext(:, 1); % diff between event rise time and stim window starts
										keep_stim_idx = find(Tdiff>=0 & Tdiff<criteria_excitated);
										dis_tf_win(keep_stim_idx) = 0;	
									case 'rebound'
										Tdiff = riseT-stim_time_error-stimWin(:, 2); % diff between event rise time and stim window starts
										keep_stim_idx = find(Tdiff>=0 & Tdiff<criteria_rebound);
										dis_tf_win(keep_stim_idx) = 0;
									otherwise
								end
							end
						end
					end
					dis_idx_event = find(dis_tf_event);
					traces(nr).eventProp(dis_idx_event) = [];
					if isempty(traces(nr).eventProp)
						dis_idx_roi = [dis_idx_roi nr];
					else
						dis_idx_win = find(dis_tf_win);
						traces(nr).value(:, dis_idx_win) = [];
						trace.mean_val = mean(traces(nr).value, 2, 'omitnan');
						trace.std = std(traces(nr).value, 0, 2, 'omitnan');
					end
			end
		end
		traces(dis_idx_roi) = [];
		alignedData(nt).traces = traces;
	end
	alignedData_filtered = alignedData;
end