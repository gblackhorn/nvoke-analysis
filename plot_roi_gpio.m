function varargout = plot_roi_gpio(varargin)
% PLOT_ROI_GPIO MATLAB code for plot_roi_gpio.fig
%      PLOT_ROI_GPIO, by itself, creates a new PLOT_ROI_GPIO or raises the existing
%      singleton*.
%
%      H = PLOT_ROI_GPIO returns the handle to a new PLOT_ROI_GPIO or the handle to
%      the existing singleton*.
%
%      PLOT_ROI_GPIO('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PLOT_ROI_GPIO.M with the given input arguments.
%
%      PLOT_ROI_GPIO('Property','Value',...) creates a new PLOT_ROI_GPIO or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before plot_roi_gpio_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to plot_roi_gpio_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help plot_roi_gpio

% Last Modified by GUIDE v2.5 05-Apr-2019 17:13:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @plot_roi_gpio_OpeningFcn, ...
                   'gui_OutputFcn',  @plot_roi_gpio_OutputFcn, ...
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


% --- Executes just before plot_roi_gpio is made visible.
function plot_roi_gpio_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to plot_roi_gpio (see VARARGIN)

% Choose default command line output for plot_roi_gpio
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes plot_roi_gpio wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% setup default input and output folders
folder.csv_file = 'G:\Workspace\Inscopix Seagate\Analysis';
setappdata(0, 'folder',folder);


% --- Outputs from this function are returned to the command line.
function varargout = plot_roi_gpio_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edit_roi_readout_file_Callback(hObject, eventdata, handles)
% hObject    handle to edit_roi_readout_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_roi_readout_file as text
%        str2double(get(hObject,'String')) returns contents of edit_roi_readout_file as a double


% --- Executes during object creation, after setting all properties.
function edit_roi_readout_file_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_roi_readout_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_gpio_file_Callback(hObject, eventdata, handles)
% hObject    handle to edit_gpio_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_gpio_file as text
%        str2double(get(hObject,'String')) returns contents of edit_gpio_file as a double


% --- Executes during object creation, after setting all properties.
function edit_gpio_file_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_gpio_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_browse_roi_readout_file.
function pushbutton_browse_roi_readout_file_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_browse_roi_readout_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
folder = getappdata(0, 'folder');
[roi_readout_file_name, folder.csv_file] = uigetfile('*.csv', 'Pick ROI readout file', folder.csv_file); % input folder
if isequal(roi_readout_file_name, 0)
  disp('User selected Cancel')
else
  roi_readout_file = fullfile(folder.csv_file, roi_readout_file_name); % file name with full path
  set(handles.edit_roi_readout_file, 'String', roi_readout_file);
  disp(['User selected ', roi_readout_file])
  gpio_file = [gpio_file(1:28), 'GPIO.raw']; % companied GPIO file full path, if the file existed
  if isfile(gpio_file)
    set(handles.edit_gpio_file, 'String', gpio_file);
  else
    set(handles.edit_gpio_file, 'String', 'No stimulation applied');
  end
end
  setappdata(0, 'folder', folder)



% --- Executes on button press in pushbutton_browse_gpio_file.
function pushbutton_browse_gpio_file_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_browse_gpio_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
folder = getappdata(0, 'folder');
[gpio_file_name, folder.csv_file] = uigetfile('*.csv', 'pick GPIO file', folder.csv_file); % input folder
if isequal(gpio_file_name, 0)
  disp('User selected Cancel')
else
  gpio_file = fullfile(folder.csv_file, gpio_file_name); % file name with full path
  set(handles.edit_gpio_file, 'String', gpio_file);
  disp(['User selected ', gpio_file])
end
  setappdata(0, 'folder', folder)


% --- Executes on button press in plot.
function plot_Callback(hObject, eventdata, handles)
% hObject    handle to plot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
roi_readout_file = get(handles.edit_roi_readout_file, 'String'); % full file path of roi readout file
gpio_file = get(handles.edit_gpio_file, 'String'); % full file path of gpio file
roi_offset_interval = 0.3; % to plot multiple roi traces in a stack, offset interval is used

% get ROI data info
opts = detectImportOptions(roi_readout_file); % creat import options based on file content
opts.DataLine = 3; % set data line from the third row of csv file. First 2 rows are 'char'
opts.VariableDescriptionsLine = 2; % set 2nd row as variable description
ROI_table = readtable(roi_readout_file, opts); % import file using modified opts, so data will be number arrays
[ROI_table recording_time ROI_num] = ROI_calc_plot(ROI_table);

% get GPIO info
if strcmp(gpio_file, "No stimulation applied") || strcmp(gpio_file, '')
  gpio_plot = 0; % GPIO info will not be plotted
else
  gpio_plot = 1; % GPIO info will be plotted
  GPIO_table = readtable(gpio_file);
  [ channel EX_LED_power GPIO_duration stimulation ] = GPIO_data_extract(GPIO_table);
end

% organize data for plot. Each figure has 11x2 subplots. top 5 rows are for ROI traces. last row is for GPIO info
x_roi = table2array(ROI_table(:, 1));
roi_group = ceil(ROI_num/10); % number of 'roi_trace x 10' columns
fig_group = ceil(roi_group/2); % number of figures containing 2 roi_group columns

roi_group_count = 1; % counting the number of roi_group in the following loop
for nf = 1 : fig_group % figure num
  figure(nf);
  for ng = 1 : 2 % column num
    subplot(11, 2, ng:2:(ng+2*9));
    roi_trace_first = (nf-1)*20+(ng-1)*10+1+1;
    if ROI_num < (nf-1)*20+ng*10
      roi_trace_last = ROI_num+1; % when last column of roi number is less than 10
    else
      roi_trace_last = (nf-1)*20+ng*10+1;
    end
    stackedplot(ROI_table(:, [1 roi_trace_first:roi_trace_last]), 'XVariable', 'Time');
    roi_group_count = roi_group_count+1;
    if gpio_plot == 1
      if length(channel)-2 >= 1 % 1st and 2nd channels are SYNC and EX_LED, 3rd is the first stimulation channel
        subplot(11, 2, 20+ng);
        for nc = 1 : length(channel)-2
          gpio_offset = 6;
          x = channel(nc+2).time_value(:, 1); % time info
          y{nc} = channel(nc+2).time_value(:, 2)+(length(channel)-2-nc)*gpio_offset;
          stairs(x, y{nc});
          hold on
        end
        axis([0 recording_time 0 max(y{1})*1.1]);
        hold off
        legend(stimulation); 
      end
    else
      % no GPIO info will be plotted
    end
  end
end


    % for nr = 1 : 10 % row number of each roi traces in subplot
    %   x = table2array(ROI_table(:, 1)); % time info
    %   if nr <= ROI_num-(ng-1)*10 
    %     roi_trace_num = (nf-1)*20+(ng-1)*10+nr; % the real number of roi 
    %     roi_name{nr} = strcat('C', sprintf('%02d', roi_trace_num)); % name of roi in ROI_table, such as C01, C02
    %     y{nr} = table2array(ROI_table(:, (roi_trace_num+1))); % ROI readout
    %   else
    %     roi_name{nr} = 'N/A';
    %     y{nr} = zeros(size(x, 1), 1);
    %   end
    % end






