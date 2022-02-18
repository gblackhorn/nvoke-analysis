function [stim_info, varargout] = get_stim_duration(stim_ch_str, varargin)
    % Return the duration of stimulation channels. 
    % Input: stimulation string: usually the string in recdata/ROIdata{x, 3};
    % 

    % Defaults
    stim_ch_strs = {'OG-LED-', 'GPIO-1-'}; % example: OG-LED-5s, GPIO-1-1s
    stim_ch_num = 0;
    stim_info(1).duration = 0;
    stim_info(1).name = 'no-stim'; 

    for i = 1:numel(stim_ch_strs)
        str_stem = stim_ch_strs{i};
        str_stem_length = numel(str_stem); % length of string stem, such as 'OG-LED-' and 'GPIO-1-'
        str_start_idx = strfind(stim_ch_str, str_stem); % 'O' for 'OG-LED'
        str_end_idx = str_start_idx+str_stem_length-1; % '-' for 'OG-LED-'

        if ~isempty(str_start_idx)
            for ii = 1:numel(str_start_idx)
                stim_count = stim_ch_num+ii; 
                stim_unit_idx = strfind(stim_ch_str(str_end_idx(ii):end), 's')+str_end_idx(ii)-1; % index of 's' in 'OG-LED-1s'
                stim_dur_str_idx = [(str_end_idx(ii)+1):(stim_unit_idx-1)];
                stim_info(stim_count).duration = str2num(stim_ch_str(stim_dur_str_idx));
                stim_info(stim_count).name = stim_ch_str(str_start_idx(ii):stim_unit_idx);
                stim_ch_num = stim_ch_num+1;
            end
        end

    end
end

