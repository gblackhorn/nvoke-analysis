% Workflow patch clamp

% set folders
global dir_ibw ephy_dir ePhy_img_dir ePhyImgPlot_dir 

if ispc
	dir_ibw = 'G:\Workspace\in_vitro\';
	ephy_dir = 'G:\Workspace\in_vitro\';
	ePhy_img_dir = 'D:\guoda\Documents\Workspace\Analysis\Analysis\calcium_imaging_slice\';
    % HDD_folder = 'G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_ventral\'; % to save peak_info_sheet var
    ePhyImgPlot_dir = 'D:\guoda\Documents\Workspace\Analysis\calcium_imaging_slice\figures\'; % to save peak_info_sheet var
elseif isunix
    dir_ibw = '/home/guoda/Documents/Workspace/Analysis/Kevin Data/ePhy';
	ephy_dir = '/home/guoda/Documents/Workspace/Analysis/Kevin Data/ePhy';
	ePhy_img_dir = '/home/guoda/Documents/Workspace/Analysis/nVoke/Slice';
    ePhyImgPlot_dir = '/home/guoda/Documents/Workspace/Analysis/nVoke/Slice/plots';
end

%% ====================
% downsample in-vitro calcium imaging data to compare it's rising time with in-vivo data
% use var ROIdata without any peak info here
dsFq = 10; % desired frequency. Default: 10 Hz
ROIdata_backup = ROIdata;
% ROIdata_downsample = ROIdata; % use calcium trace data from var ROIdata

recNum = size(ROIdata, 1);
for rn = 1:recNum
	deconTrace = ROIdata{rn, 2}.decon; % table of time series of decon trace with time
	rawTrace = ROIdata{rn, 2}.raw; % table of time series of raw trace with time

	timeInfo = deconTrace.Time; % time array
	Fq = round(1/(timeInfo(2)-timeInfo(1))); % original frequency of recording
	dsFactor = Fq/dsFq; % downsample factor

	deconTrace_ds = downsample(deconTrace, dsFactor); % downsample deconTrace
	rawTrace_ds = downsample(rawTrace, dsFactor); % downsample rawTrace

	ROIdata{rn, 2}.decon = deconTrace_ds;
	ROIdata{rn, 2}.raw = rawTrace_ds;
end



%% ====================
% load ibw file
% close all
if ~exist('dir_ibw', 'var') || ~ischar(dir_ibw)
    dir_ibw = 'G:\Workspace\Kevin_data\ePhy\RAW_SPIKE_DATA';
end
% [file_abf, dir_abf, file_type_abf] = uigetfile({'*.abf;', 'pClamp Files(*.abf)'}, 'Select recording',...
%  dir_abf);
[file_ibw, dir_ibw, file_type_ibw] = uigetfile({'*.*', 'All Files(*.*)'; '*.ibw', 'pClamp Files(*.ibw)'; '*.mat', 'MATLAB Files(*.mat)'},...
	'Select recording',...
 dir_ibw);
% path_abf = fullfile(dir_abf, file_abf);
path_ibw = fullfile(dir_ibw, file_ibw);
% nam = './data_1p.tif';
if isequal(path_ibw, 0)
    disp('User selected Cancel')
    return
else
    disp(['User selected ', path_ibw])
    % [d,si,h]=abfload(path_abf);
    pData = IBWread(path_ibw);

    % code below was adapted from AlexT's
    pData.ymv=pData.y*1000;%converts the scale from Volts to mV
    V=pData.ymv;%assigns the data to the variable V

    t = 1:length(pData.y);
    t = t';
    t = t*pData.dx(1); % pData.dx is the sampling interval time in s
    pData.t = t;
    pData.samRate = 1/pData.dx(1);

    % figure
    % plot(pData.t, pData.ymv);
end

% ====================
% find spikes and save pData including all ePhy info
pData.spikeInfo = findspikes_gd(pData.ymv, pData.t, 30);

[dir_ibw,file_ibw_stem,file_ibw_ext] = fileparts(path_ibw);
pData_fn = [file_ibw_stem, '.mat'];
pData_path = fullfile(dir_ibw, pData_fn);
save(pData_path, 'pData');

%% ====================
% organize imaging and ePhy recording of the same cells
% load ephy data output from findspikes_gd, and use calcium imaging data from var 'modified_ROIdata'

