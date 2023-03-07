function [sponFreqList,varargout] = plot_sponFreq_everyStim_trials(alignedData,stimName,varargin)
	% Returecn a list (struct var) containing the spontaneous event frequencies for all the ROIs in
	% recording(s) and plot the frquencies

	% Note: alignedData is a structure value acquired with the function
	% [get_event_trace_allTrials].  

	% Example:

	% Defaults
	eventTimeCat = 'rise_time'; % 'rise_time' of 'peak_time'. Choose one the get the event time in eventProp
	use_curvefit = true; % true/false. If true, use the curvefit to seperate the stimulations: with or without
	excludeWinPre = 0; % exclude the specified duration (unit: s) before stimulation
	excludeWinPost = 0; % exclude the specified duration (unit: s) after stimulation
	filter_roi_tf = false; % do not filter ROIs by default

	save_fig = false;
	save_dir = '';
	gui_save = false;

	% Optional
	for ii = 1:2:(nargin-2)
	    if strcmpi('use_curvefit', varargin{ii})
	        use_curvefit = varargin{ii+1}; % the idx of stimulation with a curve fit
	    elseif strcmpi('excludeWinPre', varargin{ii})
	        excludeWinPre = varargin{ii+1};
	    elseif strcmpi('excludeWinPost', varargin{ii})
	        excludeWinPost = varargin{ii+1};
	    elseif strcmpi('filter_roi_tf', varargin{ii})
	        filter_roi_tf = varargin{ii+1};
	    elseif strcmpi('title_prefix', varargin{ii})
	        title_prefix = varargin{ii+1};
        elseif strcmpi('save_fig', varargin{ii})
            save_fig = varargin{ii+1};
        elseif strcmpi('save_dir', varargin{ii})
            save_dir = varargin{ii+1};
        elseif strcmpi('gui_save', varargin{ii})
            gui_save = varargin{ii+1};
	    end
	end


	% Get the recording applied with the specific stimulation (stimName)
	stimNames_alignedData = {alignedData.stim_name};
	idx_stim_rec = find(strcmpi(stimName,stimNames_alignedData)); % look for stimName in the stim_names
	alignedData = alignedData(idx_stim_rec);


	% Filter the ROIs in all trials according to the stimulation effect
	if filter_roi_tf
		[alignedData] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData,...
			'stim_names',stim_names,'filters',filters);
		title_prefix = 'filtered';
	else
		title_prefix = '';
	end 
	

	% Create a cell array to store the list from each recording 
	recNum = numel(alignedData);
	sponFreqList_cell = cell(1,recNum);
	sponFreqList_fieldNames = {'trialName','roiName','sponEventData',...
		'sponFreq','sponfreq_withFit','sponfreq_woFit'};


	% Loop throught all the recordings
	for recn = 1:recNum
		trialName = alignedData(recn).trialName(1:15);
		timeInfo = alignedData(recn).fullTime;

		% Prepare the inputs for function [get_sponFreq_everyStim_roi]
		stimTimeRanges = alignedData(recn).stimInfo.UnifiedStimDuration.range;
		sponTimeRanges = get_sponWindowsBeforeStim(stimTimeRanges,'timeInfo',timeInfo,...
			'excludeWinPre',excludeWinPre,'excludeWinPost',excludeWinPost);
		CaData = alignedData(recn).traces;
		
		% Create an empty structure for sponFreqList
		roiNum = numel(CaData);
		sponFreqList_rec = empty_content_struct(sponFreqList_fieldNames,roiNum);

		% Loop through all the ROIs in the current recording
		for rn = 1:roiNum
			sponFreqList_rec(rn).trialName = trialName;
			sponFreqList_rec(rn).roiName = CaData(rn).roi;
			EventsTime = [CaData(rn).eventProp.(eventTimeCat)];
			stimIDX_curvefit = [CaData(rn).StimCurveFit.SN];

			% Get the sponEventData from a single ROI
			sponEventData = get_sponFreq_everyStim_roi(EventsTime,sponTimeRanges,...
				'stimIDX_curvefit',stimIDX_curvefit);
			sponFreqList_rec(rn).sponEventData = sponEventData;


			% Calculate the sponFreq and fill the sponFreqList_rec
			sponFreqList_rec(rn).sponFreq = sum([sponEventData.sponFreq])/numel(sponEventData);

			stimIDX_curvefit = find([sponEventData.curvefit_tf]); % idx of the stims with curve fit
			if ~isempty(stimIDX_curvefit)
				sponFreqList_rec(rn).sponfreq_withFit = sum([sponEventData(stimIDX_curvefit).sponFreq])/numel(stimIDX_curvefit);
			else
				sponFreqList_rec(rn).sponfreq_withFit = nan;
			end

			stimIDX_wocurvefit = find([sponEventData.curvefit_tf]==0); % idx of the stims without curve fit
			if ~isempty(stimIDX_wocurvefit)
				sponFreqList_rec(rn).sponfreq_woFit = sum([sponEventData(stimIDX_wocurvefit).sponFreq])/numel(stimIDX_wocurvefit);
			else
				sponFreqList_rec(rn).sponfreq_woFit = nan;
			end
		end
		if ~isempty(sponFreqList_rec)
			sponFreqList_cell{recn} = sponFreqList_rec;
        else
		end
	end
	sponFreqList = cat(1,sponFreqList_cell{:});


	%% Plot
	titleStr = sprintf('sponEvent freq %s [%s]',title_prefix,stimName);
	[f,f_rowNum,f_colNum] = fig_canvas(2,'unit_width',0.3,'unit_height',0.4,'column_lim',2,...
		'fig_name',titleStr); % create a figure
	tlo = tiledlayout(f,f_rowNum,f_colNum);

	% Plot the freq with bars
	barplotData = cell(1,3);
	barplotGroupName = {'all','preStimFit','preStimNofit'}; 
	barplotData{1} =  [sponFreqList.sponFreq]; % freq of all spontaneous events
	barplotData{2} =  [sponFreqList.sponfreq_withFit]; % freq of spontaneous events before stimulation with curvefit
	barplotData{3} =  [sponFreqList.sponfreq_woFit]; % freq of spontaneous events before stimulation without curvefit

	ax = nexttile(tlo);
	[statInfo] = barplot_with_stat(barplotData,'group_names',barplotGroupName,...
		'TickAngle',45,'ylabelStr','freq (Hz)',...
		'save_fig',false,'save_dir',save_dir,'gui_save',gui_save,'plotWhere',gca); %'title_str',titleStr,

	% Plot the freq with violin
	violinPlotData = cell2struct(barplotData,barplotGroupName,2);
	ax = nexttile(tlo);
	violinplot(violinPlotData);
	set(gca,'TickDir','out'); % Make tick direction to be out.The only other option is 'in'
	set(gca, 'box', 'off')

	sgtitle(titleStr);


	if save_fig
		if isempty(save_dir)
			gui_save = true;
		end
		msg = 'Choose a folder to save plots and data of spon event frequency';
		save_dir = savePlot(f,'save_dir',save_dir,'guiSave',gui_save,...
			'guiInfo',msg,'fname',titleStr);

		list_fileName = sprintf('%s-dataList',titleStr);
		save(fullfile(save_dir,list_fileName),'sponFreqList','statInfo');
	end

	varargout{1} = statInfo;
end