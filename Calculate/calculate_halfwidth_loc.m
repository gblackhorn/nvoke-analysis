function [halfwidth_loc,varargout] = calculate_halfwidth_loc(roi_trace,rise_loc,peak_loc,decay_loc,varargin)
    % calculate the halfwidth locations around peak for calculating the (full-width at half maximum) FWHM 
    
    % Defaults

    % Optionals for inputs
    % for ii = 1:2:(nargin-1)
    % 	if strcmpi('eventWin_loc', varargin{ii})
    % 		eventWin_loc = varargin{ii+1};
    % 	% elseif strcmpi('sz', varargin{ii})
    % 	% 	sz = varargin{ii+1};
    % 	% elseif strcmpi('save_fig', varargin{ii})
    % 	% 	save_fig = varargin{ii+1};
    %  %    elseif strcmpi('save_dir', varargin{ii})
    %  %        save_dir = varargin{ii+1};
    %     end
    % end

    %% main contents
    rise_amp = roi_trace(rise_loc); % value at the rise_loc
    peak_amp = roi_trace(peak_loc); % value at the rise_loc

    amp_delta = peak_amp-rise_amp;
    half_max_delta = amp_delta./2;
    half_max = rise_amp+half_max_delta;

    half_max_start_loc = FindClosest_multiWindows(roi_trace,half_max,[rise_loc, peak_loc]);
    half_max_end_loc = FindClosest_multiWindows(roi_trace,half_max,[peak_loc, decay_loc]);

    for n = 1:numel(peak_loc)
        if half_max_end_loc(n) == peak_loc
            half_max_start_loc(n) = NaN;
            half_max_end_loc(n) = NaN;
        end
    end

    halfwidth_loc = [half_max_start_loc half_max_end_loc];


    % Validating the halfwidth_loc



    % rise_to_peak_dataNum = round((peak_loc-rise_loc+1)/numel(rise_loc));
    % datapoint_int = amp_delta/(rise_to_peak_dataNum-1);

    % half_max_val_diff = roi_trace(half_max_end_loc)-roi_trace(half_max_start_loc);
    % invalid_half_max_pair = find(half_max_val_diff>datapoint_int*3);


end

