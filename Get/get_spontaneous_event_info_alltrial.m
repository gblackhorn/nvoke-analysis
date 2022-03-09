function [spont_event_info,varargout] = get_spontaneous_event_info_alltrial(rec_data,varargin)
    % Return the spontaneous event frequency of all trials in rec_data
    %   rec_data: a cell array containing information of multiple trials 
    %   recording_time: single column array from decon or raw data 
    %   Note: peak info from lowpassed data is used  


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
    trial_num = size(rec_data, 1); % number of trials

    spont_event_info_cell = cell(trial_num, 1);
    for n = 1:trial_num
        trial_data = rec_data(n, :);

        % Info for debug
        trial_name = trial_data{1};
        % fprintf('%d/%d trials: %s\n', n, trial_num, trial_name);
        % if  n == 36
        %     pause
        % end


        [spont_event_info_cell{n}] = get_spontaneous_event_info_trial(trial_data,...
            'stim_time_error', setting.stim_time_error,...
            'rebound_winT', setting.rebound_winT, 'sortout_event', setting.sortout_event);

        % spont_event_info(n) = spont_event_info_trial;
    end

    
    % Concatenate spont_event_info from cell array and creat a single structure
    spont_event_info = [spont_event_info_cell{:}];


    % Remove the ROIs with "empty" and "zero" events 
    [spont_event_info] = filter_struct(spont_event_info, {'event_num'}, {'notzero'}, 'discard_empty', true);



    % idx_empty = find(cellfun(@isempty, {spont_event_info.event_num}));
    % spont_event_info(idx_empty) = [];
    % idx_zero = find([spont_event_info.event_num]==0);
    % spont_event_info(idx_zero) = [];
end


