function [pttest,varargout] = pairedtest_eventStruct(eventStruct,neuronTags,groupfield,groups,parName,varargin)
    % Group neurons in eventStruct, calculated the mean value for each neuron and make paired ttest

    % eventStruct: a structure variable containing event properties from multiple neurons.
    % neuronTags: char or cell containing the field names used to find neurons
    %           - if cell, and length larger than 1, combine the contents of fields
    % groupfield: name of a field containing group info
    % groups: 2-entry cell array. names of groups used in ttest 
    % parName: char. a field name containing data for ttest

    
    % % Defaults
    % % ref_group = 1;
    % par = {'rise_duration','peak_mag_delta'}; % fields will be normalized in grouped_event_info.event_info
    % norm_par_suffix = 'refNorm'; % added to the end of names of new fields containing the normalized pars

    % for ii = 1:2:(nargin-2)
    %     if strcmpi('par', varargin{ii})
    %         par = varargin{ii+1};
    %     elseif strcmpi('norm_par_suffix', varargin{ii})
    %         norm_par_suffix = varargin{ii+1};
    %     end
    % end

    %% main contents

    % prepare tags to find unique neurons
    entry_num = numel(eventStruct);
    if isa(neuronTags,'cell')
        neuronTags_num = numel(neuronTags);
        tag_cells = cell(entry_num,neuronTags_num);
        for ntn = 1:neuronTags_num
            tag_cells(:,ntn) = {eventStruct.(neuronTags{ntn})};
        end
        tags = cell(entry_num,1);
        for en = 1:entry_num
            tags{en} = [tag_cells{en, 1:end}]; 
        end
    elseif isa(neuronTags,'char')
        tags = {eventStruct.(neuronTags)}';
    end

    unique_tags = unique(tags);
    unique_tags_num = numel(unique_tags);

    test_data_fields = {'neuron','group1','group2',...
    'group1_mean','group2_mean'};
    pttest.par = parName;
    pttest.group1 = groups{1};
    pttest.group2 = groups{2};
    pttest.data = empty_content_struct(test_data_fields,unique_tags_num);

    dis_idx = []; % discard neurons if they don't have data for one or both groups

    for n = 1:unique_tags_num
        pttest.data(n).neuron = unique_tags{n};
        tag_tf = strcmp(tags,unique_tags{n});
        idx = find(tag_tf); % entry index of data belong to a single neuron
        neuronData = eventStruct(idx);

        for gn = 1:numel(groups)
            group_tf = strcmp({neuronData.(groupfield)},groups(gn));
            group_idx = find(group_tf);
            if ~isempty(group_idx)
                group_field = sprintf('group%d',gn);
                pttest.data(n).(group_field) = [neuronData(group_idx).(parName)];
                pttest.data(n).([group_field,'_mean']) = mean(pttest.data(n).(group_field));
            else
                dis_idx = [dis_idx n];
            end
        end 
    end

    pttest.data(unique(dis_idx)) = [];

    group1_mean = [pttest.data.group1_mean];
    group2_mean = [pttest.data.group2_mean];

    [pttest.h,pttest.p,pttest.ci,pttest.stats] = ttest(group1_mean,group2_mean);
end

