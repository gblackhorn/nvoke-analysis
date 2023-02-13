function [check_start,check_end] = find_window_range_for_peak(roi_trace,peakLoc,varargin)
    % use trace from a single roi and peak location to find a window ranges for
    % peaks. Returned check_start and check_end can be used to find rise and
    % decay locations
    %   Detailed explanation goes here

    % Defaults
    % freq = 20; % unit: Hz.
    % max_StartWin = 1; % unit: s. Maximum duration from check_start to peak. This window is used to find the
    % % start point of a peak
    start_lim = false;
    freq = nan; 
    max_RiseWin = 1;

    % Options
    for ii = 1:2:(nargin-2)
        if strcmpi('freq', varargin{ii})
            freq = varargin{ii+1}; % unit: Hz. sampling frequency
        elseif strcmpi('max_RiseWin', varargin{ii})
            max_StartWin = varargin{ii+1}; % unit: s. Maximum duration from check_start to peak.
        % elseif strcmpi('EventTime', varargin{ii})
        %     EventTime = varargin{ii+1};
        end
    end

    % if exist('freq','var') && exist('max_RiseWin','var')
    if ~isnan(freq) && ~isnan(max_RiseWin)
        start_lim = true;
        StartWin_dpNum = max_StartWin*freq; % convert the time (max_StartWin) to datapoint number
    end

    if ~isempty(peakLoc)
    	peak_num = length(peakLoc);
    	check_start = NaN(peak_num, 1);
    	check_end = NaN(peak_num, 1);
    	for pn = 1:peak_num
    		% Decide the range to find locations of rise start and decay end for each peak
            if start_lim
                lim_check_start = peakLoc(pn)-StartWin_dpNum;
            end
    		if pn ==1 % first peak
                unlim_check_start = 1;

    			% check_start(pn) = 1;
    			if length(peakLoc) == 1 % there is only 1 peak
    				check_end(pn) = size(roi_trace, 1);
    			else
    				check_end(pn) = peakLoc(pn+1); % next peak loc
    			end
            else
                unlim_check_start = peakLoc(pn-1); % previous peak loc

                if pn > 1 && pn < length(peakLoc)
                    check_end(pn) = peakLoc(pn+1); % next peak loc
                elseif pn == length(peakLoc)
                    check_end(pn) = size(roi_trace, 1);
                end
            end

            if start_lim && lim_check_start>unlim_check_start
                check_start(pn) = lim_check_start;
            else
                check_start(pn) = unlim_check_start;
            end
    	end
    end
end

