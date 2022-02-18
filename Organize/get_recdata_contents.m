function [content,varargout] = get_recdata_contents(rec_data,element,varargin)
	% Return content in a single recording data specified by "element" keyword
	% 
	element_choices = {'fov', 'stim', 'gpio'};
	choice = find(strcmpi(element_choices, element));
	rec_data_name = char(rec_data{1});
	content = [];
	element_exist = true;
	suppress_warning = false;

	for ii = 1:2:(nargin-2)
		if strcmpi('suppress_warning', varargin{ii})
			suppress_warning = varargin{ii+1};
		end
	end

	switch choice
		case 1 % fov
			try
				content = rec_data{2}.FOV_loc;
			catch
				if ~suppress_warning
					warning('Error. \nRecording %s does not have element: %s',...
						rec_data_name, element_choices{choice});
				end
				element_exist = false;
			end
		case 2 % stim
			try
				content = char(rec_data{3});
			catch
				if ~suppress_warning
					warning('Error. \nRecording %s does not have element: %s',...
						rec_data_name, element_choices{choice});
				end
				element_exist = false;
			end
		case 3 % gpio
			try
				content = rec_data{4};
			catch
				if ~suppress_warning
					warning('Error. \nRecording %s does not have element: %s',...
						rec_data_name, element_choices{choice});
				end
				element_exist = false;
			end
		otherwise
			error('Error. \nInput one of the following for "element": fov, stim, gpio')
	end

	varargout{1} = element_exist;
end
