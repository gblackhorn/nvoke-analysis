function [eventProp_all_norm,varargout] = norm_eventProp_with_spon(eventProp_all,varargin)
	% Normalize event properties with spontaneous event properties of the same ROI. Discard spon entries is optional
	% Categories other than 'spon' can be also used. Specify it with varargin ('peakCat_denorm')

	% If sponoutaneous event not found in the ROI, discard the ROI 

	% Defaults
	peakCat_denorm = 'spon'; % The peak category of which properties are used as denominator
	propNames = {'rise_duration', 'peak_mag_delta', 'peak_delta_norm_hpstd',...
		'peak_slope', 'peak_slope_norm_hpstd',};
	norm_prefix = 'sponNorm';
	entry = 'event'; % 'event'/'roi'. Each entry contains event properties of an event or a ROI
	dis_spon = true; % true/false. discard peakCat_denorm events 

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('peakCat_denorm', varargin{ii})
	        peakCat_denorm = varargin{ii+1};
        elseif strcmpi('norm_prefix', varargin{ii})
	        norm_prefix = varargin{ii+1};
        elseif strcmpi('entry', varargin{ii})
            entry = varargin{ii+1};
        elseif strcmpi('dis_spon', varargin{ii})
            dis_spon = varargin{ii+1};
	    elseif strcmpi('propNames', varargin{ii})
            propNames = varargin{ii+1};
	    end
	end

	%% ====================
	props_num = numel(propNames);
	normPropNames = cell(size(propNames));
	for pn = 1:props_num % creat names for norm properties
		normPropNames{pn} = sprintf('%s_%s', norm_prefix, propNames{pn});
	end
	

	% Main content
	[trials, ia_trial, ic_trial] = unique({eventProp_all.trialName}, 'stable');
	trials_num = numel(trials);
	eventProp_trial_norm = cell(trials_num, 1);

	for tn = 1:trials_num
		trial_idx = find(ic_trial==tn);
		eventProp_trial = eventProp_all(trial_idx); % eventProp from a single trial

		[rois, ia_roi, ic_roi] = unique({eventProp_trial.roiName}, 'stable');
		rois_num = numel(rois);
		eventProp_roi_norm = cell(rois_num, 1);

		for rn = 1:rois_num
			roi_idx = find(ic_roi==rn);
			eventProp_roi = eventProp_trial(roi_idx); % eventProp from a single ROI

			[peakCats, ia_peakCat, ic_peakCat] = unique({eventProp_roi.peak_category}, 'stable');
			tf_spon = strcmpi(peakCat_denorm, peakCats);
			peakCat_denorm_uniqueIdx = find(tf_spon);

			% if peakCat_denorm exists, and there are other categories as well
			if ~isempty(peakCat_denorm_uniqueIdx) % && numel(peakCats)>1
				peakCat_denorm_idx = find(ic_peakCat == peakCat_denorm_uniqueIdx);
				eventProp_denorm = eventProp_roi(peakCat_denorm_idx); % peakCat_denorm entries
				eventProp_other = eventProp_roi;
				if dis_spon
					eventProp_other(peakCat_denorm_idx) = []; % discard peakCat_denorm entries
				end
				for pn = 1:props_num
					denormProp.(propNames{pn}) = mean([eventProp_denorm.(propNames{pn})]);
					normProp = num2cell([eventProp_other.(propNames{pn})]/denormProp.(propNames{pn}));
					[eventProp_other.(normPropNames{pn})] = deal(normProp{:});
				end

				switch entry
					case 'roi'
						[peakCatsOther, ia_peakCatOther, ic_peakCatOther] = unique({eventProp_other.peak_category}, 'stable');
						peakCatsOther_num = numel(peakCatsOther);
						eventProp_other_merge = cell(peakCatsOther_num, 1);
						for pcn = 1:peakCatsOther_num
							pc_idx = find(ic_peakCatOther==pcn); % index of event prop belongs to peak category (pcn)
							eventProp_other_merge_peakCat = eventProp_other(pc_idx);
							event_num_peakCat = numel(pc_idx);

							% eventProp_other_merge{pcn} = eventProp_other(ia_peakCatOther(pcn));

							eventProp_other_merge{pcn}.trialName = eventProp_other_merge_peakCat(1).trialName;
							eventProp_other_merge{pcn}.roiName = eventProp_other_merge_peakCat(1).roiName;
							eventProp_other_merge{pcn}.fovID = eventProp_other_merge_peakCat(1).fovID;
							eventProp_other_merge{pcn}.stim_name = eventProp_other_merge_peakCat(1).stim_name;
							eventProp_other_merge{pcn}.combine_stim = eventProp_other_merge_peakCat(1).combine_stim; % multiple stimuli combined in single recordings
							eventProp_other_merge{pcn}.stim_repeats = eventProp_other_merge_peakCat(1).stim_repeats;
							eventProp_other_merge{pcn}.roi_coor = eventProp_other_merge_peakCat(1).roi_coor;
							eventProp_other_merge{pcn}.peak_category = eventProp_other_merge_peakCat(1).peak_category;
							eventProp_other_merge{pcn}.event_num = event_num_peakCat;
							eventProp_other_merge{pcn}.entryStyle = entry;

							eventProp_other_merge{pcn}.eventPropData = eventProp_other_merge_peakCat;

							
							for pn = 1:props_num
								eventProp_other_merge{pcn}.(propNames{pn}) = mean([eventProp_other_merge_peakCat.(propNames{pn})]);
								eventProp_other_merge{pcn}.(normPropNames{pn}) = mean([eventProp_other_merge_peakCat.(normPropNames{pn})]);
							end
						end
						eventProp_roi_norm{rn} = [eventProp_other_merge{:}];
					otherwise
						eventProp_roi_norm{rn} = eventProp_other;
				end
			else
				eventProp_roi_norm{rn} = [];
			end
		end
		eventProp_trial_norm{tn} = [eventProp_roi_norm{:}];
	end
	eventProp_all_norm = [eventProp_trial_norm{:}];
	% eventProp_all_norm = orderfields(eventProp_all_norm);
end
