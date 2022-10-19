function [StimDuration,varargout] = CalculateStimDuration(TimeRange,varargin)
	%Calculate the stimulation durations (unit: second) using the stimulation time range 

	% [StimDuration] = CalculateStimDuration(TimeRange) TimeRange is a nx2 numeric array
	% containing the starts and the ends of stimulation. StimDuration is a structure containing
	% fields: 
	% 	StimDuration.array: numeric array containing the durations for stimulations. 
	%	StimDuration.fixed: a single number if all the durations are the same. NaN if not.
	%	StimDuration.fixed_loc: index of the 'fixed' durations in 'array'.
	%		For example: array = [1 3 4 3 1 4]; fixed = [1 3 4]; fixed_loc = {[1,5],[2,4],[3,6]};
	%	StimDuration.range: stimulation ranges for each type
	%	StimDuration.varied: true if all durations are the same
	%	StimDuration.repeats: a single number if all the durations are the same. A numeric array if 
	%		durations are varied. A cell array if multiple stimulation types applied.


	% [StimDuration] = CalculateStimDuration(StimRange,N) Round the (round_digit_sig)th significant
	% digit for duration. If round_digit_sig is not input, default number is 2.

	% [StimDuration,UnifiedStimDuration] = CalculateStimDuration(StimRange) UnifiedStimDuration
	% contains following fields:
	% 	UnifiedStimDuration.array: if only one type of stimulation applied, same as StimDuration.array.
	%		If multiple types applied (airpuff+OG), combine the durations.
	%	UnifiedStimDuration.fixed: if only one type of stimulation applied, same as StimDuration.fixed.
	%		If multiple types applied (airpuff+OG), combine the durations.
	%	StimDuration.fixed_loc: index of the 'fixed' durations in 'array'.
	%	UnifiedStimDuration.range: stimulation ranges for the unified stimulation
	%	UnifiedStimDuration.varied: true if all durations are the same
	%	UnifiedStimDuration.repeats: a single number if all the durations are the same. A numeric array if 
	%		durations are varied. A cell array if multiple stimulation types applied.


	% [StimDuration,UnifiedStimDuration,ExtraInfo] = CalculateStimDuration(StimRange) ExtraInfo
	% contains following fields:
	%	ExtraInfo.multistim: true if multiple types of stimulations applied
	%	ExtraInfo.stimtype_num: the number of stimulation types. For example, 2 if airpuff and og are applied
	%	ExtraInfo.varied: true if all durations are the same


	% Defaults
	round_digit_sig = 2; % round to the Nth significant digit for duration

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('round_digit_sig', varargin{ii})
	        round_digit_sig = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
	    end
	end	

	%% Content
	StimDuration = empty_content_struct({'array','fixed','fixed_loc','range','varied','repeats'},stimtype_num);	

	StimDuration(stn).array = round(TimeRange(:,2)-TimeRange(:,1),round_digit_sig,'significant');
	StimDuration(stn).range = TimeRange(:,1)+StimDuration(stn).array; % stimulation range [starts; (starts+durations)]
	if all(StimDuration(stn).array == StimDuration(stn).array(1))
		StimDuration.varied = false;
		StimDuration(stn).fixed = StimDuration(stn).array(1);
		StimDuration(stn).fixed_loc = {[1:numel(StimDuration(stn).array)]};
		StimDuration(stn).repeats = numel(StimDuration(stn).array);
	else
		StimDuration.varied = true;
		[StimDuration(stn).fixed,idx_array,idx_fixed] = unique(StimDuration(stn).array);
		num_uniq_durations = numel(StimDuration(stn).fixed; % number of unique durations (fixed)
		StimDuration(stn).fixed_loc = cell(num_uniq_durations,1);
		StimDuration(stn).repeats = NaN(num_uniq_durations,1);
		for fn = 1:numel(num_uniq_durations) % go through the unique durations
			StimDuration(stn).fixed_loc{fn} = find(StimDuration(stn).array==StimDuration(stn).fixed(fn));
			StimDuration(stn).repeats(fn) = numel(StimDuration(stn).fixed_loc{fn});
		end
	end
end
