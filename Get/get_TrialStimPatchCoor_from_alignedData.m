function [patchCoor,stimName,varargout] = get_TrialStimPatchCoor_from_alignedData(alignedData_trial,varargin)
	% Get PatchCoor for drawing shade to indicate the range of stimulation
	% patchCoor can be use by function 'draw_shade' to draw a transparent patch

	% Defaults
	% pick = nan; 
	% norm_FluorData = false; % true/false. whether to normalize the FluroData

	% % Optionals
	% for ii = 1:2:(nargin-1)
	%     if strcmpi('pick', varargin{ii})
	%         pick = varargin{ii+1}; % number array. An index of ROI traces will be collected 
	%     elseif strcmpi('norm_FluorData', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	%         norm_FluorData = varargin{ii+1}; % normalize every FluoroData trace with its max value
	%     % elseif strcmpi('guiSave', varargin{ii})
    %     %     guiSave = varargin{ii+1};
	%     % elseif strcmpi('fname', varargin{ii})
    %     %     fname = varargin{ii+1};
	%     end
	% end

	% ====================
	% Main contents
	StimDurationInfo = alignedData_trial.stimInfo.StimDuration;

	patchCoor = {StimDurationInfo.patch_coor};
	stimName = {StimDurationInfo.type};

	varargout{1} = numel(patchCoor); % number of stimulation channels
end