function [List_curveFitNum_eventNum,varargout] = plot_stimNum_fitNum_eventNum(alignedData,eventCat,stimName,varargin)
	% Get the stimulation number, curvefit number, eventNum (with or without a fit curve) for each
	% recordings. Output a list containing these info and create plots to show them

	% This function is primarily writted for 'rebound' events in 'og-5s' recordings 

	% Note: alignedData is a structure value acquired with the function
	% [get_event_trace_allTrials]. eventCat is a character var (such as 'rebound'). stimName is in
	% the field of 'stim_name'. It usually includes: 'og-5s', 'ap-0.1s'

	% Example:
	% [List_decayFitNum_rbNum] = plot_stimNum_fitNum_eventNum(alignedData,'rebound','og-5s')

	% Defaults
	stimTimeCol = 2;
	ylim_val = [0 1];
	titleStr = 'ratios of events with curve fit';
	save_fig = false;
	save_dir = '';
	gui_save = false;

	% Optional
	for ii = 1:2:(nargin-3)
	    if strcmpi('stimTimeCol', varargin{ii})
	        stimTimeCol = varargin{ii+1};
	    elseif strcmpi('ylim_val', varargin{ii})
	        ylim_val = varargin{ii+1};
	    elseif strcmpi('titleStr', varargin{ii})
	        titleStr = varargin{ii+1};
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
	alignedData_stim = alignedData(idx_stim_rec);

	% Create a list for each recording. This list contains the total stimulation number, the
	% curvefit number, and the eventNum (with or without a fit curve). Event category is determined
	% by the input 'eventCat'
	List_curveFitNum_eventNum = get_StimEvents_CloseToFit_trials(alignedData_stim,eventCat,stimTimeCol);
	barplotData = cell(1,4);
	barplotGroupName = {'total_curve_fit/stimulation_number','events_with_curveFit/total_curve_fit',...
		'events_with_curveFit/stimulation_number','all_events/stimulation_number'};


	
	% Calculate the ratio/percentage for plotting
	stimNum = [List_curveFitNum_eventNum.stimNum];
	fitNum = [List_curveFitNum_eventNum.fitNum];
	eventFitNum = [List_curveFitNum_eventNum.eventFitNum];
	eventNoFitNum = [List_curveFitNum_eventNum.eventNoFitNum];

	% Calculate the curve_fit/stimulation_number 
	barplotData{1} =  fitNum./stimNum;

	% Calculate the events_with_curveFit/curve_fit
	barplotData{2} =  eventFitNum./fitNum;

	% Calculate the events_with_curveFit/stimulation_number
	barplotData{3} =  eventFitNum./stimNum;

	% Calculate the events_all/stimulation_number
	barplotData{4} =  (eventFitNum+eventNoFitNum)./stimNum;


	%% Plot the data in the list
	titleStr = sprintf('%s [%s %s]',titleStr,stimName,eventCat);
	[barInfo,save_dir] = barplot_with_stat(barplotData,'group_names',barplotGroupName,...
		'TickAngle',45,'title_str',titleStr,'ylim_val',ylim_val,'ylabelStr','ratio',...
		'save_fig',save_fig,'save_dir',save_dir,'gui_save',gui_save);

	if save_fig
		list_fileName = sprintf('%s-dataList',titleStr);
		save(fullfile(save_dir,list_fileName),'List_curveFitNum_eventNum');
	end

	varargout{1} = barInfo;
	varargout{2} = save_dir;
end