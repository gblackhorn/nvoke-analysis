function [varargout] = summarizeExOgEffect(alignedData, varargin)
    % Summarize the excitatory effect of OG 5s 

    % Use the alignedData struct var
    %


        % Settings
    adata.event_type = 'detected_events'; % options: 'detected_events', 'stimWin'
    adata.eventTimeType = 'peak_time'; % rise_time/peak_time. Pick one for event time
    adata.traceData_type = 'lowpass'; % options: 'lowpass', 'raw', 'smoothed'
    adata.event_data_group = 'peak_lowpass';
    adata.event_filter = 'none'; % options are: 'none', 'timeWin', 'event_cat'(cat_keywords is needed)
    adata.event_align_point = 'rise'; % options: 'rise', 'peak'
    adata.rebound_duration = 2; % time duration after stimulation to form a window for rebound spikes. Exclude these events from 'spon'
    adata.cat_keywords ={}; % options: {}, {'noStim', 'beforeStim', 'interval', 'trigger', 'delay', 'rebound'}
    %                   find a way to combine categories, such as 'nostim' and 'nostimfar'
    adata.pre_event_time = 5; % unit: s. duration before stimulation in the aligned traces
    adata.post_event_time = 10; % unit: s. duration after stimulation in the aligned traces
    adata.stim_section = true; % true: use a specific section of stimulation to calculate the calcium level delta. For example the last 1s
    adata.ss_range = 1; % range of stim_section (compare the cal-level in baseline and here to examine the effect of the stimulation). single number (last n second during stimulation) or a 2-element array (start and end. 0s is stimulation onset)
    adata.stim_time_error = 0.05; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
    adata.mod_pcn = true; % true/false modify the peak category names with func [mod_cat_name]
    % filter_alignedData = true; % true/false. Discard ROIs/neurons in alignedData if they don't have certain event types
    adata.caDeclineOnly = false; % true/false. Only keep the calcium decline trials (og group)
    adata.disROI = true; % true/false. If true, Keep ROIs using the setting below, and delete the rest
    adata.disROI_setting.stims = {'AP_GPIO-1-1s', 'OG-LED-5s', 'OG-LED-5s AP_GPIO-1-1s'};
    adata.disROI_setting.eventCats = {{'spon'}, {'spon'}, {'spon'}};
    adata.sponfreqFilter.status = true; % true/false. If true, use the following settings to filter ROIs
    adata.sponfreqFilter.field = 'sponfq'; % 
    adata.sponfreqFilter.thresh = 0.05; % Hz. default 0.05
    adata.sponfreqFilter.direction = 'high';
    debug_mode = false; % true/false



    % Get and group (gg) Settings
    ggSetting.entry = 'event'; % options: 'roi' or 'event'. The entry type in eventProp
                    % 'roi': events from a ROI are stored in a length-1 struct. mean values were calculated. 
                    % 'event': events are seperated (struct length = events_num). mean values were not calculated
    ggSetting.modify_stim_name = true; % true/false. Change the stimulation name, 
    ggSetting.sponOnly = false; % true/false. If eventType is 'roi', and ggSetting.sponOnly is true. Only keep spon entries
    ggSetting.seperate_spon = false; % true/false. Whether to seperated spon according to stimualtion
    ggSetting.dis_spon = false; % true/false. Discard spontaneous events
    ggSetting.modify_eventType_name = true; % Modify event type using function [mod_cat_name]
    ggSetting.groupField = {'peak_category','subNuclei'}; % options: 'fovID', 'stim_name', 'peak_category'; Field of eventProp_all used to group events 
    ggSetting.mark_EXog = false; % true/false. if true, rename the og to EXog if the value of field 'stimTrig' is 1
    ggSetting.og_tag = {'og', 'og&ap'}; % find og events with these strings. 'og' to 'Exog', 'og&ap' to 'EXog&ap'
    ggSetting.sort_order = {'spon', 'trig', 'rebound', 'delay'}; % 'spon', 'trig', 'rebound', 'delay'
    ggSetting.sort_order_plus = {'ap', 'EXopto'};
    debug_mode = false; % true/false


    % Initialize input parser
    p = inputParser;

    % Define required inputs
    addRequired(p, 'alignedData', @isstruct);

    % Add optional parameters to the parser with default values and comments
    addParameter(p, 'save_fig', false, @islogical); 
    addParameter(p, 'save_dir', '', @ischar); 
    addParameter(p, 'stat', true, @islogical); 
    addParameter(p, 'plot_combined_data', false, @islogical); 
    addParameter(p, 'parNames', {'FWHM','sponNorm_peak_mag_delta','peak_delta_norm_hpstd','peak_mag_delta'}, @iscell); % Names of paremeters to be plotted
    % addParameter(p, 'filters', {[nan nan nan nan], [nan nan nan nan], [nan nan nan nan]}, @iscell); % Filters for different stimulations
    addParameter(p, 'mmModel', 'GLMM', @ischar); % LMM/GLMM. Setup parameters for linear-mixed-model (LMM) or generalized-mixed-model (GLMM) analysis
    addParameter(p, 'mmGroup', 'subNuclei', @ischar); % 
    addParameter(p, 'mmHierarchicalVars', {'trialName', 'roiName'}, @iscell); % 
    addParameter(p, 'mmDistribution', 'gamma', @ischar); % 
    addParameter(p, 'mmLink', 'log', @ischar); % 
    addParameter(p, 'adata', adata, @isstruct); % 
    addParameter(p, 'ggSetting', ggSetting, @isstruct); % 

    % Parse the inputs
    parse(p, alignedData, varargin{:});

    % Assign parsed values to variables
    alignedData = p.Results.alignedData;
    save_fig = p.Results.save_fig;
    save_dir = p.Results.save_dir;
    stat = p.Results.stat;
    plot_combined_data = p.Results.plot_combined_data;
    parNames = p.Results.parNames;
    mmModel = p.Results.mmModel;
    mmGroup = p.Results.mmGroup;
    mmHierarchicalVars = p.Results.mmHierarchicalVars;
    mmDistribution = p.Results.mmDistribution;
    mmLink = p.Results.mmLink;
    adata = p.Results.adata;
    ggSetting = p.Results.ggSetting;



    % Screen the alignedData and only keep the 'og-5s' recordings
    alignedDataOG = alignedData(strcmp({alignedData.stim_name}, 'og-5s') | strcmp({alignedData.stim_name}, 'og-5s ap-0.1s'));


    % Create grouped_event for plotting ROI properties
    ggSetting.entry = 'event'; % options: 'roi' or 'event'. The entry type in eventProp
    [eventStructForPlot] = getAndGroup_eventsProp(alignedDataOG,...
        'entry',ggSetting.entry,'modify_stim_name',ggSetting.modify_stim_name,...
        'ggSetting',ggSetting,'adata',adata,'debug_mode',debug_mode);


    % Get the entries of group 'spon-DAO' and 'spon-PO'. They will be used to count the total recording and neuron number
    eventStructSponDAO = eventStructForPlot(strcmpi({eventStructForPlot.group}, 'spon-DAO'));
    eventStructSponPO = eventStructForPlot(strcmpi({eventStructForPlot.group}, 'spon-PO'));

    % Get the total recording and neuron number
    recNumAllDAO = eventStructSponDAO.recNum;
    recNumAllPO = eventStructSponPO.recNum;
    animalNumAllDAO = eventStructSponDAO.animalNum;
    animalNumAllPO = eventStructSponPO.animalNum;
    neuronNumAllDAO = eventStructSponDAO.roiNum;
    neuronNumAllPO = eventStructSponPO.roiNum;

    % Merge og and og-ap groups
    combinedTrigDAO = mergeEventStruct(eventStructForPlot, 'trig [og-5s]-DAO', 'trig [og&ap-5s]-DAO', 'ogEX-DAO');
    combinedTrigPO = mergeEventStruct(eventStructForPlot, 'trig [og-5s]-PO', 'trig [og&ap-5s]-PO', 'ogEX-PO');
    eventStructTrig = [combinedTrigDAO, combinedTrigPO];


    % Get the n number from the og ex groups
    recNumTrigDAO = combinedTrigDAO.recNum;
    recNumTrigPO = combinedTrigPO.recNum;
    animalNumTrigDAO = combinedTrigDAO.animalNum;
    animalNumTrigPO = combinedTrigPO.animalNum;
    neuronNumTrigDAO = combinedTrigDAO.roiNum;
    neuronNumTrigPO = combinedTrigPO.roiNum;


    % Plot ogEX trig event prop
    [save_dir, plot_info] = plot_event_info(eventStructTrig,'entryType',ggSetting.entry,...
        'plot_combined_data', plot_combined_data, 'parNames', parNames, 'stat', stat,...
        'mmModel', mmModel, 'mmGroup', mmGroup, 'mmHierarchicalVars', mmHierarchicalVars,...
        'mmDistribution', mmDistribution, 'mmLink', mmLink,...
        'fname_preffix','event','save_fig', save_fig, 'save_dir', save_dir);

    % Create a UI table displaying the n numberss
    fNum = nNumberTab(eventStructTrig,'event');

    % Bar plot the percentage of neurons showing OG-ex events
    neuronPercOgEx = [neuronNumTrigDAO/neuronNumAllDAO, neuronNumTrigPO/neuronNumAllPO];
    barLabelOgEx = {'DAO', 'PO'};
    fBarPlotOgExPerc = plotPercentages(neuronPercOgEx, barLabelOgEx);

    % Save eventProp plotting data
    if save_fig
        % Save the fNum
        savePlot(fNum,'guiSave', 'off', 'save_dir', save_dir, 'fname', 'event nNumInfo');
        savePlot(fBarPlotOgExPerc,'guiSave', 'off', 'save_dir', save_dir, 'fname', 'ogExNeuronPerc');
        % savePlot(fMM,'guiSave', 'off', 'save_dir', save_dir, 'fname', fMM_name);

        % Save the statistics info
        eventPropStatInfo.eventStructForPlot = eventStructTrig;
        eventPropStatInfo.plot_info = plot_info;
        % dt = datestr(now, 'yyyymmdd');
        save(fullfile(save_dir, 'event propStatInfo'), 'eventPropStatInfo');
    end

