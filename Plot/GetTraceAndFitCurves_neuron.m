function [yfit,varargout] = GetTraceAndFitCurves_neuron(TimeInfo,fVal,TimeRanges,varargin)
	% Fit the data in the TimeRanges to curve and return the fitting information 

	% [yfit] = GetTraceAndFitCurves_neuron(TimeInfo,fVal,TimeRanges): Get the traces specified by
	% TimeRanges and fit them to exponential curve. TimeInfo is the fulltime. fVal has the same
	% size as the TimeInfo. TimeRanges is a n*2 matrix. Each row contains the start and end of a
	% period

	% [yfit] = GetTraceAndFitCurves_neuron(TimeInfo,fVal,TimeRanges,'FitType',FitType): Specify the
	% FitType. Search "List of Library Models for Curve and Surface Fitting" in Matlab for optional
	% types.

	% [yfit] = GetTraceAndFitCurves_neuron(TimeInfo,fVal,TimeRanges,EventTime',EventTime):
	% Do not collect the trace in which calcium event is detected (EventTime is not empty).

	% [yfit] = GetTraceAndFitCurves_neuron(TimeInfo,fVal,TimeRanges,'PlotFit',PlotFit): Plot the
	% curve fitting if PlotFit is true.

	% Defaults
	PlotFit = false; % true/false. Plot the input data and the fitted data to examing the fitting
	FitType = 'exp1';
	EventTime = []; % time of event peaks


	% Options
	for ii = 1:2:(nargin-3)
	    if strcmpi('PlotFit', varargin{ii})
	        PlotFit = varargin{ii+1};
	    elseif strcmpi('FitType', varargin{ii})
	        FitType = varargin{ii+1};
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

	yfit_fields = {'SN','tdata','ydata','timeDuration',...
	'fitinfo_curvefit','fitinfo_gof','fitinfo_output','rsquare'}; 
	% SN: serial number. The (n)th range in the TimeRanges
	% rsquare: coefficient of determination (0.7 means 70% of the dependent var is predicted by the independent variable) 
	
	Range_num = size(TimeRanges,1);
	yfit = empty_content_struct(yfit_fields,Range_num);

	dis_loc = []; % The location of ranges containing events
	for n = 1:Range_num % go through every TimeRanges
		yfit(n).SN = n; % the (n)th one in the TimeRanges
 		yfit(n).tdata = TimeInfo(LocRanges(n,1):LocRanges(n,2))-TimeInfo(LocRanges(n,1));
		yfit(n).ydata = fVal(LocRanges(n,1):LocRanges(n,2));
		yfit(n).timeDuration = TimeRangesDurations(n);
		
		fitCurve = true;
		if ~isempty(EventTime)
			events_in_range = find(EventTime>=TimeRanges(n,1) & EventTime<=TimeRanges(n,2));
			if ~isempty(events_in_range)
				dis_loc = [dis_loc n];
				fitCurve = false;
			end
		end

		if fitCurve
			[yfit(n).fitinfo_curvefit,yfit(n).fitinfo_gof,yfit(n).fitinfo_output] = fit(yfit(n).tdata(:),yfit(n).ydata(:),...
				FitType);
			yfit(n).rsquare = yfit(n).fitinfo_gof.rsquare;  
		end
	end
	yfit(dis_loc) = [];
	varargout{1} = numel(yfit); % number of curves fitted to data
	varargout{2} = Range_num; % total number of ranges


	%% Plot curvefitting
	if PlotFit
		plot_num = numel(yfit);
		[fig_handle] = fig_canvas(plot_num,'column_lim',4,'row_lim',2,...
			'fig_name','data and fitting');
		tlo = tiledlayout(fig_handle, ceil(plot_num/4), 4);
		for pn = 1:plot_num
			f_title = sprintf('stimulation %d/%d',yfit(pn).SN,Range_num);
			ax = nexttile(tlo);

			[ax_handle,varargout] = PlotCurveFitting(yfit(pn).tdata,yfit(pn).ydata,yfit(pn).fitinfo_curvefit,...
				'xlabel_str','Time','ylabel_str','Response Data and Curve',...
				'title_str',f_title,...
				'ax',ax)
			% if ~isempty(yfit(pn).fitinfo_curvefit)
			% 	plot(yfit(pn).tdata,yfit(pn).ydata,'o');
			% 	hold on
			% 	plot(yfit(pn).fitinfo_curvefit,'predobs')
			% 	xlabel('Time')
			% 	ylabel('Response Data and Curve')
			% 	title(f_title)
			% 	hold off
			% end
		end
	end
end