function [recdata_organized, varargout] = select_grouped_data(recdata_group, varargin)
    % Select a group of data using the same type of stimulation from recdata_group
    % 



    stim_types = fieldnames(recdata_group);

    stim_num =numel(stim_types);
    list_str = cell(stim_num, 1);
    for n = 1:stim_num
        list_str_cell{n} = sprintf(' (%d) %s\n', n, stim_types{n}); 
    end

    list_str = [list_str_cell{:}];
    question = 'Choose a group of data for following steps: ';
    prompt = sprintf('%s%s', list_str, question);


    data_group = input(prompt);

    if data_group >= 1 && data_group <= stim_num
        recdata_organized = recdata_group.(stim_types{data_group});
    else
        disp('Illegal input. Data not chosen.')
        return
    end

end