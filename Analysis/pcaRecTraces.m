function [varargout] = pcaRecTraces(alignedDataRec,varargin)
	% Run PCA analysis on ROIs' traces from a single recording

	% alignedDataRec: alignedData for one recording. Get this using the function 'get_event_trace_allTrials' 
	% roiNames: Names of ROIs. This can be used as xLabels and yLabels when displaying corrMatrix using heatmap
		% example: h = heatmap(plotWhere,xLabels,yLabels,corrMatrix,'Colormap',jet);

	% Example:
	%		

	% Defaults
	plot_unit_width = 0.4; % normalized size of a single plot to the display
	plot_unit_height = 0.4; % nomralized size of a single plot to the display

	roiNameExcessiveStr = 'neuron'; % remove this string from the ROI name to shorten it


	% Optionals
	% for ii = 1:2:(nargin-2)
	%     % if strcmpi('eventTimeType', varargin{ii}) 
	%     %     eventTimeType = varargin{ii+1}; 
	%     % elseif strcmpi('plotWhere', varargin{ii})
    %     %     plotWhere = varargin{ii+1};
	%     % elseif strcmpi('dispCorr', varargin{ii})
    %     %     dispCorr = varargin{ii+1};
	% end

	% Get some info of the recording
	timeData = alignedDataRec.fullTime;
	stimName = alignedDataRec.stim_name;
	roiNames = {alignedDataRec.traces.roi};

	% remove the 'neuron' part from the roiName for clearer display in the plots. For example,
	% change neuron5 to 5
	roiNamesShort = cell(size(roiNames));
	for i = 1:numel(roiNames)
		roiNamesShort{i} = strrep(roiNames{i},roiNameExcessiveStr,'');
	end


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
	titleStrStem = sprintf('%s %s',recDateTime,stimName); % compose a stem str used for both fig 1 and 2


	% Plot the PCA explained bars and score traces
	figTitle{1} = sprintf('%s PCA explained and score',titleStrStem);
	f(1) = fig_canvas(2,'unit_width',plot_unit_width,'unit_height',plot_unit_height,...
		'column_lim',1,'fig_name',figTitle{1}); % create a figure
	tlo = tiledlayout(f(1), 3, 1); % setup tiles

	% Create a bar plot for the explained variance
	ax = nexttile(tlo,[1,1]); % activate the ax for bar plot of explained - percentage of every PC
	bar(explained, 'FaceColor', [0.7 0.7 0.7]);
	set(gca,'box','off')
	set(gca,'TickDir','out'); % Make tick direction to be out.The only other option is 'in'
	xlabel('Principal Components');
	ylabel('Variance Explained (%)');
	title('Variance Explained by Each Principal Component');
	hold on;

	% Highlight the first n PCs with a different color
	bar(1:numComponentsToRetain, explained(1:numComponentsToRetain), 'FaceColor', [0 0.7 0.4]);
	hold off;

	
	% Plot the 'score' of the selected PCs
	ax = nexttile(tlo,[2,1]);
	scoreNames = NumArray2StringCell(numComponentsToRetain);
	scoreNames = cellfun(@(x) ['PC',x],scoreNames,'UniformOutput',false);
	% 		'ylabels',rowNames,'plot_marker',plot_marker,...
	plot_TemporalData_Trace(gca,timeData,score(:,1:numComponentsToRetain),'ylabels',scoreNames);
	title('Data projected onto principal components')

	sgtitle(figTitle{1})


	% Plot the coeff to show the contribution of every ROI to the PCs
	fig2ColLimit = 4;
	figTitle{2} = sprintf('%s PCA coeff - contributions of ROIs to PC',titleStrStem);
	f(2) = fig_canvas(numComponentsToRetain,'unit_width',plot_unit_width/2,'unit_height',plot_unit_height/2,...
		'column_lim',fig2ColLimit,'fig_name',figTitle{2}); % create a figure
	fig2RowNum = ceil(numComponentsToRetain/fig2ColLimit);
	if fig2RowNum == 1
		fig2ColNum = numComponentsToRetain;
	else
		fig2ColNum = fig2ColLimit;
	end
	tlo = tiledlayout(f(2),fig2RowNum,fig2ColNum); % setup tiles

	for i = 1:numComponentsToRetain
		ax = nexttile(tlo,[1,1]); % activate the ax for bar plot of explained - percentage of every PC
		bar(coeff(:,i));
		set(gca,'box','off')
		set(gca,'TickDir','out'); % Make tick direction to be out.The only other option is 'in'
		xticklabels([]);

		% xticks(1:length(roiNamesShort));
		% xticklabels(roiNamesShort)
		xlabel('ROIs')
		title(scoreNames{i});
	end

	sgtitle(figTitle{2})
	% bar(coeff(:,1))

end