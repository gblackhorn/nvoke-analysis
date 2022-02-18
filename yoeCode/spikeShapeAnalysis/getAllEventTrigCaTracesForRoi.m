function eventTraces = getAllEventTrigCaTracesForRoi(ROItrace, trigData, PREwin, POSTwin)
% returns segments of trace from a single ROI, that align with the frames
% in trigData
% PREwin and POSTwin give the range
% if no trigs are given, a matrix with nans is returned

winLength = PREwin + POSTwin + 1;


nTrigs = length(trigData);

eventTraces = nan(winLength, nTrigs);
for event = 1:nTrigs
    if (trigData(event))
        % get the Ca trace for each event marked in trigData
        trace =  getEventTrigCaTraceForROI(ROItrace, trigData(event), PREwin, POSTwin);
        if (~isempty(trace))
            eventTraces(:, event) = trace;
        end
    else
        warning('empty trig');
    end
end

