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
fig1 = 'D:\guoda\Documents\Workspace\manuscript\Paper\VIIO\FIGURES\Figures_In_Progress\EventProp_1sReboundWin\sponSubN cumulative distribution plots.jpg';
fig2 = 'D:\guoda\Documents\Workspace\manuscript\Paper\VIIO\FIGURES\Figures_In_Progress\EventProp_1sReboundWin_OgExKept\sponSubN cumulative distribution plots.jpg';

combinedImage = combineImages(fig1, fig2, 'label1', '1', 'label2', '2');


%% ==========

figFolder = 'D:\guoda\Documents\Workspace\manuscript\Paper\VIIO\FIGURES\Figures_In_Progress';
saveFolder = 'D:\guoda\Documents\Workspace\manuscript\Paper\VIIO\FIGURES\Figures_In_Progress';
label1 = "exclude-ogEx-neurons"; % String array
label2 = "Keep-ogEx-neurons";    % String array
figExt = 'jpg';
ignoreKeyword = 'bar stat';

% Call the function
comparePlotsUsingdiffSetting(figFolder, saveFolder,...
	'label1', label1, 'label2', label2, 'figExt', figExt, 'ignoreKeyword', ignoreKeyword);


tableExt = 'tex';

% Call the function
compareLatexTablesUsingDiffSetting(figFolder, saveFolder,...
	'label1', label1, 'label2', label2, 'tableExt', tableExt);



figFolder = 'D:\guoda\Documents\Workspace\manuscript\Paper\VIIO\FIGURES\Figures_In_Progress';
saveFolder = 'D:\guoda\Documents\Workspace\manuscript\Paper\VIIO\FIGURES\Figures_In_Progress';
label1 = "exclude-ogEx-neurons"; % String array
label2 = "Keep-ogEx-neurons";    % String array
figExt = 'jpg';
textExt = 'tex';
keywordFig = '';
ignoreKeywordFig = 'bar stat';
keywordText = '';
ignoreKeywordText = '';

compareAnalysisUsingdiffSetting(figFolder, saveFolder,...
	'label1', label1, 'label2', label2, 'figExt', figExt, 'textExt', tableExt,...
	'keywordFig', keywordFig, 'ignoreKeywordFig', ignoreKeywordFig,...
	'keywordText', keywordText, 'ignoreKeywordText', ignoreKeywordText);



%% ==========

findFunctionCalls('D:\guoda\Documents\MATLAB\Codes', 'plotNeuronEdgesAndTraces');



%% ==========
% 9.5.4.1 Plot the event probability
% Create grouped_event_info with the following settings and filter it
% [9.3] eventProp_all: entry is 'roi'. mgSetting.groupField = {'stim_name'};
% If save, save to the existing save_dir
close all
save_fig = false; % true/false
eventPb_bar = fig_canvas(1,'fig_name','event probability','unit_width',0.6,'unit_height',0.3)
;eventPb_plot_info = empty_content_struct({'group','plotinfo'},numel(roiStructForPlot));
[eventPb_plot_info.group] = roiStructForPlot.group;
tlo_eventPb_bar = tiledlayout(eventPb_bar,ceil(numel(roiStructForPlot)/4),4);
for gn = 1:numel(roiStructForPlot)
	group_name = roiStructForPlot(gn).group;
	eventPbInfo = roiStructForPlot(gn).eventPb;
	eventCats = (eventPbInfo.eventCat);
	eventPbCell = eventPbInfo{:,'eventPb_val'};
	ax_eventPb_bar = nexttile(tlo_eventPb_bar);
	[eventPb_plot_info(gn).plotinfo] = barplot_with_stat(eventPbCell,'group_names',eventCats,...
		'plotWhere',ax_eventPb_bar,'title_str',group_name,'save_fig',save_fig,'save_dir',save_dir);
end


%% ====================
% 6.6 Add the location tag (subnuclei information) to ROIs
overwrite = true; %options: true/false
recIDX = 23;
recdata_organized(recIDX,:) = addRoiLocTag2recdata(recdata_organized(recIDX,:),'overwrite',overwrite);



%% ==========
% temproal solution: plot fov percentage and save
% fov_bar = figure('Name','FOV percentage');
fov_bar = fig_canvas(1,'fig_name','FOV percentage','unit_width',0.6,'unit_height',0.3);
% eventPb_bar = figure('Name','event probability','Position',[0.1 0.1 0.4 0.2],'Units','Normalized');

