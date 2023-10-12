function [violinData,statInfo,varargout] = stylishPieChart(pieData,sliceNames,varargin)
    % Create a stylish pie chart by using explode and, heatmap, customized font

    % pieData: vector

    % sliceNames: strings 

    % default
    explodeEffect = true;


    % Optionals
    for ii = 1:2:(nargin-3)
        if strcmpi('titleStr', varargin{ii})
            titleStr = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('normToFirst', varargin{ii})
            normToFirst = varargin{ii+1};
        elseif strcmpi('save_fig', varargin{ii})
            save_fig = varargin{ii+1};
        elseif strcmpi('save_dir', varargin{ii})
            save_dir = varargin{ii+1};
        elseif strcmpi('gui_save', varargin{ii})
            gui_save = varargin{ii+1};
        end
    end 

end
