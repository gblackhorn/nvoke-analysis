function [caDiffOG] = getCaDiffOGforROI(ROItrace, OGstarts, OGends)

BASELINEwin = 200; % frames before OG that we look at calcium to compare

[meanCas, stdCas] = getMeanCaInOGsFromROI(ROItrace, OGstarts, OGends);

[baselineCaMean, baselineCaSTD] = getMeanTraceInRange(ROItrace, OGstarts - 100, OGstarts);

caDiffOG = meanCas - baselineCaMean;


