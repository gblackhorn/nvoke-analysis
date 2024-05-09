function nameAndTagStruct = createLocTagStruct(neuronNames,useSameTags,varargin)
    % Create a structure with a field containing names of neurons and another field tagging the
    % subnucleu location of neurons

    % neuronNames: A string array containing the ROI names

    % useSameTags: True or false. 
    %   - If true, prompt to ask for a tag for all the ROIs. 
    %   - If false, use a coordination value (use Y as default) to seperate the ROIs into two groups, 
    %       and then prompt to ask for the tags for ROIs with location smaller and bigger than the 
    %       coordination value

    % varargin{1}: The coordinations of ROI center. roiNum * 2 size double array containing x and y values

    % varargin{2}: The size of the image. Vector. [rowNumber, colNumber]


    % Defult
    structFieldNames = {'roiNames','locTags'};
    coorAxis = 'Y'; % Use Y axis value to seperate the ROIs into two groups


    % Get the number of ROIs
    roiNum = numel(neuronNames);

    % Create an empty structure for the output
    nameAndTagStruct = empty_content_struct(structFieldNames,roiNum);

    % Add neuronNames to the field of 'roiNames'
    [nameAndTagStruct.(structFieldNames{1})] = neuronNames{:};

    % Use 'useSameTags' input to decide the number of tags
    if useSameTags
        % Get the tag for all the ROIs from keyboard input
        promptMsgTag = sprintf('Enter the tag for all the ROIs (%d): ',roiNum);
        userTag = input(promptMsgTag, "s");

        % Add the tag to the nameAndTagStruct
        [nameAndTagStruct.(structFieldNames{2})] = deal(userTag);
    else
        % Check if the coordinations of ROI center and the size of the image is given 
        if nargin ~= 4
            error('The inputs must include the coordinations of ROI (3rd input) and the size of image (4th input)')
        end


        % Give some basic information and ask user to input a coordination value
        promptMsgCoorVal = sprintf('The img size is %d * %d (row*col, y*x). Enter a value for %s-axis to seperate the ROIs to two groups: ',...
            varargin{2}(1),varargin{2}(2),coorAxis);
        userCoorVal = input(promptMsgCoorVal);

        % Choose the y or x values of ROI coordinations according to the var 'coorAxis'
        switch coorAxis
            case 'Y'
                ROIcoorVal = varargin{1}(:,2);
                coorMax = varargin{2}(1);
            case 'X'
                ROIcoorVal = varargin{1}(:,1);
                coorMax = varargin{2}(2);
            otherwise
                error('coorAxis must be either Y or X')
        end

        % Check if the userCoorVal is valid
        if userCoorVal > coorMax
            error('The input coordination value must be equal or smaller than the size of image on the same orientation')
        end

       % Separate the ROIs into two different groups using the 'userCoorVal' and ROI coordination
       % in the varargin{1}
       idxGroup1 = find(ROIcoorVal <= userCoorVal);
       idxGroup2 = find(ROIcoorVal > userCoorVal);

       % Get the tags for two different groups from keyboard input
       promptMsgTag1 = sprintf('Enter the tag for the ROIs with coordinations SMALLER than %d on %s axis: ',...
        userCoorVal,coorAxis);
       promptMsgTag2 = sprintf('Enter the tag for the ROIs with coordinations LARGER than %d on %s axis: ',...
        userCoorVal,coorAxis);
       userTag1 = input(promptMsgTag1, "s");
       userTag2 = input(promptMsgTag2, "s");

       % Create a cell array and fill it with tags 
       userTagCell = cell(1,roiNum);
       for n = 1:roiNum
         if ~isempty(find(idxGroup1,n))
            userTagCell{n} = userTag1;
         elseif ~isempty(find(idxGroup2,n))
            userTagCell{n} = userTag2;
         end
       end

       % Add the tag to the nameAndTagStruct
       [nameAndTagStruct.(structFieldNames{2})] = userTagCell{:};
    end
end
