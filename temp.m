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