function [] = superImpTraces(traceData,varargin)
% Plot overlaped traces. 
%   Optional: varargin{1}-plotMean, plot a shade represent the average and standard error
%	traceData is a vertical cell array (2 col in each: time and value) in case traces have different size

	if nargin == 1
		plotMean = 0;
	elseif nargin == 2
		plotMean = varargin{2};
	elseif nargin > 2
		disp('Too many inputs. Only input 1 (traceData) or 2 (to specify whether plot mean value).')
		return
	end

	% get the min and max value of timeInfo and traceVal for seting xlim and ylim of plot
	xMins = cellfun(@(x) min(x(:, 1)), traceData); 
	xMaxs = cellfun(@(x) max(x(:, 1)), traceData);
	yMins = cellfun(@(x) min(x(:, 2)), traceData);
	yMaxs = cellfun(@(x) max(x(:, 2)), traceData);
	xMin = min(xMins);
	xMax = max(xMaxs);
	yMin = min(yMins);
	yMax = max(yMaxs);
	y_extra = (yMax-yMin)/10;
	yMin = yMin-y_extra;
	yMax = yMax+y_extra;

	% Plot
	gca;
	hold on
	traceNum = size(traceData, 1);
	for tn = 1:traceNum
		plot(traceData{tn}(:, 1), traceData{tn}(:, 2), 'Color', '#2D2B36');
	end
	xlim([xMin xMax])
	ylim([yMin yMax])
end

