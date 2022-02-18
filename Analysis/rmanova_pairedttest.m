function [ranovatbl,pvalueGG,h,pairedttesttbl,varargout] = rmanova_pairedttest(repeatedMeasures,varargin)
	% Analyze the repeated measures along time with "repeated measures anova", and run paired t-test for each pairs
	% repeatedMeasures: each row contains one subject, ROI. each column contains one measures of multiple subjects.
	% Note: 
	%	- if experient design is "multiple measurements over time", do not assume sphericity. 
	%	- if sphericity is not assumed, use adjusted p-values in the ranovatbl, output of func ranova
	%	- pValueGG (p-value with Greenhouse-Geisser adjustment) is recommended
	%	- There is no consensus for a proper multiple comparison after the repeated measures anova. Prisma uses essentially paired t-test


	% Defaults
	a = 0.05; % alpha for significance

	% Optionals
	% for ii = 1:2:(nargin-1)
	    % if strcmpi('groupNames', varargin{ii})
	    %     groupNames = varargin{ii+1};
        % % elseif strcmpi('nonstimMean_pos', varargin{ii})
        % %     nonstimMean_pos = varargin{ii+1};
	%     end
	% end

	% ====================
	% Main content
	repeatNum = size(repeatedMeasures,2);
	string = num2cell([1:repeatNum]);
	string = cellfun(@(x) ['t', num2str(x)], string, 'UniformOutput',false);
	repeatedMeasuresT = array2table(repeatedMeasures, 'VariableNames', string); % prepare rm table for rmanova
	Time = [1:repeatNum]';
	rmModel = sprintf('%s-%s ~ 1', repeatedMeasuresT.Properties.VariableNames{1}, repeatedMeasuresT.Properties.VariableNames{end});
	rm = fitrm(repeatedMeasuresT,rmModel,'WithinDesign',Time);
	[ranovatbl,A,C,D] = ranova(rm);
	pvalueGG = ranovatbl{1, 'pValueGG'}; % p-value with Greenhouse-Geisser adjustment.

	if pvalueGG < 0.05
		h = 1;
		combinationNum = factorial(repeatNum)/(factorial(2)*factorial(repeatNum-2));
		pairedttestcell = cell(combinationNum, 4);
		combination_n = 1;
		for mxn = 1:(repeatNum-1) % measure x number
			for myn = mxn+1:repeatNum % measure y number
				mx = repeatedMeasures(:, mxn);
				my = repeatedMeasures(:, myn);
				[h_pairedttest, p_pairedttest] = ttest(mx, my);

				pairedttestcell{combination_n, 1} = string{mxn};
				pairedttestcell{combination_n, 2} = string{myn};
				pairedttestcell{combination_n, 3} = h_pairedttest;
				pairedttestcell{combination_n, 4} = p_pairedttest;

				combination_n = combination_n+1;
			end
		end
		pairedttesttbl = cell2table(pairedttestcell,...
			'VariableNames',{'measureX' 'measureY' 'hypothesisResult' 'pValue'});
	else
		h = 0;
		pairedttesttbl = [];
	end
end
