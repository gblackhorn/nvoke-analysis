function [ROIdata_peakevent] = nvoke_event_detection_new(ROIdata, varargin)
%nvoke_event_detection 
% smooth data and find out peaks
% need structure array generated by "ROIinfo2matlab.m"
% nvoke_event_detection(ROIdata, plot_traces, subplot_roi, pause_step, lowpass_fpass)
% Input:
%		- 1. ROIdata
% 		- 2. plot_traces: 1-plot, 2-plot and save
%		- 3. subplot_roi: 1-5x2 rois in 1 figure, 2-2x1 rois in 1 figure
% 		- 4. pause_step: 1-pause after ploting every figure, 0-no pause
%		- 5. lowpass_fpass: lowpassfilter default passband is 1
%   Detailed explanation goes here
%
% nvoke_event_detection(ROIdata,1, 1)

smooth_span = 0.1; % default value for smoothing data traces
prominence_factor = 4;
lowpass_fpass = 1;
smooth_span = 0.1
[transient_properties_variable_names] = transient_properties_variable_names('peak')


if ispc
	figfolder_default = 'G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_ventral\peaks';
elseif isunix
	figfolder_default = '/home/guoda/Documents/Workspace/Analysis/nVoke/Ventral_approach/processed mat files/peaks';
end

if nargin == 1 % ROIdata
	plot_traces = 0;
	pause_step = 0;
elseif nargin == 2 % ROIdata, plot_traces
	plot_traces = varargin{1};
	if plot_traces == 1 || 2
		pause_step = 1;
		subplot_roi = 1; % mode-1: 5x2 rois in 1 figure
	else
		pause_step = 0;
		subplot_roi = 2; % mode-2: 2x1 rois in 1 figure
	end
elseif nargin == 3 % ROIdata, plot_traces, subplot_roi
	plot_traces = varargin{1};
	subplot_roi = varargin{2};
	if plot_traces == 1 || 2
		pause_step = 1;
	else
		pause_step = 0;
	end
elseif nargin >= 4 && nargin <= 5 % ROIdata, plot_traces, subplot_roi, pause_step, (lowpass_fpass)
	plot_traces = varargin{1};
	subplot_roi = varargin{2};
	pause_step = varargin{3};
	if nargin == 5
		lowpass_fpass = varargin{4};
	end
elseif nargin > 5
	error('Too many input. Maximum 5. Read document of function "nvoke_event_detection"')
end


recording_num = size(ROIdata, 1);
if plot_traces == 2
	figfolder = uigetdir(figfolder_default,...
		'Select a folder to save figures');
