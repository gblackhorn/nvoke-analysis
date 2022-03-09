function [spont_event_info,varargout] = get_spontaneous_event_info_trial(trial_data,varargin)
    % Return the spontaneous event frequency of a trial with multiple ROIs
    %   trial_data: a cell array containing information of 1 single trial 
    %   recording_time: single column array from decon or raw data 
    %	Note: peak info from lowpassed data is used  


    % Extract useful info from trial data
    rec_name_col = 1;
    trace_col = 2;
    stim_str_col = 3;
    gpio_col = 4;
    peak_info_col = 5;

    recording_name = trial_data{rec_name_col};
    stim_name = trial_data{stim_str_col};
    recording_time = trial_data{trace_col}.raw.Time;
    peak_info_table = trial_data{peak_info_col};

    category_ID_exist = false;
    if isfield(trial_data{trace_col}, 'mouseID') && isfield(trial_data{trace_col}, 'fovID')
        mouseID = trial_data{trace_col}.mouseID;
        fovID = trial_data{trace_col}.fovID;
        [fov_str] = get_fov_info(trial_data);
        category_ID_exist = true;
    else
        warning('mouseID and fovID not found in trial %s', recording_name)
    end

    gpio_info = trial_data{gpio_col};
    if numel(gpio_info) > 2 % if stimulation was applied
        stimulation_win = trial_data{gpio_col}(3).stim_range; % 3 is the first gpio channel used for stimulation. if 2 stimuli were used, 4 is the second
        stimulation_repeat = size(stimulation_win, 1);
        setting.stim_winT = stimulation_win(1, 2)-stimulation_win(1, 1); % the duration of stimulation 
    else
        stimulation_win = [];
        stimulation_repeat = [];
        setting.stim_winT = [];
    end

    
    % Defaults
    setting.stim_time_error = 0; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
    
    setting.rebound_winT = 1; % second. rebound window duration
    setting.sortout_event = 'rise'; % use rise location to sort peak
    % setting.pre_stim_duration = 10; % seconds
    % setting.post_stim_duration = 10; % seconds

    % Optionals
    for ii = 1:2:(nargin-1)
        if strcmpi('stim_time_error', varargin{ii})
            setting.stim_time_error = varargin{ii+1};
        elseif strcmpi('stim_winT', varargin{ii})
            setting.stim_winT = varargin{ii+1};
        elseif strcmpi('rebound_winT', varargin{ii})
            setting.rebound_winT = varargin{ii+1};
        elseif strcmpi('sortout_event', varargin{ii})
            setting.sortout_event = varargin{ii+1};
        % elseif strcmpi('pre_stim_duration', varargin{ii})
        %     setting.pre_stim_duration = varargin{ii+1};
        % elseif strcmpi('post_stim_duration', varargin{ii})
        %     setting.post_stim_duration = varargin{ii+1};
        end
    end

    % Main contents
    roi_num = size(peak_info_table, 2);
    % spont_event_info = struct;
    for n = roi_num:-1:1
        roi_name = peak_info_table.Properties.VariableNames{n};
        trace_data = trial_data{trace_col}.lowpass.(roi_name);

        % Info for debug
        % fprintf(' - %d/%d rois: %s\n', n, roi_num, roi_name);



        peak_properties_table = peak_info_table{'peak_lowpass', roi_name}{:}; 

        [event_info] = get_spontaneous_event_info_roi(peak_properties_table,...
            stimulation_win,recording_time,'trace_data',trace_data,...
            'stim_time_error', setting.stim_time_error, 'stim_winT', setting.stim_winT,...
            'sortout_event', setting.sortout_event,'rebound_winT', setting.rebound_winT);

        if ~isempty(event_info)
            event_info.rec_name = recording_name;
            event_info.roi_name = roi_name;
            event_info.stim = stim_name;

            if category_ID_exist
                event_info.mouseID = mouseID;
                event_info.fovID = fovID;
                event_info.fovStr = fov_str;
            end

            spont_event_info(n) = event_info;
        % else
        %     spont_event_info(n) = [];
        end
    end
    if exist('spont_event_info', 'var')
        spont_event_info = orderfields(spont_event_info);
    else
        spont_event_info = [];
    end
    % if ~isempty(spont_event_info)
    %     spont_event_info = orderfields(spont_event_info);
    % end
end


