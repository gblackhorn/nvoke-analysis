function [varargout] = plot_event_info(event_info_struct,varargin)
    % Plot various event properties 
    % Input: 
    %    - structure array including one or more event_info structures {event_info1, event_info2,...}
    % Output:
    %    - event frequency histogram
    %    - event interval variance histogram
    %    - event rise_time bar
    %    - event peak amplitude bar
    %    - event rise_time/peak scatter and correlation
    %    - event peak-slope scatter and correlation
    %    - event slope bar

    % Parse input arguments using inputParser
    params = parse_inputs(varargin{:});

    if params.save_fig 
        params.save_dir = setup_save_directory(params.save_dir, params.savepath_nogui);
        if isempty(params.save_dir)
            varargout{1} = '';
            return;
        else
        	varargout{1} = params.save_dir;
        end
    end

    % Remove empty entries
    event_info_struct = remove_empty_entries(event_info_struct);

    % Determine parameter names based on data type
    parNames = determine_par_names(event_info_struct, params.parNames);

    % Generate plots and capture output data
    [bar_data, bar_stat] = plot_bars(event_info_struct, parNames, params);
    plot_cumulative_distributions(event_info_struct, parNames, params);

    % % Un-comment this section to generate optional plots
    % [hist_data, hist_setting] = plot_histograms(event_info_struct, parNames, params);
    % histFit_info = plot_histfits(event_info_struct, parNames, params);
    % if strcmp(params.entryType, 'event')
    %     scatter_data = plot_scatters(event_info_struct, parNames, params);
    % else
    %     scatter_data = struct();
    % end

    % Collect plot data and statistics
    plot_info = collect_plot_info(bar_data, bar_stat);
    varargout{2} = plot_info;

    % Optionally save figures
    if params.save_fig
        save_all_figures(params.save_dir, params.fname_preffix);
    end
end

function params = parse_inputs(varargin)
    % Define default values
    defaultEntryType = 'event';
    defaultPlotCombinedData = false;
    defaultParNames = {'rise_duration','peak_mag_delta','peak_delta_norm_hpstd',...
        'peak_slope','peak_slope_norm_hpstd','baseDiff','baseDiff_stimWin'}; 
    defaultSaveFig = false;
    defaultSaveDir = '';
    defaultSavePathNoGui = '';
    defaultFnamePreffix = '';
    defaultMmModel = ''; % '': Do not use MM model for analysis. 'LMM': Linear-Mixed-Model. 'GLMM': Generalized-Mixed_Model
    defaultMmGroup = 'subNuclei'; % Check the input 'hierarchicalVars' input in the function 'mixed_model_analysis' for more details
    defaultMmHierarchicalVars = {'trialName', 'roiName'}; % Check the input 'hierarchicalVars' input in the function 'mixed_model_analysis' for more details
    defaultMmDistribution = 'gamma'; % Check the input 'distribution' input in the function 'mixed_model_analysis' for more details
    defaultMmLink = 'log'; % Check the input 'link' input in the function 'mixed_model_analysis' for more details
    defaultStatFig = 'off';
    defaultColorGroup = {'#3FF5E6', '#F55E58', '#F5A427', '#4CA9F5', '#33F577',...
        '#408F87', '#8F4F7A', '#798F7D', '#8F7832', '#28398F', '#000000'};
    defaultFontSize = 12;
    defaultTileColNum = 4;
    defaultFontWeight = 'bold';
    defaultTickAngle = 15;

    % Create an input parser object
    p = inputParser;
    addParameter(p, 'entryType', defaultEntryType);
    addParameter(p, 'plot_combined_data', defaultPlotCombinedData);
    addParameter(p, 'parNames', defaultParNames);
    addParameter(p, 'save_fig', defaultSaveFig);
    addParameter(p, 'save_dir', defaultSaveDir);
    addParameter(p, 'savepath_nogui', defaultSavePathNoGui);
    addParameter(p, 'fname_preffix', defaultFnamePreffix);
    addParameter(p, 'mmModel', defaultMmModel);
    addParameter(p, 'mmGroup', defaultMmGroup);
    addParameter(p, 'mmHierarchicalVars', defaultMmHierarchicalVars);
    addParameter(p, 'mmDistribution', defaultMmDistribution);
    addParameter(p, 'mmLink', defaultMmLink);
    addParameter(p, 'stat_fig', defaultStatFig);
    addParameter(p, 'colorGroup', defaultColorGroup);
    addParameter(p, 'FontSize', defaultFontSize);
    addParameter(p, 'tileColNum', defaultTileColNum);
    addParameter(p, 'FontWeight', defaultFontWeight);
    addParameter(p, 'TickAngle', defaultTickAngle);
    parse(p, varargin{:});

    % Extract values from the input parser object
    params = p.Results;
