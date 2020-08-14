function [] = ePhyImgPlot(ePhy_imaging_data, varargin)
    % Pair plot of ePhy and calaium imaging traces from same cells
    %   ePhy_imaging_data: a table data. output from workflow_patchclamp.m
    %              ePhy_imaging_data = cell2table(ePhy_imaging_data,...
    %                 'VariableNames',{'ePhyName' 'ePhyData' 'spikeInfo' 'imgName' 'imgNeuron' 'imgData' 'imgPeakInfo'});
    %   varargin(1): savePlots. 0-do not save; 1-save fig, jpg, and svg in selected folder
    
    T_diff = 1; % default = 1s. time difference between ePhy and calcium imaging
    lowpass_fpass = 10; % 10 for slice recordings
    pairsPerFig = 2; % number of paired plot per figure. 2 neuron = 2

    if nargin >= 2
        savePlots = varargin{1};
        if savePlots == 1
            if ~exist('ePhyImgPlot_dir', 'var') || ~ischar(ePhyImgPlot_dir)
                if ispc
                    % HDD_folder = 'G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_ventral\'; % to save peak_info_sheet var
                    ePhyImgPlot_dir = 'D:\guoda\Documents\Workspace\Analysis\nVoke\Slice\plots'; % to save peak_info_sheet var
                elseif isunix
                    ePhyImgPlot_dir = '/home/guoda/Documents/Workspace/Analysis/nVoke/Slice/plots';
                end
            end
            ePhyImgPlot_dir = uigetdir(ePhyImgPlot_dir, 'Choose a folder to save paired recording traces');
        end
    elseif nargin == 1
        savePlots = 0;
    end

    rec_num = size(ePhy_imaging_data, 1);
    figNum = ceil(rec_num/pairsPerFig);
    for fn = 1:figNum
    	figure(fn);
        set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ]); % [x y width height]
    	for pn = 1:pairsPerFig
    		rn = (fn-1)*pairsPerFig+pn; % rn is the number of recording being plotted
    		if rn <= rec_num
    			ePhyName = ePhy_imaging_data.ePhyName{rn, 1};
                ePhyName = strrep(ePhyName, '_', ' ');
    			ePhyTime = ePhy_imaging_data.ePhyData{rn, 1}.ePhyTime;
    			ePhyTime = ePhyTime-T_diff;
    			ePhyTrace = ePhy_imaging_data.ePhyData{rn, 1}.ePhyTrace;
    			ePhySpikeInfo = ePhy_imaging_data.spikeInfo{rn, 1};
    			ePhySpikeInfo.peak_time = ePhySpikeInfo.peak_time-T_diff;
    			ePhySpikeInfo.thresh_time = ePhySpikeInfo.thresh_time-T_diff;

    			imgName = ePhy_imaging_data.imgName{rn, 1};
                imgName = strrep(imgName, '_', ' ');
                imgNeuron = ePhy_imaging_data.imgNeuron{rn, 1};
    			imgTime = ePhy_imaging_data.imgData{rn, 1}.caTime;
    			recording_fr = 1/(imgTime(10)-imgTime(9));
    			imgTraceDecon = ePhy_imaging_data.imgData{rn, 1}.caVal_decon;
    			imgTraceRaw = ePhy_imaging_data.imgData{rn, 1}.caVal_raw;
    			imgTraceLowpass = lowpass(imgTraceRaw, lowpass_fpass, recording_fr);
    			imgTrace = [imgTraceRaw imgTraceLowpass imgTraceDecon];
    			imgPeakInfo = ePhy_imaging_data.imgPeakInfo{rn, 1}{3, 1}{:}; % {3, 1}: peak info of lowpassed data

    			subplot(pairsPerFig*2, 1, (pn-1)*2+1) % ePhyPlot
    			ePhyPlot(ePhyTime, ePhyTrace, ePhySpikeInfo);
    			xlim(gca, [ePhyTime(1) ePhyTime(end)])
    			title(ePhyName, 'FontSize', 8);
    			subplot(pairsPerFig*2, 1, (pn-1)*2+2) % imgPlot
    			caTracePlot(imgTime, imgTrace, imgPeakInfo);
    			xlim(gca, [ePhyTime(1) ePhyTime(end)])
    			title([imgName, ' - ', imgNeuron], 'FontSize', 8);
    		end 
    	end
        if savePlots == 1 % save figures
            ePhyImgPlot_name = [datestr(datetime('now'), 'yyyymmdd'), '_ePhyImg-', num2str(fn)]; % name of figure
            ePhyImgPlot_path = fullfile(ePhyImgPlot_dir, ePhyImgPlot_name);

            savefig(gcf, [ePhyImgPlot_path, '.fig']);
            saveas(gcf, ePhyImgPlot_path, 'jpeg');
            saveas(gcf, ePhyImgPlot_path, 'svg');
        end
    end
end

