function [meanCa, stdCa] = getMeanTraceInRange(ROItrace, startFrame, endFrame)
% return mean and std of the trace between startFrame and endFrame
% this is meant to be used with a single trace


meanCa = nan;
stdCa = nan;

[traceLength nTraces ] = (size(ROItrace));
if (nTraces > traceLength) % make sure trace is in columns
    ROItrace = ROItrace'; 
end
    

startFrame(find(startFrame < 1)) = 1;

endFrame(find(endFrame > traceLength-1)) = traceLength - 1;

traceSegment = ROItrace(startFrame:endFrame);
meanCa = mean(traceSegment, 'omitnan');
stdCa = std(traceSegment, 'omitnan');