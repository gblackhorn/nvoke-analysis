function [newStimNameEventCatCell,varargout] = modStimNameEventCat(StimNameEventCatCell,varargin)
    % Rename the stimNaeEventCat in a cell

    % StimNameEventCatCell: a cell var containing multiple stimName-eventCategory pairs

    
    % Defaults
    stimNameEventCatList = empty_content_struct({'old','new'},6);
    stimNameEventCatList(1).old = 'ap-0.1s-trig';
    stimNameEventCatList(1).new = 'Air-evoked [air-0.1s]';
    stimNameEventCatList(2).old = 'og-5s ap-0.1s-trig-ap [og&ap-5s]';
    stimNameEventCatList(2).new = 'Air-evoked [opto-5s air-0.1s]';
    stimNameEventCatList(3).old = 'og-5s-trig [og-5s]';
    stimNameEventCatList(3).new = 'Opto-evoked [opto-5s]';
    stimNameEventCatList(4).old = 'og-5s ap-0.1s-trig [og&ap-5s]';
    stimNameEventCatList(4).new = 'Opto-evoked [opto-5s air-0.1s]';
    stimNameEventCatList(5).old = 'og-5s-rebound [og-5s]';
    stimNameEventCatList(5).new = 'Opto-offStim [opto-5s]';
    stimNameEventCatList(6).old = 'og-5s ap-0.1s-rebound [og&ap-5s]';
    stimNameEventCatList(6).new = 'Opto-offStim [opto-5s air-0.1s]';


end

