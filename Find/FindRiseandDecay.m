function [rise_decay_loc] = FindRiseandDecay(roi_trace,peakLoc,varargin)
    % Use a single roi_trace and peak locations in it to find the locations of
    % rise and decay for each peak. 
    %   roi_trace: single column array. Information of a single roi trace. 
    %				Information of a single roi trace. Output of func findpeaks

    % Defaults
    freq = nan; 
    max_RiseWin = 1;

    % Optional
    for ii = 1:2:(nargin-2)
        if strcmpi('freq', varargin{ii})
            freq = varargin{ii+1}; % unit: Hz.
        elseif strcmpi('max_RiseWin', varargin{ii})
            max_StartWin = varargin{ii+1}; % unit: s. Maximum duration from check_start to peak.
        % elseif strcmpi('EventTime', varargin{ii})
        %     EventTime = varargin{ii+1};
        end
    end
    
    if ~isempty(peakLoc)
    	peak_num = length(peakLoc);
    	rise_decay_loc = table('Size', [peak_num 4],...
    		'VariableNames', {'rise_loc', 'decay_loc', 'check_start', 'check_end'},...
            'VariableTypes', {'double', 'double', 'double', 'double'});

    	% Decide the range to find locations of rise start and decay end for each peak
    	[check_start,check_end] = find_window_range_for_peak(roi_trace,peakLoc,...
            'freq',freq,'max_RiseWin',max_RiseWin);

    	for pn = 1:peak_num
    		% % Decide the range to find locations of rise start and decay end for each peak
    		% if pn ==1 % first peak
    		% 	check_start = 1;
    		% 	if length(peakLoc) == 1 % there is only 1 peak
    		% 		check_end = size(roi_trace, 1);
    		% 	else
    		% 		check_end = peakLoc(pn+1); % next peak loc
    		% 	end
    		% elseif pn > 1 && pn < length(peakLoc) % peaks in the middle
    		% 	check_start = peakLoc(pn-1); % previous peak loc
    		% 	check_end = peakLoc(pn+1); % next peak loc
    		% elseif pn == length(peakLoc)
    		% 	check_start = peakLoc(pn-1); % previous peak loc
    		% 	check_end = size(roi_trace, 1);
    		% end

    		% Find the locations of rise start (rise_loc) and decay end (decay_loc)
    		% rise_loc = check_start(pn)+find(diff(roi_trace(check_start(pn):peakLoc(pn)))<=0, 1, 'last');
            idx = find(diff(roi_trace(check_start(pn):peakLoc(pn)))<=0, 1, 'last');
            % [min_val_CheckToPeak,idx]= min(roi_trace(check_start(pn):peakLoc(pn))); 

            rise_loc = check_start(pn)+idx-1;
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
    	rise_decay_loc.check_start = check_start;
    	rise_decay_loc.check_end = check_end;
    else
    	error('no peakLoc information')
    end
end

