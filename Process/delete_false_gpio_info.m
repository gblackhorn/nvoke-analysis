function [gpio_info_modified, varargout] = delete_false_gpio_info(gpio_info, varargin)
    % Delete false GPIO information imported from gpio.csv 
    % gpio.csv files were created by IDAP from nVoke2 recordings

    % Defaults
    ogled_thr = 0.8; % standard signal exported by nVoke is 1
    gpio1_thr = 10000; % standard signal exported by nVoke is higher than 50'000
    digitalGPO_thr = 0.8;

    % discard_gpio_idx = [];
    channel_num = numel(gpio_info); 
    TF_channel = logical(ones(size(gpio_info))); % logical array used to delet false channel

    for i = 1:channel_num
        ch_name = gpio_info(i).name;

        % 'BNC Sync Output' and 'EX-LED' will not be examined and deleted
        if isempty(find(strcmpi(ch_name,{'BNC Sync Output','EX-LED'})))
            signal_max = max(gpio_info(i).time_value(:, 2));

            if ~isempty(strfind(ch_name, 'OG-LED'))
                if signal_max < ogled_thr
                    TF_channel(i) = 0;
                end
            elseif ~isempty(strfind(ch_name, 'Digital GPO'))
                if signal_max < digitalGPO_thr
                    TF_channel(i) = 0;
                end
            elseif ~isempty(strfind(ch_name, 'GPIO'))
                if signal_max < gpio1_thr
                    TF_channel(i) = 0;
                end
            end

        end
    end



    % for i = 3:channel_num % 'BNC Sync Output' and 'EX-LED' are the first 2. Not stimulation channels
    %     ch_name = gpio_info(i).name{:};
    %     signal_max = max(gpio_info(i).time_value(:, 2));

    %     if ~isempty(strfind(ch_name, 'OG-LED'))
    %         if signal_max < ogled_thr
    %             discard_gpio_idx = [discard_gpio_idx i];
    %         end
    %     elseif ~isempty(strfind(ch_name, 'Digital GPO'))
    %         if signal_max < digitalGPO_thr
    %             discard_gpio_idx = [discard_gpio_idx i];
    %         end
    %     elseif ~isempty(strfind(ch_name, 'GPIO'))
    %         if signal_max < gpio1_thr
    %             discard_gpio_idx = [discard_gpio_idx i];
    %         end
    %     end
    % end

    gpio_info_modified = gpio_info(TF_channel);
    varargout{1} = find(TF_channel==0); % locations of deleted channels

    % gpio_info(discard_gpio_idx) = [];
    % gpio_info_modified = gpio_info;
    % varargout{1} = discard_gpio_idx;
end

