function [varargout] = summarizeExOgEffect(alignedData, varargin)
    % Summarize the excitatory effect of OG 5s 

    % Initialize settings for creating aligned data
    adata = initializeAdata();

    % Initialize settings for collecting events
    ggSetting = initializeGgSetting();

    % Initialize settings for creating mean OG-trig events
    at = initializeAtSettings();

    % Initialize input parser
    p = inputParser;

    % Define required inputs
    addRequired(p, 'alignedData', @isstruct);

    % Add optional parameters to the parser with default values and comments
    addParameter(p, 'save_fig', false, @islogical); 
    addParameter(p, 'save_dir', '', @ischar); 
    addParameter(p, 'stat', true, @islogical); 
    addParameter(p, 'plot_combined_data', false, @islogical); 
    addParameter(p, 'parNames', {'FWHM','sponNorm_peak_mag_delta','peak_delta_norm_hpstd'}, @iscell); % Names of parameters to be plotted
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

    % Debug mode setting
    debug_mode = false; % true/false

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

    % Merge the og-trig events from og and og-ap groups
    combinedTrigDAO = mergeEventStruct(eventStructForPlot, 'trig [og-5s]-DAO', 'trig [og&ap-5s]-DAO', 'ogEX-DAO');
    combinedTrigPO = mergeEventStruct(eventStructForPlot, 'trig [og-5s]-PO', 'trig [og&ap-5s]-PO', 'ogEX-PO');
    eventStructSponAndTrig = [eventStructSponDAO, eventStructSponPO, combinedTrigDAO, combinedTrigPO];
    eventStructTrig = [combinedTrigDAO, combinedTrigPO];


    % Merge the offStim events from og and og-ap groups
    combinedOffStimDAO = mergeEventStruct(eventStructForPlot, 'rebound [og-5s]-DAO', 'rebound [og&ap-5s]-DAO', 'ogOffStim-DAO');
    combinedOffStimPO = mergeEventStruct(eventStructForPlot, 'rebound [og-5s]-PO', 'rebound [og&ap-5s]-PO', 'ogOffStim-PO');
    eventStructSponAndOffStim = [eventStructSponDAO, eventStructSponPO, combinedOffStimDAO, combinedOffStimPO];
    eventStructOffStim = [combinedOffStimDAO, combinedOffStimPO];



    % Get the n number from the ogTrig and offStim groups  
    recNumTrigDAO = combinedTrigDAO.recNum;
    recNumTrigPO = combinedTrigPO.recNum;
    animalNumTrigDAO = combinedTrigDAO.animalNum;
    animalNumTrigPO = combinedTrigPO.animalNum;
    neuronNumTrigDAO = combinedTrigDAO.roiNum;
    neuronNumTrigPO = combinedTrigPO.roiNum;
    recNumOffStimDAO = combinedOffStimDAO.recNum;
    recNumOffStimPO = combinedOffStimPO.recNum;
    animalNumOffStimDAO = combinedOffStimDAO.animalNum;
    animalNumOffStimPO = combinedOffStimPO.animalNum;
    neuronNumOffStimDAO = combinedOffStimDAO.roiNum;
    neuronNumOffStimPO = combinedOffStimPO.roiNum;




    % Plot event prop for ogEX trig and spon 
    [save_dir, plotInfoSponAndTrig] = plot_event_info(eventStructSponAndTrig,'entryType',ggSetting.entry,...
        'plot_combined_data', plot_combined_data, 'parNames', parNames, 'stat', stat,...
        'mmModel', mmModel, 'mmGroup', mmGroup, 'mmHierarchicalVars', mmHierarchicalVars,...
        'mmDistribution', mmDistribution, 'mmLink', mmLink,...
        'fname_preffix','sponAndTrigEvent','save_fig', save_fig, 'save_dir', save_dir);
    if save_fig
        close all
    end


    % Plot ogEX trig delay
    [save_dir, plotInfoTrig] = plot_event_info(eventStructTrig,'entryType',ggSetting.entry,...
        'plot_combined_data', plot_combined_data, 'parNames', [parNames, 'peak_delay'], 'stat', stat,...
        'mmModel', mmModel, 'mmGroup', mmGroup, 'mmHierarchicalVars', mmHierarchicalVars,...
        'mmDistribution', mmDistribution, 'mmLink', mmLink,...
        'fname_preffix','trigEvent','save_fig', save_fig, 'save_dir', save_dir);
    if save_fig
        close all
    end

    % % Create a UI table displaying the n numberss
    % fNumTrig = nNumberTab(eventStructTrig,'event');


    % Plot event prop for spon and offStim events
    [save_dir, plotInfoSponAndOffStim] = plot_event_info(eventStructSponAndOffStim,'entryType',ggSetting.entry,...
        'plot_combined_data', plot_combined_data, 'parNames', parNames, 'stat', stat,...
        'mmModel', mmModel, 'mmGroup', mmGroup, 'mmHierarchicalVars', mmHierarchicalVars,...
        'mmDistribution', mmDistribution, 'mmLink', mmLink,...
        'fname_preffix','sponAndOffStimEvent','save_fig', save_fig, 'save_dir', save_dir);
    if save_fig
        close all
    end


    % Plot ogEX trig event prop
    [save_dir, plotInfoOffStim] = plot_event_info(eventStructOffStim,'entryType',ggSetting.entry,...
        'plot_combined_data', plot_combined_data, 'parNames', [parNames, 'peak_delay'], 'stat', stat,...
        'mmModel', mmModel, 'mmGroup', mmGroup, 'mmHierarchicalVars', mmHierarchicalVars,...
        'mmDistribution', mmDistribution, 'mmLink', mmLink,...
        'fname_preffix','offStimEvent','save_fig', save_fig, 'save_dir', save_dir);
    if save_fig
        close all
    end

    % % Create a UI table displaying the n numberss
    % fNumOffStim = nNumberTab(eventStructOffStim,'event');

    % Create a UI table displaying the n numberss
    fNumSponAndTrig = nNumberTab(eventStructSponAndTrig,'event');

    % Create a UI table displaying the n numberss
    fNumSponAndOffStim = nNumberTab(eventStructSponAndOffStim,'event');



    % Bar plot the percentage of neurons showing OG-ex events
    neuronPercOgEx = [neuronNumTrigDAO/neuronNumAllDAO, neuronNumTrigPO/neuronNumAllPO];
    barLabelOgEx = {'DAO', 'PO'};
    fBarPlotOgExPerc = plotPercentages(neuronPercOgEx, barLabelOgEx);

    % Create a cell to store the trace info
    traceInfo = cell(1,numel(at.subNucleiTypes));


    % Create the mean traces of OG-trig in DAO and PO for examples
    % Loop through the subNucleiTypes
    for i = 1:numel(at.subNucleiTypes)
        [~,traceInfo{i}] = AlignedCatTracesSinglePlot(alignedDataOG,at.stimNames,at.eventCat,...
            'normMethod',at.normMethod,'subNucleiType',at.subNucleiTypes{i},...
            'showRawtraces',at.showRawtraces,'showMedian',at.showMedian,'medianProp',at.medianProp,...
            'plot_combined_data',at.plot_combined_data,'shadeType',at.shadeType,'y_range',at.y_range);
        % 'sponNorm',at.sponNorm,'normalized',at.normalized,
        if save_fig
            save_dir = savePlot(gcf,'guiSave', false, 'save_dir', save_dir, 'fname', traceInfo{i}.fname);
        end
    end
    traceInfo = [traceInfo{:}];



    % Create pie charts showing the percentage of neurons in which ogTrig and offStim are observed
    % Separate DAO and PO
    pieDataTrigDAO = [neuronNumTrigDAO, neuronNumAllDAO-neuronNumTrigDAO];
    pieDataTrigPO = [neuronNumTrigPO, neuronNumAllPO-neuronNumTrigPO];
    pieLabelsTrig = {'OG trig pos', 'OG trig neg'};
    pieDataOffStimDAO = [neuronNumOffStimDAO, neuronNumAllDAO-neuronNumOffStimDAO];
    pieDataOffStimPO = [neuronNumOffStimPO, neuronNumAllPO-neuronNumOffStimPO];
    pieLabelsOffStim = {'OG stimOff pos', 'OG stimOff neg'};
    explodeIDX = [1 0];

    fName_pieTrig = 'trigPosNeuronPerc';
    f_pieTrig = fig_canvas(2, 'fig_name', fName_pieTrig);
    tlo_pieTrig = tiledlayout(f_pieTrig, 1, 2);
    ax_pieTrigDAO = nexttile(tlo_pieTrig);
    pie(ax_pieTrigDAO, pieDataTrigDAO, explodeIDX);
    title('OG trig positive neruons in DAO')
    ax_pieTrigPO = nexttile(tlo_pieTrig);
    pie(ax_pieTrigPO, pieDataTrigPO, explodeIDX);
    title('OG trig positive neruons in PO')
    lgdTrig = legend(pieLabelsTrig);
    lgdTrig.Layout.Tile = 'east';
    sgtitle(fName_pieTrig)

    fName_pieOffStim = 'offStimPosNeuronPerc';
    f_pieOffStim = fig_canvas(2, 'fig_name', fName_pieOffStim);
    tlo_pieOffStim = tiledlayout(f_pieOffStim, 1, 2);
    ax_pieOffStimDAO = nexttile(tlo_pieOffStim);
    pie(ax_pieOffStimDAO, pieDataOffStimDAO, explodeIDX, pieLabelsOffStim);
    title('OG offStim positive neruons in DAO')
    ax_pieOffStimPO = nexttile(tlo_pieOffStim);
    pie(ax_pieOffStimPO, pieDataOffStimPO, explodeIDX, pieLabelsOffStim);
    title('OG offStim positive neruons in PO')
    lgdOffStim = legend(pieLabelsOffStim);
    lgdOffStim.Layout.Tile = 'east';
    sgtitle(fName_pieOffStim)

    if save_fig
        savePlot(f_pieTrig, 'guiSave', false, 'save_dir', save_dir, 'fname', fName_pieTrig);
        savePlot(f_pieOffStim, 'guiSave', false, 'save_dir', save_dir, 'fname', fName_pieOffStim);
    end



    % Save eventProp plotting data
    if save_fig
        % Save the fNum
        savePlot(fNumSponAndTrig,'guiSave', 'off', 'save_dir', save_dir, 'fname', 'sponAndTrig event nNumInfo ');
        % savePlot(fNumTrig,'guiSave', 'off', 'save_dir', save_dir, 'fname', 'event nNumInfo Trig');
        savePlot(fNumSponAndOffStim,'guiSave', 'off', 'save_dir', save_dir, 'fname', 'sponAndOffStim event nNumInfo ');
        % savePlot(fNumOffStim,'guiSave', 'off', 'save_dir', save_dir, 'fname', 'event nNumInfo OffStim');
        savePlot(fBarPlotOgExPerc,'guiSave', 'off', 'save_dir', save_dir, 'fname', 'ogExNeuronPerc');
        % savePlot(fMM,'guiSave', 'off', 'save_dir', save_dir, 'fname', fMM_name);

        % Save the statistics info
        eventPropStatInfo.eventStructForPlot = eventStructTrig;
        eventPropStatInfo.plotInfoSponAndTrig = plotInfoSponAndTrig;
        eventPropStatInfo.plotInfoTrig = plotInfoTrig;
        eventPropStatInfo.plotInfoSponAndOffStim = plotInfoSponAndOffStim;
        eventPropStatInfo.plotInfoOffStim = plotInfoOffStim;
        % dt = datestr(now, 'yyyymmdd');
        save(fullfile(save_dir, 'event propStatInfo'), 'eventPropStatInfo');
    end

