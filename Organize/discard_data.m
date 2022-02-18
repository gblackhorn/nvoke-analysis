function [recdata_new,varargout] = discard_data(recdata,trial_idx,roi_idx)
% manually discard roi traces or trials
% trial_idx: index number of a single trial
% roi_idx: array. number in the roi name, such as 2 in "neuron2". if [], delete the whole trial

	recdata_new = recdata;
	trial_name = recdata{trial_idx, 1};

	if isempty(roi_idx)
		info_str = sprintf('all data in trial %s?', trial_name);
	else
		trial_str = sprintf('following neurons in trial %s:', trial_name);
		trial_data = recdata_new{trial_idx, 2};
		roi_idx_cell = num2cell(roi_idx);
		roi_names = cellfun(@(x) ['neuron', num2str(x)], roi_idx_cell, 'UniformOutput',false);
		roi_idx_cell_space = cellfun(@(x) [' ', num2str(x)], roi_idx_cell, 'UniformOutput',false);
		info_str = [trial_str, [roi_idx_cell_space{:}], '?'];
	end

	fig = uifigure;
	msg = sprintf('Do you want to delete %s', info_str);
	selection = uiconfirm(fig,msg,'Delete Data');
	switch selection
	    case 'OK'
	        if isempty(roi_idx)
	        	recdata_new(trial_idx, :) = [];
	        else
	        	roi_num = numel(roi_names);
	        	for n = 1:roi_num
	        		trial_data.decon.(roi_names{n}) = [];
	        		trial_data.raw.(roi_names{n}) = [];
	        	end
	        	recdata_new{trial_idx, 2} = trial_data;
	        end
	    case 'Cancel'
	        return
	end
	close(fig)
end