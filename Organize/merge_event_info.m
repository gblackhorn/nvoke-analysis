function [grouped_event_info_merged] = merge_event_info(grouped_event_info,varargin)
	% merge entries in grouped_event_info
	% grouped_event_info is a structure containing field 'group', 'event_info' and 'tag'
	% merge: 
	%	rebound from [OG-LED-5s] and [OG-LED-5s GPIO-1-1s]
	%	trig from [OG-LED-5s] and [OG-LED-5s GPIO-1-1s]

	% Options
	mergeInfo(1).NewGroupName = 'trig [opto]';
	mergeInfo(1).pattern = {'trig [opto]','trig [opto-ap]'};
	mergeInfo(1).patternIdx = NaN(1, numel(mergeInfo(1).pattern));

	mergeInfo(2).NewGroupName = 'trig [EXopto]';
	mergeInfo(2).pattern = {'trig [EXopto]','trig [EXopto-ap]'};
	mergeInfo(2).patternIdx = NaN(1, numel(mergeInfo(2).pattern));

	mergeInfo(3).NewGroupName = 'rebound [opto]';
	mergeInfo(3).pattern = {'rebound [opto]','rebound [opto-ap]'};
	mergeInfo(3).patternIdx = NaN(1, numel(mergeInfo(3).pattern));

	mergeInfo(4).NewGroupName = 'rebound [EXopto]';
	mergeInfo(4).pattern = {'rebound [EXopto]','rebound [EXopto-ap]'};
	mergeInfo(4).patternIdx = NaN(1, numel(mergeInfo(4).pattern));

	mergeInfo(5).NewGroupName = 'opto-delay [opto]';
	mergeInfo(5).pattern = {'opto-delay [opto]','opto-delay [opto-ap]'};
	mergeInfo(5).patternIdx = NaN(1, numel(mergeInfo(5).pattern));

	mergeInfo(6).NewGroupName = 'opto-delay [EXopto]';
	mergeInfo(6).pattern = {'opto-delay [EXopto]','opto-delay [EXopto-ap]'};
	mergeInfo(6).patternIdx = NaN(1, numel(mergeInfo(6).pattern));

	% mergeInfo(7).NewGroupName = 'spon';
	% mergeInfo(7).pattern = {'spon [opto]','spon [opto-ap]', 'spon [EXopto]','spon [EXopto-ap]'};
	% mergeInfo(7).patternIdx = NaN(1, numel(mergeInfo(7).pattern));

	mergeInfo(7).NewGroupName = 'spon [opto]';
	mergeInfo(7).pattern = {'spon [opto]','spon [opto-ap]'};
	mergeInfo(7).patternIdx = NaN(1, numel(mergeInfo(7).pattern));

	mergeInfo(8).NewGroupName = 'spon [EXopto]';
	mergeInfo(8).pattern = {'spon [EXopto]','spon [EXopto-ap]'};
	mergeInfo(8).patternIdx = NaN(1, numel(mergeInfo(8).pattern));

	% mergeInfo(2).NewGroupName = 'rebound [opto]';
	% mergeInfo(2).pattern = {'rebound [opto]','rebound [opto-ap]','rebound [EXopto]','rebound [EXopto-ap]'};
	% mergeInfo(2).patternIdx = NaN(1, numel(mergeInfo(2).pattern));

	% mergeInfo(1).patternIdx = [NaN NaN];
	% mergeInfo(2).patternIdx = [NaN NaN];

	newGroupNum = numel(mergeInfo);

	% Content
	grouped_event_info_merged = grouped_event_info;
	groupNames = {grouped_event_info.group};

	newGroup =  struct('group', cell(1, newGroupNum), 'event_info', cell(1, newGroupNum),...
		'tag', cell(1, newGroupNum));
	dis_newGroup_idx = [];

	for n = 1:newGroupNum
		pattern = mergeInfo(n).pattern;
		ogNum = numel(pattern);
		for ogn = 1:ogNum
			% tf_idx = find(strcmpi(pattern{ogn}, groupNames));
			tf_idx = contains(groupNames, pattern{ogn}, 'IgnoreCase',true);
			if ~isempty(find(tf_idx))
				mergeInfo(n).patternIdx(ogn) = find(tf_idx);
			end
		end
		mergeInfo(n).patternIdx = rmmissing(mergeInfo(n).patternIdx);
		if ~isempty(mergeInfo(n).patternIdx)
			newGroup(n).group = mergeInfo(n).NewGroupName;
			newGroup(n).event_info = grouped_event_info(mergeInfo(n).patternIdx).event_info;
			newGroup(n).tag = mergeInfo(n).pattern;
		else
		% 	newGroup(n) = [];
		dis_newGroup_idx = [dis_newGroup_idx n];
		end
	end
	newGroup(dis_newGroup_idx) = [];

	allOldGroupIdx = [mergeInfo.patternIdx];
	grouped_event_info_merged(allOldGroupIdx) = [];
	grouped_event_info_merged = [grouped_event_info_merged newGroup];
end