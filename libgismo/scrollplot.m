function varargout = scrollplot(varargin)
% SCROLLPLOT MATLAB code for scrollplot.fig
%      SCROLLPLOT, by itself, creates a new SCROLLPLOT or raises the existing
%      singleton*.
%
%      H = SCROLLPLOT returns the handle to a new SCROLLPLOT or the handle to
%      the existing singleton*.
%
%      SCROLLPLOT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SCROLLPLOT.M with the given input arguments.
%
%      SCROLLPLOT('Property','Value',...) creates a new SCROLLPLOT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before scrollplot_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to scrollplot_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help scrollplot

% Last Modified by GUIDE v2.5 12-Oct-2016 15:18:01

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @scrollplot_OpeningFcn, ...
                   'gui_OutputFcn',  @scrollplot_OutputFcn, ...
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

% --- Executes just before scrollplot is made visible.
function scrollplot_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to scrollplot (see VARARGIN)

% Choose default command line output for scrollplot
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% This sets up the initial plot - only do when we are invisible
% so window can get raised using scrollplot.
if strcmp(get(hObject,'Visible'),'off')
    plot(rand(5));
end

% UIWAIT makes scrollplot wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = scrollplot_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.axes1);
cla;


% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
file = uigetfile('*.fig');
if ~isequal(file, 0)
    open(file);
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to PrintMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
printdlg(handles.figure1)

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
                     ['Close ' get(handles.figure1,'Name') '...'],...
                     'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end

delete(handles.figure1)


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
     set(hObject,'BackgroundColor','white');
end

set(hObject, 'String', {'plot(rand(5))', 'plot(sin(1:0.01:25))', 'bar(1:.5:10)', 'plot(membrane)', 'surf(peaks)'});


% --- Executes on button press in pushbutton2. LEFT ARROW
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = guidata(hObject);
% data.winend = data.winstart;
% data.winstart = data.winend - data.timeStep * 2;
[zoomstart zoomend zoomWindowLength] = getTimeLimits(hObject, eventdata, handles);
data.winstart = zoomstart - zoomWindowLength/2;
data.winend = zoomend - zoomWindowLength/2;
data.we = extract(data.w,'time', data.winstart, data.winend);
guidata(hObject,data);
% plot(data.we,'axeshandle',data.axes1)
replot(hObject, eventdata, handles)

% --- Executes on button press in pushbutton3. RIGHT ARROW
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[zoomstart zoomend zoomWindowLength] = getTimeLimits(hObject, eventdata, handles);
data = guidata(hObject);
% data.winstart = data.winend;
% data.winend = data.winend + data.timeStep * 2;
data.winstart = zoomstart + zoomWindowLength/2;
data.winend = zoomend + zoomWindowLength/2;
data.we = extract(data.w,'time', data.winstart, data.winend);
guidata(hObject,data);
% plot(data.we,'axeshandle',data.axes1)
replot(hObject, eventdata, handles)


% --- Executes on button press in pushbutton4.PARTICLE MOTION
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[zoomstart zoomend zoomwindowlength] = getTimeLimits(hObject, eventdata, handles);
data = guidata(hObject);
data.we = extract(data.w,'time', zoomstart, zoomend);
guidata(hObject,data);
t = threecomp(data.we([6 5 4])',199);
tr = t.rotate()
tr2 = tr.particlemotion();
tr2.plotpm()
tr2.plot3()

% --- Executes on button press in pushbutton5. SPECTRUM
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[zoomstart zoomend zoomwindowlength] = getTimeLimits(hObject, eventdata, handles);
data = guidata(hObject);
data.we = extract(data.w,'time', zoomstart, zoomend);
guidata(hObject,data);
if get(data.we(1),'data_length')>=128
    plot_spectrum(data.we);
else
    disp('Need at least 128 samples for a spectrum')
end

% --- Executes on button press in pushbutton6. SPECTROGRAM
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[zoomstart zoomend zoomwindowlength] = getTimeLimits(hObject, eventdata, handles);
data = guidata(hObject);
data.we = extract(data.w,'time', zoomstart, zoomend);
guidata(hObject,data);
if get(data.we(1),'data_length')>=4096
    figure;
    spectrogram(data.we);
else
    disp('Need at least 4096 samples for a spectrogram')
end

% --- Executes on button press in togglebutton1. AUTOSCALE
function togglebutton1_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton1
[zoomstart zoomend zoomwindowlength] = getTimeLimits(hObject, eventdata, handles);
data = guidata(hObject);
data.we = extract(data.w,'time', zoomstart, zoomend);
data.autoscale = mod(data.autoscale + 1, 2);
guidata(hObject,data);
replot(hObject, eventdata, handles)

function replot(hObject, eventdata, handles)
data = guidata(hObject);
we = data.we;       
plot(we,'axeshandle',data.axes1,'autoscale',data.autoscale)
ylabel('')

function [zoomstart zoomend zoomwindowlength] = getTimeLimits(hObject, eventdata, handles)
data = guidata(hObject);
xlim = get(data.axes1,'xlim');
if (xlim(2)-xlim(1)) < data.timeStep*86400
    zoomstart = data.winstart + xlim(1)/86400;
    zoomend = data.winstart + xlim(2)/86400;
else
    zoomstart = data.winstart;
    zoomend = data.winend;
end
zoomwindowlength = zoomend - zoomstart;    

% --- Executes on button press in pushbutton7. % UNZOOM
function pushbutton7_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
data = guidata(hObject);
middle = mean([data.winstart data.winend]);
data.winstart = middle - data.timeStep;
data.winend = middle + data.timeStep;
data.we = extract(data.w,'time', data.winstart, data.winend);
guidata(hObject,data);
replot(hObject, eventdata, handles)
