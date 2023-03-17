function [pVal,varargout] = unpaired_ttest_cellArray(cellArrayA,cellArrayB,varargin)
	% Run unpaired ttest on each pairs of cellArrayA(n) and cellArrayB(n)


	% Defaults

	% Optionals
	% for ii = 1:2:(nargin-3)
	%     if strcmpi('errorA', varargin{ii})
	%         errorA = varargin{ii+1}; % number array used to plot error bar for meanA
	%     elseif strcmpi('errorB', varargin{ii})
	%         errorB = varargin{ii+1}; % number array used to plot error bar for meanB
	%     end
	% end

	% Get the idx of entry by finding the stimName in barStat.stim
	% Preallocate array to store p-values
	% Preallocate array to store p-values

	% Keep data in group A and B the same size (use the shorter one)
	sizeA = numel(cellArrayA);
	sizeB = numel(cellArrayB);
	sizeSmaller = min(sizeA,sizeB);
	cellArrayA = cellArrayA(1:sizeSmaller);
	cellArrayB = cellArrayB(1:sizeSmaller);

	% Preallocate array to store p-values
	pVal = NaN(1,sizeSmaller);

	% Perform unpaired t-test for each pair of elements
	for n = 1:sizeSmaller
	    % Get the corresponding elements from cell1 and cell2
	    dataA = cellArrayA{n};
	    dataB = cellArrayB{n};
	    
	    % Perform unpaired t-test
	    [h, p, ci, stats] = ttest2(dataA, dataB);
	    
	    % Store the p-value in the p_values array
	    pVal(n) = p;
	end

	% % Display p-values
	% disp(pVal)
end
