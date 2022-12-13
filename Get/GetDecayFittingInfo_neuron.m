function [curvefit,varargout] = GetDecayFittingInfo_neuron(TimeInfo,fVal,TimeRanges,EventTime,rsquare_thresh,varargin)
	% Fit the data in the TimeRanges to exponantial decay curve and return the fitting information 

	% exponantial model: val(x) = A*exp(lambda*x)

	% rsquare: coefficient of determination (0.7 means 70% of the dependent var is predicted by the
	% independent variable) 


	% [yfit,tauInfo] = GetDecayFittingInfo_neuron(TimeInfo,fVal,TimeRanges,EventTime,rsquare_thresh): 
	% Get the curve fitting information (yfit) and the time constant (tauInfo) of the decay curves in 
	% a neuron. TimeInfo is the full recording time information. fVal is the recorded fluorescence data
	% TimeRanges is a n*2 matrix containing the starts and ends of time for curve fitting. EventTime 
	% contains the event peak times. rsquare_thresh is the threshold for validating the fittings. 


	% Defaults
	if nargin < 4
		error('MATLAB:notEnoughInputs','Not enough input arguments.')
	elseif nargin == 4
		rsquare_thresh = 0.7;
	end
	
	% % Options
	% for ii = 1:2:(nargin-3)
	%     if strcmpi('PlotFit', varargin{ii})
	%         PlotFit = varargin{ii+1};
	%     elseif strcmpi('FitType', varargin{ii})
	%         FitType = varargin{ii+1};
	%     elseif strcmpi('NoEvent', varargin{ii})
	%         NoEvent = varargin{ii+1};
	%     elseif strcmpi('EventTime', varargin{ii})
	%         EventTime = varargin{ii+1};
	%     end
	% end


	%% Collect the traces
	Range_num = size(TimeRanges,1);

	[yfit] = GetTraceAndFitCurves_neuron(TimeInfo,fVal,TimeRanges,...
		'FitType','exp1','EventTime',EventTime);

	FittingFlag = NaN(1,numel(yfit));
	for n = 1:numel(yfit)
		yfit(n).lambda = yfit(n).fitinfo_curvefit.b;
		yfit(n).tau = abs(1/yfit(n).lambda);
		FittingFlag(n) = FlagExpCurveFitting(yfit(n).lambda,yfit(n).rsquare,2,rsquare_thresh); % 2 means the decay curves will be flagged
	end

	curvefit = yfit(find(FittingFlag));

	if ~isempty(curvefit)
		tauInfo.vals = [curvefit.tau];
		tauInfo.mean = mean(tauInfo.vals);
		tauInfo.num = numel(tauInfo.vals);
	else
		tauInfo.vals = [];
		tauInfo.mean = NaN;
		tauInfo.num = 0;
	end

	varargout{1} = tauInfo;
end