end

function save_dir = setup_save_directory(save_dir, savepath_nogui)
    if isempty(savepath_nogui)
        save_dir = uigetdir(save_dir, 'Choose a folder to save plots');
        if save_dir == 0
            disp('Folder for saving plots not chosen. Choose one or set "save_fig" to false');
            save_dir = '';
        end
    else
        save_dir = savepath_nogui;
    end
end

function event_info_struct = remove_empty_entries(event_info_struct)
    tf_empty = cellfun(@isempty, {event_info_struct.event_info});
    event_info_struct(tf_empty) = [];
end

function parNames = determine_par_names(event_info_struct, parNames)
    event_info_fieldnames = fieldnames(event_info_struct(1).event_info);
    mean_val_idx = find(contains(event_info_fieldnames, 'mean'));
    if ~isempty(mean_val_idx)
        for pn = 1:numel(parNames)
            idx_par = find(contains(event_info_fieldnames, parNames{pn})); 
            C = intersect(idx_par, mean_val_idx);
            if ~isempty(C)
                parNames{pn} = event_info_fieldnames{C};
            end
        end
    end
end

function [hist_data, hist_setting] = plot_histograms(event_info_struct, parNames, params)
    hist_data = struct();
    hist_setting = struct();
    for pn = 1:numel(parNames)
        par = parNames{pn};
        [hist_data.(par), hist_setting.(par)] = plot_event_info_hist(event_info_struct,...
            par, 'plot_combined_data', params.plot_combined_data,'FontSize',params.FontSize,'FontWeight',params.FontWeight,...
            'save_fig', params.save_fig, 'save_dir', params.save_dir, 'fname_preffix',params.fname_preffix,'nbins', 200);
    end
end

function histFit_info = plot_histfits(event_info_struct, parNames, params)
    histFit_info = struct();
    for pn = 1:numel(parNames)
        par = parNames{pn};
        histFit_info.(par) = plot_event_info_histfit(event_info_struct,par,'dist_type','normal',...
            'save_fig', params.save_fig, 'save_dir', params.save_dir, 'fname_preffix',params.fname_preffix,...
            'xRange',[-0.2 2],'nbins', 20,'FontSize',params.FontSize,'FontWeight',params.FontWeight);
    end
end

