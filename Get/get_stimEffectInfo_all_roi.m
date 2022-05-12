function [stimEffectInfo,varargout] = get_stimEffectInfo_all_roi(alignedData,varargin)
	% Get the stimulation effect info, such as inhibition, excitation

	% stimEffectInfo: structure var. each entry contains info for a single roi

	% alignedData: structure var. including multiple trials

	% Defaults
	stim = 'OG-LED'; % data will be collected from trials applied with this stimulation
	% amp_data = []; % a vector array having the same length as peakCategories
	% normData = true; % whether normalize alignedTrace with average value of pc_norm data

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('stim', varargin{ii})
	        stim = varargin{ii+1}; 
	    % elseif strcmpi('amp_data', varargin{ii})
	    %     amp_data = varargin{ii+1};
	    % elseif strcmpi('normData', varargin{ii})
	    %     normData = varargin{ii+1};
	    % end
	end	

	%% Content
	num_trial = numel(alignedData);

	effectInfo_cell = cell(1, num_trial);
	for tn = 1:num_trial
		trialData = alignedData(tn);
		trialName = trialData.trialName;
		timeInfo = trialData.fullTime;
		stimName = trialData.stim_name;
		stimTimeInfo = trialData.stimInfo(1).time_range_notAlign;  

		% fprintf('trial %d/%d: %s\n', tn, num_trial, trialName)

		if contains(stimName, stim, 'IgnoreCase',true)
			num_roi = numel(trialData.traces);
			effectInfo_struct =  struct('trial', cell(1, num_roi), 'roi', cell(1, num_roi),...
				'inhibition', cell(1, num_roi), 'excitation',...
				cell(1, num_roi),'rebound', cell(1, num_roi), 'ex_in', cell(1, num_roi),...
				'meanIn_average', cell(1, num_roi), 'sponStim_logRatio', cell(1, num_roi));

			for rn = 1:num_roi
				roiData = trialData.traces(rn);
				roiName = roiData.roi;
				traceData = roiData.fullTrace;
				eventCats = roiData.eventProp;
				sponfq = roiData.sponfq;
				stimfq = roiData.stimfq;
				freq_spon_stim = [sponfq stimfq];

				% fprintf(' - roi %d/%d: %s\n', rn, num_roi, roiName)

				[stimEffect,in_info] = get_stimEffect(timeInfo,traceData,stimTimeInfo,eventCats,...
					'freq_spon_stim', freq_spon_stim);
				if roiData.stimEffect.excitation && roiData.stimEffect.inhibition
					ex_in = true;
				else
					ex_in = false;
				end

				effectInfo_struct(rn).trial = trialName;
				effectInfo_struct(rn).roi = roiName;
				effectInfo_struct(rn).inhibition = roiData.stimEffect.inhibition;
				effectInfo_struct(rn).excitation = roiData.stimEffect.excitation;
				effectInfo_struct(rn).rebound = roiData.stimEffect.rebound;
				effectInfo_struct(rn).ex_in = ex_in;
				effectInfo_struct(rn).meanIn_average = in_info.meanIn_average;
				effectInfo_struct(rn).sponStim_logRatio = in_info.sponStim_logRatio;
			end
			effectInfo_cell{tn} = effectInfo_struct;
		end
	end
	stimEffectInfo = [effectInfo_cell{:}];

	% organized data for plotting
	tf_inhibition = [stimEffectInfo.inhibition];
	tf_excitation = [stimEffectInfo.excitation];
	tf_rebound = [stimEffectInfo.rebound];
	tf_ExIn = [stimEffectInfo.ex_in];

	idx_inhibition = find(tf_inhibition);
	idx_excitation = find(tf_excitation);
	idx_rebound = find(tf_rebound);
	idx_ExIn = find(tf_ExIn);

	meanTrace_stim.inhibition = [stimEffectInfo(idx_inhibition).meanIn_average];
	meanTrace_stim.excitation = [stimEffectInfo(idx_excitation).meanIn_average];
	meanTrace_stim.rebound = [stimEffectInfo(idx_rebound).meanIn_average];
	meanTrace_stim.ExIn = [stimEffectInfo(idx_ExIn).meanIn_average];

	logRatio_SponStim.inhibition = [stimEffectInfo(idx_inhibition).sponStim_logRatio];
	logRatio_SponStim.excitation = [stimEffectInfo(idx_excitation).sponStim_logRatio];
	logRatio_SponStim.rebound = [stimEffectInfo(idx_rebound).sponStim_logRatio];
	logRatio_SponStim.ExIn = [stimEffectInfo(idx_ExIn).sponStim_logRatio];

	varargout{1} = meanTrace_stim;
	varargout{2} = logRatio_SponStim;
end