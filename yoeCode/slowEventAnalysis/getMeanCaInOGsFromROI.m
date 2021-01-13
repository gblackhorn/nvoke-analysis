function [meanCas, stdCas] = getMeanCaInOGsFromROI(ROItrace, OGstarts, OGends)
% means of all OG periods

nStims = length(OGstarts);
meanCas = nan(nStims, 1);
stdCas = nan(nStims, 1);

for stim = 1:nStims
    [meanCas(stim) stdCas(stim)] = getMeanTraceInRange(ROItrace, OGstarts(stim), OGends(stim));
end