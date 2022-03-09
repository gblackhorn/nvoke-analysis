function [event_category_str,varargout] = event_category_names(varargin)
	% This function stores the strings of peak categories

	% noStim: events from recordings without any stimulations
	% beforeStim: events appearing before applying the first stim in a recording
	% interval: events appearing between stimulations. events after the last stim also included
	% trigger: events appearing immediatly after the onset of a stim
	% delay: events appearing during a stim but not immediatly after its onset
	% rebound: events appearing immediatly after the end of a stim

	% event_category_str = {'noStim', 'beforeStim', 'interval',...
	% 'trigger', 'delay', 'rebound'};


	% cat_struct contains two fields, name and descipt. 
	cat_struct(1).name = 'noStim';
	cat_struct(1).descipt = 'events from recordings without any stimulations';

	cat_struct(2).name = 'beforeStim';
	cat_struct(2).descipt = 'events appearing before applying the first stim in a recording';

	cat_struct(3).name = 'interval';
	cat_struct(3).descipt = 'events appearing between stimulations. events after the last stim also included';

	cat_struct(4).name = 'trigger';
	cat_struct(4).descipt = 'events appearing immediatly after the onset of a stim';

	cat_struct(5).name = 'delay';
	cat_struct(5).descipt = 'events appearing during a stim but not immediatly after its onset';

	cat_struct(6).name = 'rebound';
	cat_struct(6).descipt = 'events appearing immediatly after the end of a stim';

	event_category_str = {cat_struct(:).name};
	varargout{1} = cat_struct;
	varargout{2} = numel(cat_struct);
end