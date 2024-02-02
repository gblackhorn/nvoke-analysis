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
	    end
	end

	% Get the roiNum
	roiNum = size(matrixData,2);

	% Create ROI names if roiNames is not input
	if ~exist('roiNames','var')
		roiNames = NumArray2StringCell(roiNum);
		roiNames = cellfun(@(x) [roiNamePrefix,x],roiNames,'UniformOutput',false);
	end


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
	% pairNum = roiNum*(roiNum-1)/2;
	% fieldNames = {'roiA','roiB','corr','lags'};
	% crossCorrResult = empty_content_struct(fieldNames,pairNum);
	crossCorrResult = cell(roiNum);
	for i = 1:roiNum
		for j = i+1:roiNum
			% pairIDX = ((i - 1) * (roiNum - i/2)) + (j - i);
			[cc, lags] = xcorr(matrixData(:, i), matrixData(:, j), 'coeff'); % 'coeff' normalizes the sequence so that the autocorrelations at zero lag equal 1

			% crossCorrResult(pairIDX).roiA = roiNames{i};
			% crossCorrResult(pairIDX).roiB = roiNames{j};
			% crossCorrResult(pairIDX).corr = cc;
			% crossCorrResult(pairIDX).lags = lags;
			crossCorrResult{i, j} = struct('roiA',roiNames{i},'roiB',roiNames{j},...
				'correlation', cc, 'lags', lags);
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


	% Plot all the cross-correlation as subplots
	close all
	figHandle = PlotCrossCorrResult(crossCorrResult);
end