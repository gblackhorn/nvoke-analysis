function [FWHMs,varargout] = calcFWHM(traceData,timeInfo,riseLocs,peakLocs,varargin)
    % calculate the halfwidth locations around peak for calculating the (full-width at half maximum) FWHM 

    % traceData: a vector var
    % timeInfo: a vector as long as traceData
    % riseLocs & peakLocs: the indices of rises and peaks in traceData and timeInfo. They have the same length
    
    % Defaults
    freq = 20; % sampling frequency
    maxTimeRange = 5; % unit: second. max time range for finding the halfMax width point

    % Optionals for inputs
    for ii = 1:2:(nargin-4)
    	if strcmpi('maxTimeRange', varargin{ii})
    		maxTimeRange = varargin{ii+1};
    	% elseif strcmpi('maxTimeRange', varargin{ii})
    	% 	maxTimeRange = varargin{ii+1};
        end
    end

    % get the amplitudes at rise and peak locations
    riseAmp = traceData(riseLocs); % value at the riseLocs
    peakAmp = traceData(peakLocs); % value at the riseLocs

    % calculate the values of half-maximums
    ampDelta = peakAmp-riseAmp;
    halfMaxDelta = ampDelta./2;
    halfMax = riseAmp+halfMaxDelta;


    % find the half max in specific windows and use them as start and end of half-max width
    % use the first >= value in [rise peak] and the furst <= in [peak traceData_end]
    maxRange = freq*maxTimeRange;
    % HMstartLoc = getFirstClosest_multiWin(traceData,halfMax,'big',[riseLocs, peakLocs]);
    HMendLoc = getFirstClosest_multiWin(traceData,halfMax,'small',[peakLocs, repmat(numel(traceData),size(peakLocs))],...
        'maxRange',maxRange);


    % loop through peaks
    peakNum = numel(peakLocs);
    riseTime = timeInfo(riseLocs);
    peakTime = timeInfo(peakLocs);
    timeAtHM = NaN(peakNum,2);
    FWHMs = NaN(peakNum,1);
    for pn = 1:peakNum
        % get the time of half-max before the peak
        rise2peakData = traceData(riseLocs(pn):peakLocs(pn));
        rise2peakTime = timeInfo(riseLocs(pn):peakLocs(pn));
        timeAtHM(pn,1) = interp1(rise2peakData,rise2peakTime,halfMax(pn));

        % get the time of half-max after the peak
        if ~isnan(HMendLoc(pn))
            peak2afterHMdata = traceData(peakLocs(pn):HMendLoc(pn));
            peak2afterHMtime = timeInfo(peakLocs(pn):HMendLoc(pn));
            timeAtHM(pn,2) = interp1(peak2afterHMdata,peak2afterHMtime,halfMax(pn));
        end

    end

    % calculate the full-width at half maximum
    FWHMs = timeAtHM(:,2) - timeAtHM(:,1);
    varargout{1} = timeAtHM;
end

