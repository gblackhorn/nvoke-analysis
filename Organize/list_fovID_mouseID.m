function [ID_list,varargout] = list_fovID_mouseID(recdata,varargin)
% List recording name, fovID and mouseID 
%   varargout shows the stat of fovID and mouseID

	ID_loc = 2; % column num for ID info
	event_loc = 5; % column num for event info

	rec_num = size(recdata, 1);
	ID_list = cell(rec_num, 4);
	ID_list(:, 1) = recdata(:, 1);

	for n = 1:rec_num
		ID_list{n, 2} = recdata{n, ID_loc}.mouseID;
		ID_list{n, 3} = recdata{n, ID_loc}.fovID;

		roi_num = size(recdata{n, event_loc}, 2);
		ID_list{n, 4} = roi_num;
	end
end

