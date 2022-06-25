function [varargout] = plot_ROIevent_scatter_from_trial_all(recdata,varargin)
    % plot events as scatter all ROIS in a trial: lowpassed, deconvoluted
    
    % Defaults
    plotInterval = 5; % offset on y axis to seperate data from various ROIs
    sz = 20; % marker area

    save_fig = false;
    save_dir = '';

    % Optionals for inputs
    for ii = 1:2:(nargin-1)
    	if strcmpi('plotInterval', varargin{ii})
    		plotInterval = varargin{ii+1};
    	elseif strcmpi('sz', varargin{ii})
    		sz = varargin{ii+1};
    	elseif strcmpi('save_fig', varargin{ii})
    		save_fig = varargin{ii+1};
        elseif strcmpi('save_dir', varargin{ii})
            save_dir = varargin{ii+1};
        end
    end

    %% main contents
    if save_fig
        save_dir = uigetdir(save_dir,...
                'Select a folder to save figures');
        if save_dir ~= 0
            SaveTo = save_dir;
        else
            disp('Folder for saving figures not selected')
            return
        end
    end

    trial_num = size(recdata,1);
    for tn = 1:trial_num
        trialData = recdata(tn,:);

        plot_ROIevent_scatter_from_trial(trialData,...
            'plotInterval',plotInterval,'sz',sz,'save_fig',save_fig,'save_dir',save_dir);

        fprintf('%d/%d recordings have been plotted\n', tn, trial_num)
    end

    varargout{1} = SaveTo;
end

