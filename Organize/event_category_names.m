function [event_category_str,varargout] = event_category_names(varargin)
	% return a cell array containing the names of event categories
	% For example: noStim, interval, triggered, noStimFar, etc.
	% the descprition of categories can be returned with varargout
	% Find the details of category definition in the function "organize_category_peaks"

	event_category_str = {'noStim', 'noStimFar', 'triggered', 'triggered_delay', 'rebound', 'interval'};


	% cat_struct contains two fields, name and descipt. 
	cat_struct(1).name = 'noStim';
	cat_struct(1).descipt = 'spontaneous events from recordings without any stimulations';

	cat_struct(2).name = 'noStimFar';
	cat_struct(2).descipt = 'spontaneous events from recordings with stimulation(s), but they appear before first stimulation or after last stimulation+interval_time';

	cat_struct(3).name = 'triggered';
	cat_struct(3).descipt = 'events triggered immediatly by stimulation';

	cat_struct(4).name = 'triggered_delay';
	cat_struct(4).descipt = 'events happens after stimulation with a short delay';

	cat_struct(5).name = 'rebound';
	cat_struct(5).descipt = 'events happens immediatly when stimulation ends';

	cat_struct(6).name = 'interval';
	cat_struct(6).descipt = 'events happens between two stimulations (rebound events excluded)';

	event_category_str = {cat_struct(:).name};
	varargout{1} = cat_struct;
end