function [result,varargout] = analyze_roi_event_possibility(eventProp,varargin)
	% Analyze the possibility of stimulation related events
	% 	- stimulation related events: event_num/stimulation_num
	% 	- In neurons with event1, what other events there are, and what are their possibilities

	% eventProp: structure var, including trial, roi names, stimEvent_possi...
	%		- the content of field "entryStyle" must be "roi"


	% Defaults
	rm_entries = true; % true/false. remove specified entries 
	rm_entry_field = 'peak_category';
	rm_entry_content = 'spon';
	debug_mode = true; % true/false


	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('rm_spon', varargin{ii})
	        rm_spon = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
	    elseif strcmpi('rm_entry_field', varargin{ii})
	        rm_entry_field = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
	    elseif strcmpi('rm_entry_content', varargin{ii})
	        rm_entry_content = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
	    elseif strcmpi('debug_mode', varargin{ii})
	        debug_mode = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
	    end
	end	

	%% Content
	entryStyle = unique({eventProp.entryStyle});
	if ~strcmp(entryStyle,'roi') % Check if eventProp only contains 'roi' info 
		error('function [analyze_roi_event_possibility]:\n field "entryStyle" of input must be "roi"')
	end
	eventProp = filter_structData(eventProp,rm_entry_field,rm_entry_content,0); % removed entries meet the cretieria

	if ~isempty(eventProp) && numel(unique({eventProp.peak_category}))>1

		[TrialRoiList,trial_num,all_roi_num] = get_roiNum_from_eventProp(eventProp,'debug_mode',debug_mode); % Get the trial and roi information

		unique_events = unique({eventProp.peak_category}); % Get the event categories 
		unique_events_num = numel(unique_events);
		event_fnames = cell(1,unique_events_num*3); % each event will have 3 fields: name, num, and fq 
		for uen = 1:unique_events_num
			event_fnames{(uen-1)*3+1} = sprintf('event%d',uen);
			event_fnames{(uen-1)*3+2} = sprintf('event%d_num',uen);
			event_fnames{(uen-1)*3+3} = sprintf('event%d_pb',uen);
		end
		pb_struct_fields = ['trialName','roiName','fovID','stim_repeats','sponfq',...
			event_fnames];
		pb_struct = empty_content_struct(pb_struct_fields,all_roi_num);
		count = 0;
		for tn = 1:trial_num
			trialName = TrialRoiList(tn).trialName;
			trial_data = filter_structData(eventProp,'trialName',trialName,1); % 1 means keep the entries containing the specific trialName
			for rn = 1:TrialRoiList(tn).roi_num
				roiName = TrialRoiList(tn).roi_list{rn};
				roi_data = filter_structData(trial_data,'roiName',roiName,1);
				roi_events = {roi_data.peak_category};



				count = count+1;
				pb_struct(count).trialName = trialName;
				pb_struct(count).roiName = roiName;
				pb_struct(count).fovID = roi_data(1).fovID;
				pb_struct(count).stim_repeats = roi_data(1).stim_repeats;
				pb_struct(count).sponfq = roi_data(1).sponfq;
				pb_struct(count).sponfq = roi_data(1).sponfq;
				for uen = 1:unique_events_num
					pb_struct(count).(event_fnames{(uen-1)*3+1}) = unique_events{uen}; % event categroy name

					% check if current roi has (unique_events{uen})
					roi_event_pos = find(strcmp(roi_events,unique_events{uen}));
					if ~isempty(roi_event_pos)
						pb_struct(count).(event_fnames{(uen-1)*3+2}) = roi_data(roi_event_pos).stimEvent_possi_info.cat_num; % event categroy num
						pb_struct(count).(event_fnames{(uen-1)*3+3}) = roi_data(roi_event_pos).stimEvent_possi_info.cat_possibility; % event categroy frequency
					else
						pb_struct(count).(event_fnames{(uen-1)*3+2}) = 0; % event categroy num
						pb_struct(count).(event_fnames{(uen-1)*3+3}) = 0; % event categroy frequency
					end
				end
			end
		end

		% create "result" var
		pb_cell = (struct2cell(pb_struct))';
		if unique_events_num > 1
			cb_num = factorial(unique_events_num)/(factorial(unique_events_num-2)*factorial(2)); % number of event cateory combinations
		else
			cb_num = 0;
		end
		row_num = unique_events_num+cb_num;

		eventCat = strings(row_num,1);
		unique_events_str = convertCharsToStrings(unique_events');
		eventCat(1:unique_events_num) = unique_events_str;
		eventPb_mean = NaN(row_num,1);
		eventPb_std = NaN(row_num,1);
		eventPb_ste = NaN(row_num,1);
		eventPb_n = NaN(row_num,1);
		eventPb_val = cell(row_num,1);
		eventPb_data = cell(row_num,1);
		cb_count = 1;
		for uen = 1:unique_events_num
			pb_val = [pb_struct.(event_fnames{(uen-1)*3+3})]; % all possibility values including "zeros"
			non_zero_idx = find(pb_val~=0); % positions of entry without zero pb
			pb = pb_struct(non_zero_idx);
			roilist = pb_cell(non_zero_idx,1:5);
			pb_nonzero = pb_val(non_zero_idx);
			eventPb_mean(uen) = mean(pb_nonzero);
			eventPb_std(uen) = std(pb_nonzero);
			eventPb_ste(uen) = std(pb_nonzero)/sqrt(numel(pb_nonzero));
			eventPb_n(uen) = numel(pb_nonzero);
			eventPb_val{uen} = pb_nonzero;
			eventPb_data{uen} = pb;

			if uen<unique_events_num
				for nn = (uen+1):unique_events_num
					pos = unique_events_num+cb_count;
					eventCat(pos) = sprintf('%s and %s',unique_events_str(uen),unique_events_str(nn));
					pb_val_2nd = [pb.(event_fnames{(nn-1)*3+3})];
					non_zero_idx_2nd = find(pb_val_2nd~=0);
					pb_2nd = pb(non_zero_idx_2nd);
					eventPb_n(pos) = numel(pb_2nd);
					eventPb_data{pos} = pb_2nd;
					cb_count = cb_count+1;
				end
			end
		end

		result = table(eventCat,eventPb_mean,eventPb_std,eventPb_ste,eventPb_n,eventPb_val,eventPb_data);

		varargout{1} = pb_struct;
	else
		result = nan;
		varargout{1} = nan;
	end
 end