end


function adata = initializeAdata()
    % Settings for creating aligned data
    adata.event_type = 'detected_events'; % options: 'detected_events', 'stimWin'
    adata.eventTimeType = 'peak_time'; % options: 'rise_time', 'peak_time'
    adata.traceData_type = 'lowpass'; % options: 'lowpass', 'raw', 'smoothed'
    adata.event_data_group = 'peak_lowpass';
    adata.event_filter = 'none'; % options: 'none', 'timeWin', 'event_cat' (cat_keywords needed)
    adata.event_align_point = 'rise'; % options: 'rise', 'peak'
    adata.rebound_duration = 2; % time duration after stimulation for rebound spikes exclusion
    adata.cat_keywords = {}; % options: {}, {'noStim', 'beforeStim', 'interval', 'trigger', 'delay', 'rebound'}
    adata.pre_event_time = 5; % duration before stimulation in the aligned traces (s)
    adata.post_event_time = 10; % duration after stimulation in the aligned traces (s)
    adata.stim_section = true; % use a specific section of stimulation to calculate the calcium level delta
    adata.ss_range = 1; % range of stim_section
    adata.stim_time_error = 0.05; % start and end time point of stimuli can be extended
    adata.mod_pcn = true; % modify the peak category names with function [mod_cat_name]
    adata.caDeclineOnly = false; % only keep the calcium decline trials (og group)
    adata.disROI = true; % if true, keep ROIs using the setting below, and delete the rest
    adata.disROI_setting.stims = {'AP_GPIO-1-1s', 'OG-LED-5s', 'OG-LED-5s AP_GPIO-1-1s'};
    adata.disROI_setting.eventCats = {{'spon'}, {'spon'}, {'spon'}};
    adata.sponfreqFilter.status = true; % if true, use the following settings to filter ROIs
    adata.sponfreqFilter.field = 'sponfq'; 
    adata.sponfreqFilter.thresh = 0.05; % Hz
    adata.sponfreqFilter.direction = 'high';