function [bar_data, bar_stat] = plot_bars(event_info_struct, parNames, params)
    bar_data = struct();
    bar_stat = struct();

    f_bar = create_figure([params.fname_preffix, ' bar plots']);
    % f_stat = uifigure('Name', 'bar stat', 'Position', [0.1 0.1 0.8 0.4]);
    f_stat = create_figure([params.fname_preffix, ' bar stat']);
    set(f_stat, 'Position', [0.05 0.1 0.95 0.4]);
    f_violin = create_figure([params.fname_preffix, ' violin plots']);

    tlo_bar = tiledlayout(f_bar, ceil(numel(parNames)/params.tileColNum), params.tileColNum);
    tlo_barstat = tiledlayout(f_stat, ceil(numel(parNames)/params.tileColNum)*2+1, params.tileColNum);
    tlo_violin = tiledlayout(f_violin, ceil(numel(parNames)/params.tileColNum), params.tileColNum);

    groupNames = {event_info_struct.group};

    for pn = 1:numel(parNames)
        par = parNames{pn};
        ax_bar = nexttile(tlo_bar);

        statTileLoc1 = floor(pn/params.tileColNum)*params.tileColNum+mod(pn,params.tileColNum)+params.tileColNum;
        statTileLoc2 = floor(pn/params.tileColNum)*params.tileColNum+mod(pn,params.tileColNum)+params.tileColNum*2;
        % statTileLoc = floor(pn/params.tileColNum)*params.tileColNum*2+pn+params.tileColNum;
        ax_stat1 = nexttile(tlo_barstat,statTileLoc1);
        ax_stat2 = nexttile(tlo_barstat,statTileLoc2);
        % ax_stat = nexttile(tlo_barstat,params.tileColNum+pn,[2 1]);

        if numel(event_info_struct) > 1
            [bar_data.(par), bar_stat.(par)] = plot_event_info_bar(event_info_struct, par, 'plotWhere', ax_bar,...
                'stat', true, 'stat_fig', params.stat_fig,...
                'mmModel', params.mmModel, 'mmGrouop', params.mmGroup, 'mmHierarchicalVars', params.mmHierarchicalVars,...
                'mmDistribution', params.mmDistribution, 'mmLink', params.mmLink,...
                'FontSize', params.FontSize,...
                'FontWeight', params.FontWeight);
            title(replace(par, '_', '-'));

            % Ensure the stat table is plotted within the correct figure context
            plot_stat_table(ax_stat1, ax_stat2, bar_stat.(par));
        end


        ax_violin = nexttile(tlo_violin);
        plot_violinplot(event_info_struct, par, groupNames, ax_violin, params);
    end

    % Collect the field names of bar_stat
    statParNames = fieldnames(bar_stat);

    % Ensure there are field names to access
    if ~isempty(statParNames)
        % Set the super title of the figure f_stat using the method field of the first bar_stat entry
        if ~isempty(params.mmModel)
            % Replace underscores with spaces
            ParNamesCombined = cellfun(@(x) strrep(x, '_', ' '), statParNames, 'UniformOutput', false);

            % Combine into one line separated with ' | '
            ParNamesCombined = strjoin(ParNamesCombined, ' | ');

            statTitleStr = sprintf('%s\n\n1. %s: Model comparison. no-fixed-effect vs fixed-effects\n[%s]\nVS\n[%s]\n\n2. %s analysis',...
                ParNamesCombined,params.mmModel,char(bar_stat.(statParNames{1}).chiLRT.formula{1}),char(bar_stat.(statParNames{1}).chiLRT.formula{2}),params.mmModel);
            statTitleStr = strrep(statTitleStr, '_', ' ');
            sgtitle(f_stat, statTitleStr);
            % sgtitle(f_stat, [params.mmModel, ' ', char(bar_stat.(statParNames{1}).method.Formula)]);
        else
            sgtitle(f_stat, bar_stat.(statParNames{1}).method);
        end
    end
end


function f = create_figure(name)
    f = figure('Name', name);
    fig_position = [0.1 0.1 0.8 0.4];
    set(f, 'Units', 'normalized', 'Position', fig_position);
end


