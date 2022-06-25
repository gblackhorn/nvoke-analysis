function [barInfo,varargout] = barplot_with_stat(data,varargin)
    % bar plot using data in data var and run statistics analysis 
    % Note: paired ttest only works when there are only two groups

    % data: double array or cell array
    %   - if double: column number is bar number
    %   - if cell: cell number is bar number

    % Defaults

    stat = 'anova'; % anova/pttest. anova test or paired ttest. The later only works when the group number is 2

    plotWhere = [];
    save_fig = false;
    save_dir = '';
    gui_save = false;
    stat = false; % true if want to run anova
    stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not

    TickAngle = 45;
    EdgeColor = 'none';
    FaceColor = '#4D4D4D';
    FontSize = 18;
    FontWeight = 'bold';


    for ii = 1:2:(nargin-1)
        if strcmpi('group_names', varargin{ii})
            group_names = varargin{ii+1};
        elseif strcmpi('stat', varargin{ii})
            stat = varargin{ii+1};
        elseif strcmpi('plotWhere', varargin{ii})
            plotWhere = varargin{ii+1};
        elseif strcmpi('title_str', varargin{ii})
            title_str = varargin{ii+1};
        elseif strcmpi('save_fig', varargin{ii})
            save_fig = varargin{ii+1};
        elseif strcmpi('save_dir', varargin{ii})
            save_dir = varargin{ii+1};
        elseif strcmpi('gui_save', varargin{ii})
            gui_save = varargin{ii+1};
        elseif strcmpi('stat_fig', varargin{ii})
            stat_fig = varargin{ii+1};
        elseif strcmpi('FontSize', varargin{ii})
            FontSize = varargin{ii+1};
        elseif strcmpi('FontWeight', varargin{ii})
            FontWeight = varargin{ii+1};
        end
    end

    %% main contents
    % store data in cells
    data_class = class(data);
    switch data_class
        case 'double'
            group_num = size(data,2);
            group_data = cell(1,group_num);
            for gn = 1:group_num
                group_data{gn} = data(:,gn);
            end
        case 'cell'
            group_num = numel(data);
            group_data = data;
        otherwise
            error('[barplot_with_stat]: input data must be either "double" or "cell"')
    end

    % Creat barInfo.data and calculate mean, std, and ste for plotting
    barInfo_data_fields = {'group','group_data','n','mean_val','std_val','ste_val'};
    barInfo.data = empty_content_struct(barInfo_data_fields,group_num);
    data_cell = cell(1, group_num); % for anova1
    data_cell_group = cell(1, group_num); % for anova1
    for gn = 1:group_num
        if exist('group_names', 'var')
            barInfo.data(gn).group = group_names{gn};
        else
            barInfo.data(gn).group = sprintf('group%d',gn);
        end
        barInfo.data(gn).group_data = group_data{gn};
        barInfo.data(gn).n = numel(group_data{gn});
        barInfo.data(gn).mean_val = mean(group_data{gn});
        barInfo.data(gn).std_val = std(group_data{gn});
        barInfo.data(gn).ste_val = barInfo.data(gn).std_val/sqrt(barInfo.data(gn).n);

        data_cell{gn} = group_data{gn};
        data_cell_group{gn} = cell(size(data_cell{gn}));
        [data_cell_group{gn}{:}] = deal(barInfo.data(gn).group);
    end
    data_all = [data_cell{:}]; % for anova1
    data_all_group = [data_cell_group{:}]; % for anova1

    % Plot
    if isempty(plotWhere)
        f = figure;
    else
        axes(plotWhere)
        f = gcf;
    end

    group_names = {barInfo.data.group};
    x = [1:1:group_num];
    y = [barInfo.data.mean_val];
    y_error = [barInfo.data.ste_val];
    n_num_str = num2str([barInfo.data.n]');

    fb = bar(x, y,...
        'EdgeColor', EdgeColor, 'FaceColor', FaceColor);
    hold on

    yl = ylim;
    yloc = yl(1)+0.05*(yl(2)-yl(1));
    yloc_array = repmat(yloc, 1, numel(x));
    text(x,yloc_array,n_num_str,'vert','bottom','horiz','center', 'Color', 'white');

    ax.XTick = x;
    set(gca, 'box', 'off')
    set(gca, 'FontSize', FontSize)
    set(gca, 'FontWeight', FontWeight)
    xtickangle(TickAngle)
    set(gca, 'XTick', [1:1:group_num]);
    set(gca, 'xticklabel', group_names);
    fe = errorbar(x, y, y_error, 'LineStyle', 'None');
    set(fe,'Color', 'k', 'LineWidth', 2, 'CapSize', 10);
    if ~exist('title_str','var')
        title_str = sprintf('barplot');
    end
    title_str = replace(title_str, '_', '-');
    title_str = replace(title_str, ':', '-');
    hold off


    barInfo_stat_fields = {'stat_method','p','tbl','c','ci','gnames','stats'};
    barInfo.stat = empty_content_struct(barInfo_stat_fields,1);

    if group_num>1
        switch stat
            case 'anova'
            case 'pttest'
                if group_num ~= 2
                    stat = 'anova';
                else
                    if numel(barInfo.data(1).group_data) ~= numel(barInfo.data(2).group_data)
                       stat = 'anova';
                    end 
                end
            otherwise
        end
        barInfo.stat.stat_method = stat;

        switch stat
            case 'anova'
                [barInfo.stat.p,barInfo.stat.tbl,barInfo.stat.stats] = anova1(data_all,data_all_group,'off');
                if barInfo.stat.stats.df~=0
                    [c,~,~,gnames] = multcompare(barInfo.stat.stats,'Display','off'); % multiple comparison test. Check if the difference between groups are significant
                    % 'tukey-kramer'
                    % The first two columns of c show the groups that are compared. 
                    % The fourth column shows the difference between the estimated group means. 
                    % The third and fifth columns show the lower and upper limits for 95% confidence intervals for the true mean difference. 
                    % The sixth column contains the p-value for a hypothesis test that the corresponding mean difference is equal to zero. 

                    % convert c to a table
                    c = num2cell(c);
                    c(:, 1:2) = cellfun(@(x) gnames{x}, c(:, 1:2), 'UniformOutput',false);
                    c = cell2table(c,...
                        'variableNames', {'g1', 'g2', 'lower-confi-int', 'estimate', 'upper-confi-int', 'p'});
                    h = NaN(size(c, 1), 1);
                    idx_sig = find(c.p < 0.05);
                    idx_nonsig = find(c.p >= 0.05);
                    h(idx_sig) = 1;
                    h(idx_nonsig) = 0;
                    c.h = h;
                end
                barInfo.stat.c = c;
                barInfo.stat.gnames = gnames;
            case 'pttest'
                [barInfo.stat.h,barInfo.stat.p,barInfo.stat.ci,barInfo.stat.stats] = ttest(barInfo.data(1).group_data,barInfo.data(2).group_data);
            otherwise
        end
    end

    if save_fig
        dt = datestr(now, 'yyyymmdd');
        fname = sprintf('%s-%s',title_str,dt);
        if isempty(save_dir) || gui_save
            save_dir = uigetdir(save_dir,'Choose a folder to save barplot and statistics');
        end
        save_dir = savePlot(f,...
            'guiSave', 'off', 'save_dir', save_dir, 'fname', fname);

        statfile_name = sprintf('%s-stat',fname);
        save(fullfile(save_dir,statfile_name), 'barInfo');
    end
end

