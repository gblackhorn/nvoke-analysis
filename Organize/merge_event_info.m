function [grouped_event_info_merged] = merge_event_info(grouped_event_info,varargin)
	% merge entries in grouped_event_info
	% grouped_event_info is a structure containing field 'group', 'event_info' and 'tag'
	% merge: 
	%	rebound from [OG-LED-5s] and [OG-LED-5s GPIO-1-1s]
	%	trig from [OG-LED-5s] and [OG-LED-5s GPIO-1-1s]

	% Options
	mergeInfo(1).NewGroupName = 'trig [opto]';
	mergeInfo(2).NewGroupName = 'rebound [opto]';
	mergeInfo(1).pattern = {'trig [OG-LED-5s]', 'trig [OG-LED-5s GPIO-1-1s]'};
	mergeInfo(2).pattern = {'rebound [OG-LED-5s]', 'rebound [OG-LED-5s GPIO-1-1s]'};
	mergeInfo(1).patternIdx = [NaN NaN];
	mergeInfo(2).patternIdx = [NaN NaN];
	
	newGroupNum = numel(mergeInfo);

	% Content
	grouped_event_info_merged = grouped_event_info;
	groupNames = {grouped_event_info.group};

	for n = 1:newGroupNum
		pattern = mergeInfo(n).pattern;
		ogNum = numel(pattern);
		for ogn = 1:ogNum
			% tf_idx = find(strcmpi(pattern{ogn}, groupNames));
			tf_idx = contains(groupNames, pattern{ogn}, 'IgnoreCase',true);
			if ~isempty(tf_idx)
				mergeInfo(n).patternIdx(ogn) = find(tf_idx);
			end
		end
		mergeInfo(n).patternIdx = rmmissing(mergeInfo(n).patternIdx);
		if ~isempty(mergeInfo(n).patternIdx)
			newGroup(n).group = mergeInfo(n).NewGroupName;
			newGroup(n).event_info = grouped_event_info(mergeInfo(n).patternIdx).event_info;
			newGroup(n).tag = mergeInfo(n).pattern;
		end
	end

	allOldGroupIdx = [mergeInfo.patternIdx];
	grouped_event_info_merged(allOldGroupIdx) = [];
	grouped_event_info_merged = [grouped_event_info_merged newGroup];
end