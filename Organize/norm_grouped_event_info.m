function [new_grouped_event_info,varargout] = norm_grouped_event_info(grouped_event_info,ref_group,varargin)
    % normalize the spike/event properties in grouped_event_info with values from specified group

    % grouped_event_info: a structure variable with multiple entries.
    %       - fields: group (char), event_info (structure)
    % ref_group: char (name of the group) or integer (index of the group)

    
    % % Defaults
    % ref_group = 1;
    par = {'rise_duration','peak_mag_delta'}; % fields will be normalized in grouped_event_info.event_info
    norm_par_suffix = 'refNorm'; % added to the end of names of new fields containing the normalized pars

    for ii = 1:2:(nargin-2)
        if strcmpi('par', varargin{ii})
            par = varargin{ii+1};
        elseif strcmpi('norm_par_suffix', varargin{ii})
            norm_par_suffix = varargin{ii+1};
        end
    end

    %% main contents
    % convert ref_group to index if it is a 'char'
    if isa(ref_group,'char')
        idx = find(strcmpi(ref_group,{grouped_event_info.group}));
        if ~isempty(idx)
            ref_group = idx;        
        else
            error_msg = sprintf('Func [norm_grouped_event_info]\n ref_group (%s) not found in group field\n',ref_group); 
            error(error_msg)
        end
    end

    ref_group_data = grouped_event_info(ref_group);
    new_grouped_event_info = grouped_event_info;
    if ~isempty(ref_group_data.event_info)
        par_num = numel(par);
        norm_par = cell(1, par_num);
        par_ref_mean = NaN(1, par_num);
        for pn = 1:par_num
            par_ref_mean(pn) = mean([ref_group_data.event_info.(par{pn})]);
            norm_par{pn} = sprintf('%s_%s', par{pn}, norm_par_suffix);
        end

        group_num = numel(grouped_event_info);
        for gn = 1:group_num
            group_data = grouped_event_info(gn).event_info; 
            if ~isempty(group_data)
                for pn = 1:par_num
                    norm_par_data = {group_data.(par{pn})};
                    norm_par_data = cellfun(@(x) x/par_ref_mean(pn), norm_par_data, 'UniformOutput',false);
                    [group_data.(norm_par{pn})] = norm_par_data{:};
                end
                new_grouped_event_info(gn).event_info = group_data;
            end
        end
    end
end