fovID_plot_info = empty_content_struct({'group','fovCount'},numel(roiStructForPlot));
[fovID_plot_info.group] = roiStructForPlot.group;
[fovID_plot_info.fovCount] = roiStructForPlot.fovCount;
tlo_fov_bar = tiledlayout(fov_bar,ceil(numel(roiStructForPlot)/4),4);
for gn = 1:numel(roiStructForPlot)
	group_name = roiStructForPlot(gn).group;
	fovInfo = roiStructForPlot(gn).fovCount;
	fovIDs = {fovInfo.fovID};
	fovPerc = [fovInfo.perc];
	ax_fov_bar = nexttile(tlo_fov_bar);
	bar(categorical(fovIDs),fovPerc);
	set(gca, 'box', 'off')
	title(group_name);
	if save_dir
		savePlot(fov_bar,'save_dir',save_dir,'fname','fovID_perc');
	end
	% [eventPb_plot_info(gn).plotinfo] = barplot_with_stat(fovPerc,'group_names',fovIDs,...
	% 	'plotWhere',ax_fov_bar,'title_str',group_name,'save_fig',save_fig,'save_dir',save_dir);
end


%% ====================
stimName = recdataAP(:,3);
apTF = strcmpi(stimName, 'ap-0.1s');
recdataAP = recdataAP(find(apTF), :);

props = {'FWHM','peak_delta_norm_hpstd','rise_duration','peak_delay'}; 
mmModel = 'GLMM'; 
mmDistribution = 'gamma'; % For continuous, positively skewed data
mmLink = 'log'; % For continuous, positively skewed data

organizeStruct(1).title = 'AP-TRIG subN';
organizeStruct(1).keepGroups = {'trig [ap-0.1s]'};
organizeStruct(1).mmFixCat = 'subNuclei';
[saveDir, eventPropDataStat] = plotEventPropMultiGroups(eventStructForPlot,props,organizeStruct,...
	'mmModel', mmModel, 'mmHierarchicalVars', mmHierarchicalVars, 'mmDistribution', mmDistribution, 'mmLink', mmLink,...
	'saveFig', saveFig, 'saveDir', FolderPathVA.fig);


