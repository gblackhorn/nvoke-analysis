function [halfwidth_loc,varargout] = calculate_halfwidth_loc(roi_trace,rise_loc,peak_loc,decay_loc,varargin)
    % calculate the halfwidth locations around peak for calculating the (full-width at half maximum) FWHM 
    
    % Defaults
    freq = 20; % sampling frequency
    maxTimeRange = 5; % unit: second. max time range for finding the halfMax width point

    % Optionals for inputs
    for ii = 1:2:(nargin-4)
    	if strcmpi('freq', varargin{ii})
    		freq = varargin{ii+1};
    	elseif strcmpi('maxTimeRange', varargin{ii})
    		maxTimeRange = varargin{ii+1};
        end
    end

    %% main contents
    rise_amp = roi_trace(rise_loc); % value at the rise_loc
    peak_amp = roi_trace(peak_loc); % value at the rise_loc

    amp_delta = peak_amp-rise_amp;
    half_max_delta = amp_delta./2;
    half_max = rise_amp+half_max_delta;

    % % find the half max in specific windows and use them as start and end of half-max width
    % % Use the closest value in [rise peak] and [peak decay] windows
    % half_max_start_loc = FindClosest_multiWindows(roi_trace,half_max,[rise_loc, peak_loc]);
    % half_max_end_loc = FindClosest_multiWindows(roi_trace,half_max,[peak_loc, decay_loc]);

    % for n = 1:numel(peak_loc)
    %     if half_max_end_loc(n) == peak_loc
    %         half_max_start_loc(n) = NaN;
    %         half_max_end_loc(n) = NaN;
    %     end
    % end


    % find the half max in specific windows and use them as start and end of half-max width
    % use the first >= value in [rise peak] and the furst <= in [peak roi_trace_end]
    maxRange = freq*maxTimeRange;
    half_max_start_loc = getFirstClosest_multiWin(roi_trace,half_max,'big',[rise_loc, peak_loc]);
    half_max_end_loc = getFirstClosest_multiWin(roi_trace,half_max,'small',[peak_loc, repmat(numel(roi_trace),size(peak_loc))],...
        'maxRange',maxRange);

    nanEndLocIDX = find(isnan(half_max_end_loc));
    half_max_start_loc(nanEndLocIDX) = NaN;


    halfwidth_loc = [half_max_start_loc half_max_end_loc];
end

