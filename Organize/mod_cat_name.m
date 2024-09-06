function [event_info,varargout] = mod_cat_name(event_info,varargin)
	% modify the category names of events
	% This is for easier grouping of events in the following analysis steps
	% common categories include: "fovID" and "peak_category" 
	% 
	% triggered peak: peak start to rise in 2s (or stim duration if it is smaller than 2) from onset of stim. 
	% rebound peak: peak start to rise in 1s from end of stim

	% Defaults
	stimType = true; % true/false. Whether consider stimulation type when modifying the categories
	seperate_spon = false; % if stimType is true, whether add stim info to spon group
	dis_extra = true; % true/false. If old category name is not found in any catNameOld groups

	% Settings for modifying the category. This can be input with varargin
	% each cell in catNameOld should pair with one cat_names element sharing the same index
	cat_type = 'peak_category'; % 'fovID', 'peak_category'

	EventCat_OldNew = CaImg_char_pat('event_group');
	catNameNew = EventCat_OldNew.new;
	catNameOld = EventCat_OldNew.old;
	cat_num = numel(catNameNew);
	% catNameNew = {'spon', 'trig', 'trig-AP', 'opto-delay', 'rebound'}; % new category names
	% cat_num = numel(catNameNew);
	% catNameOld = cell(cat_num, 1); % each cell contains old categories which will be grouped together
	% catNameOld{1} = {'noStim', 'beforeStim', 'interval',...
	% 	'beforeStim-beforeStim', 'interval-interval'}; % spon
	% catNameOld{2} = {'trigger', 'trigger-beforeStim', 'trigger-interval'}; % trig
	% catNameOld{3} = {'delay-trigger'}; % trig-AP
	% catNameOld{4} = {'delay', 'delay-rebound', 'delay-interval', 'delay-beforeStim'}; % delay. 'delay-delay', 
	% catNameOld{5} = {'rebound', 'rebound-interval'}; % rebound

	add_extra = 'stim_name'; % add info in event_info.(add_extra) to the category name;

	cat_setting = '';

	debug_mode = false;

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('cat_setting', varargin{ii})
	        cat_setting = varargin{ii+1}; % struct var including fields 'cat_type', 'catNameNew' and 'catNameOld'
        elseif strcmpi('dis_extra', varargin{ii})
	        dis_extra = varargin{ii+1};
        elseif strcmpi('stimType', varargin{ii})
            stimType = varargin{ii+1};
        elseif strcmpi('seperate_spon', varargin{ii})
            seperate_spon = varargin{ii+1};
	    end
	end

	if ~isempty(cat_setting)
		cat_type = cat_setting.cat_type;
		catNameNew = cat_setting.catNameNew;
		cat_num = numel(catNameNew);
		catNameOld = cat_setting.catNameOld;
	end

	%% ====================
	% Main content
	event_num = numel(event_info);
	dis_idx = zeros(event_num);

	for n = 1:event_num

		if debug_mode
			fprintf('func [mod_cat_name] processing event %d\n', n)
		end

		mod_name = false; % mark if the cat name has been modified
		old_name = event_info(n).(cat_type);
		tf_newName = strcmpi(old_name, catNameNew); % check if the category name is already modified
		if isempty(find(tf_newName, 1))
			for cn = 1:cat_num
				tf = strcmpi(old_name, catNameOld{cn});
				if ~isempty(find(tf, 1))
					new_name = catNameNew{cn};
					tf_newName = true;

					mod_name = true;
					break
                else
                    new_name = old_name;
				end
			end
			if ~mod_name
				dis_idx(n) = 1;
			end
		else
			new_name = old_name;
		end

		spon_tf = strcmpi('spon', new_name);
		if stimType
			addStim_tf = true;
			if spon_tf
				if ~seperate_spon
					addStim_tf = false;
				end
			end
		else
			addStim_tf = false;
		end
		if addStim_tf && isfield(event_info(n), add_extra)
			new_name = sprintf('%s [%s]', new_name, event_info(n).(add_extra));
		end

		event_info(n).(cat_type) = new_name;
	end

	if dis_extra
		event_info(find(dis_idx)) = [];
	end
end
