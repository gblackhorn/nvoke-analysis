function [varargout] = savePlot(fig_handle, varargin)
    % Save plot
    % handle of the plot to be saved

    % savePlot(fig_handle,'save_dir',folder,'guiInfo',msg,'guiSave','on','fname',figTitle, 'paperSize', 'A4')

    % Defaults
    guiSave = 'off'; % Options: 'on'/'off'/'true'/'false'. whether use the gui to choose the save_dir
    save_dir = '';
    guiInfo = 'Choose a folder to save plot';
    fname = ''; % file name
    figFormat = true;
    jpgFormat = true;
    svgFormat = true;
    paperSize = 'A4'; % Default paper size
    orientation = 'horizontal'; % Default paper orientation

    % Create input parser
    p = inputParser;
    addRequired(p, 'fig_handle');
    addParameter(p, 'save_dir', save_dir);
    addParameter(p, 'guiInfo', guiInfo, @ischar);
    addParameter(p, 'guiSave', guiSave, @(x) ischar(x) || islogical(x));
    addParameter(p, 'fname', fname, @ischar);
    addParameter(p, 'paperSize', paperSize, @(x) any(validatestring(x, {'A4', 'A5', 'Letter'})));
    addParameter(p, 'orientation', orientation, @(x) any(validatestring(x, {'horizontal', 'vertical'})));

    % Parse inputs
    parse(p, fig_handle, varargin{:});

    % Assign parsed values to variables
    fig_handle = p.Results.fig_handle;
    save_dir = p.Results.save_dir;
    guiInfo = p.Results.guiInfo;
    guiSave = p.Results.guiSave;
    fname = p.Results.fname;
    paperSize = p.Results.paperSize;
    orientation = p.Results.orientation;

    % Handle GUI save option
    if ischar(guiSave)
        switch lower(guiSave)
            case 'on'
                guiSave = true;
            case 'off'
                guiSave = false;
            otherwise
                error('Invalid value for guiSave. Use ''on'', ''off'', true, or false.');
        end
    end

    if guiSave
        guiInfo = sprintf('%s: %s', guiInfo, fname);
        save_dir = uigetdir(save_dir, guiInfo);
    else
        if isempty(save_dir)
            fprintf('[save_dir] is empty. figure will not be saved\n')
            return
        end
    end

    if save_dir == 0
        disp('Folder for saving plots not chosen.')
        return
    else
        if isempty(fname)
            fname = datestr(now, 'yyyymmdd_HHMMSS');
        end
        filepath = fullfile(save_dir, fname);

        % Set paper size
        setPaperSize(fig_handle, paperSize, orientation);

        % Adjust the title to fit within the figure
        adjustTitle(fig_handle, fname);

        if figFormat
            savefig(fig_handle, [filepath, '.fig']);
        end
        if jpgFormat
            saveas(fig_handle, [filepath, '.jpg']);
        end
        if svgFormat
            print(fig_handle, [filepath, '.svg'], '-dsvg', '-vector');
        end
    end

    varargout{1} = save_dir;
    varargout{2} = fname;
end

function setPaperSize(figHandle, paperSize, orientation)
    % Set the paper size and paper position
    set(figHandle, 'PaperUnits', 'centimeters');

    % Set default orientation if not provided
    if nargin < 3
        orientation = 'horizontal';
    end

    % Initialize paper dimensions
    paperWidth = 0;
    paperHeight = 0;
    
    % Set paper size based on the input paperSize
    switch paperSize
        case 'A4'
            paperWidth = 21.0;
            paperHeight = 29.7;
        case 'A5'
            paperWidth = 14.85;
            paperHeight = 21.0;
        case 'Letter'
            paperWidth = 21.59;
            paperHeight = 27.94;
        otherwise
            error('Unsupported paper size');
    end
    
    % Get the current aspect ratio of the figure
    figPos = get(figHandle, 'Position');
    figAspectRatio = figPos(3) / figPos(4); % Width / Height

    % Calculate new width and height maintaining the aspect ratio
    if strcmpi(orientation, 'horizontal')
        if figAspectRatio > 1 % Wider than tall
            newWidth = paperHeight; % Full width of the paper
            newHeight = paperHeight / figAspectRatio;
        else % Taller than wide or square
            newHeight = paperWidth; % Full height of the paper
            newWidth = paperWidth * figAspectRatio;
        end
    elseif strcmpi(orientation, 'vertical')
        if figAspectRatio > 1 % Wider than tall
            newWidth = paperWidth; % Full width of the paper
            newHeight = paperWidth / figAspectRatio;
        else % Taller than wide or square
            newHeight = paperHeight; % Full height of the paper
            newWidth = paperHeight * figAspectRatio;
        end
    else
        error('Unsupported orientation. Use ''vertical'' or ''horizontal''.');
    end

    % Set the new paper size and position
    set(figHandle, 'PaperSize', [newWidth, newHeight]);
    set(figHandle, 'PaperPosition', [0, 0, newWidth, newHeight]);
end

function adjustTitle(figHandle, titleStr)
    % Adjust the title to fit within the figure
    maxCharsPerLine = 50; % Maximum characters per line
    wrappedTitle = wrapTitle(titleStr, maxCharsPerLine);

    % Set the wrapped title using sgtitle
    sgtitle(figHandle, wrappedTitle, 'Interpreter', 'none');
end

