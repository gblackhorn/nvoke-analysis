function [] = batchProcess_MC2DFF_nvokeFiles(FolderPath,varargin)
	% Batch process motion corrected (MC) files and create deltaF/F (DFF) files using Inscopix API

	% DFF files will be saved to the same location as MC files and named as [MC filename]-DFF.isxd 

	% This function is mainly used to batch process manually cropped MC files 

	% Defaults
	keyword = 'MC.isxd'; % Use file name like this to look for motion corrected files
	overwrite = false; % true/false. Create new DFF files if this is true.

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('keyword', varargin{ii})
	        keyword = varargin{ii+1}; 
        elseif strcmpi('overwrite', varargin{ii})
	        overwrite = varargin{ii+1};
        % elseif strcmpi('stimStart_err', varargin{ii})
        %     stimStart_err = varargin{ii+1};
        % elseif strcmpi('nonstimMean_pos', varargin{ii})
        %     nonstimMean_pos = varargin{ii+1};
	    end
	end	


	% look for files using a keyword and prepare a list 
	MC_fileInfo = dir(fullfile(FolderPath,keyword));
	fileNum = numel(MC_fileInfo);


	% loop through MC files on the list and create DFF files
	DFF_fileNum = 0;
	for n = 1:fileNum
		% get the full path of a MC file
		MC_fullPath = fullfile(MC_fileInfo(n).folder,MC_fileInfo(n).name);

		% get the file name of the MC file without the extention, and the extention (should be .isxd)
		[~,MC_fileNameStem,ext] = fileparts(MC_fullPath);

		% generate a full file path for the DFF file
		DFF_fileName = [MC_fileNameStem,'-DFF',ext];
		DFF_fullPath = fullfile(MC_fileInfo(n).folder,DFF_fileName);

		% check if a DFF file for the MC exists and decide whether to create a new one
		if ~exist(DFF_fullPath,'file') || overwrite == true
			isx.dff(MC_fullPath,DFF_fullPath,...
				'f0_type','mean');
			% disp([' - Output: ', DFF_fullPath])
			fprintf(' - Output: %s\n',DFF_fullPath);
			DFF_fileNum = DFF_fileNum+1;
		end
	end

	fprintf('\n%g DFF files were created',DFF_fileNum)
end