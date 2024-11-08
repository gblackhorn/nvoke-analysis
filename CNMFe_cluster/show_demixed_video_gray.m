function avi_filename = show_demixed_video_gray(obj, varargin)

% avi_filename = show_demixed_video_gray(obj, save_avi, kt, frame_range, amp_ac, range_ac, range_Y, multi_factor, use_craw, varargin)

%% Save the final results of source extraction as grayscale intensity video with colored demixed signals.
%% Inputs:
%   kt: scalar, the number of frames to be skipped.
%   save_avi: whether to save the video to an AVI file (default: false).
%   frame_range: range of frames to include in the video.
%   amp_ac: amplitude scaling for activity.
%   range_ac: intensity range for activity signals.
%   range_Y: intensity range for raw data.
%   multi_factor: scaling factor for intensities.
%   use_craw: use raw signal (true) or processed signal (false).

%% Author: Your Name (based on the original by Pengcheng Zhou, Columbia University)

% % Handle input arguments with defaults
% if ~exist('save_avi', 'var') || isempty(save_avi)
%     save_avi = false;
% end
% if ~exist('kt', 'var') || isempty(kt)
%     kt = 1;
% end
% if ~exist('use_craw', 'var') || isempty(use_craw)
%     use_craw = false;
% end

% Create an input parser
p = inputParser;

% Add required and optional parameters
addRequired(p, 'obj');  % Required: CNMF-E object
addOptional(p, 'save_avi', false);  % Optional: whether to save AVI (default: false)
addOptional(p, 'kt', 1);  % Optional: frames to skip (default: 1)
addOptional(p, 'frame_range', obj.frame_range);  % Optional: range of frames (default: obj.frame_range)
addOptional(p, 'amp_ac', []);  % Optional: amplitude scaling (default: empty)
addOptional(p, 'range_ac', []);  % Optional: activity range (default: empty)
addOptional(p, 'range_Y', []);  % Optional: raw data intensity range (default: empty)
addOptional(p, 'multi_factor', []);  % Optional: multiplicative factor (default: empty)
addOptional(p, 'use_craw', false);  % Optional: use raw signal (default: false)
addOptional(p, 'folderPath', '', @(x) ischar(x) || isstring(x));  % Optional: folder path (default: empty string)
addOptional(p, 'avi_filename_prefix', 'Results', @(x) ischar(x) || isstring(x));  % Optional: folder path (default: empty string)

% Parse inputs
parse(p, obj, varargin{:});

% Assign parsed values to variables
save_avi = p.Results.save_avi;
kt = p.Results.kt;
frame_range = p.Results.frame_range;
amp_ac = p.Results.amp_ac;
range_ac = p.Results.range_ac;
range_Y = p.Results.range_Y;
multi_factor = p.Results.multi_factor;
use_craw = p.Results.use_craw;
folderPath = p.Results.folderPath;
avi_filename_prefix = p.Results.avi_filename_prefix;

% Define the AVI filename based on the folder path
avi_filename = fullfile(folderPath, [avi_filename_prefix, '_demixed_gray.avi']);

% Early check for existing AVI file
if exist(avi_filename, 'file')
    warning('AVI file already exists: %s. The file will not be overwritten.', avi_filename);
    return;  % Return the filename and exit the function early
end

if use_craw
    CC = obj.C_raw; 
else
    CC = obj.C;
end

% Load data
if ~exist('frame_range', 'var') || isempty(frame_range)
    frame_range = obj.frame_range;
end
t_begin = frame_range(1);
t_end = frame_range(2);
tmp_range = [t_begin, min(t_begin+100*kt-1, t_end)];

% if isempty(folderPath)
%     Y = obj.load_patch_data([], tmp_range);  % Load raw data
%     Ybg = obj.reconstruct_background(tmp_range);  % Reconstruct background data
% else
%     Y = load_local_patch_data(folderPath);
%     Ybg = reconstruct_background_local(obj, frame_range, folderPath);
% end

Y = load_local_patch_data(folderPath, [], tmp_range);
Ybg = reconstruct_background_local(obj, tmp_range, folderPath);
% Ybg = obj.reconstruct_background(tmp_range);  % Reconstruct background data
figure('position', [0, 0, 1800, 1200]);

