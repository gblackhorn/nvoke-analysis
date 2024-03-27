function [varargout] = pcaRecTraces(alignedDataRec,varargin)
	% Run PCA analysis on ROIs' traces from a single recording

	% alignedDataRec: alignedData for one recording. Get this using the function 'get_event_trace_allTrials' 
	% roiNames: Names of ROIs. This can be used as xLabels and yLabels when displaying corrMatrix using heatmap
		% example: h = heatmap(plotWhere,xLabels,yLabels,corrMatrix,'Colormap',jet);

	% Example:
	%		

	% Defaults
	% dispCorr = false;
	% filters = {[nan 1 nan nan], [1 nan nan nan], [nan nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: excitatory AP during OG
		% filter number must be equal to stim_names

	% Optionals
	% for ii = 1:2:(nargin-2)
	%     % if strcmpi('eventTimeType', varargin{ii}) 
	%     %     eventTimeType = varargin{ii+1}; 
	%     % elseif strcmpi('plotWhere', varargin{ii})
    %     %     plotWhere = varargin{ii+1};
	%     % elseif strcmpi('dispCorr', varargin{ii})
    %     %     dispCorr = varargin{ii+1};
	% end

	% Get the time data
	timeData = alignedDataRec.fullTime;

	% Check the size of 'alignedDataRec' If the length of 'alignedDataRec' is bigger than 1, run
	% analysis on the first recroding and show warning
	recNum = numel(alignedDataRec);
	if recNum > 1
		alignedDataRec = alignedDataRec(1);
		warning('The size of input, alignedDataRec, is bigger than 1, the first recording in it will be analyzed');
	end

	% Get the traces, ROI names, and recording names (composed by date and time)
	[traces,roiNames,recDateTime] = recTrace(alignedDataRec);


	% Standarize the data
	standardizedTraces = zscore(traces);


	% Run PCA analysis using the built-in function
	% coeff: Principal component coefficients (eigenvectors)
	% score: Data projected onto principal components
	% latent: Eigenvalues (variance explained by each principal component)
	% explained: Percentage of variance explained by each principal component
	[coeff,score,latent,tsquared,explained] = pca(standardizedTraces);


	% Run parallel analysis to select the optimal number, 'numComponentsToRetain', of PC components
	[numComponentsToRetain,meanEigenValuesRandom] = parallelAnalysisForPCA(traces,latent);



	%% Visualize the result

	% Create a bar plot for the explained variance
	figure;
	bar(explained, 'FaceColor', [0.7 0.7 0.7]);
	xlabel('Principal Components');
	ylabel('Variance Explained (%)');
	title('Variance Explained by Each Principal Component');
	hold on;

	% Highlight the first n PCs with a different color
	bar(1:numComponentsToRetain, explained(1:numComponentsToRetain), 'FaceColor', [0 0.7 0.4]);
	hold off;

	
	% Plot the 'score' of the selected PCs
	figure;
	% 		'ylabels',rowNames,'plot_marker',plot_marker,...
	plot_TemporalData_Trace(gca,timeData,score(:,1:numComponentsToRetain));

end