% load pData with ePhy data
if ~exist('ephy_dir', 'var') || ~ischar(ephy_dir)
	ephy_dir = 'G:\Workspace\Kevin_data\ePhy\RAW_SPIKE_DATA\';
end
[ephy_name, ephy_dir] = uigetfile({'*.mat', 'MATLAB Files(*.mat)'},...
	'Select a patch clamp recording', ephy_dir);
ephy_path = fullfile(ephy_dir, ephy_name);
if isequal(ephy_dir, 0)
	disp('No file selected')
	return
else
	disp(['User selected: ', ephy_path])
	load(ephy_path);
	ePhyTime = pData.t;
	ePhyTrace = pData.ymv;
	ePhyData = table(ePhyTime, ePhyTrace); 
end
if ~exist('ePhy_imaging_data', 'var')
	rec_num = 1; % number of paired recordings
else
	rec_num = size(ePhy_imaging_data, 1)+1;
end
ePhy_imaging_data{rec_num, 1} = ephy_name;
ePhy_imaging_data{rec_num, 2} = ePhyData;
ePhy_imaging_data{rec_num, 3} = pData.spikeInfo;


% Find the paired calcium imaging recording and load it
for cn = 1:size(modified_ROIdata, 1) % Calcium recording Number
	disp([num2str(cn), ': ', modified_ROIdata{cn, 1}])
end
input_rec_num = [];
input_prompt_rec = 'Select one of calcium imaging recordings listed above with number: ';
input_rec_num = input(input_prompt_rec);
while isempty(input_rec_num)
	disp('No recording selected')
	input_rec_num = input(input_prompt_rec);
end
ePhy_imaging_data{rec_num, 4} = modified_ROIdata{input_rec_num, 1}; % calcium imaging rec name
neurons = modified_ROIdata{input_rec_num, 5}.Properties.VariableNames; % names of neurons
disp(neurons)
% input_neuron_str = [];
neuron_col = [];
input_prompt_neuron = 'Input one of the neuron names above: ';
while isempty(neuron_col)
	input_neuron_str = input(input_prompt_neuron, 's');
	neurons_idx = strcmp(input_neuron_str, neurons);
	neuron_col = find(neurons_idx);
end
ePhy_imaging_data{rec_num, 5} = input_neuron_str;
caTime = modified_ROIdata{input_rec_num, 2}.decon.Time;
caVal_decon = modified_ROIdata{input_rec_num, 2}.decon.(input_neuron_str);
caVal_raw = modified_ROIdata{input_rec_num, 2}.raw.(input_neuron_str);
ePhy_imaging_data{rec_num, 6} = table(caTime, caVal_decon, caVal_raw);
ePhy_imaging_data{rec_num, 7} = modified_ROIdata{input_rec_num, 5}(:, input_neuron_str);

%% ====================
% convert ePhy_imaging_data from cell to table and save it
ePhy_imaging_data = cell2table(ePhy_imaging_data,...
'VariableNames',{'ePhyName' 'ePhyData' 'spikeInfo' 'imgName' 'imgNeuron' 'imgData' 'imgPeakInfo'});

stimulation = input(['Input info including stimulation for the name of the file saving ePhy_imaging_data var: '], 's');
ePhy_imag_name = ['ePhy_imaging_data_', datestr(datetime('now'), 'yyyymmdd'), '_', stimulation];
ePhy_imag_path = fullfile(ePhy_img_dir, ePhy_imag_name);
save(ePhy_imag_path, 'ePhy_imaging_data');
disp(['var ePhy_imaging_data was saved to file: ', ePhy_imag_path])

%% ====================
% load ePhy_imaging_data if it's not in workspace
if ~exist('ePhy_img_dir', 'var') || ~ischar(ePhy_img_dir)
	ePhy_img_dir = 'G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_slice';
end
[ePhy_img_name, ePhy_img_dir] = uigetfile({'*.mat', 'MATLAB Files(*.mat)'},...
	'Select a file including paired ephy and imaging recording.', ePhy_img_dir);
ePhy_img_path = fullfile(ePhy_img_dir, ePhy_img_name);
if isequal(ePhy_img_path, 0)
	disp('No file selected')
	return
else
	disp(['User selected: ', ePhy_img_path])
	load(ePhy_img_path);
end

%% ====================
% Plot calcium imaging and ePhy traces from the same cell in the same figure. Use data from ePhy_imaging_data
T_diff = 1; % default = 1s. time difference between ePhy and calcium imaging 
savePlots = 1; % 0-do not save plots. 1-save plots
close all

