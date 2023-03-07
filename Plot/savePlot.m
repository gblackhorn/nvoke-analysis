function [varargout] = savePlot(fig_handle,varargin)
	% save plot 
	% handle of the plot to be saved

	% savePlot(fig_handle,'save_dir',folder,'guiInfo',msg,'guiSave','on','fname',figTitle)

	% Defaults
	guiSave = 'off'; % Options: 'on'/'off'. whether use the gui to choose the save_dir
	save_dir = '';
	guiInfo = 'Choose a folder to save plot';
	fname = ''; % file name

	figFormat = true;
	jpgFormat = true;
	svgFormat = true;

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('save_dir', varargin{ii})
	        save_dir = varargin{ii+1};
	    elseif strcmpi('guiInfo', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	        guiInfo = varargin{ii+1}; % output of stim_effect_compare_trace_mean_alltrial
	    elseif strcmpi('guiSave', varargin{ii})
            guiSave = varargin{ii+1};
	    elseif strcmpi('fname', varargin{ii})
            fname = varargin{ii+1};
	    end
	end

	% ====================
	% Main contents
	switch guiSave
		case 'on'
			guiSave = true;
		case 'off'
			guiSave = false;
	end

	if guiSave
		guiInfo = sprintf('%s: %s', guiInfo, fname);
		% if ~isempty(fname)
		% 	save_dir = fullfile(save_dir, fname);
		% end
		save_dir = uigetdir(save_dir,...
			guiInfo);
	else
		if isempty(save_dir)
			fprintf('[save_dir] is empty. figure will not be saved\n')
			return
		end
	end

	% switch guiSave
	% 	case 'on'
	% 		guiSave = true;
	% 		guiInfo = sprintf('%s: %s', guiInfo, fname);
	% 		% if ~isempty(fname)
	% 		% 	save_dir = fullfile(save_dir, fname);
	% 		% end
	% 		save_dir = uigetdir(save_dir,...
	% 			guiInfo);
	% 	case 'off'
	% 		guiSave = false;
	% 		if isempty(save_dir)
	% 			fprintf('[save_dir] is empty. figure will not be saved\n')
	% 			return
	% 		end
	% 	otherwise
	% 		fprintf('Input [on] or [off] for [guiSave]\n')
	% 		return
	% end

	if save_dir == 0
		disp('Folder for saving plots not chosen.')
		return
	else
		% dt = datestr(now, 'yyyymmdd');
		if isempty(fname)
			fname = datestr(now, 'yyyymmdd_HHMMSS');
		end
		filepath = fullfile(save_dir, fname);

		if figFormat
			savefig(fig_handle, [filepath, '.fig']);
		end
		if jpgFormat
			saveas(fig_handle, [filepath, '.jpg']);
		end
		if svgFormat
			saveas(fig_handle, [filepath, '.svg']);
		end
	end

	varargout{1} = save_dir;
	varargout{2} = fname;
end