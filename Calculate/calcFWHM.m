function [FWHMs,varargout] = calcFWHM(traceData,timeInfo,riseLocs,peakLocs,varargin)
    % calculate the halfwidth locations around peak for calculating the (full-width at half maximum) FWHM 

    % traceData: a vector var
    % timeInfo: a vector as long as traceData
    % riseLocs & peakLocs: the indices of rises and peaks in traceData and timeInfo. They have the same length
    
    % Defaults
    freq = 20; % sampling frequency
    queryIntScale = 10; % This var, together with freq, are used to define the time interval of query points. 
    maxTimeRange = 5; % unit: second. max time range for finding the halfMax width point
    extraTimeAfterHMend = 1; % unit: second. Add more time after the right side half maximum (HMend). Avoid bug while looking for HMend in interpolated trace data  
    interp1Method = 'pchip'; % Shape-preserving piecewise cubic interpolation. 

    debugMode = false; % true/false

    % Optionals for inputs
    for ii = 1:2:(nargin-4)
    	if strcmpi('maxTimeRange', varargin{ii})
    		maxTimeRange = varargin{ii+1};
    	elseif strcmpi('freq', varargin{ii})
    		freq = varargin{ii+1};
        elseif strcmpi('queryIntScale', varargin{ii})
            queryIntScale = varargin{ii+1};
        elseif strcmpi('debugMode', varargin{ii})
            debugMode = varargin{ii+1};
        end
    end

    % Get the time interval of query points
    queryInt = 1/(freq*queryIntScale); 

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

        if debugMode
            fprintf('   calcium event %d/%d\n',pn,peakNum)      
            if pn == 44
                disp('pause for debugging')
                pause
            end
  
        end
        % If half-max window exists, Interpolate the traceData and calculate the FWHM
        if ~isnan(HMendLoc(pn))
            % Check if there is any unexpected peak between the current event peak and its right
            % side half maximum This may happen if there is another peak rise before the current
            % peak decay to a level below the half maximum
            peak2hmData = traceData(peakLocs(pn):HMendLoc(pn));
            highValIDX = find(peak2hmData>peakAmp(pn));
            if isempty(highValIDX)

                % Get the time point of half-maximum after the peak
                HMendTime = timeInfo(HMendLoc(pn));

                % Get the end time of peak trace, which is right half maximum time plus extraTimeAfterHMend
                traceEndTimeIdeal = HMendTime+extraTimeAfterHMend;
                if traceEndTimeIdeal <= timeInfo(end)
                    traceEndLoc = find(timeInfo>=traceEndTimeIdeal,1);
                else
                    traceEndLoc = numel(timeInfo);
                end
                traceEndTime = timeInfo(traceEndLoc);
                

                % Get the traceData and trace time between the riseTime and the traceEndTime
                rise2traceEndData = traceData(riseLocs(pn):traceEndLoc);
                rise2traceEndTime = timeInfo(riseLocs(pn):traceEndLoc);

                % Create the time info of the query points
                rise2traceEndTimeQuery = [riseTime(pn):queryInt:traceEndTime];

                % Interpolate the traceData
                traceDataQuery = interp1(rise2traceEndTime,rise2traceEndData,rise2traceEndTimeQuery,interp1Method);

                % Get the locations of rise, peak, and HMend in the traceDataQuery
                riseLocQuery = 1; % location of event's rise point in rise2traceEndTimeQuery and traceDataQuery
                % peakLocQuery = find(traceDataQuery==peakAmp(pn),1);
                HMendLocQuery = find(rise2traceEndTimeQuery>=HMendTime,1);
                traceEndLocQuery = numel(traceDataQuery);
                peakLocQuery = getFirstClosest_multiWin(rise2traceEndTimeQuery,peakTime(pn),'big',[riseLocQuery,traceEndLocQuery]);

                % Get the time of half-max before the peak
                HF1Loc = getFirstClosest_multiWin(traceDataQuery,halfMax(pn),'big',[riseLocQuery,peakLocQuery]);

                % Get the time of half-max after the peak
                if traceEndTimeIdeal > timeInfo(end) && isempty(HMendLocQuery)
                    HMendLocQuery = traceEndLocQuery;
                end
                HF2Loc = getFirstClosest_multiWin(traceDataQuery,halfMax(pn),'small',[peakLocQuery,HMendLocQuery]);

                if ~isnan(HF2Loc)
                    % Convert the location idx of half-maximum to time
                    timeAtHM(pn,1) = rise2traceEndTimeQuery(HF1Loc);
                    timeAtHM(pn,2) = rise2traceEndTimeQuery(HF2Loc);
                else
                    % This may due to the half-max point on the right side of the peak is the last
                    % data point. After the interpolation, the value of this data point is bigger
                    % than halfMax(pn). Thus, HF2Loc is not existed
                    timeAtHM(pn,1) = NaN;
                    timeAtHM(pn,2) = NaN;
                end
            end
        end
    end

    % calculate the full-width at half maximum
    FWHMs = timeAtHM(:,2) - timeAtHM(:,1);
    varargout{1} = timeAtHM;
end

