function [SaveTo, varargout] = plotTracesFromAllTrials (IOnVokeData, varargin)

	% Default
	PauseTrial = 0; % pause after each trial
	SavePlot = false;
	SaveTo = pwd; % save plot to dir
	traceNum_perFig = 10; % number of traces/ROIs per figure
	decon = true; % true/false plot decon trace
	marker = true; % true/false plot markers
	vis = 'on'; % set the 'visible' of figures

	% Optionals
	for ii = 1:2:(nargin-1)
		if strcmpi('PauseTrial', varargin{ii})
			PauseTrial = varargin{ii+1};
		elseif strcmpi('SavePlot', varargin{ii})
            SavePlot = varargin{ii+1};
        elseif strcmpi('SaveTo', varargin{ii})
            SaveTo = varargin{ii+1};
        elseif strcmpi('traceNum_perFig', varargin{ii})
            traceNum_perFig = varargin{ii+1};
        elseif strcmpi('decon', varargin{ii})
            decon = varargin{ii+1};
        elseif strcmpi('marker', varargin{ii})
            marker = varargin{ii+1};
        elseif strcmpi('vis', varargin{ii})
            vis = varargin{ii+1};
        end
	end

	if SavePlot
		figdir = uigetdir(SaveTo,...
			    'Select a folder to save calcium signal traces');
		if figdir ~= 0
			SaveTo = figdir;
		else
			disp('Folder for saving figures not selected')
			return
		end
	end

	nTrials = getNtrialsFromROIdata(IOnVokeData);

	for trial = 1:nTrials
		close all
	    % display(['trial ', num2str(trial)])
	    % if trial == 5 % used for debugging
	    % 	disp('Pause for debugging. Press any key to continue')
	    %     pause
	    % end

	    trialData = IOnVokeData(trial, :);
	    plotROItracesFromTrial(trialData,...
	    	'traceNum_perFig', traceNum_perFig, 'decon', decon, 'marker', marker,...
	    	'SavePlot', SavePlot, 'SaveTo', SaveTo, 'SaveWithGUI', false,...
	    	'vis', vis);

	    fprintf('%d/%d recordings have been plotted\n', trial, nTrials)
	    if trial==25
	    	pause
	    end


	   if PauseTrial
	   	disp('Press any key to plot next trial') 
	   	pause
	   end
	end
% 	varargout{1} = plotInterval; % distance between y ticks
	% R = 1;
end