function wrappedTitle = wrapTitle(titleStr, maxCharsPerLine)
    % Wrap the title into multiple lines based on the specified character limit
    words = strsplit(titleStr);
    currentLine = words{1};
    wrappedTitle = currentLine;

    for i = 2:length(words)
        if length(currentLine) + length(words{i}) + 1 <= maxCharsPerLine
            currentLine = [currentLine, ' ', words{i}];
        else
            wrappedTitle = [wrappedTitle, newline, words{i}];
            currentLine = words{i};
        end
    end

    % Add the remaining words to the last line
    if ~isempty(currentLine)
        wrappedTitle = [wrappedTitle, newline, currentLine];
    end
end





% function [varargout] = savePlot(fig_handle, varargin)
%     % Save plot
%     % handle of the plot to be saved

%     % savePlot(fig_handle,'save_dir',folder,'guiInfo',msg,'guiSave','on','fname',figTitle, 'paperSize', 'A4')

%     % Defaults
%     guiSave = 'off'; % Options: 'on'/'off'/'true'/'false'. whether use the gui to choose the save_dir
%     save_dir = '';
%     guiInfo = 'Choose a folder to save plot';
%     fname = ''; % file name
%     figFormat = true;
%     jpgFormat = true;
%     svgFormat = true;
%     paperSize = 'A4'; % Default paper size
%     orientation = 'horizontal'; % Default paper orientation

%     % Create input parser
%     p = inputParser;
%     addRequired(p, 'fig_handle');
%     addParameter(p, 'save_dir', save_dir);
%     addParameter(p, 'guiInfo', guiInfo, @ischar);
%     addParameter(p, 'guiSave', guiSave, @(x) ischar(x) || islogical(x));
%     addParameter(p, 'fname', fname, @ischar);
%     addParameter(p, 'paperSize', paperSize, @(x) any(validatestring(x, {'A4', 'A5', 'Letter'})));
%     addParameter(p, 'orientation', orientation, @(x) any(validatestring(x, {'horizontal', 'vertical'})));

%     % Parse inputs
%     parse(p, fig_handle, varargin{:});

%     % Assign parsed values to variables
%     fig_handle = p.Results.fig_handle;
%     save_dir = p.Results.save_dir;
%     guiInfo = p.Results.guiInfo;
%     guiSave = p.Results.guiSave;
%     fname = p.Results.fname;
%     paperSize = p.Results.paperSize;
%     orientation = p.Results.orientation;

%     % Handle GUI save option
%     if ischar(guiSave)
%         switch lower(guiSave)
%             case 'on'
%                 guiSave = true;
%             case 'off'
%                 guiSave = false;
%             otherwise
%                 error('Invalid value for guiSave. Use ''on'', ''off'', true, or false.');
%         end
%     end

%     if guiSave
%         guiInfo = sprintf('%s: %s', guiInfo, fname);
%         save_dir = uigetdir(save_dir, guiInfo);
%     else
%         if isempty(save_dir)
%             fprintf('[save_dir] is empty. figure will not be saved\n')
%             return
%         end
%     end

%     if save_dir == 0
%         disp('Folder for saving plots not chosen.')
%         return
%     else
%         if isempty(fname)
%             fname = datestr(now, 'yyyymmdd_HHMMSS');
%         end
%         filepath = fullfile(save_dir, fname);

%         % Set paper size
%         setPaperSize(fig_handle, paperSize, orientation);

%         if figFormat
%             savefig(fig_handle, [filepath, '.fig']);
%         end
%         if jpgFormat
%             saveas(fig_handle, [filepath, '.jpg']);
%         end
%         if svgFormat
%             print(fig_handle, [filepath, '.svg'], '-dsvg', '-vector');
%         end
%     end

%     varargout{1} = save_dir;
%     varargout{2} = fname;
% end



% function setPaperSize(figHandle, paperSize, orientation)
%     % Set the paper size and paper position
%     set(figHandle, 'PaperUnits', 'centimeters');

%     % Set default orientation if not provided
%     if nargin < 3
%         orientation = 'horizontal';
%     end

%     % Initialize paper dimensions
%     paperWidth = 0;
%     paperHeight = 0;
    
%     % Set paper size based on the input paperSize
%     switch paperSize
%         case 'A4'
%             paperWidth = 21.0;
%             paperHeight = 29.7;
%         case 'A5'
%             paperWidth = 14.85;
%             paperHeight = 21.0;
%         case 'Letter'
%             paperWidth = 21.59;
%             paperHeight = 27.94;
%         otherwise
%             error('Unsupported paper size');
%     end
    
%     % Get the current aspect ratio of the figure
%     figPos = get(figHandle, 'Position');
%     figAspectRatio = figPos(3) / figPos(4); % Width / Height

%     % Calculate new width and height maintaining the aspect ratio
%     if strcmpi(orientation, 'horizontal')
%         if figAspectRatio > 1 % Wider than tall
%             newWidth = paperHeight; % Full width of the paper
%             newHeight = paperHeight / figAspectRatio;
%         else % Taller than wide or square
%             newHeight = paperWidth; % Full height of the paper
%             newWidth = paperWidth * figAspectRatio;
%         end
%     elseif strcmpi(orientation, 'vertical')
%         if figAspectRatio > 1 % Wider than tall
%             newWidth = paperWidth; % Full width of the paper
%             newHeight = paperWidth / figAspectRatio;
%         else % Taller than wide or square
%             newHeight = paperHeight; % Full height of the paper
%             newWidth = paperHeight * figAspectRatio;
%         end
%     else
%         error('Unsupported orientation. Use ''vertical'' or ''horizontal''.');
%     end

%     % Set the new paper size and position
%     set(figHandle, 'PaperSize', [newWidth, newHeight]);
%     set(figHandle, 'PaperPosition', [0, 0, newWidth, newHeight]);
% end

