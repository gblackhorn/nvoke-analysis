% Initiate the folder path for saving data
GUI_chooseFolder = false; % true/false. Use GUI to locate the DataFolder and AnalysisFolder
FolderPathVA = initProjFigPathVIIO(GUI_chooseFolder);

%% ==========
% Example showing the difference between raw traces and CNMFe-denoised traces
% Note: There must be mat and csv files containing traces data in the 'save_dir'
close all

% Settings for figure
saveFig = false; % true/false
showYtickRight = true; % true/false. Show the Ytick on the right side of traces plot to display the dF/F (shifted)

% Setup the folder path to save plots
save_dir = fullfile(FolderPathVA.ventralApproach,'VIIO_paper_figure\VIIO_Fig1_method_recExample');

% Load the no-stim example recording mat file
exampleRecFile = fullfile(FolderPathVA.ventralApproach,'VIIO_paper_figure\ProcessedData_VIIO_Fig1_example.mat');
load(exampleRecFile); % Load data

% Get the recording and ROI names
shortRecName = extractDateTimeFromFileName(alignedData_allTrials.trialName); % Get he yyyyddmm-hhmmss from recording file name
roiNames = {alignedData_allTrials.traces.roi}; % Get the ROI names
shortRoiNames = cellfun(@(x) x(7:end),roiNames,'UniformOutput',false); % Remove 'neuron' from the roi names



% Plot the FOV and label ROIs in it: fExampleRecFOV
imageMatrix = alignedData_allTrials.roi_map; % Get the 2D matrix for plotting the FOV
roiBoundaries = {alignedData_allTrials.traces.roiEdge}; % Get the ROI edges
nameExampleRecFOV = [shortRecName,' FOV'];
fExampleRecFOV = fig_canvas(1,'unit_width',0.4,'unit_height',0.4,'fig_name',nameExampleRecFOV); % Create a figure for plots
plotCalciumImagingWithROIs(imageMatrix, roiBoundaries, shortRoiNames,...
	'Title',nameExampleRecFOV,'AxesHandle',gca);



% Plot the raw data dF/F: Using the data in the IDPS exported csv file
% Fig2 A
nameIDPStrace = [shortRecName,' RAW with noise']; % Setup the plot name
fIDPStrace = fig_canvas(1,'unit_width',0.4,'unit_height',0.4,'fig_name',nameIDPStrace); % Create a figure for plotting
[csvTraceTitle,csvFolder] = plotCalciumTracesFromIDPScsv('AxesHandle',gca,'folderPath',save_dir,...
	'showYtickRight',showYtickRight,'Title',nameIDPStrace); % Plot the raw traces
set(gcf, 'Renderer', 'painters'); % Use painters renderer for better vector output

% Plot the denoised data dF/F: Using the denoised data (BG and neuropil subracted) output by CNMFe
% Fig1 C, Fig2 A
nameCNMFeTrace = [shortRecName,' denoised by CNMFe']; % Setup the plot name
timeData = alignedData_allTrials.fullTime; % Get the time information
tracesData = [alignedData_allTrials.traces.fullTrace]; % Get the denoised traces
eventTime = get_TrialEvents_from_alignedData(alignedData_allTrials,'peak_time'); % Get the time of event peaks
fCNMFeTrace = fig_canvas(1,'unit_width',0.4,'unit_height',0.4,'fig_name',nameCNMFeTrace); % Create a figure for plotting
plot_TemporalData_Trace(gca,timeData,tracesData,'ylabels',shortRoiNames,'showYtickRight',showYtickRight,...
	'titleStr',nameCNMFeTrace,'plot_marker',true,'marker1_xData',eventTime); % Plot the denoised traces
set(gcf, 'Renderer', 'painters'); % Use painters renderer for better vector output
trace_xlim = xlim;



% Plot the calcium events using scatters
% Fig2 C?
colorRepresent = 'sponnorm_peak_mag_delta'; % Use this parameter to adjust the color of scatters
nameEventScatter = sprintf('%s eventScatter [Color: %s]', shortRecName, strrep(colorRepresent, '_', '-')); % Setup plot name
colorData = get_TrialEvents_from_alignedData(alignedData_allTrials, colorRepresent); % Get the values of colorRepresent properties
% Create a raster plot
fEventScatter = fig_canvas(1,'unit_width',0.4,'unit_height',0.4,'fig_name',nameEventScatter); % Create a figure for plots
plot_TemporalRaster(eventTime,'plotWhere',gca,'colorData',colorData,'norm2roi',true,...
	'rowNames',shortRoiNames,'x_window',trace_xlim,'xtickInt',25,...
	'yInterval',5,'sz',20); % Plot raster
set(gcf, 'Renderer', 'painters'); % Use painters renderer for better vector output
title(nameEventScatter)


% Save figures
if saveFig
	% Save the fNum
	savePlot(fExampleRecFOV,'guiSave', 'off', 'save_dir', save_dir,'fname', nameExampleRecFOV);
	savePlot(fCNMFeTrace,'guiSave', 'off', 'save_dir', save_dir,'fname', nameCNMFeTrace);
	savePlot(fIDPStrace,'guiSave', 'off', 'save_dir', save_dir,'fname', nameIDPStrace);
	savePlot(fEventScatter,'guiSave', 'off', 'save_dir', save_dir,'fname', nameEventScatter);
end



%% ==========
% Create the mean spontaneous traces in DAO and PO
% Note: Load mat file containing all the recordings 
% Fig2 B

% % Note: 'event_type' for alignedData must be 'detected_events'
save_fig = false; % true/false
save_dir = FolderPathVA.fig;
% at.normMethod = 'highpassStd'; % 'none', 'spon', 'highpassStd'. Indicate what value should be used to normalize the traces
% at.stimNames = ''; % If empty, do not screen recordings with stimulation, instead use all of them
% at.eventCat = 'spon'; % options: 'trig','trig-ap','rebound','spon', 'rebound'
% at.subNucleiTypes = {'DAO','PO'}; % Separate ROIs using the subnuclei tag.
% at.plot_combined_data = true; % mean value and std of all traces
% at.showRawtraces = false; % true/false. true: plot every single trace
% at.showMedian = false; % true/false. plot raw traces having a median value of the properties specified by 'at.medianProp'
% at.medianProp = 'FWHM'; % 
% at.shadeType = 'ste'; % plot the shade using std/ste
% at.y_range = [-10 20]; % [-10 5],[-3 5],[-2 1]

subNucleiTypes = {'DAO','PO'}; % Separate ROIs using the subnuclei tag.

close all

% Create a cell to store the trace info
traceInfo = cell(1,numel(subNucleiTypes));

% Loop through the subNucleiTypes
for i = 1:numel({'DAO','PO'})
	[~,traceInfo{i}] = AlignedCatTracesSinglePlot(alignedData_allTrials,'','spon',...
		'normMethod','highpassStd','subNucleiType',subNucleiTypes{i},...
		'showRawtraces',false,'showMedian',false,'medianProp','FWHM',...
		'plot_combined_data',true,'shadeType','ste','y_range',[-10 20]);
	% 'sponNorm',at.sponNorm,'normalized',at.normalized,

	if i == 1
		guiSave = 'on';
	else
		guiSave = 'off';
	end
	if save_fig
		save_dir = savePlot(gcf,'guiSave', guiSave, 'save_dir', save_dir, 'fname', traceInfo{i}.fname);
	end
end
traceInfo = [traceInfo{:}];

if save_fig
	save(fullfile(save_dir,'alignedCalTracesInfo'), 'traceInfo');
	FolderPathVA.fig = save_dir;
end




%% ==========


