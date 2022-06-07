function [stimEvent_possibility,varargout] = get_stimEvent_possibility(eventCats,stim_num,varargin)
% Return a structure containing the possibility of stimulation related events

% eventCats: cell array containing categories of all events in a ROI
% stim_num: the repeat number of stimulation applied to a ROI
% stimEvent_possibility: structure var. Each entry contains the name of event category and the possibility of the event

	% Defaults
	stim_name = ''; % if not empty, stim_name will be combined to category name and added to stimEvent_possibility
	% cat_exclude = ''; % categories containing this string will be excluded from the calculation
	debug_mode = false; % true/false


	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('stim_name', varargin{ii})
	        stim_name = varargin{ii+1}; % if not empty, cat_name will become cat_name[stim_name]
	    % elseif strcmpi('cat_exclude', varargin{ii})
	    %     cat_exclude = varargin{ii+1}; 
	    elseif strcmpi('debug_mode', varargin{ii})
	        debug_mode = varargin{ii+1}; 
	    end
	end

	% ====================
	% Main contents
	% if ~isempty(cat_exclude) % exclude entries in eventCats from calculation according to cat_exclude contents
	% 	if isa(cat_exclude,'char') % convert the cat_exclude to cell if it is a 'char' var
	% 		cat_exclude = {cat_exclude};
	% 	end
	% 	cat_exclude_num = numel(cat_exclude);
	% 	for en = 1:cat_exclude_num
	% 		exclude_pattern = cat_exclude{en};
	% 		tf_exclude = contains(eventCats,exclude_pattern);
	% 		idx_exclude = find(tf_exclude);
	% 		eventCats(idx_exclude) = '';
	% 	end
	% end

	cats_unique = unique(eventCats);
	unique_cat_num = numel(cats_unique);
	stimEvent_possibility = struct('cat_name',cell(1,unique_cat_num),'cat_num',cell(1,unique_cat_num),...
		'stim_num',cell(1,unique_cat_num),'cat_possibility',cell(1,unique_cat_num));
	if ~isempty(cats_unique)
		for cn = 1:unique_cat_num
			if ~isempty(stim_name)
				stimEvent_possibility(cn).cat_name = sprintf('%s[%s]',cats_unique{cn},stim_name);
			else
				stimEvent_possibility(cn).cat_name = cats_unique{cn};
			end
			cat_tf = strcmp(eventCats,cats_unique{cn});
			stimEvent_possibility(cn).cat_num = numel(find(cat_tf));
			stimEvent_possibility(cn).stim_num = stim_num;
			stimEvent_possibility(cn).cat_possibility = stimEvent_possibility(cn).cat_num/stimEvent_possibility(cn).stim_num;
		end
	end
end
