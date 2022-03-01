function [struct_entry_idx,varargout] = get_struct_entry_idx(structData,field_name,subfield_name,varargin)
	% Return an IDX array of entries of structData if subfield in one of structData's field meets the requirement

	% structData: a structure var
	% field_name: name of a field in structData
	% subfield_name: name of a field in structData.(field_name)

	% This func was designed for alignedData.traces. It will check the tf of alignedData.traces.stimEffect.excitation/inhibition/rebound

	% Defaults
	req = true; % requirement.

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('req', varargin{ii})
	        req = varargin{ii+1}; % label style. 'shape'/'text'
        % elseif strcmpi('dis_prefix', varargin{ii})
	       %  dis_prefix = varargin{ii+1}; % a column cell containing neuron lables
        % elseif strcmpi('shapeColor', varargin{ii})
	       %  shapeColor = varargin{ii+1}; % a column cell containing neuron lables
        % elseif strcmpi('opacity', varargin{ii})
	       %  opacity = varargin{ii+1}; % a column cell containing neuron lables
	    end
	end	

	%% Content
	struct_length = numel(structData);
	field_content = {structData.(field_name)};
	tf_cell = cellfun(@(x) x.(subfield_name), field_content,'UniformOutput',false);
	tf = cell2mat(tf_cell);
	struct_entry_idx = find(tf);
	entry_num = numel(struct_entry_idx);
	varargout{1} = entry_num;
end