function [SyncInfo, SyncStat] = SyncAnalysis(timeinfo,traces,varargin)
    % Compare every pair of ROIs and find the synchronizing transients
    % alpha version: peak info calculation is not implemented. Always input varargin(1).
    %   timeinfo: 1-column vector of time information of data
    %	traces: data matrix with multiple columns containing trace data
    %	varargin: (1) 1 or 0. 1: cell array containing transient rise index (1st-col) and peak location index (2nd-col) of each trace
    %					When varargin(1) is input, this function use transient info there. 0: no transient info given. This func will calculate them
    %			  (2) a cell array containing roi names.
    %	SyncInfo: table cell array. 1st row: each cell contains a table of host transient rises and guests' transient rises synced to host
    %						  2nd row: each cell contains a table of host transient peaks and guests' transient peaks synced to host
    %	SyncStat: n x n table (n = number of traces). A synchronization matrix
    % ====================
    % % prepare varargin(1) from modified_ROIdata(n, 5), where transient info is stored
    % transientInfo = modified_ROIdata{n, 5}{3, :};
    % varargin(1) = cellfun(@(x) x{:, {'Rise_start', 'Peak_loc'}}, transientInfo, 'UniformOutput', false);
    %
    % % prepare varargin(2) from traces table such as modified_ROIdata{n, 2}.decon
    % varargin(2) = modified_ROIdata{n, 2}.decon.Properties.VariableNames(2:end);



    % Settings
    sync_RiseWinError = 0.2; % default: 0.2 s. Due to low temperol frequency, transients from 2 ROIs with rise time as close as 0.2 or less are categoried to synced 
    sync_PeakWinError = 0.3; % default: 0.3 s. Calcium signal may reach to the peak slightly different among neurons. Low temperol resolution may also influence it.  
    riseCol = 1; % column index of rise location in transient information var (varargin(1), transientInfo)
    peakCol = 2; % column index of peak location in transient information var (varargin(1), transientInfo)
    
    if nargin > 2 
    	transientInfo = varargin{1}; % (1) transient info applied. (2) transient info not applied
    	if nargin > 3
    		roiNames = varargin{2}; % roi names for table vars
    	end
    else 
    	error('not enough input varibles')
    end
    % transientInfoT = array2table(transientInfo,...
    % 	'variableNames', {'RiseIDX', 'PeakIDX'}); % convert transient info array to table for readibility and easier access

    % ====================
    roiNum = size(traces, 2); % number of ROIs
    recFq = 1/(timeinfo(4) - timeinfo(3)); % recording frequency. use 3rd and 4th point to avoid trimed frames
    if ~exist('roiNames', 'var') % if roi names were not input. make some for table var names
    	roiNames_textpart = 'roi';
    	roiNames_numpart = num2cell([1:roiNum]);
    	roiNames = cellfun(@(x) strcat(roiNames_textpart, num2str(x)), roiNames_numpart,...
    		'UniformOutput', false);
    end

    % loop through every transient from every ROI and make table for synchronization. host-transient + guest-transient (include the host as well)
    transientCount = 0; % count transient
    roiCount = 0; % count ROI with transient(s)
    roi_transientPositive = []; % index of roi with transient
    for rn = 1:roiNum % iterate through every roi
    	if ~isempty(transientInfo{rn})
    		roiCount = roiCount+1;
    		transientNum = size(transientInfo{rn}, 1); % number of transient in this ROI
    		roi_transientPositive = [roi_transientPositive rn];
    		roi_transientPositive_name{1, roiCount} = roiNames{rn}; 

    		for tn = 1:transientNum % iterate through every transient in the same ROI
    			transientCount = transientCount+1;
    			hostROI{transientCount, 1} = roiNames{rn}; % make a column of roi names for each transient
    			TransientSN_host(transientCount, 1) = tn; % make a column of transient serial number in each ROI

    			rise_idx_host(transientCount, 1) = transientInfo{rn}(tn, riseCol); % idx of rise point tn of host ROI in "timeinfo" and traces"" 
    			peak_idx_host(transientCount, 1) = transientInfo{rn}(tn, peakCol); % idx of peak

    			rise_time_host(transientCount, 1) = timeinfo(rise_idx_host(transientCount, 1)); % time information of rise point
    			peak_time_host(transientCount, 1) = timeinfo(peak_idx_host(transientCount, 1)); % peak information of peak point

    			transientInfo_time{rn}(tn, riseCol) = timeinfo(rise_idx_host(transientCount, 1)); % transientInfo_time has the same structure as transientInfo. Instead of index, it stores time info
    			transientInfo_time{rn}(tn, peakCol) = timeinfo(peak_idx_host(transientCount, 1));
    		end
    	end
    end

    % loop through every host transient and look for transients with close rise and peak time from every ROI
    syncInfo_guest_logic = zeros(transientCount, roiCount); % allocate ram 
    syncInfoRise_guest_index = syncInfo_guest_logic; % allocate ram 
    syncInfoRise_guest_time  = syncInfo_guest_logic; % allocate ram 
    syncInfoPeak_guest_index = syncInfo_guest_logic; % allocate ram 
    syncInfoRise_guest_time  = syncInfo_guest_logic; % allocate ram 
    for ht = 1:transientCount % host transient number
    	for rtn = 1:roiCount % roi-transientPositive-number
    		roiGuest = roi_transientPositive(rtn); % index of guest roi
    		riseDiff = abs(transientInfo_time{roiGuest}(:, riseCol)-rise_time_host(ht)); % calculate the differences of rise time of host and guest transients 
    		peakDiff = abs(transientInfo_time{roiGuest}(:, peakCol)-peak_time_host(ht)); % calculate the differences of peak time of host and guest transients 

    		riseSync = find(riseDiff <= sync_RiseWinError); % index of guest transient meeting criteria of rise time
    		peakSync = find(peakDiff <= sync_PeakWinError); % index of guest transient meeting criteria of peak time

    		if ~isempty(riseSync) && ~isempty(peakSync)
    			transientSync = intersect(riseSync, peakSync); % index of guest transient synced to host transient
    			if ~isempty(transientSync)
    				syncInfo_guest_logic(ht, rtn) = 1;
    				syncInfoRise_guest_index(ht, rtn) = transientInfo{roiGuest}(transientSync, riseCol);
    				syncInfoRise_guest_time(ht, rtn)  = transientInfo_time{roiGuest}(transientSync, riseCol);
    				syncInfoPeak_guest_index(ht, rtn) = transientInfo{roiGuest}(transientSync, peakCol);
    				syncInfoPeak_guest_time(ht, rtn)  = transientInfo_time{roiGuest}(transientSync, peakCol);
    			end
    		end
    	end
    end

    % Convert arrays and cells to table for final output of SyncInfo
    syncInfo_guest_logic_T = array2table(syncInfo_guest_logic,...
    	'VariableNames', roi_transientPositive_name);
    syncInfoRise_guest_index_T = array2table(syncInfoRise_guest_index,...
    	'VariableNames', roi_transientPositive_name);
    syncInfoRise_guest_time_T = array2table(syncInfoRise_guest_time,...
    	'VariableNames', roi_transientPositive_name);
    syncInfoPeak_guest_index_T = array2table(syncInfoPeak_guest_index,...
    	'VariableNames', roi_transientPositive_name);
    syncInfoPeak_guest_time_T = array2table(syncInfoPeak_guest_time,...
    	'VariableNames', roi_transientPositive_name);

    hostROI_T = cell2table(hostROI,...
    	'VariableNames', {'HostROI'});
	TransientSN_host_T = array2table(TransientSN_host);
    rise_idx_host_T = array2table(rise_idx_host);
    peak_idx_host_T = array2table(peak_idx_host);
    rise_time_host_T = array2table(rise_time_host);
    peak_time_host_T = array2table(peak_time_host);

    % Concatenate tables. SyncInfo will be ready for output
    SyncInfo.logic = [hostROI_T TransientSN_host_T syncInfo_guest_logic_T];
    SyncInfo.index.rise = [hostROI_T TransientSN_host_T syncInfoRise_guest_index_T];
    SyncInfo.index.peak = [hostROI_T TransientSN_host_T syncInfoPeak_guest_index_T];
    SyncInfo.time.rise = [hostROI_T TransientSN_host_T syncInfoRise_guest_time_T];
    SyncInfo.time.peak = [hostROI_T TransientSN_host_T syncInfoPeak_guest_time_T];

    % ====================
    % loop through every host ROI. Count the total number of transient, and the numbers of transients synced to other ROIs
    ROI_pos_unique = unique(SyncInfo.logic.HostROI);
    for rpn = 1:length(ROI_pos_unique) % iterate every ROI with transient(s)
    	roiRows = find(strcmp(ROI_pos_unique{rpn}, SyncInfo.logic.HostROI)); % rows of transient from the rpn ROI in SyncInfo table
    	syncStat_totalNum(rpn, 1) = length(roiRows);
    	for grn = 1:length(ROI_pos_unique) % iterate every ROI and get the number of host transients synced to guest transients
    		guestROI_name = ROI_pos_unique{grn}; % Varibile name of column of SyncInfo table
    		syncStat_syncNum(rpn, grn) = length(find(SyncInfo.logic{roiRows, guestROI_name}));
    		syncStat_syncPerc(rpn, grn) = syncStat_syncNum(rpn, grn)/syncStat_totalNum(rpn, 1);
    	end
    end

    % Convert arrays and cells to table for final output of SyncStat
    ROI_pos_unique_trans = ROI_pos_unique';
    syncStat_totalNum_T = array2table(syncStat_totalNum,...
    	'VariableNames', {'TotalTransientNum'});
    syncStat_syncNum_T = array2table(syncStat_syncNum,...
    	'VariableNames', ROI_pos_unique_trans);
    syncStat_syncPerc_T = array2table(syncStat_syncPerc,...
    	'VariableNames', ROI_pos_unique_trans);

    % Concatenate table. SyncStat will be ready for output
    syncStat_RowNames = ROI_pos_unique;
    SyncStat.number = [syncStat_totalNum_T syncStat_syncNum_T];
    SyncStat.number.Properties.RowNames = ROI_pos_unique;
    SyncStat.percentage = syncStat_syncPerc_T;
    SyncStat.percentage.Properties.RowNames = ROI_pos_unique_trans;
end

