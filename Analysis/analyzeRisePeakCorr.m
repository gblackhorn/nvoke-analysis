function [selectGroupsStruct,save_dir,varargout] = analyzeRisePeakCorr(alignedData,varargin)
	% Collect the calcium values at the event rise and peak locations. Calculate the correlation.

	% alignedData: structure data output by the function 'get_event_trace_allTrials'

	% Defaults
	normWithSponEvent = false; % Use the mean value of spontaneous events in a ROI to normalize the rise and peak values
	selectGroups = {'AP-trig','OGAP-trig-ap','OG-rebound','OGAP-rebound'}; % plot these in different color. All the rest group in another color
	scatterColors = {'#00759E','#8B009E','#9E5200','#509E00','#AFAFAF'};
	MarkerSize = 30;
	% scatterColors = {'#3A8E9E','#873A9E','#9E683A','#7B9E3A','#AFAFAF'};

	plot_unit_width = 0.4; % normalized size of a single plot to the display
	plot_unit_height = 0.4; % nomralized size of a single plot to the display
	columnLim = 2; % number of plot column. 1 column includes violine and tables
	titleStr = sprintf('Correlation of calcium values at rise and peak locations');

	save_fig = false;
	save_dir = [];
	gui_save = false;

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('normWithSponEvent', varargin{ii})
	        normWithSponEvent = varargin{ii+1}; % label style. 'shape'/'text'
	    elseif strcmpi('normWithSponEvent', varargin{ii})
	        normWithSponEvent = varargin{ii+1}; % label style. 'shape'/'text'
	    elseif strcmpi('save_fig', varargin{ii})
	        save_fig = varargin{ii+1}; % label style. 'shape'/'text'
	    elseif strcmpi('save_dir', varargin{ii})
	        save_dir = varargin{ii+1}; % label style. 'shape'/'text'
	    elseif strcmpi('gui_save', varargin{ii})
	        gui_save = varargin{ii+1}; % label style. 'shape'/'text'
	    end
	end	

	% Add 'normWithSponEvent' to the end of title string if normWithSponEvent is true
	titleStr = [titleStr, ' normWithSponEvent'];


	% Get the values of at rises and peaks. Calculate the peak amplitudes
	[riseValsAll,peakValsAll,eventTypesAll] = getRisePeakValFromRecordings(alignedData,'normWithSponEvent',normWithSponEvent);
	peakAmpsAll = peakValsAll-riseValsAll;

	% Create a structure to store the values in different groups
	selectGroupsStruct = empty_content_struct({'labels','riseVals','peakVals','peakAmps'},numel(selectGroups));

	% Loop through groups and organize data
	riseVals = riseValsAll;
	peakVals = peakValsAll;
	peakAmps = peakAmpsAll;
	eventTypes = eventTypesAll;
	for i = 1:numel(selectGroups)
		selectGroupsStruct(i).labels = selectGroups{i};
		tf = strcmpi(selectGroupsStruct(i).labels,eventTypes);
		IDX = find(tf);
		selectGroupsStruct(i).riseVals = riseVals(IDX);
		selectGroupsStruct(i).peakVals = peakVals(IDX);
		selectGroupsStruct(i).peakAmps = peakAmps(IDX);

		eventTypes(IDX) = [];
		riseVals(IDX) = [];
		peakVals(IDX) = [];
		peakAmps(IDX) = [];
	end


	% create a figure canvas for plotting 4 scatter plots
	[f,f_rowNum,f_colNum] = fig_canvas(4,'unit_width',...
	    plot_unit_width,'unit_height',plot_unit_height,'column_lim',columnLim,...
	    'fig_name',titleStr); % create a figure
	tlo = tiledlayout(f, 2, 2); % setup tiles

	% 1. Plot rise vs peak
	axRP = nexttile;
	for j = 1:numel(selectGroupsStruct)
		hold on
		stylishScatter(selectGroupsStruct(j).riseVals,selectGroupsStruct(j).peakVals,...
			'plotWhere',gca,'MarkerFaceColor',scatterColors{j},'MarkerSize',MarkerSize,...
			'xlabelStr','riseVals','ylabelStr','peakVals');
	end
	legend({selectGroupsStruct.labels})
	legend('boxoff')
	title('riseVal vs peakVal')

	% 2. Plot rise vs amplitude
	axRA = nexttile;
	for j = 1:numel(selectGroupsStruct)
		hold on
		stylishScatter(selectGroupsStruct(j).riseVals,selectGroupsStruct(j).peakAmps,...
			'plotWhere',gca,'MarkerFaceColor',scatterColors{j},'MarkerSize',MarkerSize,...
			'xlabelStr','riseVals','ylabelStr','peakAmps');
	end
	legend({selectGroupsStruct.labels})
	legend('boxoff')
	title('riseVal vs peakAmps')

	% 3. Plot all data together (Plot rise vs peak) and add a linear fit and R
	axRPall = nexttile;
	stylishScatter(riseValsAll,peakValsAll,'plotWhere',gca,'showCorrCoef',true,...
		'xlabelStr','riseValsAll','ylabelStr','peakValsAll');
	title('riseVal vs peakVal (All events with linear fitting)')

	% 4. Plot all data together (rise vs amplitude) and add a linear fit and R
	axRPall = nexttile;
	stylishScatter(riseValsAll,peakAmpsAll,'plotWhere',gca,'showCorrCoef',true,...
		'xlabelStr','riseValsAll','ylabelStr','peakAmpsAll');
	title('riseVal vs peakAmps (All events with linear fitting)')

	% set the title for the figure
	sgtitle(titleStr)
	if save_fig
	    if isempty(save_dir)
	        gui_save = true;
	    end
	    msg = 'Choose a folder to save the plot of correlation of calcium values at rise and peak locations';
	    save_dir = savePlot(f,'save_dir',save_dir,'guiSave',gui_save,...
	        'guiInfo',msg,'fname',titleStr);
	    save(fullfile(save_dir, [titleStr, ' dataStat']),...
	        'selectGroupsStruct','riseValsAll','peakValsAll','peakAmpsAll','eventTypesAll');
	end 

	varargout{1} = riseValsAll;
	varargout{2} = peakValsAll;
	varargout{3} = peakAmpsAll;
	varargout{4} = eventTypesAll;
end

% function [stimNameNew,varargout] = modStimName(stimName)
%     strPairs = {{'og-5s','OG'},...
%         {'ap-0.1s','AP'}};
%     blankRep = ''; % replacement for blank

%     for m = 1:numel(strPairs)
%         stimName = replace(stimName,strPairs{m}{1},strPairs{m}{2});
%     end

%     stimNameNew = replace(stimName,' ',blankRep);
% end