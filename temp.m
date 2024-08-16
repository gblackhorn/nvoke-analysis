%% ==========
% 2.4 Extract properties of spontaneous events and group them according to ROIs' subnuclous location

% Get and group (gg) Settings
ggSetting.entry = 'event'; % options: 'roi' or 'event'. The entry type in eventProp
                % 'roi': events from a ROI are stored in a length-1 struct. mean values were calculated. 
                % 'event': events are seperated (struct length = events_num). mean values were not calculated
ggSetting.modify_stim_name = true; % true/false. Change the stimulation name, 
ggSetting.sponOnly = false; % true/false. If eventType is 'roi', and ggSetting.sponOnly is true. Only keep spon entries
ggSetting.seperate_spon = false; % true/false. Whether to seperated spon according to stimualtion
ggSetting.dis_spon = false; % true/false. Discard spontaneous events
ggSetting.modify_eventType_name = true; % Modify event type using function [mod_cat_name]
ggSetting.groupField = {'peak_category','subNuclei'}; % options: 'fovID', 'stim_name', 'peak_category', 'type'; Field of eventProp_all used to group events 
ggSetting.mark_EXog = false; % true/false. if true, rename the og to EXog if the value of field 'stimTrig' is 1
ggSetting.og_tag = {'og', 'og&ap'}; % find og events with these strings. 'og' to 'Exog', 'og&ap' to 'EXog&ap'
ggSetting.sort_order = {'spon', 'trig', 'rebound', 'delay'}; % 'spon', 'trig', 'rebound', 'delay'
ggSetting.sort_order_plus = {'ap', 'EXopto'};
debug_mode = false; % true/false

% Create grouped_event for plotting event properties
[eventStructForPlot] = getAndGroup_eventsProp(dataStructure_withSynchInfo,...
    'entry',ggSetting.entry,'modify_stim_name',ggSetting.modify_stim_name,...
    'ggSetting',ggSetting,'adata',adata,'debug_mode',debug_mode);

% Keep spontaneous events and discard all others
tags_keep = {'spon'}; % Keep groups containing these words. {'trig','trig-ap','rebound [og-5s]','spon'}
[eventStructForPlotFiltered] = filter_entries_in_structure(eventStructForPlot,'group',...
    'tags_keep',tags_keep);


% Create grouped_event for plotting ROI properties
ggSetting.entry = 'roi'; % options: 'roi' or 'event'. The entry type in eventProp
[roiStructForPlot] = getAndGroup_eventsProp(alignedData_allTrials,...
    'entry',ggSetting.entry,'modify_stim_name',ggSetting.modify_stim_name,...
    'ggSetting',ggSetting,'adata',adata,'debug_mode',debug_mode);

% Keep spontaneous events and discard all others
% tags_keep = {'spon'}; % Keep groups containing these words. {'trig','trig-ap','rebound [og-5s]','spon'}
[roiStructForPlotFiltered] = filter_entries_in_structure(roiStructForPlot,'group',...
    'tags_keep',tags_keep);



%% ==========
[dataStructure_withSynchInfo, cohensDPO, cohensDDAO] = clusterSpikeAmplitudeAnalysis(dataStructure,...
	'synchTimeWindow', 1, 'minROIsCluster', 2);

%% ==========
epCellNum = numel(eventProp_all_cell);
fieldsInFirstRec = fieldnames(eventProp_all_cell{1});
for i = 2:epCellNum
	if ~isempty(eventProp_all_cell{i})
		fields = fieldnames(eventProp_all_cell{i});
		tf = isequal(fieldsInFirstRec, fields);

		if ~tf
			noticeStr = sprintf('Recording %d has different fields', i);
			disp(noticeStr)
		end
	end
end


%% ==========
% Define two cell arrays
% Define the index for the second cell array
cellArray2Index = 7;

% Get the field names of the structures in the cell arrays
fieldsInCellArray2 = fieldnames(eventProp_all_cell{cellArray2Index});

% Example field names for the first record (replace with actual data)
fieldsInFirstRec = fieldnames(eventProp_all_cell{1}); % Adjust this index as needed

% Combine and find unique field names from both cell arrays
allFields = unique([fieldsInFirstRec; fieldsInCellArray2]);

