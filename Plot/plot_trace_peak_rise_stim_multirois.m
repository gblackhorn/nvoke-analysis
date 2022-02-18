function [] = plot_trace_peak_rise_stim_multirois(traceinfo,varargin)
    % plot stimulation signal as patches
    % Caution: prepare traceinfo and peak_properties as pairs. More trace sets can be added at the end
    %   timeinfo: 1-col array
    %   traceinfo: 1 or multiple cell array(s), such as ({decon_traces}, {lowpass_traces})
    %   peak_properties_tables: multiple roi table
    %   stim_ch_patch: 1 or multiple cell arraies containing nx2 matrix. 1st column contains x coordinate, 2nd column contains y coordinates
    %   varargin: 

    % Defaults
    peak_info = cell(1, 1);
    rise_info = cell(1, 1);
    stim_ch_patch = [];
    subplot_row_num = 3; % number of subplot row in each figure
    subplot_col_num = 2; % number of subplot column in each figure

    % xlim_min = timeinfo(1);
    % xlim_max = timeinfo(end);
    % ylim_min = 0;
    % ylim_max = 1;
    % patch_color = {'cyan', 'magenta', 'yellow'};
    % patch_EdgeColor = 'none';
    % patch_FaceAlpha = 0.3;

    % Optionals
    for ii = 1:2:(nargin-1)
        % if strcmpi('peak_info', varargin{ii})
        %     peak_info = varargin{ii+1};
        % elseif strcmpi('rise_info', varargin{ii})
        %     rise_info = varargin{ii+1};
        if strcmpi('peak_properties_tables', varargin{ii})
            peak_properties_tables = varargin{ii+1};
        elseif strcmpi('stim_ch_patch', varargin{ii})
            stim_ch_patch = varargin{ii+1};
        elseif strcmpi('subplot_row_num', varargin{ii})
            subplot_row_num = varargin{ii+1};
        end
    end

    % Main contents
    trace_set_num = length(traceinfo);
    peak_properties_set_num = size(peak_properties_tables, 1); % number of peak propertis set: peak_decon, peak_lowpass...
    time_info = traceinfo{1, 1}{:, 1};
    roi_num = size(traceinfo{1, 1}, 2)-1;
    col_num_all = ceil(roi_num/subplot_row_num);
    fig_num_all = ceil(col_num_all/subplot_col_num);

    for fn = 1:fig_num_all
        fig_handle(fn) = figure(fn);
        set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ]); % [x y width height]
        for cn = 1:subplot_col_num
            col_num_now = (fn-1)*subplot_col_num+cn;
            if col_num_now <= col_num_all
                % decide the number of last row
                if col_num_now < col_num_all
                    last_row_num = subplot_row_num;
                else
                    last_row_num = rem(roi_num, subplot_row_num);
                end

                for rn = 1:last_row_num
                    roi_n = rn+(fn-1)*subplot_col_num*subplot_row_num+(cn-1)*subplot_row_num; % the index of roi in traceinfo
                    traces = NaN(length(time_info), trace_set_num);
                    peak_info = cell(1, peak_properties_set_num);
                    rise_info = cell(1, peak_properties_set_num);

                    for tsn = 1:trace_set_num
                        traces(:, tsn) = traceinfo{1, tsn}{:, (roi_n+1)};
                    end

                    for psn = 1:peak_properties_set_num
                        if size(peak_properties_tables{psn, roi_n}, 2) ~= 1
                            peak_properties_table_single = peak_properties_tables{1, roi_n};
                        else
                            peak_properties_table_single = peak_properties_tables{1, rn}{:};
                        end
                        peak_info{psn} = [peak_properties_table_single.peak_time peak_properties_table_single.peak_mag];
                        rise_point_value = traces(peak_properties_table_single.rise_loc, psn);
                        rise_info{psn} = [peak_properties_table_single.rise_time rise_point_value];
                    end
                    sub_handle(roi_n) = subplot(subplot_row_num, subplot_col_num, cn+(rn-1)*subplot_col_num);
                    plot_trace_peak_rise(time_info,traces,peak_info,rise_info)
                    set(get(sub_handle(roi_n), 'YLabel'),...
                        'String', traceinfo{1}.Properties.VariableNames{roi_n+1});
                    yl = ylim;
                    hold on
                    if ~isempty(stim_ch_patch)
                        plot_stim_patch(time_info,stim_ch_patch,'ylim',yl);
                    end
                    hold off
                end
            end
        end
    end

end