function plot_stat_table(ax_stat1, ax_stat2, bar_stat)
    % Set the current figure to the one containing ax_stat1
    figure(ax_stat1.Parent.Parent);

    set(ax_stat1, 'XTickLabel', []);
    set(ax_stat1, 'YTickLabel', []);
    set(ax_stat2, 'XTickLabel', []);
    set(ax_stat2, 'YTickLabel', []);
    
    uit_pos1 = get(ax_stat1, 'Position');
    uit_unit1 = get(ax_stat1, 'Units');
    uit_pos2 = get(ax_stat2, 'Position');
    uit_unit2 = get(ax_stat2, 'Units');

    % Create the table in the correct figure and context
    if isfield(bar_stat, 'c')
        MultCom_stat = bar_stat.c(:, ["g1", "g2", "p", "h"]);
        uit = uitable('Data', table2cell(MultCom_stat), 'ColumnName', MultCom_stat.Properties.VariableNames,...
            'Units', uit_unit1, 'Position', uit_pos1);
    elseif isfield(bar_stat, 'fixedEffectsStats') && ~isempty(bar_stat.method) % if LMM or GLMM (mixed models) are used
        chiLRTCell = table2cell(bar_stat.chiLRT);
        chiLRTCell = convertCategoricalToChar(chiLRTCell);
        uit = uitable('Data', chiLRTCell, 'ColumnName', bar_stat.chiLRT.Properties.VariableNames,...
                    'Units', uit_unit1, 'Position', uit_pos1);

        fixedEffectsStatsCell = table2cell(bar_stat.fixedEffectsStats);
        fixedEffectsStatsCell = convertCategoricalToChar(fixedEffectsStatsCell);
        uit = uitable('Data', fixedEffectsStatsCell, 'ColumnName', bar_stat.fixedEffectsStats.Properties.VariableNames,...
                    'Units', uit_unit2, 'Position', uit_pos2);
    else
        uit = uitable('Data', ensureHorizontal(struct2cell(bar_stat)), 'ColumnName', fieldnames(bar_stat),...
            'Units', uit_unit1, 'Position', uit_pos1);
    end
    
    % Adjust table appearance
    jScroll = findjobj(uit);
    jTable = jScroll.getViewport.getView;
    jTable.setAutoResizeMode(jTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS);
    drawnow;
end


function convertedCellArray = convertCategoricalToChar(cellArray)
    % Check and convert categorical or nominal data to char in a cell array
    convertedCellArray = cellArray;  % Copy the input cell array
    
    % Iterate through each element in the cell array
    for i = 1:numel(cellArray)
        % Check if the current element is categorical or nominal
        if iscategorical(cellArray{i}) || isa(cellArray{i}, 'nominal')
            % Convert to char
            convertedCellArray{i} = char(cellArray{i});
        end
    end
end


function plot_boxplot(event_info_struct, par, groupNames, ax_box, params)
    event_info_cell = cell(1, numel(event_info_struct));
    for gn = 1:numel(event_info_struct)
        event_info_cell{gn} = [event_info_struct(gn).event_info.(par)]';
    end
    boxPlot_with_scatter(event_info_cell, 'groupNames', groupNames, 'plotWhere', ax_box, 'stat', true,...
        'FontSize', params.FontSize, 'FontWeight', params.FontWeight);
    title(replace(par, '_', '-'));
end

function plot_violinplot(event_info_struct, par, groupNames, ax_violin, params)
    event_info_cell = cell(1, numel(event_info_struct));
    for gn = 1:numel(event_info_struct)
        event_info_cell{gn} = [event_info_struct(gn).event_info.(par)]';
    end
    [violinData, violinGroups] = createDataAndGroupNameArray(event_info_cell, groupNames);
    if ~isempty(violinData)
        violinplot(violinData, violinGroups);
        set(ax_violin, 'box', 'off', 'TickDir', 'out', 'FontSize', params.FontSize, 'FontWeight', params.FontWeight);
        xtickangle(params.TickAngle);
        title(replace(par, '_', '-'));
    end
end

function plot_cumulative_distributions(event_info_struct, parNames, params)
    figNameStr = sprintf('%s cumulative distribution plots', params.fname_preffix);
    f_cd = create_figure(figNameStr);
    tlo = tiledlayout(f_cd, ceil(numel(parNames)/4), 4);

    for pn = 1:numel(parNames)
        par = parNames{pn};
        ax = nexttile(tlo);
        event_info_cell = cell(1, numel(event_info_struct));
        for gn = 1:numel(event_info_struct)
            event_info_cell{gn} = [event_info_struct(gn).event_info.(par)]';
        end
        cumulative_distr_plot(event_info_cell, 'groupNames', {event_info_struct.group}, 'plotWhere', ax,...
            'plotCombine',false,'stat', true, 'colorGroup', params.colorGroup,...
            'FontSize', params.FontSize, 'FontWeight', params.FontWeight);
        title(replace(par, '_', '-'));
    end