%% ====================
% Discard the OGex neurons
ogStimTags = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % {'og-5s','ap-0.1s','og-5s ap-0.1s'}. compare the alignedData.stim_name with these strings and decide what filter to use
ogStimEffects = {[0 nan nan nan], [nan nan nan nan], [0 nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG

[alignedDataOGexExcluded,tfIdxWithSubNucleiInfo,roiNumAll,roiNumKep,roiNumDis] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData_allTrials,...
    'stim_names',ogStimTags,'filters',ogStimEffects);

%% ====================
% Plot the FOV with ROIs and traces for all the recordings
saveFig = true;
saveDir = FolderPathVA.fig;
plotNeuronEdgesAndTraces(alignedData_allTrials, 'saveFig', saveFig, 'saveDir', saveDir);


%% ====================
saveToFile = true;

folderPath = 'D:\guoda\Documents\Workspace\Analysis\nVoke_ventral_approach\VIIO_paper_figure\VIIO_eventProp\VIIO_eventProp_variousCat';
filePairs = findAllTexFilePairs(folderPath);

combinedFileName = 'D:\guoda\Documents\Workspace\Analysis\nVoke_ventral_approach\VIIO_paper_figure\VIIO_eventProp\combineLatexTab.tex';

file1 = 'D:\guoda\Documents\Workspace\Analysis\nVoke_ventral_approach\VIIO_paper_figure\VIIO_eventProp\VIIO_eventProp_variousCat\AP-TRIG subN peak_delta_norm_hpstd meanSemTab.tex';
file2 = 'D:\guoda\Documents\Workspace\Analysis\nVoke_ventral_approach\VIIO_paper_figure\VIIO_eventProp\VIIO_eventProp_variousCat\AP-TRIG subN nNumInfo.tex';

[combinedTable, combinedCaption] = combineLatexTables(file1, file2, 'saveToFile', saveToFile,'combinedFileName', combinedFileName);


%% ====================
stimNames = {alignedData.stim_name};
stimTF = strcmpi(stimNames, 'og-5s');

%% ====================
baselineDataCell = {barStat.PO(1).data(1:8).groupData}';
baselineData = vertcat(baselineDataCell{:});
baselineDataCombine = mean(baselineData);

OGearlyDataCell = {barStat.PO(1).data(12).groupData}';
OGearlyData = vertcat(OGearlyDataCell{:});
% OGearlyDataCombine = mean(OGearlyData);

barplot_with_errBar({baselineDataCombine, OGearlyData}, 'barNames', {'baseline', 'OGearly'});

[h, p, ci, stats] = ttest(baselineDataCombine, OGearlyData);



%% ====================
% Example data vectors (replace these with your actual data)
baseline = barStat.PO(1).data(1).groupData; % Data points for the first bar (e.g., 'baseline')
lateFirstStim1 = barStat.PO(1).data(4).groupData; % Data points for the second bar (e.g., 'firstStim')

% Perform the Sign Test
[p, h] = signtest(baseline, lateFirstStim1);

% Display results
fprintf('p-value: %.4f\n', p);
fprintf('Hypothesis Test Result (h): %d\n', h); % h = 1 indicates rejection of the null hypothesis


%% ====================
folderPath = 'D:\guoda\Documents\Workspace\Analysis\nVoke_ventral_approach\VIIO_paper_figure\VIIO_eventProp\VIIO_eventProp_variousCat';
function pairedFiles = findFilePairs(folderPath)
    % List all files in the directory
    files = dir(fullfile(folderPath, '*.tex'));  % Assuming the files are .tex
    fileList = {files.name};

    % Containers for results
    meanSemTabFiles = {};
    modelCompTabFiles = {};

    % Search for specific files
    for i = 1:length(fileList)
        fileName = fileList{i};
        if contains(fileName, 'peak_delta_norm_hpstd meanSemTab nNumInfo')
            meanSemTabFiles{end+1} = fileName;
        elseif contains(fileName, 'peak_delta_norm_hpstd modelCompTab')
            modelCompTabFiles{end+1} = fileName;
        end
    end

    % Find pairs
    pairedFiles = {};
    for i = 1:length(meanSemTabFiles)
        prefix = extractBefore(meanSemTabFiles{i}, 'peak_delta_norm_hpstd');
        % Find matching modelCompTab file
        match = modelCompTabFiles(contains(modelCompTabFiles, [prefix 'peak_delta_norm_hpstd modelCompTab']));
        if ~isempty(match)
            pairedFiles{end+1} = {meanSemTabFiles{i}, match{1}};  % Store the pair
        end
    end
end

%% ====================
folderPath = 'D:\guoda\Documents\Workspace\Analysis\nVoke_ventral_approach\VIIO_paper_figure\VIIO_eventProp\test';
file1Keyword = 'meanSemTab nNumInfo';
file2Keyword = 'modelCompTab';
addPval2StatSummaryLatexTab(folderPath, file1Keyword, file2Keyword, 'normalizedAmp ');

%% ==========
close all
folder = '/flash/UusisaariU/GD/data_VIIO_example';
select_with_UI = false;
plot_contour = true;
plot_roi_traces = true;
creat_video = true;

cnmfe_gen_plot_video_grey_cluster('folder', folder,'select_with_UI', select_with_UI,...
	'plot_contour', plot_contour, 'plot_roi_traces', plot_roi_traces, 'creat_video', creat_video);


%% ==========
DAOogEX = eventStruct.noSyncTag(8);
trialName = {DAOogEX.event_info.trialName};
roiName = {DAOogEX.event_info.roiName};

trialNameShort = cellfun(@(x) x(1:15), trialName, 'UniformOutput',false);
trialRoiName = strcat(trialNameShort, {'-'}, roiName);
DAOogEX_neuronNum = numel(unique(trialRoiName))

POogEX = eventStruct.noSyncTag(9);
trialName = {POogEX.event_info.trialName};
roiName = {POogEX.event_info.roiName};

trialNameShort = cellfun(@(x) x(1:15), trialName, 'UniformOutput',false);
trialRoiName = strcat(trialNameShort, {'-'}, roiName);
POogEX_neuronNum = numel(unique(trialRoiName))


%% ====================
% 9.5.4.1 Plot the event probability
% Create grouped_event_info with the following settings and filter it
% [9.3] eventProp_all: entry is 'roi'. mgSetting.groupField = {'stim_name'};
% If save, save to the existing save_dir
close all
save_fig = false; % true/false
fieldnameGroup = 'peak_category';
fieldnameVal = 'stimEvent_possi';
eventPb_bar = fig_canvas(1,'fig_name','event probability','unit_width',0.6,'unit_height',0.3);
eventPb_plot_info = empty_content_struct({'group','plotInfo'},numel(roiStructForEventProb));
[eventPb_plot_info.group] = roiStructForEventProb.group;
tlo_eventPb_bar = tiledlayout(eventPb_bar,ceil(numel(roiStructForEventProb)/4),4);
for gn = 1:numel(roiStructForEventProb)
	ax_eventPb_bar = nexttile(tlo_eventPb_bar);
	[eventPb_plot_info(gn).plotInfo] = boxPlotOfStructData(roiStructForEventProb(gn).event_info,...
	 fieldnameVal, fieldnameGroup,'plotWhere', gca, 'titleStr', fieldnameVal, 'TickAngle', 45, 'FaceColor', '#FF5733');
end



%% ====================
