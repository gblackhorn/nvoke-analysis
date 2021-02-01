function caTrace = getEventTrigCaTraceForROI(ROItrace, trigFrame, PREwin, POSTwin)
% return ONE segment of calcium trace (lowpassed for now) from the ROItrace
% (single cell) defined by trigFrame and wins
% inputs are in FRAMES
% ca trace is one column with only the fluo values

caTrace = [];
traceLength = length(ROItrace);
if ((trigFrame > (traceLength-POSTwin)) ||(trigFrame < PREwin+1))
    warning('ca event out of bounds');
else
    startFrame = trigFrame - PREwin;
    endFrame = trigFrame + POSTwin;
    caTrace = ROItrace(startFrame:endFrame)';
end