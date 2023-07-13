function [gpio_info_modified, varargout] = delete_false_gpio_info(gpio_info, varargin)
    % Delete false GPIO information imported from gpio.csv 
    % gpio.csv files were created by IDAP from nVoke2 recordings

    % Defaults
    ogled_thr = 0.1; % standard signal exported by nVoke is 1
    gpio1_thr = 10000; % standard signal exported by nVoke is higher than 50'000
    digitalGPO_thr = 0.8;
    discard_ch = {'DI-LED','e-focus'}; % always discard these channels

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
            elseif contains(ch_name,discard_ch)
                TF_channel(i) = 0;
            % elseif ~isempty(strfind(ch_name, 'e-focus'))
            %     TF_channel(i) = 0;
            end
        end
    end


    gpio_info_modified = gpio_info(TF_channel);
    varargout{1} = find(TF_channel==0); % locations of deleted channels
end

