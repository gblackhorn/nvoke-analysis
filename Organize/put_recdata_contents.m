function [rec_data_updated,varargout] = put_recdata_contents(rec_data,element,element_content,varargin)
	% Return content in a single recording data specified by "element" keyword
	% 
	element_choices = {'fov', 'stim', 'gpio'};
	choice = find(strcmpi(element_choices, element));
	rec_data_name = char(rec_data{1});

	
	% content = [];
	% element_exist = true;

	switch choice
		case 1 % fov
			rec_data{2}.FOV_loc = element_content;
		case 2 % stim
            rec_data{3} = [];
			rec_data{3}{1} = element_content;
		case 3 % gpio
			rec_data{4} = element_content;
		otherwise
			error('Error. \nInput one of the following for "element": fov, stim, gpio')
	end

	rec_data_updated = rec_data;
	% fprintf('%s in recording %s has been updated\n',...
	% 	element, rec_data_name);
	% varargout{1} = element_exist;
end
