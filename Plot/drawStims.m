function [varargout] = drawStims(trialData, plotWhere)
    % to be used in trace plots,  scatters and histograms of trials
    % plotWhere is the axis where to plot

    trialType = getTrialTypeFromROIdataStruct(trialData);
    frameRate = getFrameRateForTrial(trialData);
    nROIs = getNROIsFromTrialData(trialData);
    axes(plotWhere);
    axp = get(gca);
    ylims = axp.YLim;

    gpio_info = trialData{1, 4};
    stim_num = length(gpio_info)-2; % subtract 'BNC Sync Output' and 'EX-LED' channels which are not used for stimulation
    patchColor = '#4DBEEE';
    patchAlpha = 0.3; % transparency of patch 


    if stim_num > 0 % if stimulation applied
        for i = 1:stim_num
            stim_name = gpio_info(i+2).name; % name of the stimulation channel
            stim_patch_data = gpio_info(i+2).patch_coordinats; % number arrays used for plot "patch" representing stimulation

            if strcmpi('GPIO-1', stim_name)
                patchColor = '#4DBEEE';
            elseif strcmpi('OG-LED', stim_name)
                patchColor = '#ED8564';
            end

            % Locate the min and max value in patch_data, and replace them with yLims
            stim_patch_data_ymin_idx = find(stim_patch_data(:,2)==0);
            stim_patch_data_ymax_idx = find(stim_patch_data(:,2)==1);
            stim_patch_data(stim_patch_data_ymin_idx, 2) = ylims(1);
            stim_patch_data(stim_patch_data_ymax_idx, 2) = ylims(2);

            patch('XData',stim_patch_data(:, 1), 'YData', stim_patch_data(:, 2),...
                'FaceColor', patchColor, 'FaceAlpha', patchAlpha, 'EdgeColor', 'none');
        end
    end
end