% Initialize logical arrays to track presence of fields
presenceInFirstRec = ismember(allFields, fieldsInFirstRec);
presenceInCellArray2 = ismember(allFields, fieldsInCellArray2);

% Find indices where the fields differ
differingIndices = find(presenceInFirstRec ~= presenceInCellArray2);

% Display the differing fields
if isempty(differingIndices)
    disp('The cell arrays contain exactly the same contents.');
else
    disp('The cell arrays do not contain the same contents.');
    disp('Differences found in the following fields:');
    for i = 1:length(differingIndices)
        index = differingIndices(i);
        fprintf('Field: %s\n', allFields{index});
        if presenceInFirstRec(index)
            fprintf('  Present in Rec 1\n');
        else
            fprintf('  Missing in Rec 1\n');
        end
        if presenceInCellArray2(index)
            fprintf('  Present in Rec %d\n', cellArray2Index);
        else
            fprintf('  Missing in Rec %d\n', cellArray2Index);
        end
    end
end



%% ==========

stimList = {tfIdxWithSubNucleiInfo.stim};
OGidx = strcmpi('og-5s', stimList);
filterlistOG = tfIdxWithSubNucleiInfo(OGidx);

subNucleiList = {filterlistOG.subNuclei};
POidx = strcmpi('PO', subNucleiList);
DAOidx = strcmpi('DAO', subNucleiList);

filterListPO = filterlistOG(POidx);
filterListDAO = filterlistOG(DAOidx);

roiNumAllPO = numel(filterListPO);
roiNumAllDAO = numel(filterListDAO);

roiNumKeptPO = sum([filterListPO.tf]);
roiNumKeptDAO = sum([filterListDAO.tf]);

roiNumDisPO = roiNumAllPO-roiNumKeptPO;
roiNumDisDAO = roiNumAllDAO-roiNumKeptDAO;

reportOG = sprintf('Number of neurons in og-5s recordings: %d', sum(OGidx));
reportPO = sprintf('PO neurons: %d in total, %d kept, %d discarded', roiNumAllPO, roiNumKeptPO, roiNumDisPO);
reportDAO = sprintf('DAO neurons: %d in total, %d kept, %d discarded', roiNumAllDAO, roiNumKeptDAO, roiNumDisDAO);

disp(reportOG)
disp(reportPO)
disp(reportDAO)

%% ==========
recNum = numel(alignedData);
roiNumAll = 0;
for n = 1:recNum
	roiNum = numel(alignedData(n).traces);
	if ~isempty(roiNum)
		roiNumAll = roiNumAll+roiNum;
	end
end

disp(sprintf('Total number of ROI is %d', roiNumAll))


for n = 1:numel(EventFreqInBins_cell)
	if ~isempty(EventFreqInBins_cell{1, n})
		recName = EventFreqInBins_cell{1, n}(1).TrialNames(1:15);
		disp(sprintf('%d. %s', n, recName))
	else
		disp(sprintf('%d. empty recording', n))
	end
end


roiNum = 0;
for n = 1:numel(alignedData_filtered)
	if ~isempty(alignedData_filtered(n).traces)
		roiNum = roiNum + numel(alignedData_filtered(n).traces);
	end
end
disp(roiNum)


%% ==========
% Get the recording '20230219-152710'
alignedData_OgInExampleDAO = alignedData_allTrials(28);
% Generate a random permutation of indices from 1 to 23 (9 out of the neuron numbers)
random_indices = randperm(length(alignedData_OgInExampleDAO.traces), 9);

% Select the 9 random entries from the struct array
alignedData_OgInExampleDAO.traces = alignedData_OgInExampleDAO.traces(random_indices);

close all
save_fig = true; % true/false