% Set amplitude scaling if not provided
if ~exist('amp_ac', 'var') || isempty(amp_ac)
    amp_ac = median(max(obj.A,[],1)'.*max(CC,[],2))*2;
end
if ~exist('range_ac', 'var') || isempty(range_ac)
    range_ac = amp_ac * [0.001, 0.2];  % Narrow range to boost contrast for smaller signals
    % range_ac = amp_ac * [0.01, 1.01];
end
range_res = range_ac - mean(range_ac);  % Calculate residual range

if ~exist('range_Y', 'var') || isempty(range_Y)
    if ~exist('multi_factor', 'var') || isempty(multi_factor)
        temp = quantile(double(Y(randi(numel(Y), 10000,1))), [0.01, 0.98]);
        multi_factor = ceil(diff(temp)/diff(range_ac));
    else
        temp = quantile(Y(randi(numel(Y), 10000,1)), 0.01);
    end
    center_Y = temp(1) + multi_factor * amp_ac / 2;
    range_Y = double(center_Y) + range_res * multi_factor;
end

if save_avi
    avi_file = VideoWriter(avi_filename, 'Uncompressed AVI');
    if ~isnan(obj.Fs)
        avi_file.FrameRate = obj.Fs / kt;
    end
    avi_file.open();
else
    avi_filename = [];
end

% % Create AVI file if needed
% if save_avi
%     avi_filename = [folderPath, 'demixed_gray.avi'];
%     avi_file = VideoWriter(avi_filename, 'Uncompressed AVI');
%     if ~isnan(obj.Fs)
%         avi_file.FrameRate = obj.Fs / kt;
%     end
%     avi_file.open();
% else
%     avi_filename = [];
% end

% Add pseudo color to demixed signals for visualization
[K, ~] = size(CC);  % K is the number of neurons/components
Y_mixed = zeros(obj.options.d1 * obj.options.d2, diff(tmp_range) + 1, 3);  % Preallocate the RGB image data
temp = prism;  % Use the 'prism' colormap for assigning random colors
col = temp(randi(64, K, 1), :);  % Randomly assign colors to each neuron

% Generate the RGB image data for each frame by applying colors to the components
for m = 1:3
    % Convert to double to avoid multiplication errors with integers
    Y_mixed(:, :, m) = obj.A * (diag(double(col(:, m))) * double(CC(:, tmp_range(1):tmp_range(2))));
end
Y_mixed = uint16(Y_mixed * 2 / (amp_ac) * 65536);  % Scale the intensity to 16-bit format

%% Initialize axes for visualizing different components
ax_y = axes('position', [0.015, 0.51, 0.3, 0.42]);
ax_bg = axes('position', [0.015, 0.01, 0.3, 0.42]);
ax_signal = axes('position', [0.345, 0.51, 0.3, 0.42]);
ax_denoised = axes('position', [0.345, 0.01, 0.3, 0.42]);
ax_res = axes('position', [0.675, 0.51, 0.3, 0.42]);
ax_mix = axes('position', [0.675, 0.01, 0.3, 0.42]);

tt0 = (t_begin - 1);  % Initialize starting time

%% Main loop to process and display each frame
for tt = t_begin:kt:t_end
    m = tt - tt0;  % Frame index

    % --- Raw Data (Grayscale) ---
    axes(ax_y); cla;
    imagesc(Y(:, :, m), range_Y);  % Display raw data using grayscale intensity
    colormap(ax_y, gray);  % Force grayscale colormap
    title('Raw data');
    axis equal off tight;

    % --- Background Data (Grayscale) ---
    axes(ax_bg); cla;
    imagesc(Ybg(:, :, m), range_Y);  % Display background using grayscale intensity
    colormap(ax_bg, gray);  % Force grayscale colormap
    title('Background');
    axis equal off tight;

    % --- (Raw - BG) signal (Grayscale) ---
    axes(ax_signal); cla;
    imagesc(double(Y(:, :, m)) - Ybg(:, :, m), range_ac);  % Display residuals (Raw - BG)
    colormap(ax_signal, gray);  % Force grayscale colormap
    title(sprintf('(Raw-BG) X %d', multi_factor));
    axis equal off tight;

    % --- Denoised Data (Grayscale) ---
    axes(ax_denoised); cla;
    img_ac = obj.reshape(obj.A * CC(:, tt), 2);  % Reshape denoised data for display
    imagesc(img_ac, range_ac);  % Display denoised signals using grayscale intensity
    colormap(ax_denoised, gray);  % Force grayscale colormap
    title(sprintf('Denoised X %d', multi_factor));
    axis equal off tight;

    % --- Residuals (Grayscale) ---
    axes(ax_res); cla;
    imagesc(double(Y(:, :, m)) - Ybg(:, :, m) - img_ac, range_res);  % Display residuals (Raw - BG - denoised)
    colormap(ax_res, gray);  % Force grayscale colormap
    title(sprintf('Residual X %d', multi_factor));
    axis equal off tight;

    % % --- Demixed Data (Colorful) ---
    % axes(ax_mix); cla;
    % imagesc(obj.reshape(Y_mixed(:, m, :), 2));  % Display demixed with color
    % title('Demixed (Colored ROIs)');
    % text(1, 10, sprintf('Time: %.2f second', (tt) / obj.Fs), 'color', 'w', 'fontweight', 'bold');
    % axis equal tight off;

    % Capture and save frames to AVI if necessary
    drawnow();
    if save_avi
        temp = getframe(gcf);
        temp = imresize(temp.cdata, [1200, 1800]);  % Resize for consistency
        avi_file.writeVideo(temp);  % Write frame to video
    end

    %% Batch processing for additional frames
    if tt == tt0 + kt * 99 + 1
        tt0 = tt0 + kt * 100;  % Update start frame
        tmp_range = [tt0 + 1, min(tt0 + 100 * kt, t_end)];  % Adjust frame range

        if isempty(tmp_range) || diff(tmp_range) < 1
            break;
        end

        % % Load next batch of raw data and background
        % Y = load_local_patch_data(folderPath, [], tmp_range);
        % Ybg = reconstruct_background_local(obj, tmp_range, folderPath);
        % % Y = obj.load_patch_data([], tmp_range);
        % % Ybg = obj.reconstruct_background(tmp_range);


        % %% Add pseudo-color to denoised signals for the new frames
        % [d1, d2, Tp] = size(Y);  % Get dimensions of the new data
        % Y_mixed = zeros(d1 * d2, Tp, 3);  % Preallocate new Y_mixed for RGB image

        % % Recompute demixed signals with color
        % tmp_C = CC(:, tt0 + (1:Tp));  % Extract neuron activity for the new frame range
        % col = temp(randi(64, K, 1), :);  % Reassign colors to neurons
        % for m = 1:3
        %     Y_mixed(:, :, m) = obj.A * (diag(double(col(:, m))) * double(tmp_C));
        % end
        % Y_mixed = uint16(Y_mixed * 2 / amp_ac * 65536);  % Scale demixed signals for 16-bit format

    end
end

% Close the video file if saving
if save_avi
    avi_file.close();  % Finalize and close the video file
end

end


