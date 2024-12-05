function [violinInfo,varargout] = violinplotWithStat(violinData,varargin)
    % Create a violin plot, its descriptive info (mean, median, ste, etc.) as a table, and
    % statistics also as a table

    % Defaults
    bootstrap = false; % Use bootstrap or conventional method
    plot_unit_width = 0.4; % normalized size of a single plot to the display
    plot_unit_height = 0.4; % normalized size of a single plot to the display
    columnLim = 1; % number of plot column
    titleStr = sprintf('violin plot');
    save_fig = false;
    save_dir = [];
    gui_save = 'off';
    debug_mode = false;
    yTickInterval = 2; % Default interval for y-axis ticks

    % Parse Optionals
    for ii = 1:2:(nargin-1)
        if strcmpi('groupNames', varargin{ii})
            groupNames = varargin{ii+1};
        elseif strcmpi('titleStr', varargin{ii})
            titleStr = varargin{ii+1};
        elseif strcmpi('bootstrap', varargin{ii})
            bootstrap = varargin{ii+1};
        elseif strcmpi('extraUItable', varargin{ii})
            extraUItable = varargin{ii+1};
        elseif strcmpi('save_fig', varargin{ii})
            save_fig = varargin{ii+1};
        elseif strcmpi('save_dir', varargin{ii})
            save_dir = varargin{ii+1};
        elseif strcmpi('gui_save', varargin{ii})
            gui_save = varargin{ii+1};
        elseif strcmpi('yTickInterval', varargin{ii})
            yTickInterval = varargin{ii+1};
        end
    end 


    % decide the number of plots
    [dataRowNum,dataColNum] = size(violinData);
    plotNum = dataRowNum;

    % verify groupNames. If it does not exist, create one
    if exist('groupNames','var')
        [nameRowNum,nameColNum] = size(groupNames);

        if nameRowNum ~= dataRowNum || nameColNum ~= dataColNum
            error('Inputs violinData and groupNames must have the same size')
        end

        % modify the groupNames if they are not suitable for structure fieldnames
        for rn = 1:dataRowNum
            for cn = 1:dataColNum
                % Regular expression pattern to match numbers (including decimals)
                pattern = '\d+(\.\d+)?s';

                % Use 'regexprep' to remove numbers from the string
                groupNames{rn,cn} = regexprep(groupNames{rn,cn}, pattern, '');

                % groupIDX = (rn-1)*dataColNum+cn;
                groupNames{rn,cn} = strrep(groupNames{rn,cn},' ','');
                groupNames{rn,cn} = strrep(groupNames{rn,cn},'-','');
            end
        end
    else
        % create groupNames
        groupNames = cell(size(violinData));
        alphabets = char('A':'Z');
        for rn = 1:dataRowNum
            for cn = 1:dataColNum
                groupIDX = (rn-1)*dataColNum+cn;
                groupNames{rn,cn} = sprintf('%s%g',alphabets(),cn);
            end
        end
    end


    % create a struct var to store data, descriptive info (mean, median, ste, etc.), and stat info
    violinInfoFields = {'allGroups','data','dataInfo','stat','statTab'};
    violinInfo = empty_content_struct(violinInfoFields,dataRowNum);

    % create a struct var for violin plot and store the data here
    dataStruct = empty_content_struct(groupNames(rn,:),1);

    % create a struct var to store the data info
    dataInfoFields = {'Group','Mean','Median','STD','SEM'};
    dataInfoStruct = empty_content_struct(dataInfoFields,dataColNum);



    % create a figure canvas for plotting two columns for one plot. left: violin, right-top: info
    % (mean, median, ste, etc.), right-bottom: stat
    [f,f_rowNum,f_colNum] = fig_canvas(dataRowNum*2,'unit_width',...
        plot_unit_width,'unit_height',plot_unit_height,'column_lim',2,...
        'fig_name',titleStr); % create a figure
    tlo = tiledlayout(f, dataRowNum*3, 2); % setup tiles



    % fill violinInfo and plot
    for rn = 1:dataRowNum
        % use groupNames to create a string for field 'group'
        violinInfo(rn).(violinInfoFields{1}) = strjoin(groupNames(rn,:),' vs ');

        violinInfo(rn).(violinInfoFields{2}) = dataStruct;

        violinInfo(rn).(violinInfoFields{3}) = dataInfoStruct;

        for cn = 1:dataColNum
            % store the data
            violinInfo(rn).data.(groupNames{rn,cn}) = violinData{rn,cn};

            % calculate the info (mean, median, ste, etc.) and store it
            violinInfo(rn).dataInfo(cn).(dataInfoFields{1}) = groupNames{rn,cn};
            violinInfo(rn).dataInfo(cn).(dataInfoFields{2}) = mean(violinData{rn,cn});
            violinInfo(rn).dataInfo(cn).(dataInfoFields{3}) = median(violinData{rn,cn});
            violinInfo(rn).dataInfo(cn).(dataInfoFields{4}) = std(violinData{rn,cn});
            violinInfo(rn).dataInfo(cn).(dataInfoFields{5}) = ste(violinData{rn,cn});
        end

        % statistics
        if bootstrap
            % Bootstrap
            bootstrapLabel = sprintf('%s vs. %s', groupNames{rn, 1}, groupNames{rn,2});
            [~, ~, bootstrapPval, ~, violinInfo(rn).(violinInfoFields{5})] = bootstrapAnalysis(violinData{rn, 1}, violinData{rn,2}, 'label', bootstrapLabel);
            violinInfo(rn).(violinInfoFields{4}).Method = 'Bootstrap';
            violinInfo(rn).(violinInfoFields{4}).Group1 = groupNames{rn, 1};
            violinInfo(rn).(violinInfoFields{4}).Group2 = groupNames{rn, 2};
            violinInfo(rn).(violinInfoFields{4}).p = bootstrapPval;
        else
            % Non-bootstrap
            [violinInfo(rn).(violinInfoFields{4}),violinInfo(rn).(violinInfoFields{5})] = ttestOrANOVA(violinData(rn,:),'groupNames',groupNames(rn,:));
        end



        % plot violin
        axViolin = nexttile(tlo,[3 1]); 
        violinplot(violinInfo(rn).(violinInfoFields{2}),groupNames(rn,:));

        % Customize y-axis ticks
        customizeYAxis(axViolin, yTickInterval);

        % plot dataInfo 
        axDataInfo = nexttile(tlo,[1 1]);
        dataInfoTab = struct2table(violinInfo(rn).(violinInfoFields{3}));
        plotUItable(gcf,axDataInfo,dataInfoTab);


        % plot stat results
        axStat = nexttile(tlo,[1 1]);
        plotUItable(gcf,axStat,violinInfo(rn).statTab);
        title(violinInfo(rn).(violinInfoFields{4}).Method)


        % plot an extra UI table if input is not empty
        if exist('extraUItable','var') && ~isempty(extraUItable)
            axExUItable = nexttile(tlo,[1 1]);
            plotUItable(gcf,axExUItable,extraUItable);
        end
    end



    % set the title for the figure
    sgtitle(titleStr)
    if save_fig
        if isempty(save_dir)
            gui_save = 'on';
        end
        msg = 'Choose a folder to save the violin plot and the statistics';
        save_dir = savePlot(f,'save_dir',save_dir,'guiSave',gui_save,...
            'guiInfo',msg,'fname',titleStr);
        save(fullfile(save_dir, [titleStr, '_dataStat']),...
            'violinInfo');
    end 
    varargout{1} = save_dir;
end

function customizeYAxis(gcaHandle, yTickInterval)
    % Customize y-axis ticks and labels based on the provided interval
    yLimits = ylim(gcaHandle);
    yTicks = floor(yLimits(1)/yTickInterval)*yTickInterval : yTickInterval : ceil(yLimits(2)/yTickInterval)*yTickInterval;
    set(gcaHandle, 'YTick', yTicks);
    set(gcaHandle, 'YTickLabel', arrayfun(@num2str, yTicks, 'UniformOutput', false));
end