end

function scatter_data = plot_scatters(event_info_struct, parNames, params)
    scatter_data = struct();

    % Define scatter plot parameters
    duration_val_idx = find(contains(parNames, 'duration'));
    mag_val_idx = find(contains(parNames, 'mag_delta'));
    mag_norm_val_idx = find(contains(parNames, 'peak_delta_norm_hpstd'));
    all_mag_val_idx = [mag_val_idx; mag_norm_val_idx];
    all_slope_val_idx = find(contains(parNames, 'slope'));
    norm_slope_val_idx = find(contains(parNames, 'peak_slope_norm_hpstd'));
    slope_val_idx = setdiff(all_slope_val_idx, norm_slope_val_idx);
    baseDiff_idx = find(contains(parNames, 'baseDiff'));
    baseDiffRise_idx = find(contains(parNames, 'baseDiffRise'));
    riseDelay_idx = find(contains(parNames, 'rise_delay'));

    % Scatter plot of event width vs. preEvent time interval
    plot_scatter(event_info_struct, 'FWHM', 'preEventIntPeak', 'ScatterPlot FWHM vs preEvent time interval', params, scatter_data);

    % Scatter plot of event peakMagDelta vs. preEvent time interval
    plot_scatter(event_info_struct, 'peak_mag_delta', 'preEventIntPeak', 'ScatterPlot peakMagDelta vs preEvent time interval', params, scatter_data);

    % Additional scatter plots
    if ~isempty(duration_val_idx)
        plot_additional_scatters(event_info_struct, parNames, duration_val_idx, all_mag_val_idx, all_slope_val_idx, params, scatter_data);
    end
    if ~isempty(mag_val_idx)
        plot_mag_vs_slope(event_info_struct, parNames, mag_val_idx, slope_val_idx, params, scatter_data);
    end
    if ~isempty(mag_norm_val_idx)
        plot_mag_norm_vs_slope_norm(event_info_struct, parNames, mag_norm_val_idx, norm_slope_val_idx, params, scatter_data);
    end
    if ~isempty(baseDiff_idx)
        plot_baseDiff_vs_mag(event_info_struct, parNames, baseDiff_idx, mag_val_idx, params, scatter_data);
        plot_baseDiff_vs_duration(event_info_struct, parNames, baseDiff_idx, duration_val_idx, params, scatter_data);
    end
    if ~isempty(baseDiffRise_idx)
        plot_baseDiffRise_vs_mag(event_info_struct, parNames, baseDiffRise_idx, mag_val_idx, params, scatter_data);
    end
    if ~isempty(riseDelay_idx)
        plot_riseDelay_vs_other_params(event_info_struct, parNames, riseDelay_idx, duration_val_idx, mag_val_idx, params, scatter_data);
    end
end

function plot_scatter(event_info_struct, y_param, x_param, fig_name, params, scatter_data)
    f_scatter = create_figure(fig_name);
    tlo_scatter = tiledlayout(f_scatter, ceil(numel(event_info_struct)/4), 4);

    for gn = 1:numel(event_info_struct)
        ax_scatter = nexttile(tlo_scatter);
        y_data = [event_info_struct(gn).event_info.(y_param)]';
        x_data = [event_info_struct(gn).event_info.(x_param)]';
        cellDataWithoutNaN = rmNaN({x_data, y_data});
        x_data = cellDataWithoutNaN{1};
        y_data = cellDataWithoutNaN{2};
        stylishScatter(x_data, y_data, 'plotWhere', ax_scatter, 'titleStr', event_info_struct(gn).group,...
            'xlabelStr', x_param, 'ylabelStr', y_param, 'showCorrCoef', true);
        scatter_data.(fig_name) = [x_data, y_data];
    end

    if params.save_fig
        fname = sprintf('%s-%s', fig_name, params.fname_preffix);
        savePlot(f_scatter, 'guiSave', 'off', 'save_dir', params.save_dir, 'fname', fname);
    end
