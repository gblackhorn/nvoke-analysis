function [check_start,check_end] = find_window_range_for_peak(roi_trace,peakLoc)
    % use trace from a single roi and peak location to find a window ranges for
    % peaks. Returned check_start and check_end can be used to find rise and
    % decay locations
    %   Detailed explanation goes here
    if ~isempty(peakLoc)
    	peak_num = length(peakLoc);
    	check_start = NaN(peak_num, 1);
    	check_end = NaN(peak_num, 1);
    	for pn = 1:peak_num
    		% Decide the range to find locations of rise start and decay end for each peak
    		if pn ==1 % first peak
    			check_start(pn) = 1;
    			if length(peakLoc) == 1 % there is only 1 peak
    				check_end(pn) = size(roi_trace, 1);
    			else
    				check_end(pn) = peakLoc(pn+1); % next peak loc
    			end
    		elseif pn > 1 && pn < length(peakLoc) % peaks in the middle
    			check_start(pn) = peakLoc(pn-1); % previous peak loc
    			check_end(pn) = peakLoc(pn+1); % next peak loc
    		elseif pn == length(peakLoc)
    			check_start(pn) = peakLoc(pn-1); % previous peak loc
    			check_end(pn) = size(roi_trace, 1);
    		end
    	end
    end
end

