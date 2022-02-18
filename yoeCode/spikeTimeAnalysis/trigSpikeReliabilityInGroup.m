function [meanTrigFractionInGroup meanTrigFractionsInTrials semTrigFractionsInTrials trigFractions] = trigSpikeReliabilityInGroup(IOnVokeData, PREwin, POSTwin, trigWINDOW)

nTrials = getNtrialsFromROIdata(IOnVokeData);
trialType = getTrialTypeFromROIdataStruct(IOnVokeData);

if (strcmp(trialType, 'GPIO1-1s'))
    trialType = 'airpuff';
else if (strcmp(trialType, 'nostim'))
        trialType = 'nostim';
    else
        if strcmp (trialType, 'OG-LED-10s')
            trialType = '10 s OG';
        else
            if strcmp (trialType, 'OG-LED-5s')
                trialType = '5 s OG';
            else
                trialType = '1 s OG';
            end
        end
    end
end
    
    
    
    legendStr = {};
    
    for trial = 1:nTrials
        trigFractions{trial} = trigSpikeReliabilityInTrial(IOnVokeData(trial, :), PREwin, POSTwin, trigWINDOW);
        meanTrigFractionsInTrials(trial) = mean(trigFractions{trial}, 'omitnan');
        stdTrigFractionsInTrials(trial) = std (trigFractions{trial}, 'omitnan');
        semTrigFractionsInTrials(trial) = stdTrigFractionsInTrials(trial) ./sqrt(length(trigFractions{trial}));
        legendStr{trial} = ['trial ' num2str(trial)];
    end
    
    % note: cellfun has non-defined order of cells to be processes. better use
    % for loop here
    %meanTrigFractionsInTrials = cellfun(@(x) mean(x,'omitnan'), trigFractions);
    
    
    meanTrigFractionInGroup = mean(meanTrigFractionsInTrials, 'omitnan');
    
    figure; hold on;
    for trial = 1:nTrials
        xVals = ones(length(trigFractions{trial}), 1)*trial;
        
        scatter (xVals,trigFractions{trial}, 60, 'filled',  'MarkerEdgeColor', 'black', 'jitter','on', 'jitterAmount',0.4);
    end
    ylim ([0 1.05]);
    xlim ([0 nTrials+1]);
    xticks(1:nTrials);
    xlabel ('Trial N');
    ylabel ('Fraction of spikes triggered');
    titleString = ['Spike trigger reliability with ' trialType 'trials with ' num2str(frames2sec(trigWINDOW)) ' sec trigger window, per ROI'];
    title (titleString);
    legend (legendStr);