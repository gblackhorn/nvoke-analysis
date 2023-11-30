function [varargout] = crop_nVokeRec(recFolder,outputFolder,cropRectangle,varargin)
    % Crop .isdx files in the 'recFolder' using the cropRectangle [top, left, bottom, right] 

    % 'keyword' can be used to filter the isdx files in the 'redFolder'

    % Defaults
    keyword = ''; % filter won't be applied if keyword is empty
    overwrite = false;

    TDF = 1; % temporal_downsample_factor
    SDF = 1; % spatial_downsample_factor
    % useGUI = false; % true/false. If to use a GUI interface to choose where to load the 
% 
    % Optionals for inputs
    for ii = 1:2:(nargin-3)
        if strcmpi('keyword', varargin{ii})
            keyword = varargin{ii+1};
        elseif strcmpi('overwrite', varargin{ii})
            overwrite = varargin{ii+1};
        elseif strcmpi('TDF', varargin{ii})
            TDF = varargin{ii+1};
        elseif strcmpi('SDF', varargin{ii})
            SDF = varargin{ii+1};
        end
    end

    if isempty(cropRectangle)
        disp('cropRectangle is empty, no file will be cropped')
        return
    else

        input_fileInfo = dir(fullfile(recFolder,keyword));
        movie_num = numel(input_fileInfo);
        cropped_num = 0;

        startMSG = sprintf('\ncropping %g movies (isxd files)\n - input folder: %s\n - output folder: %s\n - crop rectangle: [%s] [top left bottom right]',...
            movie_num,recFolder,outputFolder,num2str(cropRectangle));
        disp(startMSG)
        disp('Cropped movie list:')

        for mn=1:movie_num
            input_file_fullpath = fullfile(recFolder, input_fileInfo(mn).name);

            [~, file_name_stem, ~] = fileparts(input_file_fullpath);
            output_filename = [file_name_stem, '-crop.isxd'];
            output_file_fullpath = fullfile(outputFolder, output_filename);

            existFileInfo = dir(output_file_fullpath);

            if isempty(existFileInfo) || overwrite
                isx.preprocess(input_file_fullpath, output_file_fullpath,...
                    'temporal_downsample_factor', TDF, 'spatial_downsample_factor', SDF,...
                    'crop_rect',cropRectangle);
                % exported_num = exported_num+1;
                reportCrop = sprintf(' - movie (%d/%d): %s',mn,movie_num,output_filename);
                % reportCrop = sprintf('file: %s\n - output file: %s\n - cropRectangle: [%s] [top left bottom right]',...
                %     input_fileinfo(mn).name,output_filename,num2str(cropRectangle));
                disp(reportCrop)


                % Save cropping parameters
                cropWidth = cropRectangle(4)-cropRectangle(2);
                cropHeight = cropRectangle(3)-cropRectangle(1);
                cropInfo = [cropRectangle cropWidth cropHeight];
                colNames = {'Top', 'Left', 'Bottom', 'Right', 'Width', 'Height'};  % Column names
                tbl = array2table(cropInfo, 'VariableNames', colNames);

                % Save the table as a CSV file
                cropInfoFile = [file_name_stem,'-cropInfo.csv'];
                writetable(tbl, fullfile(outputFolder,cropInfoFile), 'Delimiter', ',');
            end
        end
        % fprintf('\n%d movies were cropped and saved to\n %s\n',exported_num,output_folder);
    end
end
