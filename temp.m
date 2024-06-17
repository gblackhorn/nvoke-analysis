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
cellArray2Index =7 ;
fieldsInCellArray2 = fieldnames(eventProp_all_cell{cellArray2Index});

% Compare the cell arrays using strcmp
comparisonResult = strcmpi(fieldsInFirstRec, fieldsInCellArray2);

% Find the indices of differing elements
differingIndices = find(~comparisonResult);

% Display the differing elements
if isempty(differingIndices)
    disp('The cell arrays contain exactly the same contents.');
else
    disp('The cell arrays do not contain the same contents.');
    disp('Differences found at the following indices:');
    for i = 1:length(differingIndices)
        index = differingIndices(i);
        fprintf('Index %d:\n', index);
        fprintf('  Rec 1: %s\n', fieldsInFirstRec{index});
        fprintf('  Rec %d: %s\n', cellArray2Index, fieldsInCellArray2{index});
    end
end
