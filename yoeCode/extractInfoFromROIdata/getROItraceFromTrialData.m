function trace = getROItraceFromTrialData(trialData, ROI, TYPE, varargin)
% return the lowpassed ca trace for indicated ROI

for ii = 1:2:(nargin-3)
	if strcmpi('roi_name', varargin{ii})
		roi_name = varargin{ii+1};
	end
end

if (~exist('TYPE', 'var'))
    TYPE = 'lowpass';
end
if strcmp(TYPE, 'lowpass')
traceT = trialData{1, 2}.lowpass;
else
    traceT = trialData{1, 2}.decon;
end

if exist('roi_name', 'var')
	traceT_roi_names = traceT.Properties.VariableNames;
	roi_col = find(strcmp(roi_name, traceT_roi_names));
else
	roi_col = ROI+1;
end


trace = traceT {:, roi_col};

