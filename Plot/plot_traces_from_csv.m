function [varargout] = plot_traces_from_csv(path_traceCSV,varargin)
	% Read a ROI trace csv file directly exported from ISPS and plot the data  

	% Use varargin to read the gpio csv file and mark the stimulation period with transparent shade
	% in the plot.

	% Use varargin to save the plot 

	% Example: 
	%	path_traceCSV = 'D:\guoda\Documents\Workspace_Analysis\OIST\manuscript\nucleo-olivary pathway bidirectionally modulates IO activity\Figures\example_traces';
	%	plot_traces_from_csv(path_traceCSV,'roiName_mod',true,'roiName_str','neuron','stimShade',true,'save_fig',true);


	% Defaults
	useGUI = true;
	roiName_mod = true;
	roiName_str = 'neuron';
	stimShade = false;
	save_fig = false;
	path_gpio = '';


	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('path_gpio', varargin{ii})
	        path_gpio = varargin{ii+1};
	    elseif strcmpi('save_fig', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	        save_fig = varargin{ii+1}; % output of stim_effect_compare_trace_mean_alltrial
	    elseif strcmpi('plotWhere', varargin{ii})
            plotWhere = varargin{ii+1};
	    elseif strcmpi('useGUI', varargin{ii})
            useGUI = varargin{ii+1};
	    elseif strcmpi('roiName_mod', varargin{ii})
            roiName_mod = varargin{ii+1};
	    elseif strcmpi('roiName_str', varargin{ii})
            roiName_str = varargin{ii+1};
	    elseif strcmpi('stimShade', varargin{ii})
            stimShade = varargin{ii+1};
	    end
	end


	%% Read ROI trace csv file and get the time and trace data for plot
	if isempty(path_traceCSV)
		useGUI = true;
	end
	[timeInfo,neuron_matrix,neuron_names,folder_CSV,file_traceCSV] = get_traceData_from_csv(path_traceCSV,...
		'useGUI',useGUI,'roiName_mod',roiName_mod,'roiName_str',roiName_str);

	% convert the df/f value to df/f %
	neuron_matrix = neuron_matrix*100;
	titleStr = strrep(file_traceCSV, '_', ' ');


	% (optional) Read gpio file and Extract stimulation information for drawing shade in the trace plot
	if stimShade
		if isempty(path_gpio)
			useGUI = true;
			path_gpio = folder_CSV;
		end
		[patchCoor,stimName] = get_gpio_from_csv(path_gpio,'useGUI',useGUI);
	else
		patchCoor = {};
		stimName = '';
	end


	%% Plot the trace data
	titleStr = sprintf('%s %s',titleStr,stimName);
	if ~exist('plotWhere')
		f = fig_canvas(1,'unit_width',0.6,'unit_height',0.8,'fig_name',titleStr);
		plotWhere = gca;
	end
	plot_TemporalData_Trace(plotWhere,timeInfo,neuron_matrix,...
		'ylabels',neuron_names,'plot_marker',false,...
		'shadeData',patchCoor);
	
	title(titleStr)



	% Save the plot
	if save_fig
		msg = 'Choose a folder to save calcium traces';
		savePlot(f,'save_dir',folder_CSV,'guiSave',true,...
			'guiInfo',msg,'fname',titleStr);
	end

end