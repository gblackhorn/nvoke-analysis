function [grouped_event,varargout] = get_and_collect_events_from_alignedData(alignedData,unit,mgsettings,varargin)
	% Get events from alignedData and group them

	% alignedData: a structure var, created by function [get_event_trace_allTrials]
	% unit: 'roi'/'event'. 
		% 'roi': events from a ROI are stored in a length-1 struct. mean values were calculated. 
		% 'event': events are seperated (struct length = events_num). mean values were not calculated
	% mgsettings: used to adjust what events will be collected and how to group them 


	% Defaults
	mgsettings.modify_stim_name = true; % true/false. Change the stimulation name, 
                            % such as GPIOxxx and OG-LEDxxx (output from nVoke), to simpler ones (ap, og, etc.)
	mgsettings.sponOnly = false; % true/false. If eventType is 'roi', and mgsettings.sponOnly is true. Only keep spon entries
	mgsettings.seperate_spon = true; % true/false. Whether to seperated spon according to stimualtion
	mgsettings.dis_spon = false; % true/false. Discard spontaneous events
	mgsettings.modify_eventType_name = true; % Modify event type using function [mod_cat_name]
	mgsettings.groupField = {'stim_name', 'peak_category'}; % options: 'fovID', 'stim_name', 'peak_category'; Field of eventProp_all used to group events 

	% rename the stimulation tag if og evokes spike at the onset of stimulation
	mgsettings.mark_EXog = false; % true/false. if true, rename the og to EXog if the value of field 'stimTrig' is 1
	mgsettings.og_tag = {'og', 'og&ap'}; % find og events with these strings. 'og' to 'Exog', 'og&ap' to 'EXog&ap'

	% arrange the order of group entries using function [sort_struct_with_str] with mgsettings below. 
	mgsettings.sort_order = {'spon', 'trig', 'rebound', 'delay'}; % 'spon', 'trig', 'rebound', 'delay'
	mgsettings.sort_order_plus = {'ap', 'EXopto'};
	debug_mode = false; % true/false


	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('plotWhere', varargin{ii})
	        plotWhere = varargin{ii+1};
	    elseif strcmpi('debug_mode', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	        debug_mode = varargin{ii+1}; % output of stim_effect_compare_trace_mean_alltrial
	    % elseif strcmpi('guiSave', varargin{ii})
        %     guiSave = varargin{ii+1};
	    % elseif strcmpi('fname', varargin{ii})
        %     fname = varargin{ii+1};
	    end
	end


	% Collect events from alignedData
	[eventProp_all]=collect_events_from_alignedData(alignedData,...
		'entry',unit,'modify_stim_name',mgsettings.modify_stim_name);


	% Group events
	[grouped_event,grouped_event_setting] = mod_and_group_eventProp(eventProp_all,unit,[],...
		'mgSetting',mgsettings,'debug_mode',debug_mode);

	% Add roi numbers
	[grouped_event_setting.TrialRoiList] = get_roiNum_from_eventProp_fieldgroup(eventProp_all,'stim_name'); % calculate all roi number


	if strcmpi(unit,'roi')
		GroupNum = numel(grouped_event);
		% GroupName = {grouped_event.group};
		for gn = 1:GroupNum
			EventInfo = grouped_event(gn).event_info;
			fovIDs = {EventInfo.fovID};
			roi_num = numel(fovIDs);
			fovIDs_unique = unique(fovIDs);
			fovIDs_unique_num = numel(fovIDs_unique);
			fovID_count_struct = empty_content_struct({'fovID','numROI','perc'},fovIDs_unique_num);
			[fovID_count_struct.fovID] = fovIDs_unique{:};
			for fn = 1:fovIDs_unique_num
				fovID_count_struct(fn).numROI = numel(find(contains(fovIDs,fovID_count_struct(fn).fovID)));
				fovID_count_struct(fn).perc = fovID_count_struct(fn).numROI/roi_num;
			end
			grouped_event(gn).fovCount = fovID_count_struct;
		end
	end

	varargout{1} = grouped_event_setting;
end