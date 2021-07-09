function [struct_data_filtered] = filter_struct(struct_data, filter_field, par, varargin)
	% filter a structure array with specified fieldname and parameter
	% filter_field: {fieldname1, fieldname2,...}	
	% par: {[field1_min, field1_max], 'non-zero'}. 1x2 double or 'non-zero' (keep non-zero elements)
	% Note: Use NaN to replace one of the values in [field1_min, field1_max] to not set min or max


	% Defaults
	discard_empty = true;

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('discard_empty', varargin{ii})
	        discard_empty = varargin{ii+1};
	    end
	end


	for fn = 1:numel(filter_field)
		field_name = filter_field{fn};
		field_par = par{fn};

		if discard_empty
			idx_empty = find(cellfun(@isempty, {struct_data.(field_name)}));
			struct_data(idx_empty) = [];
		end

		idx_discard = [];
		if ~isstr(field_par)
			par_num = numel(field_par);
			if par_num == 2
				if ~isnan(field_par(1))
					idx_found = find([struct_data.(field_name)>=field_par(1)]);
					idx_discard = [idx_discard idx_found];
				end
				if ~isnan(field_par(2))
					idx_found = find([struct_data.(field_name)<=field_par(1)]);
					idx_discard = [idx_discard idx_found];
				end
				struct_data(idx_discard) = [];
			else
				error('input [min max] as parameter')
			end
		else
			if strcmpi(field_par, 'notzero')
				idx_found = find([struct_data.(field_name)]==0);
				idx_discard = [idx_discard idx_found];
				struct_data(idx_discard) = [];
			else
				error('input [min max] or "notzero" as parameter')
			end
		end
	end
	struct_data_filtered = struct_data;
end