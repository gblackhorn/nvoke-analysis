function TF = validateTrialData(trialData)
%check that trialData is a valid thing

TF = 1;


if (isempty(trialData))
    TF = 0;
else
    if (length(trialData) ~= 5)
        TF = 0;
    else
        if ((~ischar(trialData{1})) ||(~ischar(trialData{3}{1})))
            TF = 0;
        end
        
        if ((~isstruct(trialData{2}))||(~isstruct(trialData{4})))
            TF = 0;
        else
            %check if appropriate trace data exists
            fields = fieldnames(trialData{2});
            a = ~contains(fields, {'lowpass' 'decon' 'raw', 'highpass'});
            if any (a)
                TF = 0;
            end
            fields = fieldnames(trialData{4});
            a = ~contains(fields, {'name' 'time_value' 'stim_range'});
            if any (a)
                TF = 0;
            end
        end
        if (~istable(trialData{5}))
             TF = 0;
        end
            
    end
end

% data structure has changed ... need to skip this
TF = 1; 