end


function CombinedEventStruct = mergeEventStruct(parentEventStruct, group1Name, group2Name, CombinedEventStructName)

    group1Entry = parentEventStruct(strcmpi({parentEventStruct.group}, group1Name));
    group2Entry = parentEventStruct(strcmpi({parentEventStruct.group}, group2Name));

    CombinedEventStruct.group = CombinedEventStructName;
    CombinedEventStruct.event_info = [group1Entry.event_info, group2Entry.event_info];
    CombinedEventStruct.tag = group1Entry.tag;
    CombinedEventStruct.recNum = group1Entry.recNum + group2Entry.recNum;
    CombinedEventStruct.animalNum = group1Entry.animalNum + group2Entry.animalNum;
    CombinedEventStruct.roiNum = group1Entry.roiNum + group2Entry.roiNum;
    CombinedEventStruct.TrialRoiList = [group1Entry.TrialRoiList, group2Entry.TrialRoiList];
end

function f = plotPercentages(percentages, labels)
    % Check inputs
    if length(percentages) ~= length(labels)
        error('The number of percentages must match the number of labels.');
    end

    % Create a bar plot
    f = figure;
    hBar = bar(percentages);

    % Set properties
    hBar.FaceColor = '#4D4D4D';
    hBar.EdgeColor = 'none';

    % Customize the axes
    ax = gca;
    ax.XTickLabel = labels;
    ax.XTickLabelRotation = 45;
    ax.FontSize = 12;
    ax.FontWeight = 'bold';

    % Add labels and title if needed
    xlabel('subnuclei');
    ylabel('Percentage');
    title('Percentage neurons showing OG-ex events');

    % Turn off the grid
    grid off;
end

