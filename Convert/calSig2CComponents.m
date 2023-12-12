function [CComponents,varargout] = calSig2CComponents(calSig,varargin)
    % Convert calcium signal (including time info) to CNMF C (temporal components of neurons)

    % C (temporal components of neurons) can be used with A (spatial components of neurons) to
    % recreate the whole recording
    % Y = A*C

    % calSig variable can be found in recdata/recdata_organized as 'decon' and 'raw'
    % both of them are table variables. First column contains time information, the rest contain calcium signal



    % Check if calSig is a table variable
    if ~istable(calSig)
        error('Input must be a table variable including time and calcium signal information')
    end

    calSigArray = calSig{:,2:end}; % Get the calcium signal info and convert it to a double matrix. Exclude time info.
    CComponents = calSigArray'; % Transpose the calSigArray to make it a C components 

    roiNum = size(CComponents,1); % number of ROIs
    varargout{1} = roiNum;
end
