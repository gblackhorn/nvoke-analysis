function [barInfo,varargout] = barplot_with_stat(data,varargin)
    % bar plot using data in data var and run statistics analysis 
    % Note: paired ttest only works when there are only two groups

    % data: double array or cell array
    %   - if double: column number is bar number
    %   - if cell: cell number is bar number

    % Defaults

    stat = 'anova'; % anova/pttest/upttest. anova test or paired ttest. The later only works when the group number is 2
    xdata = [];
    ylim_val = [];
    ylabelStr = '';

    plotData = true; % true/false
    plotWhere = [];
    save_fig = false;
    save_dir = '';
    gui_save = false;
    % stat = false; % true if want to run anova
    stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not

    TickAngle = 0;
    EdgeColor = 'none';
    FaceColor = '#4D4D4D';
    FontSize = 14;
    FontWeight = 'bold';


    for ii = 1:2:(nargin-1)
        if strcmpi('group_names', varargin{ii})
            group_names = varargin{ii+1};
        elseif strcmpi('stat', varargin{ii})
            stat = varargin{ii+1};
        elseif strcmpi('xdata', varargin{ii})
            xdata = varargin{ii+1};
        elseif strcmpi('ylim_val', varargin{ii})
            ylim_val = varargin{ii+1};
        elseif strcmpi('ylabelStr', varargin{ii})
            ylabelStr = varargin{ii+1};
        % elseif strcmpi('xticks', varargin{ii})
        %     xticks = varargin{ii+1};
        elseif strcmpi('plotWhere', varargin{ii})
            plotWhere = varargin{ii+1};
        elseif strcmpi('title_str', varargin{ii})
            title_str = varargin{ii+1};
        elseif strcmpi('TickAngle', varargin{ii})
            TickAngle = varargin{ii+1};
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

    % Get x for plotting. Create group_names using x if it does not exist
    if isempty(xdata)
        x = [1:1:group_num]; % create x using group number if xdata does not exist
    else
        x = xdata;
    end
    if ~exist('group_names', 'var')
        group_names = NumArray2StringCell(x); % use x as group names, if group_name does not exist
    end

    % Replace underscore with space in all cells
    group_names = cellfun(@(x) strrep(x, '_', ' '), group_names, 'UniformOutput', false);

    for gn = 1:group_num
        barInfo.data(gn).group = group_names{gn};
        nonNanIndices = ~isnan(group_data{gn});
        group_data{gn} = group_data{gn}(nonNanIndices);

        barInfo.data(gn).group_data = group_data{gn};
        barInfo.data(gn).n = numel(group_data{gn});
        barInfo.data(gn).mean_val = mean(group_data{gn});
        barInfo.data(gn).std_val = std(group_data{gn});
        barInfo.data(gn).ste_val = barInfo.data(gn).std_val/sqrt(barInfo.data(gn).n);

        data_cell{gn} = group_data{gn};
        data_cell_group{gn} = cell(size(data_cell{gn}));
        [data_cell_group{gn}{:}] = deal(barInfo.data(gn).group);
    end

    % convert all the cell contents to row vectors
    data_cell = cellfun(@(x) reshape(x,1,[]),data_cell,'UniformOutput',false);
    data_cell_group = cellfun(@(x) reshape(x,1,[]),data_cell_group,'UniformOutput',false);

    data_all = [data_cell{:}]; % for anova1
    data_all_group = [data_cell_group{:}]; % for anova1

    % Plot
    if plotData
        if isempty(plotWhere)
            f = figure;
            plotWhere = gca;
        else
            axes(plotWhere)
            f = gcf;
        end

        group_names = {barInfo.data.group};
        % x = [1:1:group_num];
        y = [barInfo.data.mean_val];
        y_error = [barInfo.data.ste_val];


        % ==========
        [barPlotInfo] = barplot_with_errBar(y(:)','barX',x,'plotWhere',plotWhere,...
            'errBarVal',y_error(:)','barNames',group_names,'dataNumVal',[barInfo.data.n]);


        ylabel(ylabelStr);
        if ~exist('title_str','var')
            % title_str = sprintf('barplot');
        else
            title_str = replace(title_str, '_', '-');
            title_str = replace(title_str, ':', '-');
            title(title_str);
        end
        hold off
    end



    % statistics
    [barInfo.stat,barInfoStatTab] = ttestOrANOVA(group_data,'groupNames',group_names);



    if plotData && save_fig 
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
    varargout{1} = save_dir;
    varargout{2} = barInfoStatTab;
end

