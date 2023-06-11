function [targetData_with_fovid,varargout] = copy_fovInfo(sourceData,targetData,varargin)
% Copy the fovID sourceData to targetData (recdata_organized) if same trials found in both 
%   Detailed explanation goes here

	% Defaults
	overwrite = false;
	data_col = 2;

	% Optionals
    for ii = 1:2:(nargin-2)
    	if strcmpi('overwrite', varargin{ii})
    		overwrite = varargin{ii+1}; %
    	end
    end


	sourceData_num = size(sourceData, 1);
	targetData_num = size(targetData, 1);
	sourceData_trialNames = sourceData(:, 1);
	targetData_trialNames = targetData(:, 1);


	% Get the date and time info in the trial name
	% example fileName: '20211008-150406_video_sched_0-PP-BP-MC-ROI.csv'. 
	% Take the first part, '20211008-150406', separated by '_'
	sourceData_trialNames_sep = cellfun(@(x) strsplit(x),sourceData_trialNames,'UniformOutput',false);
	targetData_trialNames_sep = cellfun(@(x) strsplit(x),targetData_trialNames,'UniformOutput',false);

	sourceData_trialNames = cellfun(@(x) x{1},sourceData_trialNames_sep,'UniformOutput',false);
	targetData_trialNames = cellfun(@(x) x{1},targetData_trialNames_sep,'UniformOutput',false);


	% Copy the fovInfo if the targetData_trialNames can be found in sourceData_trialNames_sep
	targetData_with_fovid = targetData;
	copy_num = 0;
	targetData_fov_num = zeros(targetData_num, 1);
	for sn = 1:sourceData_num

		% fprintf('%dth trial in sourceData\n', sn)
		% if sn == 21
		% 	pause
		% end

		trialName = sourceData_trialNames{sn};
		trial_data_source = sourceData{sn, data_col};
		same_trial_tag = strcmp(trialName, targetData_trialNames);
		trial_idx = find(same_trial_tag); % index of the trial in targetData

		if ~isempty(trial_idx)
			trial_data_target = targetData{trial_idx, data_col};
			if ~isfield(trial_data_target, 'FOV_loc') || overwrite
				if ~isfield(trial_data_source, 'FOV_loc')
					fprintf('sourceData %s (%d) does not contain FOV_loc info\n', trialName, sn)
					return
				else
					trial_data_target.FOV_loc = trial_data_source.FOV_loc;
					targetData_with_fovid{trial_idx, data_col} = trial_data_target;
					copy_num = copy_num+1;
					targetData_fov_num(trial_idx) = 1;
				end
			elseif isfield(trial_data_target, 'FOV_loc') 
				targetData_fov_num(trial_idx) = 1;
			end
		end
	end

	fprintf('%d/%d trails in targetData have fovInfo\n', copy_num, targetData_num);
	targetTrials_wo_fovInfo = targetData_trialNames(find(targetData_fov_num==0));
	varargout{1} = targetTrials_wo_fovInfo; % trial names in targetData without FOV information

end

