function [EventFreqInBins,varargout] = get_EventFreqInBins_roi(eventTimeStamps_periStimulus,PeriStimulusRange,binWidth,varargin)
    % Calculte the event frequency in time bins

    % [EventFreqInBins] = get_EventFreqInBins_roi(eventTimeStamps_periStimulus,PeriStimulusRange,binWidth)
    % 'eventTimeStamps_periStimulus' is a vertical cell array/numerical array. As a cell array, 
    % each cell contains events in the 'PeriStimulusRange'. The number of cells is the repeat number 
    % of stimulation. As a numerical array, the repeat number of stimulation should be specified. 
    % 'binWidth' is the span of a single bin

    % Defaults
    binWidth = 1; % the width of histogram bin. the default value is 1 s.
    plotHisto = false; % true/false [default].Plot histogram if true.

    % Optionals for inputs
    for ii = 1:2:(nargin-2)
        if strcmpi('denorm', varargin{ii}) 
            denorm = varargin{ii+1}; % denorminator used to normalize the EventFreq 
        elseif strcmpi('stimRepeats', varargin{ii})
            stimRepeats = varargin{ii+1}; % the repeat number of stimulation
        % elseif strcmpi('StimDuration', varargin{ii})
        %     StimDuration = varargin{ii+1}; % specify the duration of stimulations. only a single number is valid
        % elseif strcmpi('round_digit_sig', varargin{ii})
        %     round_digit_sig = varargin{ii+1}; % round to the Nth significant digit for duration
        end
    end

    % Find out if 'eventTimeStamps_periStimulus' is a cell array or numerical array
    if iscell(eventTimeStamps_periStimulus)
        stimRepeats = numel(eventTimeStamps_periStimulus); % get the repeat number of stimulation
        eventTimeStamps_periStimulus = cell2mat(eventTimeStamps_periStimulus);
    else
        if exist('stimRepeats')==0
            error('stimRepeats is needed to run fun [get_EventFreqInBins_roi]')
        end
    end

    HistEdges = [PeriStimulusRange(1):binWidth:PeriStimulusRange(2)];
    % if PeriStimulusRange(2) > HistEdges(end) % if PeriStimulusRange is not long enough to make the last bin
    %     HistEdges = [HistEdges PeriStimulusRange(2)]; % add the end of PeriStimulusRange to the edges to keep the full PeriStimulusRange
    % end

    [eventCounts,HistEdges] = histcounts(eventTimeStamps_periStimulus,HistEdges); % get the event numbers in histbins
    eventCounts_mean = eventCounts/stimRepeats; % use the repeat number of stimulation as denominater to get the mean values of event counts
    EventFreqInBins = eventCounts_mean/binWidth; % Get the event frequency using the binWidth (duration)

    if exist('denorm')==1 && ~isempty(denorm);
        EventFreqInBins = EventFreqInBins/denorm; % normalize the EventFreqInBins with an input, denorm.
    end

    if plotHisto
        histogram(EventFreqInBins,HistEdges);
    end
end
