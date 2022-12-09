function [yfit,varargout] = GetTraceAndFitCurves_neuron(TimeInfo,fVal,TimeRanges,varargin)
	% Fit the data in the TimeRanges to curve and return the fitting information 

	% [yfit] = GetTraceAndFitCurves_neuron(TimeInfo,fVal,TimeRanges): Get the traces specified by
	% TimeRanges and fit them to exponential curve. TimeInfo is the fulltime. fVal has the same
	% size as the TimeInfo. TimeRanges is a n*2 matrix. Each row contains the start and end of a
	% period

	% [yfit] = GetTraceAndFitCurves_neuron(TimeInfo,fVal,TimeRanges,'FitType',FitType): Specify the
	% FitType. Search "List of Library Models for Curve and Surface Fitting" in Matlab for optional
	% types.

	% [yfit] = GetTraceAndFitCurves_neuron(TimeInfo,fVal,TimeRanges,'NoEvent',NoEvent,'EventTime',EventTime):
	% Do not collect the trace in which calcium event is detected if NoEvent is true. EventTime must 
	% be input if NoEvent is true.

	% [yfit] = GetTraceAndFitCurves_neuron(TimeInfo,fVal,TimeRanges,'PlotFit',PlotFit): Plot the
	% curve fitting if PlotFit is true.

	% Defaults
	PlotFit = false; % true/false. Plot the input data and the fitted data to examing the fitting
	FitType = 'exp1';
	NoEvent = false;
	EventTime = []; % time of event peaks

	% Options
	for ii = 1:2:(nargin-2)
	    if strcmpi('PlotFit', varargin{ii})
	        PlotFit = varargin{ii+1};
	    elseif strcmpi('FitType', varargin{ii})
	        FitType = varargin{ii+1};
	    elseif strcmpi('NoEvent', varargin{ii})
	        NoEvent = varargin{ii+1};
	    elseif strcmpi('EventTime', varargin{ii})
	        EventTime = varargin{ii+1};
	    end
	end


	%% Collect the traces
	TimeRangesDurations = TimeRanges(:,2)-TimeRanges(:,1); % Get the duration of the time ranges
	LocRanges = NaN(size(TimeRanges)); % the locations of the time ranges

	% Get the closest values for TimeRanges if they cannot be find in the TimeInfo
	[TimeRanges(:,1),LocRanges(:,1)] = find_closest_in_array(TimeRanges(:,1),TimeInfo);  
	[TimeRanges(:,2),LocRanges(:,2)] = find_closest_in_array(TimeRanges(:,2),TimeInfo);
	% TimeRanges = TimeRanges-TimeRanges(:,1); % make every TimeRanges starts from 0

	yfit_fields = {'tdata','ydata','fitdata','timeDuration',...
	'fitinfo_curvefit','fitinfo_gof','fitinfo_output'};
	Range_num = size(TimeRanges,1);
	yfit = empty_content_struct(yfit_fields,Range_num);

	for n = 1:Range_num % go through every TimeRanges
		yfit(n).tdata = TimeInfo(LocRanges(n,1):LocRanges(n,2))-TimeInfo(LocRanges(n,1));
		yfit(n).ydata = fVal(LocRanges(n,1):LocRanges(n,2));

		dis_loc = []; % The location of ranges containing events
		if NoEvent
			if ~isempty
				events_in_range = find(EventTime>=TimeRanges(n,1) & EventTime<=TimeRanges(n,2));
				if ~isempty(events_in_range)
					dis_loc = [dis_loc n];
					fitCurve = true;
				else
					fitCurve = false;
				end
			else
				error('EventTime is missing in funtion [GetTraceAndFitCurves_neuron]')
			end
		end

		if fitCurve
			[yfit(n).fitinfo_curvefit,yfit(n).fitinfo_gof,yfit(n).fitinfo_output] = fit(yfit(n).tdata(:),yfit(n).ydata(:),...
				FitType);
		end
	end
	yfit(dis_loc) = [];


	%% Plot curvefitting
	if PlotFit
		plot_num = numel(yfit);
		[fig_handle] = fig_canvas(plot_num,'column_lim',4,'row_lim',2,
			'fig_name','data and fitting');
		tlo = tiledlayout(fig_handle, ceil(plot_num/4), 4);
		for pn = 1:plot_num
			f_title = sprintf('%d - %d s',yfit(pn).ydata(1),yfit(pn).ydata(end));
			ax = nexttile(tlo);
			plot(yfit(pn).tdata,yfit(pn).ydata,'o');
			hold on
			plot(yfit(pn).fitinfo_curvefit,'predobs')
			xlabel('xdata')
			ylabel('Response Data and Curve')
			title(f_title)
			hold off
		end
	end
end