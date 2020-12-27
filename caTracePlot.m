function [] = caTracePlot(timeInfo, traceInfo, peakInfo)
    % Plot calcium imaging trace with given time, trace and peak info
    % traceInfo needs to have at least 2 cols. 2nd lowpass data is used for peak info
    %	caTracePlot(timeInfo, traceInfo, peakInfo)	
    %   input: timeInfo (s)-time
    %		   traceInfo-1st_col(rawdata), 2nd_col(lowpassed), 3rd_col(CNMFe_decon). trace can be 1-3
    %  	 	   peakInfo-get this from output (modified_ROIdata{n, 5}.neuronX(3, Y)) of 'nvoke_correct_peakdata.m'
    plotRaw = 0;
    plotLowpass = 0;
    plotDecon = 0;
    switch size(traceInfo, 2) % number of traces
    case 1 % rawdata
    	rawTrace = traceInfo(:, 1);
    	plotRaw = 1;
    case 2 % rawdata, lowpassed_data
    	rawTrace = traceInfo(:, 1);
    	lowpassTrace  = traceInfo(:, 2);
    	plotRaw = 1;
    	plotLowpass = 1;
    case 3 % rawdata, lowpassed_data, CNMFe_decon_data
    	rawTrace = traceInfo(:, 1);
    	lowpassTrace  = traceInfo(:, 2);
    	deconTrace = traceInfo(:, 3);
    	plotRaw = 1;
    	plotLowpass = 1;
    	plotDecon = 1;
    end

    peakTime = peakInfo.Peak_loc_s_;
    peakVal = peakInfo.Peak_mag;
    riseStartTime = peakInfo.Rise_start_s_;
    riseStartLoc = peakInfo.Rise_start;
    riseStartVal = lowpassTrace(riseStartLoc);

    plot(timeInfo, rawTrace, 'Color', '#7E2F8E')
    hold on 
    if plotDecon == 1
    	plot(timeInfo, deconTrace, 'k')
    end
    if plotLowpass == 1
	    plot(timeInfo, lowpassTrace,  'Color', '#0072BD', 'linewidth', 1)
	    plot(peakTime, peakVal, 'o', 'Color', '#D95319', 'linewidth', 2)
	    plot(riseStartTime, riseStartVal, 'd', 'Color', '#D95319',  'linewidth', 2)
	end
end