end

function plot_additional_scatters(event_info_struct, parNames, duration_val_idx, all_mag_val_idx, all_slope_val_idx, params)
    duration_par_num = numel(duration_val_idx);
    for dn = 1:duration_par_num
        par_duration = parNames{duration_val_idx(dn)};
        if ~isempty(all_mag_val_idx)
            plot_duration_vs_mag(event_info_struct, par_duration, parNames, all_mag_val_idx, params);
        end
        if ~isempty(all_slope_val_idx)
            plot_duration_vs_slope(event_info_struct, par_duration, parNames, all_slope_val_idx, params);
        end
    end
end

function plot_duration_vs_mag(event_info_struct, par_duration, parNames, all_mag_val_idx, params)
    mag_par_num = numel(all_mag_val_idx);
    for mn = 1:mag_par_num
        par_mag = parNames{all_mag_val_idx(mn)};
        plot_event_info_scatter(event_info_struct, par_duration, par_mag, 'FontSize', params.FontSize,...
            'FontWeight', params.FontWeight, 'save_fig', params.save_fig, 'save_dir', params.save_dir,...
            'fname_preffix', params.fname_preffix);
    end
end

function plot_duration_vs_slope(event_info_struct, par_duration, parNames, all_slope_val_idx, params)
    slope_par_num = numel(all_slope_val_idx);
    for sn = 1:slope_par_num
        par_slope = parNames{all_slope_val_idx(sn)};
        plot_event_info_scatter(event_info_struct, par_duration, par_slope, 'FontSize', params.FontSize,...
            'FontWeight', params.FontWeight, 'save_fig', params.save_fig, 'save_dir', params.save_dir,...
            'fname_preffix', params.fname_preffix);
    end
end

function plot_mag_vs_slope(event_info_struct, parNames, mag_val_idx, slope_val_idx, params)
    mag_par_num = numel(mag_val_idx);
    for mn = 1:mag_par_num
        par_mag = parNames{mag_val_idx(mn)};
        slope_par_num = numel(slope_val_idx);
        for sn = 1:slope_par_num
            par_slope = parNames{slope_val_idx(sn)};
            plot_event_info_scatter(event_info_struct, par_mag, par_slope, 'FontSize', params.FontSize,...
                'FontWeight', params.FontWeight, 'save_fig', params.save_fig, 'save_dir', params.save_dir,...
                'fname_preffix', params.fname_preffix);
        end
    end
end

function plot_mag_norm_vs_slope_norm(event_info_struct, parNames, mag_norm_val_idx, norm_slope_val_idx, params)
    mag_norm_par_num = numel(mag_norm_val_idx);
    for mn = 1:mag_norm_par_num
        par_mag_norm = parNames{mag_norm_val_idx(mn)};
        slope_norm_par_num = numel(norm_slope_val_idx);
        for sn = 1:slope_norm_par_num
            par_slope_norm = parNames{norm_slope_val_idx(sn)};
            plot_event_info_scatter(event_info_struct, par_mag_norm, par_slope_norm, 'FontSize', params.FontSize,...
                'FontWeight', params.FontWeight, 'save_fig', params.save_fig, 'save_dir', params.save_dir,...
                'fname_preffix', params.fname_preffix);
        end
    end
end

function plot_baseDiff_vs_mag(event_info_struct, parNames, baseDiff_idx, mag_val_idx, params)
    baseDiff_num = numel(baseDiff_idx);
    for bn = 1:baseDiff_num
        par_baseDiff = parNames{baseDiff_idx(bn)};
        mag_par_num = numel(mag_val_idx);
        for mn = 1:mag_par_num
            par_mag = parNames{mag_val_idx(mn)};
            plot_event_info_scatter(event_info_struct, par_baseDiff, par_mag, 'FontSize', params.FontSize,...
                'FontWeight', params.FontWeight, 'save_fig', params.save_fig, 'save_dir', params.save_dir,...
                'fname_preffix', params.fname_preffix);
        end
    end
