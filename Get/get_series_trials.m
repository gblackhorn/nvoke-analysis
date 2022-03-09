function [sNum,sTrialIDX,varargout] = get_series_trials(recdata_series,varargin)
	% Get the total number of series and the index of trials belongs to the same series

	% recdata_series: a cell array. usually called recdata_organized. Every trial should contains fovID

	% Defaults
	trialName_col = 1;
	traceData_col = 2;

	% ====================
	% Main content
	sNum = 0;
	recNum = size(recdata_series, 1);
	sTrialIdx = NaN(recNum, 1);

	fovIDInfo = cell(recNum, 1); 
	for rn = 1:recNum
		trialData = recdata_series(rn, :);
		if isfield(trialData{traceData_col}, 'fovID')
			fovIDInfo{rn} = trialData{traceData_col}.fovID;
		else
			trialName = trialData{trialName_col};
			sprintf('fovID information not found in %s\n', trialName);
		end
	end

	trialDateInfo = cellfun(@(x) x(1:8), recdata_series(:, 1), 'UniformOutput',false); % Get date info from trial names
	trialDate_unique = unique(trialDateInfo); % find the unique dates
	dateNum = numel(trialDate_unique);

	for dn = 1:dateNum
		trialDate = trialDate_unique{dn}; % get one trial date
		trialDate_idx = find(strcmp(trialDate, trialDateInfo)); % get the index of trials taken on trialDate

		fovIDInfo_trialDate = fovIDInfo(trialDate_idx);
		fovIDInfo_trialDate_unique = unique(fovIDInfo_trialDate);
		fovIDNum = numel(fovIDInfo_trialDate_unique);
		for fn = 1:fovIDNum
			fovID = fovIDInfo_trialDate_unique{fn};
			fovID_idx = find(strcmp(fovID, fovIDInfo_trialDate)); % index in fovIDInfo_trialDate
			seriesIDX = trialDate_idx(fovID_idx);
			sNum = sNum+1;
			sTrialIDX(seriesIDX) = sNum;
		end
	end
end
