function [ca_events_conditioned,varargout] = collect_events_with_conditions(ca_events,varargin)
    % Return a subset of ca_events chosen by using condition(s)
    % All fields containing a single string can be used as condition

    % ca_events: structure var calcium event info
    %   Fields: trialName, roiName, fovID, stim_name, combine_stim, peak_category
    %           rise_duration, peak_mag_delta, baseDiff, baseDiff_stimWin, rise_delay

    % Example:
    %   [ca_events_conditioned] = collect_events_with_conditions(ca_events,...
    %                               'stim_name',stim_name_str,'roiName',roiName_str,'fieldname',fieldname_str)

    
    % Defaults
    FieldN = fieldnames(ca_events);

    % Optionals for inputs
    for ii = 1:2:(nargin-1)
        if ~isempty(find(strcmpi(varargin{ii}, FieldN))) && ~isempty(varargin{ii+1})
            condition.(varargin{ii}) = varargin{ii+1};
        end
    end

    %% main contents
    con_fn = fieldnames(condition); % fieldnames used for conditioning
    con_num = numel(con_fn); % number of fields used for conditioning

    ca_events_conditioned = ca_events;

    for n = 1:con_num
        f = con_fn{n}; % one field name used for conditioning
        f_str = condition.(f); 

        ca_events_f_contents = {ca_events_conditioned.(f)};
        idx = find(strcmpi(f_str, ca_events_f_contents)); % index of entries meet the condition, having "f_str" in field "f"

        ca_events_conditioned = ca_events_conditioned(idx); % Get the entries meet the condition
    end
end

