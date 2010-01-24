function varargout = uiscnlobject(varargin)
% UISCNLOBJECT create or modify a scnlobject via a user interface
% Useage: newscnlobject = uiscnlobject(base_scnlobject)
%   base_scnlobject is either an existing scnlobject that you wish to
%   modify or just the classname "scnlobject" (no quotes).
%
% Created 5/6/2009 by Celso Reyes

%      UISCNLOBJECT, by itself, creates a new UISCNLOBJECT or raises the existing
%      singleton*.
%
%      H = UISCNLOBJECT returns the handle to a new UISCNLOBJECT or the handle to
%      the existing singleton*.
%
%      UISCNLOBJECT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in UISCNLOBJECT.M with the given input arguments.
%
%      UISCNLOBJECT('Property','Value',...) creates a new UISCNLOBJECT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before uiscnlobject_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to uiscnlobject_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help uiscnlobject

% Last Modified by GUIDE v2.5 06-May-2009 16:41:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @uiscnlobject_OpeningFcn, ...
                   'gui_OutputFcn',  @uiscnlobject_OutputFcn, ...
                   'gui_LayoutFcn',  @uiscnlobject_LayoutFcn, ...
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


% --- Executes just before uiscnlobject is made visible.
function uiscnlobject_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to uiscnlobject (see VARARGIN)

if numel(varargin) == 1 && isa(varargin{1},'scnlobject')
  scnl = varargin{1};
else
  scnl = scnlobject;
end
% Choose default command line output for uiscnlobject
handles.output = scnl;

set(hObject,'UserData',{scnl});
set(handles.edit_station,'String',get(scnl,'station'));
set(handles.edit_channel,'String',get(scnl,'channel'));
set(handles.edit_network,'String',get(scnl,'network'));
set(handles.edit_location,'String',get(scnl,'location'));

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes uiscnlobject wait for user response (see UIRESUME)
uiwait(handles.uiscnl);
disp('last of input')

% --- Outputs from this function are returned to the command line.
function varargout = uiscnlobject_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
delete(hObject)



