function [sNum,sTrialIDX,varargout] = get_series_trials_structVer(alignedData,varargin)
	% Get the total number of series and the index of trials belongs to the same series
	% This code is for finding the series trials in alignedData var
	% Note: Series trials must share the same ROI set. Use proper CNMFe process for series analysis

	% alignedData: a structure var. The fields containing date, stimulation and fovID info 
	%	are used to find trials belong to the same series
	% sNum: number of series
	% sTrialIDX: the index of trials belongs to the same series

	% Defaults
	FieldName_date = 'trialName'; % this field should be partially same among series trials
	% FieldName_stim = 'stim_name'; % this field must be different among series trials
	FieldName_fov = 'fovID'; % this field must be the same among series trials

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('FieldName_date', varargin{ii})
	        FieldName_date = varargin{ii+1};
        % elseif strcmpi('FieldName_stim', varargin{ii})
	       %  FieldName_stim = varargin{ii+1};
        elseif strcmpi('FieldName_fov', varargin{ii})
            FieldName_fov = varargin{ii+1};
        % % elseif strcmpi('nonstimMean_pos', varargin{ii})
        % %     nonstimMean_pos = varargin{ii+1};
	    end
	end


	%% Main content
	sNum = 0;
	recNum = numel(alignedData);
	sTrialIdx = NaN(recNum, 1);

	trialDate = {alignedData.(FieldName_date)};
	% trialStim = {alignedData.(FieldName_stim)};
	trialFOV = {alignedData.(FieldName_fov)};


	trialDateInfo = cellfun(@(x) x(1:8), trialDate, 'UniformOutput',false); % Get date info from trial names
	trialDate_unique = unique(trialDateInfo); % find the unique dates
	dateNum = numel(trialDate_unique);

	for dn = 1:dateNum
		trialDate = trialDate_unique{dn}; % get one trial date
		trialDate_idx = find(strcmp(trialDate, trialDateInfo)); % get the index of trials taken on trialDate

		fovIDInfo_trialDate = trialFOV(trialDate_idx);
		fovIDInfo_trialDate_unique = unique(fovIDInfo_trialDate);
		fovIDNum = numel(fovIDInfo_trialDate_unique);
		for fn = 1:fovIDNum
			fovID = fovIDInfo_trialDate_unique{fn};
			fovID_idx = find(strcmp(fovID, fovIDInfo_trialDate)); % index in fovIDInfo_trialDate
			seriesIDX = trialDate_idx(fovID_idx);
			sNum = sNum+1;
			% sTrialIDX(seriesIDX) = sNum;
			sTrialIDX{sNum} = seriesIDX;
		end
	end
end
