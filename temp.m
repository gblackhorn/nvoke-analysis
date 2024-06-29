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