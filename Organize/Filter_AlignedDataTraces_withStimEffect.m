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

    SE_name = 'stimEffect'; % default name of the stimEffect field

    % Optionals for inputs
    for ii = 1:2:(nargin-2)
        if strcmpi('ex', varargin{ii}) 
            ex = varargin{ii+1}; % excitation filter.  
        elseif strcmpi('in', varargin{ii}) 
            in = varargin{ii+1}; % inhibition filter.
        elseif strcmpi('rb', varargin{ii}) 
            rb = varargin{ii+1}; % rebound filter. 
        end
    end


    roi_num = numel(alignedDataTraces);
    tf_idx = logical(ones(1,roi_num));

    stimEffect_all = {alignedDataTraces.(SE_name)};
    for rn = 1:roi_num
        stimEffect = stimEffect_all{rn};
        ex_tf = true;
        in_tf = true;
        rb_tf = true;

        if ~isnan(ex) && stimEffect.excitation ~= ex
            ex_tf = false;
        end

        if ~isnan(in) && stimEffect.inhibition ~= in
            in_tf = false;
        end

        if ~isnan(rb) && stimEffect.rebound ~= rb
            rb_tf = false;
        end

        if ~ex_tf || ~in_tf || ~rb_tf
            tf_idx(rn) = false;
        end
    end

    alignedDataTraces_filtered = alignedDataTraces(tf_idx);
    varargout{1} = find(tf_idx);
end

