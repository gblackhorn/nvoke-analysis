function [diffData,varargout] = organizeDataForDiffComp(PSEF,diffPairs,varargin)
	% organize the data in PSEF to compare peri-stim event frequencies from recordings applied with
	% different stimulation

	% PSEF (peri-stim event frequency): structure var data is created in the
	% function 'periStimEventFreqAnalysis'

	% diffPairss: cell array. each cell contains two numbers, which are the idx of data in PSEF to be
	% compared

	% if using the binNames names in binSettings. The names should be found in PSEF
	% (n).binNamess. Make sure the names are created properly in[periStimEventFreqAnalysis] >
	% [plot_event_freq_alignedData_allTrials] > [get_EventFreqInBins_trials] >
	% [setPeriStimSectionForEventFreqCalc]


	% Defaults
	binSettings(1).stimA = 'ap-0.1s';	
	binSettings(1).stimB = 'og-5s ap-0.1s';	
	binSettings(1).binNamesA = {'baseline','preStim','firstStim','baseAfter'}; % 	
	binSettings(1).binNamesB = {'baseline','preStim','secondStim','lateFirstStim'};	
	binSettings(1).binNamesAB = {'baseline','preStim','airPuff','postAirPuff'};	
	binSettings(1).shiftBinIDX = 3; % if this bin in binSettings(1).binNamesAB is shifted, shade data will also be shifted
	binSettings(2).stimA = 'og-5s';	
	binSettings(2).stimB = 'ap-0.1s';	
	binSettings(2).binNamesA = {'baseline','preStim','lateFirstStim1','lateFirstStim2'};	
	binSettings(2).binNamesB = {'baseline','preStim','firstStim','baseAfter'}; % 	
	binSettings(2).binNamesAB = {'baseline','preStim','airPuff','postAirPuff'};	
	binSettings(2).shiftBinIDX = 3; % if this bin in binSettings(2).binNamesAB is shifted, shade data will also be shifted

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('binSettings', varargin{ii})
	        binSettings = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
	    % elseif strcmpi('postStimDuration', varargin{ii})
	    %     postStimDuration = varargin{ii+1}; 
	    % elseif strcmpi('PeriBaseRange', varargin{ii})
	    %     PeriBaseRange = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        % elseif strcmpi('stimEffectDuration', varargin{ii})
	    %     stimEffectDuration = varargin{ii+1};
        % elseif strcmpi('splitLongStim', varargin{ii})
	    %     splitLongStim = varargin{ii+1};
	    end
	end

	% create an empty stucture diffData
	diffPairsNum = numel(diffPairs);

	% 'binNamesAB': use names here when plotting A and B together for comparison 
	diffDataFields = {'groupA','groupB','xA','xB','dataA','dataB','dataBnorm','binEdgesA','binEdgesB',...
	'binNamesA','binNamesB','binNamesAB','shadeA','shadeB','shiftBins',...
	'ttestAB','ttestABnorm','diffAB','diffABnorm'};
	diffData = empty_content_struct(diffDataFields,diffPairsNum);


	% loop through the diffPairss
	for dpn = 1:diffPairsNum
		% get the idx of PSEF data for diff
		pairIDX = diffPairs{dpn};
		idx1 = pairIDX(1); % idx of groupA
		idx2 = pairIDX(2);


		% compare the number of bins in dataA and dataB
		% use all the bins if binNumA and binNumB are the same
		% discard bins and shift on x-direction using 'binSettings' when they are different
		binNum1 = numel(PSEF(idx1).binNames);
		binNum2 = numel(PSEF(idx2).binNames);
		if binNum1 ~= binNum2
			shiftBins = true; 
		else
			shiftBins = false;
		end
		diffData(dpn).shiftBins = shiftBins;

		% assign some data from PSEF to diffData
		stimPairs = {PSEF(pairIDX).stim}; % strings of stimulations

		% select specific bins from groupA and groupB if the number of bins are different  
		if shiftBins
			settingIDX = [];
			for sn = 1:numel(binSettings)

				% compare the stimPairs with the stim names in binSettings
				settingStimNames = {binSettings(sn).stimA,binSettings(sn).stimB};
				settingStimNamesSorted = sort(settingStimNames);
				stimPairsSorted = sort(stimPairs);
				if isequal(settingStimNamesSorted,stimPairsSorted)
					settingIDX = sn;
					break % stop this loop used when the stimPair is found in the binSettings
				end
			end

			if isempty(settingIDX)
				error('paired stimulations are not found in the binSettings')
			else
				% assign the stim names and the binNames (bins) stored in binSettings to
				% the diffData
				diffData(dpn).groupA = binSettings(settingIDX).stimA;
				diffData(dpn).groupB = binSettings(settingIDX).stimB;
				diffData(dpn).binNamesA = binSettings(settingIDX).binNamesA;
				diffData(dpn).binNamesB = binSettings(settingIDX).binNamesB;
				diffData(dpn).binNamesAB = binSettings(settingIDX).binNamesAB;

				% get the index of groupA and groupB in the PSEF
				idxA = find(strcmpi({PSEF.stim},diffData(dpn).groupA)); 
				idxB = find(strcmpi({PSEF.stim},diffData(dpn).groupB)); 

				% get the binNames from PSEF (binNames here is >= the ones in binSettings)
				PSEFbinNamesA = PSEF(idxA).binNames;
				PSEFbinNamesB = PSEF(idxB).binNames;

				% find out what binNames in PSEF are also in binSettings/diffData(dpn)
				posBinNamesA = find(ismember(PSEFbinNamesA,diffData(dpn).binNamesA));
				posBinNamesB = find(ismember(PSEFbinNamesB,diffData(dpn).binNamesB));

				% Use the binEdges from PSEF to calculate xData (centered between two edges)
				binEdgesA = PSEF(idxA).binEdges; % binEdges of dataA
				binEdgesB = PSEF(idxB).binEdges; % binEdges of dataB
				xDataCenterA = binEdgesA(1:end-1)+diff(binEdgesA)/2; % use the mid values between two bin edges for xDataA
				xDataCenterB = binEdgesB(1:end-1)+diff(binEdgesB)/2; % use the mid values between two bin edges for xDataB
				diffData(dpn).binEdgesA = binEdgesA; % store the xData of the positive binNames
				diffData(dpn).binEdgesB = binEdgesB; % store the xData of the positive binNames


				% select the xData with the positive binNames and store them in the diffData 
				diffData(dpn).xA = xDataCenterA(posBinNamesA); % store the xData of the positive binNames
				diffData(dpn).xB = xDataCenterB(posBinNamesB); % store the xData of the positive binNames

				% store the selected bin data 
				diffData(dpn).dataA = PSEF(idxA).binData(posBinNamesA);
				diffData(dpn).dataB = PSEF(idxB).binData(posBinNamesB);
				diffData(dpn).dataBnorm = normDataBwithDataA(diffData(dpn).dataA,diffData(dpn).dataB);

				% store the shade data
				diffData(dpn).shadeA = PSEF(idxA).stimShade; 
				diffData(dpn).shadeB = PSEF(idxB).stimShade; 

				% compare the xData between groupA and groupB in diffData. 
				% use the one with bigger value. Shift shade data accordingly
				xDataShiftIDX = find(diffData(dpn).xA-diffData(dpn).xB~=0);
				% xDataShiftIDX = find(diffData(dpn).xA-diffData(dpn).xB<0);

				% check if the shifted xData including the bin with the name 'firstStim'
				% if yes, shift the data and shade
				shiftBinIDX = binSettings(settingIDX).shiftBinIDX;
				shiftVal = diffData(dpn).xA(shiftBinIDX)-diffData(dpn).xB(shiftBinIDX);
				% shiftVal = abs(diffData(dpn).xA(shiftBinIDX)-diffData(dpn).xB(shiftBinIDX));

				if ~isempty(xDataShiftIDX==shiftBinIDX)
					if shiftVal > 0 % use xA for dataB and shift shadeB
						diffData(dpn).xB = diffData(dpn).xA;
						shiftShade = PSEF(idxB).stimShade;
						for n = 1:numel(shiftShade.shadeData)
							shiftShade.shadeData{n}(:,1) = shiftShade.shadeData{n}(:,1)+shiftVal;
						end
						diffData(dpn).shadeB = shiftShade;
					elseif shiftVal < 0 % use xB for dataA and shift shadeA
						diffData(dpn).xA = diffData(dpn).xB;
						shiftShade = PSEF(idxA).stimShade;
						for n = 1:numel(shiftShade.shadeData)
							shiftShade.shadeData{n}(:,1) = shiftShade.shadeData{n}(:,1)-shiftVal;
						end
						diffData(dpn).shadeA = shiftShade;
					end
				end
			end
		else % when the bin numbers in two different groups are the same
			diffData(dpn).groupA = PSEF(idx1).stim;
			diffData(dpn).groupB = PSEF(idx2).stim;

			binEdgesA = PSEF(idx1).binEdges; % binEdges of dataA
			binEdgesB = PSEF(idx2).binEdges; % binEdges of dataB
			diffData(dpn).binEdgesA = binEdgesA; % store the xData of the positive binNames
			diffData(dpn).binEdgesB = binEdgesB; % store the xData of the positive binNames

			xDataCenterA = binEdgesA(1:end-1)+diff(binEdgesA)/2; % use the mid values between two bin edges for xDataA
			xDataCenterB = binEdgesB(1:end-1)+diff(binEdgesB)/2; % use the mid values between two bin edges for xDataB
			diffData(dpn).xA = xDataCenterA;
			diffData(dpn).xB = xDataCenterB;

			diffData(dpn).dataA = PSEF(idx1).binData;
			diffData(dpn).dataB = PSEF(idx2).binData;
			diffData(dpn).dataBnorm = normDataBwithDataA(diffData(dpn).dataA,diffData(dpn).dataB);

			diffData(dpn).shadeA = PSEF(idx1).stimShade;
			diffData(dpn).shadeB = PSEF(idx2).stimShade;

			diffData(dpn).binNamesA = PSEF(idx1).binNames;
			diffData(dpn).binNamesB = PSEF(idx2).binNames;
			diffData(dpn).binNamesAB = PSEF(idx2).binNames;
		end
	end
end

function [dataBnorm] = normDataBwithDataA(dataA,dataB)
	% norm dataB using mean values of dataA

	% dataB and dataA have the same length and are both cell array vars.

	% get the length of dataA
	cellNum = numel(dataA);

	% create an empty cell array to store the output
	dataBnorm = cell(size(dataB));

	% calculate the mean of each cell in dataA
	dataAmean = cellfun(@mean,dataA);

	for cn = 1:cellNum
		dataBnorm{cn} = dataB{cn}/dataAmean(cn);
	end
end