function edit_station_Callback(hObject, eventdata, handles)
% hObject    handle to edit_station (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_station as text
%        str2double(get(hObject,'String')) returns contents of edit_station as a double


% --- Executes during object creation, after setting all properties.
function edit_station_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_station (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_channel_Callback(hObject, eventdata, handles)
% hObject    handle to edit_channel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_channel as text
%        str2double(get(hObject,'String')) returns contents of edit_channel as a double


% --- Executes during object creation, after setting all properties.
function edit_channel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_channel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_network_Callback(hObject, eventdata, handles)
% hObject    handle to edit_network (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_network as text
%        str2double(get(hObject,'String')) returns contents of edit_network as a double


% --- Executes during object creation, after setting all properties.
function edit_network_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_network (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_location_Callback(hObject, eventdata, handles)
% hObject    handle to edit_location (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_location as text
%        str2double(get(hObject,'String')) returns contents of edit_location as a double


% --- Executes during object creation, after setting all properties.
function edit_location_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_location (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_ok.
function pushbutton_ok_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_ok (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%create scnlobject from fields
s = get(handles.edit_station,'string');
c = get(handles.edit_channel,'string');
n = get(handles.edit_network,'string');
l = get(handles.edit_location,'string');
handles.output = scnlobject(s,c,n,l);
% Update the handles structure
guidata(hObject,handles);
uiresume;

% --- Executes on button press in pushbutton_cancel.
function pushbutton_cancel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume;




% --- Creates and returns a handle to the GUI figure. 
function h1 = uiscnlobject_LayoutFcn(policy)
% policy - create a new figure or use a singleton. 'new' or 'reuse'.

persistent hsingleton;
if strcmpi(policy, 'reuse') & ishandle(hsingleton)
    h1 = hsingleton;
    return;
end
load uiscnlobject.mat


appdata = [];
appdata.GUIDEOptions = struct(...
    'active_h', 183.001831054688, ...
    'taginfo', struct(...
    'figure', 2, ...
    'text', 5, ...
    'edit', 5, ...
    'pushbutton', 3), ...
    'override', 1, ...
    'release', 13, ...
    'resize', 'none', ...
    'accessibility', 'on', ...
    'mfile', 1, ...
    'callbacks', 1, ...
    'singleton', 1, ...
    'syscolorfig', 1, ...
    'blocking', 0, ...
    'lastSavedFile', 'C:\Users\Celso\Documents\MATLAB\GISMO\@scnlobject\uiscnlobject.m', ...
    'lastFilename', 'C:\Users\Celso\Documents\MATLAB\uiscnl.fig');
appdata.lastValidTag = 'uiscnl';
appdata.GUIDELayoutEditor = [];
appdata.initTags = struct(...
    'handle', [], ...
    'tag', 'uiscnl');

h1 = figure(...
'Units','characters',...
'Color',[0.941176470588235 0.941176470588235 0.941176470588235],...
'Colormap',[0 0 0.5625;0 0 0.625;0 0 0.6875;0 0 0.75;0 0 0.8125;0 0 0.875;0 0 0.9375;0 0 1;0 0.0625 1;0 0.125 1;0 0.1875 1;0 0.25 1;0 0.3125 1;0 0.375 1;0 0.4375 1;0 0.5 1;0 0.5625 1;0 0.625 1;0 0.6875 1;0 0.75 1;0 0.8125 1;0 0.875 1;0 0.9375 1;0 1 1;0.0625 1 1;0.125 1 0.9375;0.1875 1 0.875;0.25 1 0.8125;0.3125 1 0.75;0.375 1 0.6875;0.4375 1 0.625;0.5 1 0.5625;0.5625 1 0.5;0.625 1 0.4375;0.6875 1 0.375;0.75 1 0.3125;0.8125 1 0.25;0.875 1 0.1875;0.9375 1 0.125;1 1 0.0625;1 1 0;1 0.9375 0;1 0.875 0;1 0.8125 0;1 0.75 0;1 0.6875 0;1 0.625 0;1 0.5625 0;1 0.5 0;1 0.4375 0;1 0.375 0;1 0.3125 0;1 0.25 0;1 0.1875 0;1 0.125 0;1 0.0625 0;1 0 0;0.9375 0 0;0.875 0 0;0.8125 0 0;0.75 0 0;0.6875 0 0;0.625 0 0;0.5625 0 0],...
'InvertHardcopy',get(0,'defaultfigureInvertHardcopy'),...
'MenuBar','none',...
'Name','Edit SCNL',...
'NumberTitle','off',...
'PaperPosition',get(0,'defaultfigurePaperPosition'),...
'Position',[103.8 42.2307692307692 40.4 19.2307692307692],...
'Resize','off',...
'WindowStyle','modal',...
'Tag','uiscnl',...
'UserData',[],...
'Visible','on',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'text1';

h2 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Position',[4.40000000000001 16.3846153846154 10.4 1.07692307692308],...
'String','Station:',...
'Style','text',...
'Tag','text1',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'edit_station';

h3 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'Callback',mat{1},...
'Position',[14.8 16.3846153846154 20.2 1.69230769230769],...
'String','sta',...
'Style','edit',...
'CreateFcn',mat{2},...
'Tag','edit_station');

local_CreateFcn(h3, [], '', appdata);

appdata = [];
appdata.lastValidTag = 'text2';

h4 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Position',[4.00000000000001 12.5384615384615 10.8 1.07692307692308],...
'String','Channel:',...
'Style','text',...
'Tag','text2',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'edit_channel';

h5 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'Callback',mat{3},...
'Position',[14.8 12.5384615384615 20.2 1.76923076923077],...
'String','chan',...
'Style','edit',...
'CreateFcn',mat{4},...
'Tag','edit_channel');

local_CreateFcn(h5, [], '', appdata);

appdata = [];
appdata.lastValidTag = 'text_network';

h6 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Position',[4.00000000000001 8.6923076923077 10.8 1.07692307692308],...
'String','Network:',...
'Style','text',...
'Tag','text_network',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'edit_network';

h7 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'Callback',mat{5},...
'Position',[14.6 8.6923076923077 20.2 1.69230769230769],...
'String','net',...
'Style','edit',...
'CreateFcn',mat{6},...
'Tag','edit_network');

local_CreateFcn(h7, [], '', appdata);

appdata = [];
appdata.lastValidTag = 'text_location';

h8 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Position',[4.00000000000001 4.84615384615385 10.8 1.07692307692308],...
'String','Location:',...
'Style','text',...
'Tag','text_location',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'edit_location';

h9 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'BackgroundColor',[1 1 1],...
'Callback',mat{7},...
'Position',[14.8 4.84615384615385 20.2 1.69230769230769],...
'String','loc',...
'Style','edit',...
'CreateFcn',mat{8},...
'Tag','edit_location');

local_CreateFcn(h9, [], '', appdata);

appdata = [];
appdata.lastValidTag = 'pushbutton_ok';

h10 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Callback',mat{9},...
'Position',[2.6 1 15.8 2.46153846153846],...
'String','OK',...
'Tag','pushbutton_ok',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );

appdata = [];
appdata.lastValidTag = 'pushbutton_cancel';

h11 = uicontrol(...
'Parent',h1,...
'Units','characters',...
'Callback',mat{10},...
'Position',[21.8 1 15.6 2.46153846153846],...
'String','CANCEL',...
'Tag','pushbutton_cancel',...
'CreateFcn', {@local_CreateFcn, blanks(0), appdata} );


hsingleton = h1;


% --- Set application data first then calling the CreateFcn. 
function local_CreateFcn(hObject, eventdata, createfcn, appdata)

if ~isempty(appdata)
   names = fieldnames(appdata);
   for i=1:length(names)
       name = char(names(i));
       setappdata(hObject, name, getfield(appdata,name));
   end
end

if ~isempty(createfcn)
   eval(createfcn);
end


% --- Handles default GUIDE GUI creation and callback dispatch
function varargout = gui_mainfcn(gui_State, varargin)

gui_StateFields =  {'gui_Name'
    'gui_Singleton'
    'gui_OpeningFcn'
    'gui_OutputFcn'
    'gui_LayoutFcn'
    'gui_Callback'};
gui_Mfile = '';
for i=1:length(gui_StateFields)
    if ~isfield(gui_State, gui_StateFields{i})
        error('MATLAB:gui_mainfcn:FieldNotFound', 'Could not find field %s in the gui_State struct in GUI M-file %s', gui_StateFields{i}, gui_Mfile);
    elseif isequal(gui_StateFields{i}, 'gui_Name')
        gui_Mfile = [gui_State.(gui_StateFields{i}), '.m'];
    end
end

numargin = length(varargin);

if numargin == 0
    % UISCNLOBJECT
    % create the GUI only if we are not in the process of loading it
    % already
    gui_Create = true;
elseif local_isInvokeActiveXCallback(gui_State, varargin{:})
    % UISCNLOBJECT(ACTIVEX,...)
    vin{1} = gui_State.gui_Name;
    vin{2} = [get(varargin{1}.Peer, 'Tag'), '_', varargin{end}];
    vin{3} = varargin{1};
    vin{4} = varargin{end-1};
    vin{5} = guidata(varargin{1}.Peer);
    feval(vin{:});
    return;
elseif local_isInvokeHGCallbak(gui_State, varargin{:})
    % UISCNLOBJECT('CALLBACK',hObject,eventData,handles,...)
    gui_Create = false;
else
    % UISCNLOBJECT(...)
    % create the GUI and hand varargin to the openingfcn
    gui_Create = true;
end

if ~gui_Create
    % In design time, we need to mark all components possibly created in
    % the coming callback evaluation as non-serializable. This way, they
    % will not be brought into GUIDE and not be saved in the figure file
    % when running/saving the GUI from GUIDE.
    designEval = false;
    if (numargin>1 && ishghandle(varargin{2}))
        fig = varargin{2};
        while ~isempty(fig) && ~isa(handle(fig),'figure')
            fig = get(fig,'parent');
        end
        
        designEval = isappdata(0,'CreatingGUIDEFigure') || isprop(fig,'__GUIDEFigure');
    end
        
    if designEval
        beforeChildren = findall(fig);
    end
    
    % evaluate the callback now
    varargin{1} = gui_State.gui_Callback;
    if nargout
        [varargout{1:nargout}] = feval(varargin{:});
    else       
        feval(varargin{:});
    end
    
    % Set serializable of objects created in the above callback to off in
    % design time. Need to check whether figure handle is still valid in
    % case the figure is deleted during the callback dispatching.
    if designEval && ishandle(fig)
        set(setdiff(findall(fig),beforeChildren), 'Serializable','off');
    end
else
    if gui_State.gui_Singleton
        gui_SingletonOpt = 'reuse';
    else
        gui_SingletonOpt = 'new';
    end

    % Check user passing 'visible' P/V pair first so that its value can be
    % used by oepnfig to prevent flickering
    gui_Visible = 'auto';
    gui_VisibleInput = '';
    for index=1:2:length(varargin)
        if length(varargin) == index || ~ischar(varargin{index})
            break;
        end

        % Recognize 'visible' P/V pair
        len1 = min(length('visible'),length(varargin{index}));
        len2 = min(length('off'),length(varargin{index+1}));
        if ischar(varargin{index+1}) && strncmpi(varargin{index},'visible',len1) && len2 > 1
            if strncmpi(varargin{index+1},'off',len2)
                gui_Visible = 'invisible';
                gui_VisibleInput = 'off';
            elseif strncmpi(varargin{index+1},'on',len2)
                gui_Visible = 'visible';
                gui_VisibleInput = 'on';
            end
        end
    end
    
    % Open fig file with stored settings.  Note: This executes all component
    % specific CreateFunctions with an empty HANDLES structure.

    
    % Do feval on layout code in m-file if it exists
    gui_Exported = ~isempty(gui_State.gui_LayoutFcn);
    % this application data is used to indicate the running mode of a GUIDE
    % GUI to distinguish it from the design mode of the GUI in GUIDE. it is
    % only used by actxproxy at this time.   
    setappdata(0,genvarname(['OpenGuiWhenRunning_', gui_State.gui_Name]),1);
    if gui_Exported
        gui_hFigure = feval(gui_State.gui_LayoutFcn, gui_SingletonOpt);

        % make figure invisible here so that the visibility of figure is
        % consistent in OpeningFcn in the exported GUI case
        if isempty(gui_VisibleInput)
            gui_VisibleInput = get(gui_hFigure,'Visible');
        end
        set(gui_hFigure,'Visible','off')

        % openfig (called by local_openfig below) does this for guis without
        % the LayoutFcn. Be sure to do it here so guis show up on screen.
        movegui(gui_hFigure,'onscreen');
    else
        gui_hFigure = local_openfig(gui_State.gui_Name, gui_SingletonOpt, gui_Visible);
        % If the figure has InGUIInitialization it was not completely created
        % on the last pass.  Delete this handle and try again.
        if isappdata(gui_hFigure, 'InGUIInitialization')
            delete(gui_hFigure);
            gui_hFigure = local_openfig(gui_State.gui_Name, gui_SingletonOpt, gui_Visible);
        end
    end
    if isappdata(0, genvarname(['OpenGuiWhenRunning_', gui_State.gui_Name]))
        rmappdata(0,genvarname(['OpenGuiWhenRunning_', gui_State.gui_Name]));
    end

    % Set flag to indicate starting GUI initialization
    setappdata(gui_hFigure,'InGUIInitialization',1);

    % Fetch GUIDE Application options
    gui_Options = getappdata(gui_hFigure,'GUIDEOptions');
    % Singleton setting in the GUI M-file takes priority if different
    gui_Options.singleton = gui_State.gui_Singleton;

    if ~isappdata(gui_hFigure,'GUIOnScreen')
        % Adjust background color
        if gui_Options.syscolorfig
            set(gui_hFigure,'Color', get(0,'DefaultUicontrolBackgroundColor'));
        end

        % Generate HANDLES structure and store with GUIDATA. If there is
        % user set GUI data already, keep that also.
        data = guidata(gui_hFigure);
        handles = guihandles(gui_hFigure);
        if ~isempty(handles)
            if isempty(data)
                data = handles;
            else
                names = fieldnames(handles);
                for k=1:length(names)
                    data.(char(names(k)))=handles.(char(names(k)));
                end
            end
        end
        guidata(gui_hFigure, data);
    end

    % Apply input P/V pairs other than 'visible'
    for index=1:2:length(varargin)
        if length(varargin) == index || ~ischar(varargin{index})
            break;
        end

        len1 = min(length('visible'),length(varargin{index}));
        if ~strncmpi(varargin{index},'visible',len1)
            try set(gui_hFigure, varargin{index}, varargin{index+1}), catch break, end
        end
    end

    % If handle visibility is set to 'callback', turn it on until finished
    % with OpeningFcn
    gui_HandleVisibility = get(gui_hFigure,'HandleVisibility');
    if strcmp(gui_HandleVisibility, 'callback')
        set(gui_hFigure,'HandleVisibility', 'on');
    end

    feval(gui_State.gui_OpeningFcn, gui_hFigure, [], guidata(gui_hFigure), varargin{:});

    if isscalar(gui_hFigure) && ishandle(gui_hFigure)
        % Handle the default callbacks of predefined toolbar tools in this
        % GUI, if any
        guidemfile('restoreToolbarToolPredefinedCallback',gui_hFigure); 
        
        % Update handle visibility
        set(gui_hFigure,'HandleVisibility', gui_HandleVisibility);

        % Call openfig again to pick up the saved visibility or apply the
        % one passed in from the P/V pairs
        if ~gui_Exported
            gui_hFigure = local_openfig(gui_State.gui_Name, 'reuse',gui_Visible);
        elseif ~isempty(gui_VisibleInput)
            set(gui_hFigure,'Visible',gui_VisibleInput);
        end
        if strcmpi(get(gui_hFigure, 'Visible'), 'on')
            figure(gui_hFigure);
            
            if gui_Options.singleton
                setappdata(gui_hFigure,'GUIOnScreen', 1);
            end
        end

        % Done with GUI initialization
        if isappdata(gui_hFigure,'InGUIInitialization')
            rmappdata(gui_hFigure,'InGUIInitialization');
        end

        % If handle visibility is set to 'callback', turn it on until
        % finished with OutputFcn
        gui_HandleVisibility = get(gui_hFigure,'HandleVisibility');
        if strcmp(gui_HandleVisibility, 'callback')
            set(gui_hFigure,'HandleVisibility', 'on');
        end
        gui_Handles = guidata(gui_hFigure);
    else
        gui_Handles = [];
    end

    if nargout
        [varargout{1:nargout}] = feval(gui_State.gui_OutputFcn, gui_hFigure, [], gui_Handles);
    else
        feval(gui_State.gui_OutputFcn, gui_hFigure, [], gui_Handles);
    end

    if isscalar(gui_hFigure) && ishandle(gui_hFigure)
        set(gui_hFigure,'HandleVisibility', gui_HandleVisibility);
    end
end

function gui_hFigure = local_openfig(name, singleton, visible)

% openfig with three arguments was new from R13. Try to call that first, if
% failed, try the old openfig.
if nargin('openfig') == 2
    % OPENFIG did not accept 3rd input argument until R13,
    % toggle default figure visible to prevent the figure
    % from showing up too soon.
    gui_OldDefaultVisible = get(0,'defaultFigureVisible');
    set(0,'defaultFigureVisible','off');
    gui_hFigure = openfig(name, singleton);
    set(0,'defaultFigureVisible',gui_OldDefaultVisible);
else
    gui_hFigure = openfig(name, singleton, visible);
end

function result = local_isInvokeActiveXCallback(gui_State, varargin)

try
    result = ispc && iscom(varargin{1}) ...
             && isequal(varargin{1},gcbo);
catch
    result = false;
end

function result = local_isInvokeHGCallbak(gui_State, varargin)

try
    fhandle = functions(gui_State.gui_Callback);
    result = ~isempty(findstr(gui_State.gui_Name,fhandle.file)) || ...
             (ischar(varargin{1}) ...
             && isequal(ishandle(varargin{2}), 1) ...
             && (~isempty(strfind(varargin{1},[get(varargin{2}, 'Tag'), '_'])) || ...
                ~isempty(strfind(varargin{1}, '_CreateFcn'))) );
catch
    result = false;
end


