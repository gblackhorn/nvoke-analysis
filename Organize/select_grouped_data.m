function [recdata_organized, varargout] = select_grouped_data(recdata_group, varargin)
    % Select a group of data using the same type of stimulation from recdata_group
    % 


    stim_types = {'GPIO-1-1s', 'OG-LED-1s', 'OG-LED-5s', 'OG-LED-5s GPIO-1-1s'};
    prompt = sprintf('(1) %s \n(2) %s \n(3) %s \n(4) %s \n(5) %s \nChoose a group of data for following steps: ',...
        stim_types{1}, stim_types{2}, stim_types{3}, stim_types{4}, 'All');
    data_group = input(prompt, 's');
    switch data_group
        case '1'
            recdata_organized = recdata_group.ap1s;
        case '2'
            recdata_organized = recdata_group.og1s;
        case '3'
            recdata_organized = recdata_group.og5s;
        case '4'
            recdata_organized = recdata_group.og5s_ap1s;
        case '5'
            recdata_organized = recdata_group.all;
        otherwise
            disp('Illegal input. Data not chosen.')
            return
    end
end