end
for rn = 1:recording_num
	if plot_traces == 2
		if subplot_roi == 1
			fig_subfolder = figfolder; % do not creat subfolders when subplots are 5x2
		elseif subplot_roi == 2
			fig_subfolder = fullfile(figfolder, ROIdata{rn, 1}(1:25));
			if ~exist(fig_subfolder)
				mkdir(fig_subfolder);
			end
		end
	end

	if isstruct(ROIdata{rn,2})
		single_recording = ROIdata{rn,2}.decon;
		single_rec_raw = ROIdata{rn,2}.raw;
		cnmfe_process = true; % data was processed by CNMFe
		peak_table_row = 1; % more detailed peak info for plot and further calculation will be stored in roidata_gpio{x, 5} 1st row (peak row)
	else
		single_recording = ROIdata{rn,2};
		single_rec_raw = ROIdata{rn,2};
		cnmfe_process = false; % data was not processed by CNMFe
		peak_table_row = 3; % more detailed peak info for plot and further calculation will be stored in roidata_gpio{x, 5} 3rd row (peak row)
	end
	
	[single_recording, recording_time, roi_num] = ROI_calc_plot(single_recording);

	time_info = single_recording{:, 1};

	[TransientProperties_decon, dataTable_processed_decon] = organize_transient_properties(single_recording,...
		'decon', 1, 'prom_par', prominence_factor,...
		'TransientProperties_names', transient_properties_variable_names);
	[TransientProperties_raw_lp, dataTable_processed_raw_lp] = organize_transient_properties(single_rec_raw,...
		'decon', 0, 'prom_par', prominence_factor, 'filter', 'lowpass'...
		'filter_par', lowpass_fpass,...
		'TransientProperties_names', transient_properties_variable_names);
	[TransientProperties_raw_smooth, dataTable_processed_raw_smooth] = organize_transient_properties(single_rec_raw,...
		'decon', 0, 'prom_par', prominence_factor, 'filter', 'smooth'...
		'filter_par', smooth_span,...
		'TransientProperties_names', transient_properties_variable_names);

	TransientProperties_decon_cell = table2cell(TransientProperties_decon);
	TransientProperties_raw_smooth_cell = table2cell(TransientProperties_raw_smooth);
	TransientProperties_raw_lp_cell = table2cell(TransientProperties_raw_lp);

	TransientProperties_combine_cell = [TransientProperties_decon_cell; TransientProperties_raw_smooth_cell; TransientProperties_raw_lp_cell];
	TransientProperties_combine_RowNames = {'peak_decon', 'peak_smooth', 'peak_lowpass'};
	TransientProperties_combine = cell2table(TransientProperties_combine_cell,...
		'VariableNames', TransientProperties_decon.Properties.VariableNames,...
		'RowNames', TransientProperties_combine_RowNames);


	if isfield(ROIdata{rn,2}, 'cnmfe_results') % extract roi spatial information from CNMFe results
		[ROIdata{rn,2}.roi_map, ROIdata{rn,2}.roi_center] = roimap(ROIdata{rn,2}.cnmfe_results);
	end

	% peak_loc_mag_table_row = {'peak'; 'peak_smooth'; 'Peak_lowpassed'};
	% peak_loc_mag_table = array2table(peak_table, 'VariableNames', peak_loc_mag_table_variable, 'RowNames', peak_loc_mag_table_row);

	if nargin >= 2
		if plot_traces == 1 || plot_traces == 2 % 1: only plot. 2: plot and save
			if isempty(ROIdata{rn, 3}) 
				GPIO_trace = 0; % no stimulation used during recording, don't show GPIO trace
			else
				GPIO_trace = 1; % show GPIO trace representing stimulation
				stimulation = ROIdata{rn, 3}{1, 1};
				channel = ROIdata{rn, 4}; % GPIO channels
			end

	  		if subplot_roi == 1
				% traces are subplotted in 5x2 size 
				colNumPerFig = 2;
				rowNumPerFig = 5;
			elseif subplot_roi == 2
				% traces are subplotted in 2x1 size
				colNumPerFig = 1;
				rowNumPerFig = 2;
			end
			plot_col_num = ceil(roi_num/rowNumPerFig);
			plot_fig_num = ceil(plot_col_num/colNumPerFig);

			close all
			for p = 1:plot_fig_num % figure num
				peak_plot_handle(p) = figure (p);
				set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ]); % [x y width height]
				for q = 1:colNumPerFig % column num
					if (plot_col_num-(p-1)*colNumPerFig-q) >= 0

						% roi_trace_first = (p-1)*10+(q-1)*5+1+1; % fist +1 to get the real count of ROI, second +1 to get ROI column in table
						% roi_trace_last = (p-1)*10+q*5+1;
						% subplot(5, 2, q:2:(q+2*4))
						% stackedplot(single_recording)

						% last row number of last column
						if plot_col_num > (p-1)*colNumPerFig+q
							last_row = rowNumPerFig;
						else
							last_row = roi_num-(p-1)*colNumPerFig*rowNumPerFig-(q-1)*rowNumPerFig;
						end
						for m = 1:last_row
							roi_plot = (p-1)*colNumPerFig*rowNumPerFig+(q-1)*rowNumPerFig+m; % the number of roi to be plot
							roi_col_loc = roi_plot+1; % the column number of this roi in single_recording (ROI_table)
							roi_col_data = dataTable_processed_decon.processed_data{:, roi_col_loc}; % roi data 
							roi_col_data_raw = single_rec_raw{:, roi_col_loc}; % roi data 
							peak_time = TransientProperties_combine{1, roi_plot}{1}.peak_time; % peak in time
							peak_mag = TransientProperties_combine{1, roi_plot}{1}.peak_mag; % peak magnitude

							roi_col_data_lowpassed = dataTable_processed_raw_lp.processed_data{:, roi_col_loc};
							peak_time_lowpassed = TransientProperties_combine{3, roi_plot}{1}.peak_time;
							peak_mag_lowpassed = TransientProperties_combine{3, roi_plot}{1}.peak_mag;

							peak_rise_turning_time = TransientProperties_combine{peak_table_row, roi_plot}{1}.rise_time;
							peak_rise_turning_loc = roi_col_data(TransientProperties_combine{peak_table_row, roi_plot}{1}.rise_loc);
							peak_rise_turning_time_lowpassed = TransientProperties_combine{3, roi_plot}{1}.rise_time;
							peak_rise_turning_value_lowpassed = roi_col_data_lowpassed(TransientProperties_combine{3, roi_plot}{1}.rise_loc);

							% plot traces, peaks, and rises 
							sub_handle(roi_plot) = subplot((rowNumPerFig+1), colNumPerFig, q+(m-1)*colNumPerFig);
							
							traceinfo = [roi_col_data roi_col_data_lowpassed roi_col_data_raw];
							peakinfo{1} = [peak_time peak_mag];
							peakinfo{2} = [peak_time_lowpassed peak_mag_lowpassed];
							riseinfo{1} = [peak_rise_turning_time peak_rise_turning_loc];
							riseinfo{2} = [peak_rise_turning_time_lowpassed peak_rise_turning_value_lowpassed];

							plot_trace_peak_rise(time_info,traceinfo,peakinfo,riseinfo)

							set(get(sub_handle(roi_plot), 'YLabel'), 'String', single_recording.Properties.VariableNames{roi_plot+1});
						end
					end
					if GPIO_trace == 1
						subplot((rowNumPerFig+1), colNumPerFig, colNumPerFig*rowNumPerFig+q);
						for nc = 1:length(channel)-2
							gpio_offset = 6; % in case there are multiple stimuli, GPIO traces will be stacked, seperated by offset 6
							x = channel(nc+2).time_value(:, 1);
							y{nc} = channel(nc+2).time_value(:, 2)+(length(channel)-2-nc)*gpio_offset;
							stairs(x, y{nc});
							hold on
						end
						axis([0 recording_time 0 max(y{1})+1])
						hold off
						legend(stimulation, 'Location', "SouthOutside");
					end
				end
				sgtitle(ROIdata{rn, 1}, 'Interpreter', 'none');
				if plot_traces == 2 && ~isempty(figfolder)
					figfile = [ROIdata{rn,1}(1:(end-4)), '-', num2str(p), '.fig'];
					figfullpath = fullfile(fig_subfolder,figfile);
					savefig(gcf, figfullpath);
					jpgfile_name = [figfile(1:(end-3)), 'jpg'];
					jpgfile_fullpath = fullfile(fig_subfolder, jpgfile_name);
					saveas(gcf, jpgfile_fullpath);
					svgfile_name = [figfile(1:(end-3)), 'svg'];
					svgfile_fullpath = fullfile(fig_subfolder, svgfile_name);
					saveas(gcf, svgfile_fullpath);
				end	
				if pause_step == 1
					disp('Press any key to continue')
					pause;
				end
			end
			if isfield(ROIdata{rn,2}, 'roi_map') && isfield(ROIdata{rn,2}, 'roi_center')
				roimap_handle = figure;
				plotroimap(ROIdata{rn,2}.roi_map, ROIdata{rn,2}.roi_center, 1)
				if plot_traces == 2 && ~isempty(figfolder)
					roimap_file_name = [ROIdata{rn,1}(1:(end-4)), '-roimap.jpg'];
					roimap_file_fullpath = fullfile(fig_subfolder, roimap_file_name);
					saveas(gcf, roimap_file_fullpath);
				end
				if pause_step == 1
					disp('Press any key to continue')
					pause;
				end
			end
		end
	end
	ROIdata{rn,5} = TransientProperties_combine;

	clearvars peak_table 
	clearvars TransientProperties_combine

end
ROIdata_peakevent = ROIdata;
end