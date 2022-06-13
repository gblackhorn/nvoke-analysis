function [all_caLevel_data,varargout] = collect_aligned_caLevel(alignedData,varargin)
	% collect calcium level information form every neurons and trial in alignedData for analysis

	% % Defaults
	% guiSave = 'off'; % Options: 'on'/'off'. whether use the gui to choose the save_dir
	% save_dir = '';
	% guiInfo = 'Choose a folder to save plot';
	% fname = ''; % file name

	% figFormat = true;
	% jpgFormat = true;
	% svgFormat = true;

	% % Optionals
	% for ii = 1:2:(nargin-1)
	%     if strcmpi('save_dir', varargin{ii})
	%         save_dir = varargin{ii+1};
	%     elseif strcmpi('guiInfo', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	%         guiInfo = varargin{ii+1}; % output of stim_effect_compare_trace_mean_alltrial
	%     elseif strcmpi('guiSave', varargin{ii})
 %            guiSave = varargin{ii+1};
	%     elseif strcmpi('fname', varargin{ii})
 %            fname = varargin{ii+1};
	%     end
	% end

	% ====================
	% Main contents
	stims = {alignedData.stim_name};
	unique_stims = unique(stims);
	stim_num = numel(unique_stims);

	all_caLevel_data_fieldnames = {'stim_group','timeInfo','caLevel','CaLevel_cal_range','stat'};
	all_caLevel_data = empty_content_struct(all_caLevel_data_fieldnames,stim_num);

	for sn = 1:stim_num
		stim_data_idx = find(strcmp(stims,unique_stims{sn}));
		stim_data =  alignedData(stim_data_idx);
		stim_trial_num = numel(stim_data); % number of trials in a stim group
		all_caLevel_data(sn).stim_group = unique_stims{sn};

		% use the first trial's time info and CaLevel_cal_range for the stim group
		all_caLevel_data(sn).timeInfo = stim_data(1).timeCaLevel; 
		all_caLevel_data(sn).CaLevel_cal_range = stim_data(1).CaLevel_cal_range;

		for tn = 1:stim_trial_num
			trial_caLevel_cell = {stim_data(tn).traces.CaLevelTrace};
			trial_caLevel_combine = [trial_caLevel_cell{:}];
			if tn == 1
				caLevel = trial_caLevel_combine;
			else
				caLevel = [caLevel,trial_caLevel_combine];
			end
		end
		all_caLevel_data(sn).caLevel = caLevel;

		ranges = all_caLevel_data(sn).CaLevel_cal_range;
		data_base_range = caLevel(ranges.rang_base(1):ranges.rang_base(2),:);
		data_stim_range = caLevel(ranges.range_stimSec(1):ranges.range_stimSec(2),:);

		stat.mean_base = mean(data_base_range);
		stat.mean_stim = mean(data_stim_range);

		stat.mean_base_all = mean(stat.mean_base);
		stat.std_base_all = std(stat.mean_base);
		stat.mean_stim_all = mean(stat.mean_stim);
		stat.std_stim_all = std(stat.mean_stim);
		stat.ste_stim_all = stat.std_stim_all/sqrt(length(stat.mean_stim));

		[stat.h,stat.p,stat.ci,stat.stats] = ttest(stat.mean_base,stat.mean_stim);
		all_caLevel_data(sn).stat = stat;
	end
end