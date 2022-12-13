function [FittingFlag,varargout] = FlagExpCurveFitting(lambda,rsquare,RiseDecay,rsquare_thresh)
	% Flag an exponential curve fitting with creterias

	% exponantial model: val(x) = A*exp(lambda*x)
	% tau = |1/lambda|. tau is time constant

	% rsquare: coefficient of determination (0.7 means 70% of the dependent var is predicted by the
	% independent variable) 

	% lambda and rsquare (Coefficient of determination) from the curve fitting are used to decide
	% the flag val: true/false


	% [flag] = FlagExpCurveFitting(lambda,rsquare,RiseDecay,rsquare_thresh): When lambda meets the
	% creteria of RiseDecay (positive if RiseDecay is 1, negative if RiseDecay is 2), and when
	% rsquare is larger than rsquare_thresh (default value is 0.7)


	% Defaults
	if nargin < 3
		error('MATLAB:notEnoughInputs','Not enough input arguments.')
	elseif nargin == 3
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


	%% Decide the flag value
	if RiseDecay == 1
		if lambda > 0
			flag_lambda = true;
		else
			flag_lambda = false;
		end
	elseif RiseDecay == 2
		if lambda < 0
			flag_lambda = true;
		else
			flag_lambda = false;
		end
	end

	if rsquare >= rsquare_thresh
		flag_rsquare = true;
	else
		flag_rsquare = false;
	end

	if flag_lambda && flag_rsquare
		FittingFlag = true;
	else
		FittingFlag = false;
	end
end