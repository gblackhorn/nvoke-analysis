function [stat_info,varargout] = comparison_within_strutEntry(structVar,paired_fieldnames,varargin)
    % Paired comparison of values in paired_fieldnames and plot

    % structVar: a structure variable
    % paired_fieldnames: 
    %   - single cell with 2 character variables (names of structure fields in structVar)
    %   - multiple cells which all contain 2 character variables (names of structure fields in structVar)

    % Defaults
    stat = 'pttest';

    plotdata = false;
    save_fig = false;
    save_dir = '';
    gui_save = false;
    title_str = '';
    fig_position = [];
    max_row = 2; % max row number for plot
    max_col = 4; % max col number for plot
    % debug_mode = false; % true/false

    % Options
    for ii = 1:2:(nargin-2)
        if strcmpi('debug_mode', varargin{ii})
            debug_mode = varargin{ii+1};
        elseif strcmpi('save_fig', varargin{ii})
            save_fig = varargin{ii+1};
        elseif strcmpi('save_dir', varargin{ii})
            save_dir = varargin{ii+1};
        elseif strcmpi('gui_save', varargin{ii})
            gui_save = varargin{ii+1};
        elseif strcmpi('title_str', varargin{ii})
            title_str = varargin{ii+1};
        elseif strcmpi('plotdata', varargin{ii})
            plotdata = varargin{ii+1};
        end
    end

    %% main contents
    switch class(paired_fieldnames{1})
        case 'char'
            paired_fn{1} = paired_fieldnames;
        case 'cell'
            paired_fn = paired_fieldnames;
    end

    pair_num = numel(paired_fn);
    if pair_num < max_col
        max_col = pair_num;
    end

    % normalized values for position and size
    if plotdata
        if isempty(title_str)
            inter_sign = '';
        else
            inter_sign = '_';
        end
        f_bar_name = sprintf('BarPlots%s%s',inter_sign,title_str);
        [f_bar] = fig_canvas(pair_num,'fig_name',f_bar_name,...
            'unit_width',0.2,'unit_height',0.4);
        f_box_name = sprintf('boxPlots%s%s',inter_sign,title_str);
        [f_box] = fig_canvas(pair_num,'fig_name',f_box_name,...
            'unit_width',0.2,'unit_height',0.4);
        tlo_bar = tiledlayout(f_bar,ceil(pair_num/max_col),max_col);
        tlo_box = tiledlayout(f_box,ceil(pair_num/max_col),max_col);
        if save_fig
            if gui_save || isempty(save_dir)
                save_dir = uigetdir(save_dir,...
                    'Choose a folder to save plots');
                if save_dir == 0
                    disp('Folder for saving plots not chosen. Choose one or set "save_fig" to false')
                    return
                end
            end
        end
    end
    
    stat_info = empty_content_struct({'pair_group','data','stat'},pair_num);
    for pn = 1:pair_num
        p_dataname =  paired_fn{pn};
        p_data_gNum = numel(p_dataname);
        p_data = cell(1,p_data_gNum);

        pair_group_cell = p_dataname;
        for pdgn = 1:p_data_gNum
            p_data{pdgn} = [structVar.(p_dataname{pdgn})];
            if pdgn~=1
                pair_group_cell{pdgn} = sprintf('VS%s',pair_group_cell{pdgn});
            end
        end
        if pdgn > 2
            stat = 'anova';
        end

        if plotdata
            ax_bar = nexttile(tlo_bar);
            ax_box = nexttile(tlo_box);
        end

        stat_info(pn).pair_group = cell2mat(pair_group_cell);
        [barInfo] = barplot_with_stat(p_data,'plotData',plotdata,'plotWhere',ax_bar,...
            'group_names',p_dataname,'stat',stat);
                stat_info(pn).data = barInfo.data;
        stat_info(pn).stat = barInfo.stat;

        f_box = boxPlot_with_scatter(p_data,'groupNames',p_dataname,'plotWhere',ax_box);
    end

    if save_fig
        [save_dir,fname] = savePlot(f_bar,'save_dir',save_dir,'fname',f_bar_name);
        savePlot(f_box,'save_dir',save_dir,'fname',f_box_name);
        save(fullfile(save_dir, [title_str, '_stat']),...
            'stat_info');
    end
    varargout{1} = save_dir;
end

