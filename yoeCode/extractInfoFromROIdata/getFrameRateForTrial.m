function frameRate = getFrameRateForTrial(trialData)
% input: one row from ROIdata cell array with the data for trial
% calculate frame rate from time sync field, found in struct in column 4

timeData = trialData{2}.lowpass.Time;
sampleInt = timeData(5) - timeData(4); % not using first frames
trialIDs = getTrialIDsFromROIdataStruct(trialData);

frameRate = round(1/sampleInt); % get rid of annoying decimals for fr
if frameRate ~= 10
    warning([' frameRate in trial ' trialIDs(1) ' is ' num2str(frameRate)]);
end