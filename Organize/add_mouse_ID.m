function [rec_data,varargout] = add_mouse_ID(rec_data,varargin)
	% Automatic generate and add mouseIDs to rec_data cell array
	% recordings from the same day are considered taken from the same animal

	rec_name_col = 1;
	rec_data_col = 2;


	% Defaults
	% overwrite = false;
	% generate = false;

	% Optionals
	% for ii = 1:2:(nargin-1)
 %    	if strcmpi('overwrite', varargin{ii})
 %    		overwrite = varargin{ii+1};
 %    	end
 %    end

    % Main content
    % data_1st_rec_trial = rec_data{1, rec_data_col}; % Check the existence of mouseID and fovID in the first recording
    % TF_mouseID = isfield(data_1st_rec_trial, 'mouseID'); % mouseID true/false
    % TF_fovID = isfield(data_1st_rec_trial, 'fovID'); % fovID true/false

    % if overwrite
    % 	generate = true;
    % else
    % 	if ~TF_mouseID || ~TF_fovID
    % 		generate = true;
    % 	end
    % end

	rec_num = size(rec_data, 1);
	% mouseIDs = cell(size(rec_data, 1), 1);

	rec_dates = cellfun(@(x) x(1:8), rec_data(:, rec_name_col), 'UniformOutput',false); 
	[unique_dates, ~, i_dates] = unique(rec_dates, 'stable');
	unique_mouseIDs = cell(numel(unique_dates), 1);
	% unique_i_dates = unique(i_dates);

	for n = (unique(i_dates))'
		 unique_mouseIDs{n} = sprintf('mouse-%d', n); 
	end

	mouseIDs = unique_mouseIDs(i_dates);
	for rn = 1:rec_num
		rec_data{rn, rec_data_col}.mouseID = mouseIDs{rn};
	end


	varargout{1} = mouseIDs;
end