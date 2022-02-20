function [num_f1,varargout] = get_num_fieldUniqueContent(structData,varargin)
	% Get the numbers of unique contents in fields (max field nume == 2)
	% if field numer is 2. fn_2 number will be calculated from each unique fn_1
	% varargout{1}: total number of unique num_f2
	% varargout{1}: a vector containing unique numbers of fn_2 from each fn_1

	% field names can be specified with varargin

	% Defaults
	fn_1 = ''; % field name of trial info
	fn_2 = ''; % field name of trial info

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('fn_1', varargin{ii})
	        fn_1 = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('fn_2', varargin{ii})
	        fn_2 = varargin{ii+1};
	    end
	end	

	%% Content
	if ~isempty(fn_1) && isfield(structData, fn_1)
		[uni_f1, ia_f1, ic_f1] = unique({structData.(fn_1)});
		num_f1 = numel(uni_f1);
		num_f2_array = [];
		for nf1 = 1:num_f1
			if ~isempty(fn_2) && isfield(structData, fn_1)
				idxSec = find(ic_f1==nf1); % index of entries of small section
				structDataSec = structData(idxSec); % section of structData
				[uni_f2, ia_f2, ic_f2] = unique({structDataSec.(fn_2)});
				num_uni_f2 = numel(uni_f2);
				num_f2_array = [num_f2_array num_uni_f2];
			end
		end
	else
		error('Error [func get_num_fieldUniqueContent]: \n field %s not found', fn_1);
		return
	end

	if ~isempty(num_f2_array)
		num_f2 = sum(num_f2_array, 'all');
		varargout{1} = num_f2; 
		varargout{2} = num_f2_array;
	end
end