if ~exist('ePhy_imaging_data', 'var') % load ePhy_imaging_data if it's not in workspace
	if ~exist('ePhy_img_dir', 'var') || ~ischar(ePhy_img_dir)
		ePhy_img_dir = 'G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_slice';
	end
	[ePhy_img_name, ePhy_img_dir] = uigetfile({'*.mat', 'MATLAB Files(*.mat)'},...
		'Select a file including paired ephy and imaging recording.', ePhy_img_dir);
	ePhy_img_path = fullfile(ePhy_img_dir, ePhy_img_name);
	if isequal(ePhy_img_path, 0)
		disp('No file selected')
		return
	else
		disp(['User selected: ', ePhy_img_path])
		load(ePhy_img_path);
	end
end

ePhyImgPlot(ePhy_imaging_data, savePlots);

%% ====================
% align traces with their peak rising point for overlapping plot
% [alignedTraceData] = alignPeaks(traceData, peakInfo, expType)
% expType: 1 is ePhy 
% 		   2 is Ca imaging with 2 col
%	 	   3 is Ca imaging with 3 col

% use ePhy_imaging_data
if exist('ePhy_imaging_data', 'var') % load ePhy_imaging_data if it's not in workspace
	alignedTraceData_ePhy = [];
	alignedTraceData_img = [];
	recNum = size(ePhy_imaging_data, 1); % number of paired recordings
	for rn = 1:recNum
		traceData_ePhy = ePhy_imaging_data.ePhyData{rn};
		peakInfo_ePhy = ePhy_imaging_data.spikeInfo{rn};
		expType_ePhy = 1;
		[aligned_ePhy] = alignPeaks(traceData_ePhy, peakInfo_ePhy, expType_ePhy);
		alignedTraceData_ePhy = [alignedTraceData_ePhy; aligned_ePhy];

		traceData_img = ePhy_imaging_data.imgData{rn};
		peakInfo_img = ePhy_imaging_data.imgPeakInfo{rn}{3, 1}{:};
		expType_img = 3; % 1 is ePhy; 2 is Ca imaging with 2 col; 3 is Ca imaging with 3 col
		[aligned_img] = alignPeaks(traceData_img, peakInfo_img, expType_img);
		alignedTraceData_img = [alignedTraceData_img; aligned_img];
	end
end

%% ====================
% normalize aligned data with peak for different view
% [timeSeries_norm] = normalizeTimeSeries(timeSeries, varargin)
traceNum_ephy = size(alignedTraceData_ePhy, 1);
alignedTraceData_ePhy_norm2max = alignedTraceData_ePhy;
for tn = 1:traceNum_ephy
	trace_norm2max = normalizeTimeSeries(alignedTraceData_ePhy.alignedTrace{tn});
	alignedTraceData_ePhy_norm2max.alignedTrace{tn} = trace_norm2max;
end

traceNum_img = size(alignedTraceData_img, 1);
alignedTraceData_img_norm2max = alignedTraceData_img;
for tn = 1:traceNum_img
	trace_norm2max = normalizeTimeSeries(alignedTraceData_img.alignedTrace{tn});
	alignedTraceData_img_norm2max.alignedTrace{tn} = trace_norm2max;
end

%% ====================
% plot overlapping traces with raw data
Trace_ePhy_plot = alignedTraceData_ePhy.alignedTrace;
Trace_img_plot = alignedTraceData_img.alignedTrace;

%% ====================
% plot overlapping traces with normalized to max data
Trace_ePhy_plot = alignedTraceData_ePhy_norm2max.alignedTrace;
Trace_img_plot = alignedTraceData_img_norm2max.alignedTrace;

%% ====================
% plot overlapping traces with aligned data
% superImpTraces(traceData)

figure % ePhy overlapping figure
superImpTraces(Trace_ePhy_plot);
title('ePhy')

figure
superImpTraces(Trace_img_plot);
title('Calcium imaging')


%% ====================
% scatter plot halfWidth
halfWidth_val = alignedTraceData_ePhy.PeakInfo.halfWidth;
hw_num = size(halfWidth_val, 1);
x = [1:hw_num]'; % make an array for scatter plot halfwidth x-axe
x_rand = x(randperm(length(x)));
x_plot = x_rand/hw_num*5;
figure
scatter(x_plot, halfWidth_val);
title('Half width')


%% ====================
% try spike_times2
[N, out1] = spike_times2(pData.ymv,5);