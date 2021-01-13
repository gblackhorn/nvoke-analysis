function [eventStarts eventEnds] = getEventStartStopsforTrial(trialData, frameRate)

if (~exist('frameRate', 'var'))
    frameRate = 10;
end

eventStarts = [];
eventEnds = [];


% if (~ validateTrialData(trialData))
%     warning('Invalid trial data');
% else
    stimRangeData = trialData{4}(3).stim_range;
    stimRangeFrames = round(stimRangeData*frameRate);
    eventStarts = stimRangeFrames(:, 1);
    eventEnds = stimRangeFrames(:, 2);
% end
