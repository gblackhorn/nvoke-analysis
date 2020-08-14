function [outputArg] = organize_invitro_data(organize_folder)
    % organize in vitro calcium imaging data fro CNMFe process
    %   CNMFe process requires single folder for each recording

    % default_folder = 'G:\Workspace\Kevin_data\';
    % organize_folder = uigetdir(default_folder, 'Select a folder to make it organized for CNMFe process');
    folderInfo = dir(organize_folder);
    folderInfo = folderInfo(3:end); % get rid of . and .. from folderInfo
    folderInfoCell = struct2cell(folderInfo); % convert structure to cell

    file_logical = cellfun(@(x) x==0, folderInfoCell(5, :));
    file_idx = find(file_logical);
    if ~isempty(file_idx)
    	folderInfoCell = folderInfoCell(:, file_idx);
	    lb_idx = cellfun(@(x) strfind(x, '['), folderInfoCell(1, :), 'UniformOutput', false); % index number of left bracket
	    rb_idx = cellfun(@(x) strfind(x, ']'), folderInfoCell(1, :), 'UniformOutput', false); % index number of left bracket
	    filenameStem = folderInfoCell(1, :);
	    filenameStemPlus = folderInfoCell(1, :);
	    filenameStemSC = folderInfoCell(1, :);

	    for fn = 1:size(folderInfoCell, 2)
	    	% filenameStemPlus: from begining of file name to last letter before first ']'. Delete '[' in the file name
	    	filenameStemPlus{fn} = [filenameStemPlus{fn}(1:(lb_idx{fn}(1)-1)), '_', filenameStemPlus{fn}((lb_idx{fn}(1)+1):(rb_idx{fn}(1)-1))];
	    	% filenameStemSC：from begining of file name to SxCx immediatly after '['， replace '[' with '_'. example: Direct-GCamp6s_IO2020-04-07-173852_00_S1C4
	    	filenameStemSC{fn} = [filenameStemPlus{fn}(1:(lb_idx{fn}(1)-1)), '_', filenameStemPlus{fn}((lb_idx{fn}(1)+1):(lb_idx{fn}(1)+4))];
	    	% filenameStem： from begining of file name to SxCx immediatly after '['. example: Direct-GCamp6s_IO2020-04-07-173852_00[S1C4
	    	filenameStem{fn} = [filenameStem{fn}(1:(lb_idx{fn}(1)+4))];
	    end
	    % example file name stem: Direct-GCamp6s_IO_ChrimsonR_DCN2020-04-19-172303
	    % filenameStem = cellfun(@(x) x(1:48), folderInfoCell(1, :), 'UniformOutput', false);
	    [recNames, ia, ic] = unique(filenameStem); % unique file name stem. number of recNames is number of recordings
	    for rn = 1:length(recNames)
	    	fullfolder = [organize_folder, '\', filenameStemSC{ia(rn)}];
	    	if ~exist(fullfolder, 'dir')
	    		recNamesWild = [organize_folder, '\', recNames{rn}, '*'];
	    		% singleRecInfo = dir([organize_folder, '\', recNames{rn}]);
	    		fullfolder = [organize_folder, '\', filenameStemSC{ia(rn)}];
	    		% mkdir(fullfoler);
	    		movefile(recNamesWild, fullfolder)
	    	end
			tifFile = dir([fullfolder, '\*.tif*']);
			oldname = tifFile(1).name;
			newname = [filenameStemPlus{ia(rn)}, '.tif'];
			movefile(fullfile(fullfolder, oldname), fullfile(fullfolder, newname));
	    end
	end
end

 