end

function ggSetting = initializeGgSetting()
    % Settings for collecting events
    ggSetting.entry = 'event'; % options: 'roi', 'event'
    ggSetting.modify_stim_name = true; % change the stimulation name
    ggSetting.sponOnly = false; % only keep spon entries
    ggSetting.seperate_spon = false; % separate spon according to stimulation
    ggSetting.dis_spon = false; % discard spontaneous events
    ggSetting.modify_eventType_name = true; % modify event type using function [mod_cat_name]
    ggSetting.groupField = {'peak_category','subNuclei'}; % field of eventProp_all used to group events
    ggSetting.mark_EXog = false; % if true, rename the og to EXog if 'stimTrig' is 1
    ggSetting.og_tag = {'og', 'og&ap'}; % find og events with these strings
    ggSetting.sort_order = {'spon', 'trig', 'rebound', 'delay'};
    ggSetting.sort_order_plus = {'ap', 'EXopto'};
end

function at = initializeAtSettings()
    % Settings for creating mean OG-trig events
    at.normMethod = 'highpassStd'; % 'none', 'spon', 'highpassStd'
    at.stimNames = ''; % if empty, do not screen recordings with stimulation
    at.eventCat = 'trig'; % options: 'trig','trig-ap','rebound','spon'
    at.subNucleiTypes = {'DAO','PO'}; % separate ROIs using the subnuclei tag
    at.plot_combined_data = true; % plot mean value and std of all traces
    at.showRawtraces = false; % plot every single trace
    at.showMedian = false; % plot raw traces having a median value of specified properties
    at.medianProp = 'FWHM'; % 
    at.shadeType = 'std'; % plot the shade using std/ste
    at.y_range = [-10 20]; % Y-axis range for plotting
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

