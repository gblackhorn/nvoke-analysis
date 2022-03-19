function [rise_decay_loc] = FindRiseandDecay_with_existing_peakinfo(roi_trace,peakLoc,existing_peakInfo,varargin)
    % Use a single roi_trace, peak locations, and existing peakInfo (decon events), including rise and decay, to find the locations of
    % rise and decay for each peak. 
    %   roi_trace: single column array. Information of a single roi trace. 
    %				Information of a single roi trace. Output of func findpeaks
    
    % Defaults
    eventWin_idx = [];

    % Options
        % Optionals
    for ii = 1:2:(nargin-3)
        if strcmpi('eventWin_idx', varargin{ii})
            eventWin_idx = varargin{ii+1};
        % elseif strcmpi('eventWin_idx', varargin{ii})
        %     eventWin_idx = varargin{ii+1};
        end
    end



    if ~isempty(peakLoc)
    	peak_num = length(peakLoc);
    	rise_decay_loc = table('Size', [peak_num 4],...
    		'VariableNames', {'rise_loc', 'decay_loc', 'check_start', 'check_end'},...
            'VariableTypes', {'double', 'double', 'double', 'double'});

        if isempty(eventWin_idx)
        	% Decide the range to find locations of rise start and decay end for each peak
        	[check_start,check_end] = find_window_range_for_peak(roi_trace,peakLoc);
            for pn = 1:peak_num
                [existing_peak_loc, existing_peak_idx] = min(abs(existing_peakInfo.peak_loc-peakLoc(pn)));
                rise_decay_loc.rise_loc(pn) = existing_peakInfo.rise_loc(existing_peak_idx);
                rise_decay_loc.decay_loc(pn) = existing_peakInfo.decay_loc(existing_peak_idx);
            end
        else
            check_start = eventWin_idx(:, 1);
            check_end = eventWin_idx(:, 2);
            for pn = 1:peak_num
                % Find the locations of rise start (rise_loc) and decay end (decay_loc)
                rise_loc = check_start(pn)+find(diff(roi_trace(check_start(pn):peakLoc(pn)))<=0, 1, 'last');
                decay_diff_value = diff(roi_trace(peakLoc(pn):check_end(pn))); % diff value from peak to check_end
                diff_turning_value = min(decay_diff_value); % when the diff of decay is smallest. Decay stop loc will be looked for from here
                diff_turning_loc = peakLoc(pn)+find(decay_diff_value==diff_turning_value, 1, 'first');
                decay_diff_value_after_turning = diff(roi_trace(diff_turning_loc:check_end(pn))); % from decay diff_turning_loc to check_end;
                if find(decay_diff_value_after_turning<=0) % if decay continue after the decay_diff_value_after_turning
                  decay_stop_diff_value = max(decay_diff_value_after_turning(decay_diff_value_after_turning<=0)); % discard 
                  decay_loc = diff_turning_loc+find(diff(roi_trace(diff_turning_loc:check_end(pn)))==decay_stop_diff_value, 1, 'first');
                else % most likely another activity jump in before complete recorvery
                  decay_loc = diff_turning_loc;
                end
                if isempty(rise_loc)
                  rise_loc = peakLoc(pn); % when no results, assign peak location to it
                end
                if isempty(decay_loc)
                  decay_loc = peakLoc(pn); % when no results, assign peak location to it
                end

                rise_decay_loc.rise_loc(pn) = rise_loc;
                rise_decay_loc.decay_loc(pn) = decay_loc;
            end
        end

    	% for pn = 1:peak_num
     %        [existing_peak_loc, existing_peak_idx] = min(abs(existing_peakInfo.peak_loc-peakLoc(pn)));
     %        rise_decay_loc.rise_loc(pn) = existing_peakInfo.rise_loc(existing_peak_idx);
     %        rise_decay_loc.decay_loc(pn) = existing_peakInfo.decay_loc(existing_peak_idx);
    	% end

    	rise_decay_loc.check_start = check_start;
    	rise_decay_loc.check_end = check_end;
    else
    	error('no peakLoc information')
    end
end

