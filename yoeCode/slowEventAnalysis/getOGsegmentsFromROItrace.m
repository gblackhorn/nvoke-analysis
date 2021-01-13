function traceSegments = getOGsegmentsFromROItrace(ROItrace, OGstarts, OGdur, PREwin, POSTwin)

traceSegments = getAllEventTrigCaTracesForRoi(ROItrace, OGstarts, PREwin, OGdur + POSTwin);

