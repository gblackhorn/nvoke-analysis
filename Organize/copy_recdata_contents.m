function [receiver_updated,varargout] = copy_recdata_contents(source,receiver,element,varargin)
	% Find receiver recordings in source and fetch centain content from source
	% element: fov, stim, gpio


	% Defaults
	overwrite = false;

	% Optionals for inputs
	for ii = 1:2:(nargin-3)
		% if strcmpi('content', varargin{ii})
		% 	content = varargin{ii+1}; % recording frequency
		if strcmpi('overwrite', varargin{ii})
			overwrite = varargin{ii+1}; % recording frequency
		% elseif strcmpi('save_contours', varargin{ii})
		% 	save_contours = varargin{ii+1}; % recording frequency
		end
	end

	% Main content
	receiver_updated = receiver;
	rec_num = size(receiver, 1);
	source_rec_names = source(:, 1);

	for n = 1:rec_num
		rec = receiver(n, :);
		rec_name = rec{1};
		rec_idx_in_source = find(strcmp(rec_name, source_rec_names));
		source_rec = source(rec_idx_in_source, :);

		[source_rec_content, source_rec_content_exist] = get_recdata_contents(source_rec, element);
		[rec_content, rec_content_exist] = get_recdata_contents(rec, element, 'suppress_warning', true);
		
		if source_rec_content_exist
			if ~rec_content_exist || overwrite
				fprintf('Add/update the "%s" in receiver recording %s\n', element, rec_name);
				[rec_updated] = put_recdata_contents(rec,element,source_rec_content);
				receiver_updated(n, :) = rec_updated;
			else
				fprintf('Nothing updated in the receiver recording %s\n', rec_name)
			end
		else
		end
	end
end
