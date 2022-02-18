function [] = plot_stim_patch(timeinfo,stim_ch_patch,varargin)
    % plot stimulation signal as patches
    %   timeinfo: 1-col array
    %   stim_ch_patch: 1 or multiple cell arraies containing nx2 matrix. 1st column contains x coordinate, 2nd column contains y coordinates
    %   varargin: y limitation (1x2 number array [min max])

    % Defaults
    xlim_min = timeinfo(1);
    xlim_max = timeinfo(end);
    ylim_min = 0;
    ylim_max = 1;
    patch_color = {'cyan', 'magenta', 'yellow'};
    patch_EdgeColor = 'none';
    patch_FaceAlpha = 0.3;

    % Optionals
    for ii = 1:2:(nargin-2)
        if strcmpi('xlim', varargin{ii})
            xlim_min = varargin{ii+1}(1);
            xlim_max = varargin{ii+1}(2);
        elseif strcmpi('ylim', varargin{ii})
            ylim_min = varargin{ii+1}(1);
            ylim_max = varargin{ii+1}(2);
        end
    end

    % Main contents
    stim_ch_num = size(stim_ch_patch, 1);
    for sn = 1:stim_ch_num
        idx_stim_on = find(stim_ch_patch{sn}(:, 2) == 1);
        idx_stim_off = find(stim_ch_patch{sn}(:, 2) == 0);

        stim_ch_patch{sn}(idx_stim_on, 2) = ylim_max;
        stim_ch_patch{sn}(idx_stim_off, 2) = ylim_min;

        patch(stim_ch_patch{sn}(:, 1), stim_ch_patch{sn}(:, 2),...
            patch_color{sn}, 'EdgeColor', patch_EdgeColor, 'FaceAlpha', patch_FaceAlpha);
        hold on
    end
    hold off
end

