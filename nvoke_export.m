function varargout = nvoke_export(varargin)
% NVOKE_EXPORT MATLAB code for nvoke_export.fig
%      NVOKE_EXPORT, by itself, creates a new NVOKE_EXPORT or raises the existing
%      singleton*.
%
%      H = NVOKE_EXPORT returns the handle to a new NVOKE_EXPORT or the handle to
%      the existing singleton*.
%
%      NVOKE_EXPORT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in NVOKE_EXPORT.M with the given input arguments.
%
%      NVOKE_EXPORT('Property','Value',...) creates a new NVOKE_EXPORT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before nvoke_export_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to nvoke_export_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help nvoke_export

% Last Modified by GUIDE v2.5 06-Nov-2018 16:44:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @nvoke_export_OpeningFcn, ...
                   'gui_OutputFcn',  @nvoke_export_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before nvoke_export is made visible.
function nvoke_export_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to nvoke_export (see VARARGIN)

% Choose default command line output for nvoke_export
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes nvoke_export wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% Setup default input and output folders
folder.processed_file = 'F:\Workspace\inscopix\Projects'; % Folder contains subfolders including processed recordings
folder.exported_file = 'F:\Workspace\inscopix\Analysis'; % Exported files will be saved here
setappdata(0, 'folder', folder);



% --- Outputs from this function are returned to the command line.
function varargout = nvoke_export_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edit_processed_data_folder_Callback(hObject, eventdata, handles)
% hObject    handle to edit_processed_data_folder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_processed_data_folder as text
%        str2double(get(hObject,'String')) returns contents of edit_processed_data_folder as a double




% --- Executes during object creation, after setting all properties.
function edit_processed_data_folder_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_processed_data_folder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_exported_data_folder_Callback(hObject, eventdata, handles)
% hObject    handle to edit_exported_data_folder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_exported_data_folder as text
%        str2double(get(hObject,'String')) returns contents of edit_exported_data_folder as a double


% --- Executes during object creation, after setting all properties.
function edit_exported_data_folder_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_exported_data_folder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_browse_processed_data.
function pushbutton_browse_processed_data_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_browse_processed_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
folder = getappdata(0, 'folder');

folder.processed_file = uigetdir(folder.processed_file, 'Choose a folder containing processed data'); % input folder
if folder.processed_file ~= 0 
  set(handles.edit_processed_data_folder,'String',folder.processed_file);
end
setappdata(0, 'folder', folder);



