function [StimDuration,varargout] = ExtractStimDurationAndExtraInfo(StimRange,varargin)
	%Calculate the stimulation durations (unit: second) using the stimulation time range 

	% [StimDuration] = CalculateStimDuration(StimRange) StimRange is a nx2 numeric array
	% containing the starts and the ends of stimulation, or a cell array containing multiple
	% numeric arrays (more than one types of stimulation applied). StimDuration is a structure containing
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
	%	ExtraInfo.type_order: sort the type of stimulations according to their start time. This can be 
	%		used to create the name for unified stimulation to avoid something like 'ap og' vs 'og ap'. 


	% Defaults
	round_digit_sig = 2; % round to the Nth significant digit for duration

	% Optionals
	if nargin == 2
		round_digit_sig = varargin{1};

	%% Content
	if iscell(StimRange)
		stimtype_num = numel(StimRange);
	else
		stimtype_num = 1;
	end

	ExtraInfo = empty_content_struct({'multistim','stimtype_num','type_order'});

	ExtraInfo(1).stimtype_num = stimtype_num;
	if stimtype_num == 1
		ExtraInfo(1).multistim = false;
	else
		ExtraInfo(1).multistim = true;
	end

	stim_start_time = NaN(1, stimtype_num); % This is used to create unified/combined stimulation ranges and durations
	stim_end_time = NaN(1, stimtype_num); % This is used to create unified/combined stimulation ranges and durations

	for stn = 1:stimtype_num % loop through every stimulation type
		TimeRange = StimRange{stn};
		% if ExtraInfo(1).multistim
		% 	TimeRange = StimRange{stn};
		% else
		% 	TimeRange = StimRange;
		% end

		% Calculate and round the durations
		[StimDuration(stn)] = CalculateStimDuration(TimeRange,round_digit_sig);
		stim_start_time(stn) = StimDuration(stn).range(1,1); % the start time of very first stimulation for each type 
		stim_end_time(stn) = StimDuration(stn).range(1,2); % the start time of very first stimulation for each type 
	end

	if ~ExtraInfo.multistim
		UnifiedStimDuration = StimDuration;
	else
		[~, stim_start_order] = sort(stim_start_time); % When various stim applied, use the one start early as the stim_start
		stim_start_first_loc = stim_start_order(1);
		ExtraInfo(1).type_order = stim_start_order;

		[~, stim_end_order] = sort(stim_end_time,'descend'); % When various stim applied, use the one end late as the stim_end
		stim_end_first_loc = stim_end_order(1);

		UnifiedStimDuration(1).range = [StimDuration(stim_start_first_loc).range(:,1) StimDuration(stim_end_first_loc).range(:,2)];

		[UnifiedStimDuration] = CalculateStimDuration(UnifiedStimDuration.range,round_digit_sig);
	end

	varargout{1} = UnifiedStimDuration;
	varargout{2} = ExtraInfo;
end
