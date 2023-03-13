function [timeInfo,neuron_matrix,neuron_names,varargout] = get_traceData_from_csv(path_traceCSV,varargin)
	% Read a ROI trace csv file directly exported from ISPS and plot the data  


	% Defaults
	useGUI = true; % use GUI to load csv file
	roiName_mod = true; % rename the roi names from 'C00' to 'roiName_str1'
	roiName_str = 'neuron'; % used to rename the rois


	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('useGUI', varargin{ii})
	        useGUI = varargin{ii+1};
	    elseif strcmpi('roiName_mod', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	        roiName_mod = varargin{ii+1}; % output of stim_effect_compare_trace_mean_alltrial
	    elseif strcmpi('roiName_str', varargin{ii})
            roiName_str = varargin{ii+1};
	    % elseif strcmpi('fname', varargin{ii})
        %     fname = varargin{ii+1};
	    end
	end


	% Read ROI trace csv file 
	if useGUI
		[file_traceCSV,folder_traceCSV] = uigetfile('*.csv', 'Select a ROI trace CSV file',path_traceCSV);
		path_traceCSV = fullfile(folder_traceCSV,file_traceCSV);
	else
		[folder_traceCSV, file_traceCSV, ext] = fileparts(path_traceCSV);
	end
	T = readtable(path_traceCSV);
	
	% Modify the ROI trace info: change the ROI name, seperate timeInfo
	% and ROI trace data. In short, get the data ready to be plotted by function 'plot_trace' 

	% Get the column names of the table T
	col_names = T.Properties.VariableNames;

	% Initialize a cell array to store the new column names
	new_col_names = cell(size(col_names));

	if roiName_mod
		% Loop over the column names
		for i = 1:length(col_names)
		    % Check if the column name starts with 'C'
		    if startsWith(col_names{i}, 'C')
		        % Extract the trailing digits as a numeric value
		        col_num = str2double(col_names{i}(2:end));
		        % Replace 'C' with 'neuron' and add 1 to the numeric value
		        new_col_names{i} = [roiName_str, num2str(col_num + 1)];
		    else
		        % Keep the original column name
		        new_col_names{i} = col_names{i};
		    end
		end

		% Rename the selected columns of the table with the new column names
		T.Properties.VariableNames = new_col_names;
	end

	% Get the time information
	timeInfo = T.Var1;

	% Find the columns that start with 'neuron'
	neuron_cols = startsWith(T.Properties.VariableNames, roiName_str);

	% Select the corresponding columns of the table T
	neuron_data = T(:, neuron_cols);

	% Convert the table to a matrix
	neuron_matrix = table2array(neuron_data);

	% Get the names for columns of neuron_matrix
	neuron_names = T.Properties.VariableNames(neuron_cols);


	varargout{1} = folder_traceCSV;
	varargout{2} = file_traceCSV;
end