% --- Executes on button press in checkbox_motion_corrected_video.
function checkbox_motion_corrected_video_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_motion_corrected_video (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_motion_corrected_video



% --- Executes on button press in checkbox_dff_video.
function checkbox_dff_video_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_dff_video (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_dff_video


% --- Executes on button press in checkbox_ROI.
function checkbox_ROI_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_ROI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_ROI


% --- Executes on button press in checkbox_GPIO.
function checkbox_GPIO_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_GPIO (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_GPIO


% --- Executes on button press in pushbutton_browse_exported_data.
function pushbutton_browse_exported_data_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_browse_exported_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
folder = getappdata(0, 'folder');

folder.exported_file = uigetdir(folder.exported_file, 'Choose a folder containing processed data'); % input folder
if folder.exported_file ~= 0 
  set(handles.edit_exported_data_folder,'String',folder.exported_file);
end
setappdata(0, 'folder', folder);


% --- Executes on button press in pushbutton_export.
function pushbutton_export_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_export (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
folder.processed_file = get(handles.edit_processed_data_folder, 'String'); % Folder contains subfolders including processed recordings
folder.exported_file = get(handles.edit_exported_data_folder, 'String'); % Exported files will be saved here
setappdata(0, 'folder', folder);

% Notice that only files with ROIs will be exported. 

Exported_ROI_files = dir([folder.processed_file, '\*ROI*']); % list all ROI files
no_of_ROIs = numel(Exported_ROI_files); % number of ROI files

% list 'recording_yyyymmdd_hhmmss' of all ROI files, and mark the duplicates
Exported_recordings = {};
for n = 1:numel(Exported_ROI_files)
  Exported_recordings = [Exported_recordings {Exported_ROI_files(n).name(1:25)}];
end

% find all unique recordings. i contains the location of all unique recordings.
% j contains locations of all recordings including duplicated
[unique_Exported_recordings i j] = unique(Exported_recordings, 'first');

% check what info should be exported
check_motion_corrected_video = get(handles.checkbox_motion_corrected_video, 'Value');
check_dff_video = get (handles.checkbox_dff_video, 'Value');
check_ROI = get(handles.checkbox_ROI, 'Value');
check_GPIO = get(handles.checkbox_GPIO, 'Value');

if check_motion_corrected_video == 1 || check_dff_video == 1 || check_ROI == 1 || check_GPIO ==1
  if no_of_ROIs ~= 0
    for n = 1:no_of_ROIs
      disp(['Export ', Exported_ROI_files(n).name(1:25), ' (', num2str(n), '/', num2str(no_of_ROIs), ')'])

      if find(i == n) % if this file is not a duplicate
        % Export motion corrected video
        if check_motion_corrected_video == 1
          input_movie_file_mc = fullfile(folder.processed_file, [Exported_ROI_files(n).name(1:34), '.isxd']);
          output_tiff_file_mc = fullfile(folder.exported_file, [Exported_ROI_files(n).name(1:34), '.tiff']);
          if ~exist(output_tiff_file_mc, 'file')
            isx.export_movie_to_tiff(input_movie_file_mc, output_tiff_file_mc);
            disp([' - ', Exported_ROI_files(n).name(1:34), '.tiff'])
          end
        end

        % Export DFF video
        if check_dff_video == 1
          input_movie_file_dff = fullfile(folder.processed_file, [Exported_ROI_files(n).name(1:38), '.isxd']);
          output_tiff_file_dff = fullfile(folder.exported_file, [Exported_ROI_files(n).name(1:38), '.tiff']);
          if ~exist(output_tiff_file_dff, 'file')
            isx.export_movie_to_tiff(input_movie_file_dff, output_tiff_file_dff);
            disp([' - ', Exported_ROI_files(n).name(1:38),  '.tiff'])
          end
        end

        % % Export GPIO 
        % if check_GPIO == 1
        %   input_movie_file_GPIO = fullfile(folder.processed_file, [Exported_ROI_files(n).name(1:25), '-GPIO_gpio.isxd']);
        %   output_csv_file_GPIO = fullfile(folder.exported_file,[Exported_ROI_files(n).name(1:25), '-GPIO.csv']);
        %   if exist(input_movie_file_GPIO, 'file')
        %     isx.export_event_set_to_csv(input_movie_file_GPIO, output_csv_file_GPIO);
        %     disp([' - ', Exported_ROI_files(n).name(1:25),  '.csv'])
        %   end
        % end
      end

      % Export ROI traces
      if check_ROI == 1
        input_movie_file_ROI = fullfile(folder.processed_file, [Exported_ROI_files(n).name(1:(end-5)), '.isxd']);
        output_csv_file_ROI = fullfile(folder.exported_file,[Exported_ROI_files(n).name(1:(end-5)), '.csv']);
        output_tiff_file_dff = fullfile(folder.exported_file, [Exported_ROI_files(n).name(1:38), '.tiff']);
        if ~exist(output_csv_file_ROI, 'file')
          % isx.export_cell_set_to_csv_tiff(input_movie_file_ROI, output_csv_file_ROI);
          isx.export_cell_set_to_csv_tiff(input_movie_file_ROI, output_csv_file_ROI, output_tiff_file_dff);
          disp([' - ', Exported_ROI_files(n).name(1:(end-5)),  '.csv'])
          % disp([' - ', Exported_ROI_files(n).name(1:38),  '.tiff'])
        end
      end
    end
  else
    disp(['no ROI files found in the "', get(handles.text_processed_data_folder, 'String'), '"']);
  end
end


       
