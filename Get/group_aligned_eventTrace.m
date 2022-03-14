function [grouped_alignedTrace,varargout] = group_aligned_eventTrace(alignedTrace,peakCategories,varargin)
	% Get the index of events belongs to different categories

	% alignedTrace: a matrix. size: traceLength*traceNum
	% peakCategories: cell array containing strings of peak category names. Usually arranged chronologically

	% Defaults
	pc_norm = 'spon'; % alignedTrace will be normalized to the average value of this event category
	amp_data = []; % a vector array having the same length as peakCategories
	normData = true; % whether normalize alignedTrace with average value of pc_norm data

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('pc_norm', varargin{ii})
	        pc_norm = varargin{ii+1}; 
	    elseif strcmpi('amp_data', varargin{ii})
	        amp_data = varargin{ii+1};
	    elseif strcmpi('normData', varargin{ii})
	        normData = varargin{ii+1};
	    end
	end	

	%% Content
	[category_idx, catNum, catName] = get_eventCategory_idx(peakCategories);

	if ~isempty(pc_norm) && ~isempty(amp_data)
		pc_norm_loc = find(strcmpi(pc_norm, catName));
		if isempty(pc_norm_loc)
			normData = false;
			fprintf('Warning [func group_aligned_eventTrace]: \n pc_norm (%s) not found in peak categories',...
				pc_norm);
		end
	else
		normData = false;
	end

	if normData
		pc_norm_data = amp_data(category_idx(pc_norm_loc).idx);
		if ~isempty(pc_norm_data)
			pc_norm_val = mean(pc_norm_data);
			alignedTrace = alignedTrace/pc_norm_val;
		else
			fprintf('Warning [func group_aligned_eventTrace]: \n peakCat(%s) data is empty',...
				pc_norm);
		end
	end

	grouped_alignedTrace = struct('group', cell(1, catNum), 'alignedTrace', cell(1, catNum));
	for n = 1:catNum
		grouped_alignedTrace(n).group = category_idx(n).name;
		grouped_alignedTrace(n).alignedTrace = alignedTrace(category_idx(n).idx);
	end
end