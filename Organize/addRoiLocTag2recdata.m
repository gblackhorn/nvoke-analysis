function newRecdata = addRoiLocTag2recdata(recdata,varargin)
    % Add the location tags to ROIs in a new field,roiLocTag, at recdata{n,2}

    % recdata: a cell array created by the function 'organize_add_peak_gpio_to_recdata'
    % or 'ROI_matinfo2matlab'
    %   - Suggestion: Use this code after adding the FOV location into the recdata. Check if 'recdata.FOV_loc' exists

    % Defaults
    recNameCol = 1; % Column number in 'recdata' containing the recording file name
    roiInfoCol = 2; % Column number in 'recdata' containing the ROI info
    recStimNameCol = 3; % Column number in 'recdata' containing the stimulation name
    showRoiMap = true; % Show the map of ROIs 
    roiNameExcessiveStr = 'neuron'; % remove this string from the ROI name to shorten it
    overwrite = false; % Overwrite the the existing field of 'locTag' in recdata{n,roiInfoCol}

    % Optionals
    for ii = 1:2:(nargin-1)
        if strcmpi('overwrite', varargin{ii})
            overwrite = varargin{ii+1}; % label style. 'shape'/'text'
        end
    end 

    % Assign recdata to newRecdata
    newRecdata =  recdata;

    % Ask user to confirm the overwrite mode
    if overwrite
        fprintf('Overwrite mode is on. Recording containing the location tag will be overwritten\n')
        userConfirm = input('Confirm [y/n. Default-N]: ',"s");
        if isempty(userConfirm)
            userConfirm = 'n';
        end
        if strcmpi(userConfirm,'n')
            return
        end
    else
        fprintf('Overwrite mode is off. Recording containing the location tag will not be overwritten\n')
    end


    % Get the number of recordings
    recNum = size(recdata,1);

    % Loop through all the recordings
    for n = 1:recNum
        % Check if the current recording already have the location tag
        if ~overwrite
            if ~isfield(recdata{n,roiInfoCol},'locTag')
                genTag = true;
            else
                genTag = false;
            end
        else
            genTag = true;
        end

        if genTag
            % get the recording date and time from the trialName
            underScoreIDX = strfind(recdata{n,recNameCol},'_');
            recDateTime = recdata{n,recNameCol}(1:(underScoreIDX(1)-1));

            % Get roi names
            roiNames = getRoiNames(recdata{n,roiInfoCol}.raw); % String cell array

            % remove the 'neuron' part from the roiName for clearer display in the plots. For example,
            % change neuron5 to 5
            roiNamesShort = cell(size(roiNames));
            for i = 1:numel(roiNames)
                roiNamesShort{i} = strrep(roiNames{i},roiNameExcessiveStr,'');
            end

            % Get the coordinations of ROIs. roiNum*2 double array. Format: [x, y] (from top left of an image)
            roiCoor = convert_roi_coor(recdata{n,roiInfoCol}.roi_center); 

            % Get the ROI map
            roiMap = recdata{n,roiInfoCol}.roi_map;
            [rowNum,colNum] = size(roiMap);

            % Get the FOV location if it exists
            if isfield(recdata{n, roiInfoCol}, 'FOV_loc')
                fovLocInfo = recdata{n,roiInfoCol}.FOV_loc;
                fovLocStr = sprintf('%s hemisphere, AP-%s, ML-%s, %s positive area. ',...
                    fovLocInfo.hemi,fovLocInfo.ap,fovLocInfo.ml,fovLocInfo.hemi_ext);
            else
                fovLocStr = '';
            end

            % Create the recording info string
            recInfoStr = sprintf('%sstimulation-%s',fovLocStr,recdata{n,recStimNameCol});

            % Display the roi map to get an impression of the recording view
            if showRoiMap
                % Create a figure
                f = figure(Color = "white", Units = 'normalized', Position = [0.1 0.1 0.4 0.4]);
                % roiMapAx = nexttile(fTile,43,[3 3]);
                plotRoiCoor2(roiMap,roiCoor,'plotWhere',gca,...
                    'textCell',roiNamesShort,'textColor','m','labelFontSize',12,'showMap',true); % plotWhere is [] to supress plot
                % title(sprintf('%s [%s]',recDateTime,recInfoStr))
                title({recDateTime,recInfoStr})
            end

            % Display the recording name
            fprintf('\nRecording %d/%d: %s [%s]\n',n,recNum,recDateTime,recInfoStr)


            % Ask user to use the same tag for all the ROIs or devide the FOV to 2 parts 
            % promptMsg = sprintf('Use a single [1] or two [2] tags for the ROIs in this recording [default - 1]: ');
            promptMsg = sprintf('Use the same tag [1 = true] for all the ROIs or not [0 = false] [default - 1]: ');
            useSameTags = input(promptMsg);
            if isempty(useSameTags)
                useSameTags = 1;
            end

            % Validate the 'useSameTags'
            if useSameTags ~= 0 && useSameTags ~= 1
                error('The input for tag number must be 0 or 1')
            end

            % Add a new field containing roi location as a tag  
            newRecdata{n,roiInfoCol}.locTag = createLocTagStruct(roiNames,useSameTags,roiCoor,[rowNum,colNum]);

            % Close RoiMap
            if exist('f')
                close(f)
            end
        end
    end
end

function roiNames = getRoiNames(traceTab)
    % Extract the roiNames from a calcium trace table
    % 2nd to the last columns contains the roi traces. The VariableNames of these columns are the roiNames
    roiNames = traceTab.Properties.VariableNames(2:end);
end
