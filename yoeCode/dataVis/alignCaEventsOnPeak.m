function alignedTraces = alignCaEventsOnPeak(traces, PREwin, POSTwin)

traceLength = PREwin + POSTwin +1;
pks = [];
locs = [];

[nFrames nTraces] = size(traces);
for tr = 1:nTraces
    
    [p l] = findpeaks(traces(:, tr), 'MinPeakProminence', 0.5);
    if (~isempty(p))
        pks =[pks p(1)];
        locs = [locs l(1)];
    else
        pks =[pks 0.1];
        locs = [locs 1];
        
    end
   
    
end

refFrame = max(locs);

shiftFrames = abs(locs - refFrame);
newTraceLength = traceLength + max(shiftFrames);

alignedTraces = nan(newTraceLength, nTraces);

for tr = 1:nTraces
    alignStartFrame = shiftFrames(tr)+1;
    alignEndFrame =  shiftFrames(tr)+traceLength;
    
    alignedTraces (alignStartFrame : alignEndFrame, tr) = traces(:, tr);
end
R = 1;




