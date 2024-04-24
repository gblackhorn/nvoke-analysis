function [violinInfo,varargout] = violinplotWithStat(violinData,varargin)
    % Create a violin plot, its descriptive info (mean, median, ste, etc.) as a table, and
    % statistics also as a table

    % violinData: m*n cell array. m is the number of plots, n is the violin number in a single plot

    % groupNames: m*n cell array. size of groupNames must be the same as violinData. One name for one 

    % default

    plot_unit_width = 0.4; % normalized size of a single plot to the display
    plot_unit_height = 0.4; % nomralized size of a single plot to the display
    columnLim = 1; % number of plot column. 1 column includes violine and tables
    titleStr = sprintf('violin plot');
    save_fig = false;
    save_dir = [];
    gui_save = 'off';

    debug_mode = false;

    % Optionals
    for ii = 1:2:(nargin-1)
        if strcmpi('groupNames', varargin{ii})
            groupNames = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('titleStr', varargin{ii})
            titleStr = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('extraUItable', varargin{ii})
            extraUItable = varargin{ii+1};
        elseif strcmpi('save_fig', varargin{ii})
            save_fig = varargin{ii+1};
        elseif strcmpi('save_dir', varargin{ii})
            save_dir = varargin{ii+1};
        elseif strcmpi('gui_save', varargin{ii})
            gui_save = varargin{ii+1};
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
    violinInfoFields = {'group','data','dataInfo','stat','statTab'};
    violinInfo = empty_content_struct(violinInfoFields,dataRowNum);

    % create a struct var for violin plot and store the data here
    dataStruct = empty_content_struct(groupNames(rn,:),1);

    % create a struct var to store the data info
    dataInfoFields = {'groupNames','meanVal','medianVal','stdVal','steVal'};
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
        violinInfo(rn).group = strjoin(groupNames(rn,:),' vs ');

        violinInfo(rn).data = dataStruct;

        violinInfo(rn).dataInfo = dataInfoStruct;

        for cn = 1:dataColNum
            % store the data
            violinInfo(rn).data.(groupNames{rn,cn}) = violinData{rn,cn};

            % calculate the info (mean, median, ste, etc.) and store it
            violinInfo(rn).dataInfo(cn).groupNames = groupNames{rn,cn};
            violinInfo(rn).dataInfo(cn).meanVal = mean(violinData{rn,cn});
            violinInfo(rn).dataInfo(cn).medianVal = median(violinData{rn,cn});
            violinInfo(rn).dataInfo(cn).stdVal = std(violinData{rn,cn});
            violinInfo(rn).dataInfo(cn).steVal = ste(violinData{rn,cn});
        end

        % statistics
        [violinInfo(rn).stat,violinInfo(rn).statTab] = ttestOrANOVA(violinData(rn,:),'groupNames',groupNames(rn,:));


        % plot violin
        axViolin = nexttile(tlo,[3 1]); 
        violinplot(violinInfo(rn).data,groupNames(rn,:));

        % plot dataInfo 
        axDataInfo = nexttile(tlo,[1 1]);
        dataInfoTab = struct2table(violinInfo(rn).dataInfo);
        plotUItable(gcf,axDataInfo,dataInfoTab);


        % plot stat results
        axStat = nexttile(tlo,[1 1]);
        plotUItable(gcf,axStat,violinInfo(rn).statTab);
        title(violinInfo(rn).stat.method)


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

