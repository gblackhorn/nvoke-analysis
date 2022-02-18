function [lowpassPeakInfo_correct] = correctRisePeak(rawTrace, deconTrace, lowpassTrace, lowpassPeakInfo)
% Plot raw, decon, and lowpassed traces. Manually correct rise and peak position
%	lowpassPeakInfo is compatible with data from modified_ROIdata, should be good with ROIdata_peakevent data as well
%   rawTrace, deconTrace and lowpassTrace are arries
% 	lowpassPeakInfo is table variable
	fig = figure;
	set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ]);
	lowpassPeakInfo_correct = lowpassPeakInfo;
	riseLoc = lowpassPeakInfo.Rise_start;
	riseTime = lowpassTrace(riseLoc, 1);
	riseVal = lowpassTrace(riseLoc, 2);
	peakLoc = lowpassPeakInfo.Peak_loc;
	peakTime = lowpassTrace(peakLoc, 1);
	peakVal = lowpassTrace(peakLoc, 2);

	traceWhole = subplot(2, 1, 1);
	plot(rawTrace(:, 1), rawTrace(:, 2), 'Color', '#2D2B36', 'linewidth', 1); % raw trace
	hold on
	plot(deconTrace(:, 1), deconTrace(:, 2), 'Color', '#827C4E', 'linewidth', 1); % decon trace
	plot(lowpassTrace(:, 1), lowpassTrace(:, 2), 'Color', '#625B82', 'linewidth', 2); % lowpass trace
	plot(riseTime, riseVal, 'd', 'Color', '#D95319',  'linewidth', 2) % rise point on lowpass trace
	plot(peakTime, peakVal, 'o', 'Color', '#D95319',  'linewidth', 2) % rise point on lowpass trace
	legend(traceWhole, {'Raw', 'Decon', 'Lowpass', 'Rise', 'Peak'})
	title('Full trace')
	tracePeak = subplot(2, 1, 2);


	% Peaks will be checked one by one
	discard_peak = [];
	peakNum = size(lowpassPeakInfo, 1); % number of peaks
	for pn = 1:peakNum
        disp(['Peak number ', num2str(pn)]);
		rT_single = riseTime(pn); % current rise time
		pT_single = peakTime(pn); % current peak time
		rT_pT_diff = pT_single-rT_single;
		time_left = rT_single-rT_pT_diff*5; % left of xlim
		time_right = pT_single+rT_pT_diff*5; % right of xlim 
		rV_single = riseVal(pn); % current rise value
		pV_single = peakVal(pn);
		rV_pV_diff = pV_single-rV_single;
		val_low = rV_single-rV_pV_diff*0.5; % low of ylim
		val_high = pV_single+rV_pV_diff*0.5; % high of ylim

		fig;
		tracePeak;
		plot(rawTrace(:, 1), rawTrace(:, 2), 'Color', '#2D2B36', 'linewidth', 1); % raw trace
		hold on
		plot(deconTrace(:, 1), deconTrace(:, 2), 'Color', '#827C4E', 'linewidth', 1); % decon trace
		patch('XData', [time_left time_left time_right time_right], 'YData', [val_low val_high val_high val_low],...
			'FaceColor', '#4DBEEE', 'EdgeColor', 'none', 'FaceAlpha', 0.1)
		plot(lowpassTrace(:, 1), lowpassTrace(:, 2), 'Color', '#625B82', 'linewidth', 2); % lowpass trace
		plot(riseTime, riseVal, 'd', 'Color', '#D95319',  'linewidth', 2) % rise point on lowpass trace
		plot(peakTime, peakVal, 'o', 'Color', '#D95319',  'linewidth', 2) % rise point on lowpass trace
		xlim([time_left time_right])
		ylim([val_low val_high])
		title(['Single Peak ', num2str(pn)])

		input_correct = input(['Correct rise and/or peak positions for this Peak: \n',...
			' 1-Keep current positions\n 2-Correct rise\n 3-Correct peak\n 4-Correct both\n 5-delete\n[1]: ']);
		if isempty(input_correct)
			input_correct = 1;
		end
		if input_correct == 1
		elseif ismember(input_correct, [2 3 4])
			% Enable data cursor mode
			datacursormode on
			dcm_obj = datacursormode(fig);
			if ismember(input_correct, [2  4])
				disp('Click on lowpass trace to choose a new rise position, then press "Return"')
				pause
				info_struct = getCursorInfo(dcm_obj);
				if exist('usedPosition', 'var')
					if info_struct.Position(1) == usedPosition(1) && info_struct.Position(2) == usedPosition(2)
						disp('New position not selected. Data not updated')
					else
						riseTime(pn) = info_struct.Position(1); % new rise time
						riseVal(pn) = info_struct.Position(2);
						usedPosition = info_struct.Position;
					end
				else
					riseTime(pn) = info_struct.Position(1); % new rise time
					riseVal(pn) = info_struct.Position(2);
					usedPosition = info_struct.Position;
				end
			end
			if ismember(input_correct, [3 4])
				disp('Click on lowpass trace to choose a new peak position, then press "Return"')
				pause
				info_struct = getCursorInfo(dcm_obj);
				if exist('usedPosition', 'var')
					if info_struct.Position(1) == usedPosition(1) && info_struct.Position(2) == usedPosition(2)
						disp('New position not selected. Data not updated')
					else
						peakTime(pn) = info_struct.Position(1); % new peak time
						peakVal(pn) = info_struct.Position(2);
						usedPosition = info_struct.Position;
					end
				else
					peakTime(pn) = info_struct.Position(1); % new peak time
					peakVal(pn) = info_struct.Position(2);
					usedPosition = info_struct.Position;
				end
			end
		elseif input_correct == 5
			discard_peak = [discard_peak; pn]; % mark delete of current peak
		end
		hold(tracePeak, 'off')
	end
	lowpassPeakInfo_correct.Rise_start_s_ = riseTime; % update rise time
	lowpassPeakInfo_correct.Peak_loc_s_ = peakTime; % update peak time
	lowpassPeakInfo_correct.Peak_mag = peakVal; % update peak value
	lowpassPeakInfo_correct(discard_peak, :) = []; % delete marked discard peaks
end

