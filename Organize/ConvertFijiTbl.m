function [new_tbl] = ConvertFijiTbl(tbl)
%Convert the table exported from ROI multi-measure in FIJI to a time(single col)--neurons(multi col)

% Read a csv file to get tbl
	% example: 
	% folder = 'G:\Workspace\Inscopix_Seagate\Projects\Exported_tiff\IO_ventral_approach\2021-03-29_dff_crop';
	% file = '2021-03-29-14-24-37_video_sched_0-PP-BP-MC-DFF_crop-2.csv';
	% csvpath = fullfile(folder,file);
	% opts = detectImportOptions(csvpath);
	% tbl = readtable(csvpath,opts);


	% Defaults
	keyword_keep = 'Mean';
	keyword_discard = {'Var','Area','StdDev','X','Y'};

	rpl_header = 'neuron'; % replace the keyword_keep in headers with this

	ScaleUp = 100; % the value will be multiplied by 100 and show as xx%

	% Optionals
	% for ii = 1:2:(nargin-1)
	%     if strcmpi('fn_stimName', varargin{ii})
	%         fn_stimName = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
 %        elseif strcmpi('fn_range', varargin{ii})
	%         fn_range = varargin{ii+1};
 %        elseif strcmpi('round_digit_sig', varargin{ii})
	%         round_digit_sig = varargin{ii+1};
 %        % elseif strcmpi('in_calLength', varargin{ii})
	%        %  in_calLength = varargin{ii+1};
	%     end
	% end	

	%% Content
	% Remove columnes with headers containing keyword_discard
	tbl_header = tbl.Properties.VariableNames;
	idx_dis = [];
	for kdn = 1:numel(keyword_discard)
		kw = keyword_discard(kdn);
		new_dis_locs = find(contains(tbl_header,kw));
		idx_dis = [idx_dis new_dis_locs];
	end
	tbl(:,idx_dis) = [];

	% Rename the kept headers
	tbl_header = tbl.Properties.VariableNames;
	tbl_header_new = strrep(tbl_header,keyword_keep,rpl_header);
	tbl = renamevars(tbl,tbl_header,tbl_header_new);

	% The last column contains the background value. Subtract all other values with this and then delete this col
	tbl_BG_val = tbl{:,end};
	tbl_val_rmBG = tbl{:,:}-tbl_BG_val;
	tbl{:,:} = tbl_val_rmBG*ScaleUp;
	tbl(:,end) = [];
	new_tbl = tbl;
end