function [alignedDataTraces_filtered,varargout] = Filter_AlignedDataTraces_withStimEffect(alignedDataTraces,varargin)
    % Filter the alignedData_allTrials(x).traces with its field "stimEffect"

    % field 'stimEffect' contains 3 fields, excitation, inhibition and rebound. Their values are
    % either 1 or 0


    % [alignedDataTraces_filtered,idx] = Filter_AlignedDataTraces_withStimEffect(alignedDataTraces,'ex',true,'in',false,'rb',false)
    % 'alignedDataTraces' is a struct var. It is a field of variable alignedData_allTrials. It contains
    % informations for each roi in a single trial. In this example, the filter will only keep the rois
    % in which stimulation show excitatory effect. alignedDataTraces_filtered is the filtered data.
    % idx is the locations of alignedDataTraces_filtered in alignedDataTraces.

    % Defaults
    ex = nan; % excitation filter. if is nan, filter won't be applied
    in = nan; % inhibition filter. if is nan, filter won't be applied
    rb = nan; % rebound filter. if is nan, filter won't be applied
    exApOg = nan; % excitatory AP during OG . If is nan, filter won't be applied

    SE_name = 'stimEffect'; % default name of the stimEffect field

    % Optionals for inputs
    for ii = 1:2:(nargin-1)
        if strcmpi('ex', varargin{ii}) 
            ex = varargin{ii+1}; % excitation filter.  
        elseif strcmpi('in', varargin{ii}) 
            in = varargin{ii+1}; % inhibition filter.
        elseif strcmpi('rb', varargin{ii}) 
            rb = varargin{ii+1}; % rebound filter. 
        elseif strcmpi('exApOg', varargin{ii}) 
            exApOg = varargin{ii+1}; % rebound filter. 
        end
    end


    roi_num = numel(alignedDataTraces);
    tf_idx = logical(ones(1,roi_num)); % default: keep all ROIs
    tfStruct = empty_content_struct({'subNuclei', 'tf'}, roi_num);

    stimEffect_all = {alignedDataTraces.(SE_name)};
    for rn = 1:roi_num
        stimEffect = stimEffect_all{rn};
        ex_tf = true; % default: do not discard
        in_tf = true; % default: do not discard
        rb_tf = true; % default: do not discard  
        exApOg_tf = true; % default: do not discard                                                                 

        if ~isnan(ex) && stimEffect.excitation ~= ex % use 'ex' filter && the stim effect is different from the 'ex' filter
            ex_tf = false; % mark discard
        end

        if ~isnan(in) && stimEffect.inhibition ~= in % use 'in' filter && the stim effect is different from the 'in' filter
            in_tf = false; % mark discard
        end

        if ~isnan(rb) && stimEffect.rebound ~= rb % use 'rb' filter && the stim effect is different from the 'rb' filter
            rb_tf = false; % mark discard
        end

        if ~isnan(exApOg) && stimEffect.exAP_eventCat ~= exApOg % use 'exApOg' filter && the stim effect is different from the 'exApOg' filter
            exApOg_tf = false; % mark discard
        end

        if ~ex_tf || ~in_tf || ~rb_tf || ~exApOg_tf % if the ROI receives "discard" tag for at least once
            tf_idx(rn) = false; % mark the ROI with 'discard'
        end

        % Fill the info into the tfStruct
        tfStruct(rn).subNuclei = alignedDataTraces(rn).subNuclei;
        tfStruct(rn).tf = tf_idx(rn);
    end

    alignedDataTraces_filtered = alignedDataTraces(tf_idx); % using the logical array tf_idx to filter ROIs
    varargout{1} = find(tf_idx); % the locations of ROIs in the original 
    varargout{2} = tfStruct; % a structure including the subnuclei and tf (1: kept. 2: discarded)
    varargout{3} = sprintf('%d/%d ROIs are kept (filter: ex-%d, in-%d, rb-%d)',...
        length(varargout{1}),roi_num,ex,in,rb);
end

