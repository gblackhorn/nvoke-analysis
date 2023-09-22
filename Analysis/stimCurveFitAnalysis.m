function [statInfo,varargout] = stimCurveFitAnalysis(alignedData,varargin)
    % Conclude the the data of stimulation caused curve fit
    %   - How many neurons with/without fitted curve
    %   - Percentage of fitted curve: number of fitted curve/number of stimualtion
    %   - Calculate the event frequency before the stimulation. Separate the trials with and without fitted curves

    % default
    filter_roi_tf = false; % true/false. If true, screen ROIs using stim_names and stimulation effects (filters)
    stim_names = {'og-5s','og-5s ap-0.1s'}; % compare the alignedData.stim_name with these strings and decide what filter to use
    filters = {[0 nan nan nan], [0 nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG


    % Optionals
    for ii = 1:2:(nargin-1)
        if strcmpi('filter_roi_tf', varargin{ii})
            filter_roi_tf = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('stimName', varargin{ii})
            stim_names = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('filters', varargin{ii})
            filters = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        % elseif strcmpi('titleStr', varargin{ii})
        %     titleStr = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        % % elseif strcmpi('normToFirst', varargin{ii})
        % %     normToFirst = varargin{ii+1};
        % elseif strcmpi('save_fig', varargin{ii})
        %     save_fig = varargin{ii+1};
        % elseif strcmpi('save_dir', varargin{ii})
        %     save_dir = varargin{ii+1};
        % elseif strcmpi('gui_save', varargin{ii})
        %     gui_save = varargin{ii+1};
        end
    end 

    % filter the trials and ROIs
    if filter_roi_tf    
        [alignedData] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData,...
                    'stim_names',stim_names,'filters',filters);
    end



end


