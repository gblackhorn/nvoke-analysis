function [] = ePhyPlot(timeInfo, traceInfo, spikeInfo)
    % Plot ePhy trace with given time, trace and peak info
    %   input: timeInfo (s)-time. pData.t
    %		   traceInfo (mv)-1 col of ePhy data. pData.ymv
    %		   spikeInfo-pData.spikeInfo 
    plot_spike = 0;
    if ~isempty(spikeInfo)
	    threshTime = spikeInfo.thresh_time;
	    threshVal = spikeInfo.thresh_val;
	    spikeTime = spikeInfo.peak_time;
	    spikeVal = spikeInfo.peak_val;
	    plot_spike = 1;
	end

    plot(timeInfo, traceInfo, 'k')
    hold on 
    if plot_spike == 1
	    plot(threshTime, threshVal, 'd', 'Color', '#D95319',  'linewidth', 2)
	    plot(spikeTime, spikeVal, 'o', 'Color', '#D95319', 'linewidth', 2)
	end
end

