function [crossCorrResult,varargout] = roiCorrTrace(matrixData,varargin)
	% Calculate the cross-correation of ROIs from the same recording

	% matrixData: each column represents the calcium trace of a region of interest (ROI) and each
	% row represents a time point

	% Example:
	%		

	% Defaults
	roiNamePrefix = 'roi-'; % used to create ROI names if roiNames is not input
	detrendTrace = false; % detrend the calcium traces
	normTrace = true; % default: true
	normMethod = 'zscore'; % zscore/maxVal. Value used to do the normalization. 
	% corrMaxLag = 100; % limits the lag range from -corrMaxLag to corrMaxLag frames

	numPermutations = 1000; % Resample time point data for the number of var. Calculate the correlation after each resampling
	samplingFreq = 20; % Hz. The sampling frequency of matrixData
	lagsOfInterest = 0; % second. This can be a vector containing multiple lags

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('roiNames', varargin{ii}) 
	        roiNames = varargin{ii+1}; 
	    elseif strcmpi('detrendTrace', varargin{ii}) 
	        detrendTrace = varargin{ii+1}; 
	    elseif strcmpi('normTrace', varargin{ii}) 
	        normTrace = varargin{ii+1}; 
	    elseif strcmpi('normMethod', varargin{ii}) 
	        normMethod = varargin{ii+1}; 
	    % elseif strcmpi('corrMaxLag', varargin{ii}) 
	    %     corrMaxLag = varargin{ii+1}; 
	    elseif strcmpi('numPermutations', varargin{ii}) 
	        numPermutations = varargin{ii+1}; 
	    elseif strcmpi('samplingFreq', varargin{ii}) 
	        samplingFreq = varargin{ii+1}; 
	    elseif strcmpi('lagOfInterest', varargin{ii}) 
	        lagOfInterest = varargin{ii+1}; 
	    end
	end

	% Get the roiNum
	roiNum = size(matrixData,2);

	% Create ROI names if roiNames is not input
	if ~exist('roiNames','var')
		roiNames = NumArray2StringCell(roiNum);
		roiNames = cellfun(@(x) [roiNamePrefix,x],roiNames,'UniformOutput',false);
	end

	% Get the numbers of lags
	lagsOfInterestFrame = arrayfun(@(x) round(x)/(1000/samplingFreq),lagsOfInterest);
	numLags = length(lagsOfInterest);


	% Detrend the traces. Remove the best straight-fit line from data, column by column
	if detrendTrace
		for i = 1:roiNum
			matrixData(:, i) = detrend(matrixData(:, i));
		end
	end

	% Normalize traces
	if normTrace
		switch normMethod
			case 'zscore'
				for i = 1:roiNum
					matrixData(:, i) = (matrixData(:, i) - mean(matrixData(:, i))) / std(matrixData(:, i));
				end
			case 'maxVal'
				for i = 1:roiNum
					matrixData(:, i) = (matrixData(:, i) - mean(matrixData(:, i))) / std(matrixData(:, i));
				end
			otherwise
				error('Input zscore or maxVal for the input normMethod')
		end
	end


	% Calculate the cross-correlation
	% pairNum = nchoosek(roiNum,2);
	% pairNum = roiNum*(roiNum-1)/2;
	% fieldNames = {'roiA','roiB','corr','lags'};
	% crossCorrResult = empty_content_struct(fieldNames,pairNum);
	crossCorrResult = cell(roiNum); % Used to store all the corr and lag info
	actualCorr = zeros(nchoosek(roiNum, 2), numLags); % Used to save the corr at specified lags
	for i = 1:roiNum-1
		for j = i+1:roiNum
			pairIDX = ((i - 1) * (roiNum - i/2)) + (j - i);
			[cc, lags] = xcorr(matrixData(:, i), matrixData(:, j), 'coeff'); % 'coeff' normalizes the sequence so that the autocorrelations at zero lag equal 1

			% Store actual correlations for lags of interest
		       for k = 1:numLags
		           lagIdx = find(lags == lagsOfInterestFrame(k));
		           actualCorr(pairIDX, k) = cc(lagIdx);
		       end

			% crossCorrResult(pairIDX).roiA = roiNames{i};
			% crossCorrResult(pairIDX).roiB = roiNames{j};
			% crossCorrResult(pairIDX).corr = cc;
			% crossCorrResult(pairIDX).lags = lags;
			crossCorrResult{i, j} = struct('roiA',roiNames{i},'roiB',roiNames{j},...
				'correlation', cc, 'lags', lags,...
				'CorrAtLags',actualCorr(pairIDX, :),'lagsOfInterest',lagsOfInterestFrame);
		end
	end


	% Permutation testing for null distribution
	for pn = 1:numPermutations
		shuffledData = matrixData(randperm(size(matrixData, 1)), :);
		% countPairs = 1;
		for i = 1:roiNum-1
		    for j = i+1:roiNum
		    	pairIDX = ((i - 1) * (roiNum - i/2)) + (j - i);
		        [ccShuffled, ~] = xcorr(shuffledData(:, i), shuffledData(:, j), 'coeff');
		        for k = 1:numLags
		            lagIdx = find(lags == lagsOfInterestFrame(k));
		            nullDist(pn, pairIDX, k) = ccShuffled(lagIdx);
		        end
		        % countPairs = countPairs + 1;
		    end
		end
	end


	% Significance testing for each lag
	pValues = zeros(nchoosek(roiNum, 2), numLags);
	adjPValues = zeros(nchoosek(roiNum, 2), numLags);

	for k = 1:numLags
	    % Compute p-values
	    pValues(:, k) = mean(bsxfun(@ge, abs(squeeze(nullDist(:, :, k))), abs(actualCorr(:, k))'), 1);
	    
	    % Correct for multiple comparisons, e.g., using FDR
	    % [~, ~, ~, adjPValues(:, k)] = fdr_bh(pValues(:, k), 0.05, 'pdep', 'yes');
	    adjPValues(:, k) = mafdr(pValues, 'BHFDR', true);

	end

	% Store p-values and adjusted p-values in your crossCorrResult structure
	% countPairs = 1;
	for i = 1:roiNum-1
	    for j = i+1:roiNum
	        if i < j
	        	pairIDX = ((i - 1) * (roiNum - i/2)) + (j - i);
	            crossCorrResult{i, j}.pValues = pValues(pairIDX, :);
	            crossCorrResult{i, j}.adjPValues = adjPValues(pairIDX, :);
	            % countPairs = countPairs + 1;
	        end
	    end
	end

	% Plot the cross-correlation one by one with pause
	% for n = 1:numel(crossCorrResult)
	% 	close
	% 	figure
	% 	plot(crossCorrResult(n).lags,crossCorrResult(n).corr);
	% 	xlabel('Lags');
	% 	ylabel('Cross-correlation');
	% 	title(sprintf('Cross-correlation %s vs %s',crossCorrResult(n).roiA,crossCorrResult(n).roiB));
	% 	pause
	% end

	% for i = 1:roiNum
	%     for j = i+1:roiNum
	%     	close all
	%         plot(crossCorrResult{i, j}.lags, crossCorrResult{i, j}.correlation);
	%         xlabel('Lags');
	%         ylabel('Cross-Correlation');
	%         title(sprintf('Cross-correlation %s vs %s',crossCorrResult(i,j).roiA,crossCorrResult(i,j).roiB));
	%         pause; % Pause to view each plot
	%     end
	% end


	% % Plot all the cross-correlation as subplots
	% close all
	% figHandle = PlotCrossCorrResult(crossCorrResult);
end