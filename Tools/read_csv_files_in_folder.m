function [combined_csv_data,varargout] = read_csv_files_in_folder(folder,varargin)
    % Read .csv files in a folder and combine them into a single table
    % Use keywords to filter files
    % All .csv files should contain tables with the same column headers

    % combined_csv_data: a struct var. combined data, data in each single csv, the csv folder are stored in it


    % Defaults
    debug_mode = false;
    keywords = {}; 
    del_col = {};
    % keywords_exclud = {};
    save_tbl = false;
    gui_read = false;
    debug_mode = false;


    % Options
    for ii = 1:2:(nargin-1)
        if strcmpi('debug_mode', varargin{ii})
            debug_mode = varargin{ii+1};
        elseif strcmpi('keywords', varargin{ii})
            keywords = varargin{ii+1}; % look for csv files containing the keywords in a folder
        elseif strcmpi('del_col', varargin{ii}) 
            del_col = varargin{ii+1}; % delete column. Add column header in a cell array
        elseif strcmpi('save_tbl', varargin{ii})
            save_tbl = varargin{ii+1};
        elseif strcmpi('gui_read', varargin{ii})
            gui_read = varargin{ii+1};
        elseif strcmpi('debug_mode', varargin{ii})
            debug_mode = varargin{ii+1};
        end
    end

    %% main contents
    if ~exist('folder','var')
        folder = '';
    end
    if gui_read || isempty(folder)
        selpath = uigetdir(folder, 'Select a folder to read csv files in it');
    else
        selpath = folder;
    end

    csv_list_all = dir(fullfile(selpath,'*.csv'));
    csv_name_all = {csv_list_all.name};

    [~,idx] = filter_CharCells(csv_name_all,keywords);
    csv_list = csv_list_all(idx);
    csv_num = numel(csv_list);

    if csv_num > 0
        single_roi_data = empty_content_struct({'name','data'});
        for cn = 1:csv_num
            single_roi_data(cn).name = csv_list(cn).name;

            if debug_mode
                fprintf('%s\n',single_roi_data(cn).name)
            end

            fullpath_csv = fullfile(selpath,single_roi_data(cn).name);
            single_roi_data(cn).data = table2struct(readtable(fullpath_csv)); % read csv file and convert the tbl to struct
            [single_roi_data(cn).data.CsvName] = deal(single_roi_data(cn).name); 

            if ~isempty(del_col)
                field_TF = isfield(single_roi_data(cn).data,del_col);
                field_del = del_col(find(field_TF));
                single_roi_data(cn).data = rmfield(single_roi_data(cn).data,field_del);
            end

            if cn == 1
                combined_data = single_roi_data(cn).data;
            else
                combined_data = [combined_data;single_roi_data(cn).data];
            end
        end

        combined_csv_data.combined_data = combined_data;
        combined_csv_data.single_roi_data = single_roi_data;
        combined_csv_data.selpath = selpath;
    else
        keywords_WithSpace = cellfun(@(x) [x, ' '], keywords, 'UniformOutput',false); % add space to the end of each keyword
        keywords_string = sprintf('%s',string(keywords_WithSpace)); % convert keywords cell array to string array for display
        warning('CSV files containing keywords (%s) are not found', keywords_string)
        combined_csv_data = [];
    end
    varargout{1} = csv_num;
    varargout{2} = csv_list;
end