end

function plot_baseDiff_vs_duration(event_info_struct, parNames, baseDiff_idx, duration_val_idx, params)
    baseDiff_num = numel(baseDiff_idx);
    for bn = 1:baseDiff_num
        par_baseDiff = parNames{baseDiff_idx(bn)};
        duration_par_num = numel(duration_val_idx);
        for dn = 1:duration_par_num
            par_duration = parNames{duration_val_idx(dn)};
            plot_event_info_scatter(event_info_struct, par_baseDiff, par_duration, 'FontSize', params.FontSize,...
                'FontWeight', params.FontWeight, 'save_fig', params.save_fig, 'save_dir', params.save_dir,...
                'fname_preffix', params.fname_preffix);
        end
    end
end

function plot_baseDiffRise_vs_mag(event_info_struct, parNames, baseDiffRise_idx, mag_val_idx, params)
    baseDiffRise_num = numel(baseDiffRise_idx);
    for bn = 1:baseDiffRise_num
        par_baseDiffRise = parNames{baseDiffRise_idx(bn)};
        mag_par_num = numel(mag_val_idx);
        for mn = 1:mag_par_num
            par_mag = parNames{mag_val_idx(mn)};
            plot_event_info_scatter(event_info_struct, par_baseDiffRise, par_mag, 'FontSize', params.FontSize,...
                'FontWeight', params.FontWeight, 'save_fig', params.save_fig, 'save_dir', params.save_dir,...
                'fname_preffix', params.fname_preffix);
        end
    end
end

function plot_riseDelay_vs_other_params(event_info_struct, parNames, riseDelay_idx, duration_val_idx, mag_val_idx, params)
    par_riseDelay = parNames{riseDelay_idx};
    if ~isempty(duration_val_idx)
        duration_val_num = numel(duration_val_idx);
        for dvn = 1:duration_val_num
            par_duration_val = parNames{duration_val_idx(dvn)};
            plot_event_info_scatter(event_info_struct, par_riseDelay, par_duration_val, 'FontSize', params.FontSize,...
                'FontWeight', params.FontWeight, 'save_fig', params.save_fig, 'save_dir', params.save_dir,...
                'fname_preffix', params.fname_preffix);
        end
    end
    if ~isempty(mag_val_idx)
        mag_val_num = numel(mag_val_idx);
        for mvn = 1:mag_val_num
            par_mag_val = parNames{mag_val_idx(mvn)};
            plot_event_info_scatter(event_info_struct, par_riseDelay, par_mag_val, 'FontSize', params.FontSize,...
                'FontWeight', params.FontWeight, 'save_fig', params.save_fig, 'save_dir', params.save_dir,...
                'fname_preffix', params.fname_preffix);
        end
    end
end

function plot_info = collect_plot_info(bar_data, bar_stat)
    % Initialize plot_info struct
    plot_info = struct();

    % Collect plot data and statistics
    % if exist('hist_data', 'var')
    %     plot_info.hist_data = hist_data;
    %     plot_info.hist_setting = hist_setting;
    %     plot_info.histFit_info = histFit_info;
    % end
    if exist('bar_data', 'var')
        plot_info.bar_data = bar_data;
        plot_info.bar_stat= bar_stat;
    end
    if exist('box_stat', 'var')
        plot_info.box_stat= box_stat;
    end
    % if exist('scatter_data', 'var')
    %     plot_info.scatter_data = scatter_data;
    % end
end


function save_all_figures(save_dir, fname_preffix)
    figs = findall(0, 'Type', 'figure');
    for i = 1:length(figs)
        fname = sprintf('%s', figs(i).Name);
        savePlot(figs(i), 'guiSave', 'off', 'save_dir', save_dir, 'fname', fname);
    end
end