filter_roi_tf = true; % true/false. If true, screen ROIs
stim_names = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % {'og-5s','ap-0.1s','og-5s ap-0.1s'}. compare the alignedData.stim_name with these strings and decide what filter to use
filters = {[nan nan nan nan], [nan nan nan nan], [nan nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG

event_type = 'peak_time'; % rise_time/peak_time
norm_FluorData = true; % true/false. whether to normalize the FluroData
sortROI = true; % true/false. Sort ROIs according to the event number: high to low
preTime = 10; % fig3 include time before stimulation starts for plotting
postTime = 10; % fig3 include time after stimulation ends for plotting. []: until the next stimulation starts
activeHeatMap = true; % true/false. If true, only plot the traces with specified events in figure 3
stimEvents(1).stimName = 'og-5s';
stimEvents(1).eventCat = 'rebound';
stimEvents(1).eventCatFollow = 'spon'; % The category of first event following the eventCat one
stimEvents(1).stimRefType = 'end'; % The category of first event following the eventCat one
stimEvents(2).stimName = 'ap-0.1s';
stimEvents(2).eventCat = 'trig';
stimEvents(2).eventCatFollow = 'spon'; % The category of first event following the eventCat one
stimEvents(2).stimRefType = 'start'; % The category of first event following the eventCat one
stimEvents(3).stimName = 'og-5s ap-0.1s';
stimEvents(3).eventCat = 'trig-ap';
stimEvents(3).eventCatFollow = 'spon'; % The category of first event following the eventCat one
stimEvents(3).stimRefType = 'start'; % The category of first event following the eventCat one
colorLUT = 'cyanMap'; % 'turbo' ,'magentaMap', 'cyanMap'
followDelayType = 'stim'; % stim/stimEvent. Calculate the delay of the following events using the stimulation start or the stim-evoked event time
eventsTimeSort = 'all'; % 'off'/'inROI','all'. sort traces according to eventsTime
hist_binsize = 5; % the size of the histogram bin, used to calculate the edges of the bins
xtickInt_scale = 5; % xtickInt = hist_binsize * xtickInt_scale. Use by figure 2
debug_mode = false; % true/false. 

FolderPathVA.fig = plot_calcium_signals_alignedData_allTrials(alignedData_OgInExampleDAO,...
	'filter_roi_tf',filter_roi_tf,'stim_names',stim_names,'filters',filters,...
	'norm_FluorData',norm_FluorData,'sortROI',sortROI,'event_type',event_type,...
	'preTime',preTime,'postTime',postTime,'followDelayType',followDelayType,...
	'activeHeatMap',activeHeatMap,'stimEvents',stimEvents,'eventsTimeSort',eventsTimeSort,...
	'hist_binsize',hist_binsize,'xtickInt_scale',xtickInt_scale,'colorLUT',colorLUT,...
	'save_fig',save_fig,'save_dir',FolderPathVA.fig,'debug_mode',debug_mode);





%% ==========
% 2.3 Create the mean spontaneous traces in DAO and PO
% Note: 'event_type' for alignedData must be 'detected_events'
save_fig = true; % true/false
save_dir = FolderPathVA.fig;
at.normMethod = 'highpassStd'; % 'none', 'spon', 'highpassStd'. Indicate what value should be used to normalize the traces
at.stimNames = ''; % If empty, do not screen recordings with stimulation, instead use all of them
at.eventCat = 'spon'; % options: 'trig','trig-ap','rebound','spon', 'rebound'
at.subNucleiTypes = {'DAO','PO'}; % Separate ROIs using the subnuclei tag.
at.plot_combined_data = true; % mean value and std of all traces
at.showRawtraces = false; % true/false. true: plot every single trace
at.showMedian = false; % true/false. plot raw traces having a median value of the properties specified by 'at.medianProp'
at.medianProp = 'FWHM'; % 
at.shadeType = 'std'; % plot the shade using std/ste
at.y_range = [-10 20]; % [-10 5],[-3 5],[-2 1]
% at.sponNorm = true; % true/false
% at.normalized = false; % true/false. normalize the traces to their own peak amplitudes.

close all

% Create a cell to store the trace info
traceInfo = cell(1,numel(at.subNucleiTypes));

% Loop through the subNucleiTypes
for i = 1:numel(at.subNucleiTypes)
	[~,traceInfo{i}] = AlignedCatTracesSinglePlot(alignedData_allTrials,at.stimNames,at.eventCat,...
		'normMethod',at.normMethod,'subNucleiType',at.subNucleiTypes{i},...
		'showRawtraces',at.showRawtraces,'showMedian',at.showMedian,'medianProp',at.medianProp,...
		'plot_combined_data',at.plot_combined_data,'shadeType',at.shadeType,'y_range',at.y_range);
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
spon2spon_intervals = intData.violinData.spon2spon;
trig2spon_intervals = intData.violinData.trig2spon;

[h, p] = kstest2(spon2spon_intervals, trig2spon_intervals);
disp(['K-S test p-value: ', num2str(p)]);







%% ==========
alignedDataDAO = screenSubNucleiROIs(alignedData_allTrials,'DAO');
alignedDataPO = screenSubNucleiROIs(alignedData_allTrials,'PO');

% 3.3 Violin plot showing the difference of
% stim-related-event_to_following_event_time and the spontaneous_event_interval
close all
save_fig = false; % true/false
stimNameAll = {'og-5s'}; % 'og-5s' 'ap-0.1s'
stimEventCatAll = {'rebound'}; % 'rebound', 'trig'
maxDiff = 5; % the max difference between the stim-related and the following events

% loop through different stim-event pairs

for n = 1:numel(stimNameAll) 
	stimName = stimNameAll{n};
	stimEventCat = stimEventCatAll{n};
	% [intData,eventIntMean,eventInt,f,fname] = stimEventSponEventIntAnalysis(alignedData_allTrials,stimName,stimEventCat,...
	% 'maxDiff',maxDiff);

	[intData,f,fname] = stimEventSponEventIntAnalysis(alignedDataPO,stimName,stimEventCat,...
	'maxDiff',maxDiff);

	if save_fig
		if n == 1 
			guiSave = 'on';
		else
			guiSave = 'off';
		end
		FolderPathVA.fig = savePlot(f,'save_dir',FolderPathVA.fig,'guiSave',guiSave,'fname',fname);
		save(fullfile(FolderPathVA.fig, [fname,' data']),'intData');
	end
end


%% =========
% Compare the late OG bins in DAO and PO
dataDAO = barStat.DAO(1).dataStruct;
dataPO = barStat.PO(1).dataStruct;

lateOGxdata1 = 1.5;
lateOGxdata2 = 3.5;

IDXlateOG1DAO = find([dataDAO.xdata] == lateOGxdata1);
IDXlateOG2DAO = find([dataDAO.xdata] == lateOGxdata2);
dataLateOG1DAO = dataDAO(IDXlateOG1DAO);
dataLateOG2DAO = dataDAO(IDXlateOG2DAO);

IDXlateOG1PO = find([dataPO.xdata] == lateOGxdata1);
IDXlateOG2PO = find([dataPO.xdata] == lateOGxdata2);
dataLateOG1PO = dataPO(IDXlateOG1PO);
dataLateOG2PO = dataPO(IDXlateOG2PO);

dataLateOG1Comb = [dataLateOG1DAO, dataLateOG1PO];
dataLateOG2Comb = [dataLateOG2DAO, dataLateOG2PO];


[GLMMresultsLateOG1] = twoPartMixedModelAnalysis(dataLateOG1Comb, 'val',...
	'subNuclei', {'trialNames', 'roiNames'});
[GLMMresultsLateOG2] = twoPartMixedModelAnalysis(dataLateOG2Comb, 'val',...
	'subNuclei', {'trialNames', 'roiNames'});


dataLateOG1CombCell = {[dataLateOG1DAO.val], [dataLateOG1PO.val]};
dataLateOG2CombCell = {[dataLateOG2DAO.val], [dataLateOG2PO.val]};

[statLateOG1,statTabLateOG1] = ttestOrANOVA(dataLateOG1CombCell);
[statLateOG2,statTabLateOG2] = ttestOrANOVA(dataLateOG2CombCell);


%% =========
% Compare the late OG bins in DAO and PO
eventFreqData = {barInfo.groupData};
barPlotInfo = barplot_with_errBar(eventFreqData,'barX',x,'plotWhere',plotWhere,...
        'barNames',groupNames,...
        'TickAngle', TickAngle, 'FontSize', FontSize, 'FontWeight', FontWeight);



%% =========
[stimEventJitter] = stimEventJitterAnalysis(alignedData_allTrials,{'og-5s'},'rebound');



%% ==========
% 2.3 Create the mean spontaneous traces of ogDelay events in DAO and PO
% Note: 'event_type' for alignedData must be 'detected_events'
save_fig = true; % true/false
save_dir = FolderPathVA.fig;
at.normMethod = 'highpassStd'; % 'none', 'spon', 'highpassStd'. Indicate what value should be used to normalize the traces
at.stimNames = ''; % If empty, do not screen recordings with stimulation, instead use all of them
at.eventCat = 'opto-delay'; % options: 'trig','trig-ap','rebound','spon', 'rebound'
at.subNucleiTypes = {'DAO','PO'}; % Separate ROIs using the subnuclei tag.
at.plot_combined_data = true; % mean value and std of all traces
at.showRawtraces = false; % true/false. true: plot every single trace
at.showMedian = false; % true/false. plot raw traces having a median value of the properties specified by 'at.medianProp'
at.medianProp = 'FWHM'; % 
at.shadeType = 'ste'; % plot the shade using std/ste
at.y_range = [-10 20]; % [-10 5],[-3 5],[-2 1]
% at.sponNorm = true; % true/false
% at.normalized = false; % true/false. normalize the traces to their own peak amplitudes.

close all

[OGalignedData_allTrials] = filter_entries_in_structure(alignedData_allTrials,'stim_name',...
	'tags_keep','og-5s','tags_discard','ap-0.1s');

% Create a cell to store the trace info
traceInfo = cell(1,numel(at.subNucleiTypes));

% Loop through the subNucleiTypes
for i = 1:numel(at.subNucleiTypes)
	[~,traceInfo{i}] = AlignedCatTracesSinglePlot(OGalignedData_allTrials,at.stimNames,at.eventCat,...
		'normMethod',at.normMethod,'subNucleiType',at.subNucleiTypes{i},...
		'showRawtraces',at.showRawtraces,'showMedian',at.showMedian,'medianProp',at.medianProp,...
		'plot_combined_data',at.plot_combined_data,'shadeType',at.shadeType,'y_range',at.y_range);
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
% 2.5 Plot event properties: OG-delay vs spon

% Settings
save_fig = true; % true/false
plot_combined_data = false;
parNames = {'FWHM','sponNorm_peak_mag_delta','peak_delta_norm_hpstd','peak_mag_delta'}; 
    % 'rise_duration','FWHM','sponNorm_peak_mag_delta','peak_mag_delta'
stat = true; % Set it to true to run anova when plotting bars

close all

% Setup parameters for linear-mixed-model (LMM) or generalized-mixed-model (GLMM) analysis
mmModel = 'GLMM'; % LMM/GLMM
mmGroup = 'subNuclei'; % LMM/GLMM
mmHierarchicalVars = {'trialName', 'roiName'};
mmDistribution = 'gamma'; % For continuous, positively skewed data
mmLink = 'log'; % For continuous, positively skewed data

% Keep spontaneous events and discard all others
tags_keep = {'opto-delay [og-5s]', 'spon'}; % Keep groups containing these words. {'trig','trig-ap','rebound [og-5s]','spon'}
[eventStructForPlotFiltered] = filter_entries_in_structure(eventStructForPlot,'group',...
	'tags_keep',tags_keep);

% Generate and save figures
[save_dir, plot_info] = plot_event_info(eventStructForPlotFiltered,'entryType',ggSetting.entry,...
	'plot_combined_data', plot_combined_data, 'parNames', parNames, 'stat', stat,...
	'mmModel', mmModel, 'mmGroup', mmGroup, 'mmHierarchicalVars', mmHierarchicalVars,...
	'mmDistribution', mmDistribution, 'mmLink', mmLink,...
	'fname_preffix','ogDelaySponEvent','save_fig', save_fig, 'save_dir', FolderPathVA.fig);

% Create a UI table displaying the n numberss
fNum = nNumberTab(eventStructForPlotFiltered,'event');

% Save data
if save_fig
	% Save the fNum
	savePlot(fNum,'guiSave', 'off', 'save_dir', save_dir, 'fname', 'ogDelaySponEvent nNumInfo');
	% savePlot(fMM,'guiSave', 'off', 'save_dir', save_dir, 'fname', fMM_name);

	% Save the statistics info
	eventPropStatInfo.eventStructForPlotFiltered = eventStructForPlotFiltered;
	eventPropStatInfo.plot_info = plot_info;
	% dt = datestr(now, 'yyyymmdd');
	save(fullfile(save_dir, 'ogDelaySponEvent propStatInfo'), 'eventPropStatInfo');
end


%% ==========
stimName = 'og-5s';

alignedData = alignedData_allTrials;
stimNameAll = {alignedData.stim_name};
stimPosIDX = find(cellfun(@(x) strcmpi(stimName,x),stimNameAll));
alignedDataFiltered = alignedData(stimPosIDX);

[CaLevelData,CaLevelData_n_num] = GetCalLevelInfoFromAlignedData(alignedDataFiltered,stim_name);
freq = get_frame_rate(CaLevelData.time);
box_DataPoint = box_duration*freq; % time point number in a singla box 
box_num = floor(max(CaLevelData.time)-min(CaLevelData.time))/box_duration;
xData = [CaLevelData.time(1):box_duration:(CaLevelData.time(1)+box_duration*(box_num-1))]+box_duration/2; % the x-axis location of data in the plot 
box_data_cellarray = cell(box_num,1);
data_groupName = cell(box_num,1);
for bn = 1:box_num
	start_loc = (bn-1)*box_DataPoint+1;
	end_loc = bn*box_DataPoint;
	single_box_data = mean(CaLevelData.data(start_loc:end_loc,:));
	box_data_cellarray{bn} = single_box_data(:);
end
[~,CaLevel_box_statInfo] = boxPlot_with_scatter(box_data_cellarray,'groupNames',NumArray2StringCell(xData),...
	'stat',true,'plotScatter',false);
title('CaLevel box')
ylim([-4 4]);
FolderPathVA.fig = savePlot(gcf,'guiSave','on','save_dir',FolderPathVA.fig,'fname','CaLevel box');
save(fullfile(save_dir, ['CaLevel_data_stat']),'CaLevelData','CaLevelData_n_num','CaLevel_box_statInfo');

violinData = [box_data_cellarray{:}]; % convert cell data to matrix
violinplot(violinData,NumArray2StringCell(xData));

%% ==========
stimName = 'og-5s';
subNucleiTypes = {'DAO', 'PO'};
box_duration = 1; % unit: s

for sn = 1:numel(subNucleiTypes)
	alignedDataSubN = screenSubNucleiROIs(alignedData_allTrials,subNucleiTypes{sn});

	stimNameAll = {alignedDataSubN.stim_name};
	stimPosIDX = find(cellfun(@(x) strcmpi(stimName,x),stimNameAll));
	alignedDataSubNStim = alignedDataSubN(stimPosIDX);

	[CaLevelData,CaLevelData_n_num] = GetCalLevelInfoFromAlignedData(alignedDataSubNStim,stimName);
	freq = get_frame_rate(CaLevelData.time);
	box_DataPoint = box_duration*freq; % time point number in a singla box 
	box_num = floor(max(CaLevelData.time)-min(CaLevelData.time))/box_duration;
	xData = [CaLevelData.time(1):box_duration:(CaLevelData.time(1)+box_duration*(box_num-1))]+box_duration/2; % the x-axis location of data in the plot 
	box_data_cellarray = cell(box_num,1);
	data_groupName = cell(box_num,1);
	for bn = 1:box_num
		start_loc = (bn-1)*box_DataPoint+1;
		end_loc = bn*box_DataPoint;
		single_box_data = mean(CaLevelData.data(start_loc:end_loc,:));
		box_data_cellarray{bn} = single_box_data(:);
	end
	[~,CaLevel_box_statInfo] = boxPlot_with_scatter(box_data_cellarray,'groupNames',NumArray2StringCell(xData),...
		'stat',true,'plotScatter',false);
	titleStr = sprintf('%s CaLevel box', subNucleiTypes{sn});
	title(titleStr)
	ylim([-4 4]);
end


plot_raw_traces = false;
[tracesAverage, tracesShade] = plotAlignedTracesAverage(gca, CaLevelData.data, CaLevelData.time,...
	'plot_raw_traces', plot_raw_traces);



formula = sprintf('%s ~ %s * %s + %s', responseVar, groupVar, timeBinVar, strjoin(randomEffects, ' + '))


%% ==========
% Convert binIDX to a categorical variable
tbl.binIDX = categorical(tbl.binIDX);

% Define the model formula with interaction term
randomEffects = strcat('(1|', {'recTags', 'roiTags'}, ')');
formula = sprintf('%s ~ %s * %s + %s', 'binVal', 'subN', 'binIDX', strjoin(randomEffects, ' + '));

% Fit the Linear Mixed-Effects Model (LMM)
lme = fitlme(tbl, formula);

% Display the results
disp(lme);

% Extract the names of the fixed effects
fixedEffectsNames = lme.CoefficientNames;

% Initialize arrays to store p-values and test statistics
pValues = [];
testStats = [];

% Specify the time bin to compare
timeBinToCompare = '4';  % Modify as needed for the specific bin

% Construct the hypothesis matrix H
effectName = sprintf('binIDX_%s:subN_PO', timeBinToCompare);
idx = find(strcmp(fixedEffectsNames, effectName));

if ~isempty(idx)
    H = zeros(1, length(fixedEffectsNames));
    H(idx) = 1;
    
    % Perform the hypothesis test
    [pValue, F, DF1, DF2] = coefTest(lme, H);
    
    % Store the p-value and test statistic
    pValues = [pValues; pValue];
    testStats = [testStats; F];
    
    % Print the results
    fprintf('Comparison for Time Bin: %s\n', timeBinToCompare);
    fprintf('F(%d,%d) = %.2f, p = %.4f\n', DF1, DF2, F, pValue);
else
    fprintf('Effect %s not found in the model.\n', effectName);
end

% Display the p-values
disp('P-values:');
disp(pValues);



%% ==========
close all
figure
caMinDeltaReboundDAO = [eventStructForPlot(8).event_info.caLevelDelta]; 
peakHpstdReboundDAO = [eventStructForPlot(8).event_info.peak_slope_norm_hpstd]; 

stylishScatter(caMinDeltaReboundDAO,peakHpstdReboundDAO, 'plotWhere', gca, 'MarkerEdgeColor', 'k');

hold on

caMinDeltaReboundPO = [eventStructForPlot(9).event_info.caLevelDelta]; 
peakHpstdReboundPO = [eventStructForPlot(9).event_info.peak_slope_norm_hpstd]; 

stylishScatter(caMinDeltaReboundPO,peakHpstdReboundPO, 'plotWhere', gca);


%% ==========
% Open a file to write the LaTeX table
fid = fopen('chiLRT_table.tex', 'w');

% Write the beginning of the LaTeX table environment
fprintf(fid, '\\begin{table}[H]\n');
fprintf(fid, '\\centering\n');
fprintf(fid, '\\begin{tabular}{|l|c|c|c|c|c|c|c|c|}\n');
fprintf(fid, '\\hline\n');

% Write the header row
header = chiLRT.Properties.VariableNames;
fprintf(fid, '%s & %s & %s & %s & %s & %s & %s & %s & %s \\\\\n', header{:});
fprintf(fid, '\\hline\n');

% Write the data rows
for i = 1:height(chiLRT)
    row = chiLRT(i, :);
    
    % Convert each element to string for concatenation
    modelStr = char(row.Model); % Convert 'Model' to a char
    formulaStr = char(row.Formula); % Convert 'Formula' to a char
    
    % Handle numerical values directly
    DF = row.DF;
    AIC = row.AIC;
    BIC = row.BIC;
    LogLik = row.LogLik;
    LRStat = row.LRStat;
    deltaDF = row.deltaDF;
    pValue = row.pValue;
    
    % Print the row
    fprintf(fid, '%s & %s & %d & %.0f & %.0f & %.1f & %.1f & %.1f & %.1e \\\\\n', ...
        modelStr, formulaStr, DF, AIC, BIC, LogLik, LRStat, deltaDF, pValue);
end

% Write the end of the LaTeX table environment
fprintf(fid, '\\hline\n');
fprintf(fid, '\\end{tabular}\n');
fprintf(fid, '\\caption{Your caption here}\n');
fprintf(fid, '\\label{tab:chiLRT}\n');
fprintf(fid, '\\end{table}\n');

% Close the file
fclose(fid);

% Display the content of the generated LaTeX file (optional)
type('chiLRT_table.tex');
