function varargout = VolView(varargin)
% A light-weight VolumeViewer for plotting structural image in grey-scale
% with coloured functional overlay. Exploits ability from Matlab2014a
% onward to be able to overlay axes.
%
% Usage:
%         VolView(struct_volume, overlay_volume)
%
% where struct_volume and overlay_volume are 3D doubles.
%
% AS18



% Edit the above text to modify the response to help VolView

% Last Modified by GUIDE v2.5 17-Dec-2018 16:16:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @VolView_OpeningFcn, ...
                   'gui_OutputFcn',  @VolView_OutputFcn, ...
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


% --- Executes just before VolView is made visible.
function VolView_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to VolView (see VARARGIN)

% Choose default command line output for VolView
handles.output = hObject;

Volume         = varargin{1};
handles.Volume = Volume;

Overlay         = varargin{2};
%Overlay         = NewMeanFilt3D(Overlay,16);
handles.Overlay = Overlay;

% use a constant colorbar caxis
handles.limz = max(abs(Overlay(:)));

% initialise viewpoints
if ~isfield(handles,'CurrentView')
    midpoints = 0.5*floor(size(Volume)); % initial views = ~ mid point
    handles.CurrentView = midpoints;
end

% initialise overlay smoothing
if ~isfield(handles,'smooth')
    handles.smooth = 2;
end

if ~isfield(handles,'AlphaMask');
    handles.AlphaMask = 'O';
end

% we'll be doing a lot of squeezing
Q = @squeeze; 
handles.Q = Q;


% update viewpoints
handles = UpdateViews(handles);


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes VolView wait for user response (see UIRESUME)
% uiwait(handles.figure1);



function handles = UpdateViews(handles)
% Main function for recalculating slices, updating axes and sliders.
%
%
%

curpoints = handles.CurrentView;
Volume    = handles.Volume;
Overlay   = handles.Overlay;
Q         = handles.Q;

% current viewpoints
xview = Q(Volume(curpoints(1),:           ,:           ));
yview = Q(Volume(:           ,curpoints(2),:           ));
zview = Q(Volume(:           ,:           ,curpoints(3)));

try
    xviewo = Q(Overlay(curpoints(1),:           ,:           ));
    yviewo = Q(Overlay(:           ,curpoints(2),:           ));
    zviewo = Q(Overlay(:           ,:           ,curpoints(3)));
end


% Use the same, symmetrical [-x x] color scaling for everything
limx = handles.limz;
limy = handles.limz;
limz = handles.limz;

    
% current smoothing kernel
try
    xviewo = HighResMeanFilt(xviewo,1,handles.smooth);
    yviewo = HighResMeanFilt(yviewo,1,handles.smooth);
    zviewo = HighResMeanFilt(zviewo,1,handles.smooth);
end

try
    % recalculate constant colorbar caxis
    ovr = [xviewo(:); yviewo(:); zviewo(:)];
    handles.limz = max(abs(ovr(:)));
    limx = handles.limz;
end

% delete preiouvs colorbar
if isfield(handles,'cb')
    handles.cb.delete()
end

% the plots: (x)
%-------------------------------------------------------
axes(handles.axes1); hold off;

S  = ( flipud(xview') );
XO = ( flipud(xviewo') );

% Plot the sturctural image in axes 1
XS = mat2gray(S);
h0 = imshow(XS);% hold on;

% Gen new axes over the top
axb = axes('position', get(handles.axes1, 'position'));
set(axb,'visible','off')

% plot overlay in new axes
axes(axb);
caxis([-limx limx]);
h1 = imshow(XO,[-limx limx],'Colormap',cmocean('balance'));
caxis([-limx limx]);

switch handles.AlphaMask
    case 'O'
        SO = XO;
    case 'S'
        SO = S;
end

set(h1,'AlphaData',abs(SO));
caxis([-limx limx]);
caxis([-limx limx]);

% crosshairs
hold on;
line([0 256],[256-curpoints(3) 256-curpoints(3)],'Color','w','linewidth',2);
line([curpoints(2) curpoints(2)],[0 256],'Color','w','linewidth',2);

handles.cb = colorbar(axb,'Position',[.5 .1 .04 .3]);% Left, Btm, Wdth, Ht

% the slider: (x)
set(handles.slider1, 'Min', 1);
set(handles.slider1, 'Max', size(Volume,1));
set(handles.slider1, 'Value', curpoints(1));
set(handles.slider1, 'SliderStep', [1/size(Volume,1) , 10/size(Volume,1) ]);


% the plots: (y)
%-------------------------------------------------------
axes(handles.axes2); hold off;

S  = fliplr(flipud(yview'));
YO = fliplr(flipud(yviewo'));

% Plot the sturctural image in axes 1
YS = mat2gray(S);
h0 = imshow(YS);% hold on;

% Gen new axes over the top
axb2 = axes('position', get(handles.axes2, 'position'));
set(axb2,'visible','off')

% plot overlay in new axes
axes(axb2);
caxis([-limx limx]);
h1 = imshow(YO,[-limx limx],'Colormap',cmocean('balance'));

switch handles.AlphaMask
    case 'O'
        SO = YO;
    case 'S'
        SO = S;
end

set(h1,'AlphaData',abs(SO));
caxis([-limx limx]);
caxis([-limx limx]);

% crosshairs
hold on;
line([0 256],[256-curpoints(3) 256-curpoints(3)],'Color','w','linewidth',2);
line([curpoints(1) curpoints(1)],[0 256],'Color','w','linewidth',2);

% the slider: (y)
set(handles.slider2, 'Min', 1);
set(handles.slider2, 'Max', size(Volume,2));
set(handles.slider2, 'Value', curpoints(2));
set(handles.slider2, 'SliderStep', [1/size(Volume,2) , 10/size(Volume,2) ]);



% the plots (z)
%-------------------------------------------------------
axes(handles.axes3); hold off;

S  = fliplr(flipud(zview'));
ZO = fliplr(flipud(zviewo'));

% Plot the sturctural image in axes 1
ZS = mat2gray(S);
h0 = imshow(ZS);  % hold on;


% Gen new axes over the top
axb3 = axes('position', get(handles.axes3, 'position'));
set(axb3,'visible','off')

% plot overlay in new axes
axes(axb3);
caxis([-limx limx]);
h1 = imshow(ZO,[-limx limx],'Colormap',cmocean('balance'));

switch handles.AlphaMask
    case 'O'
        SO = ZO;
    case 'S'
        SO = S;
end

set(h1,'AlphaData',abs(SO));
caxis([-limx limx]);
caxis([-limx limx]);

% crosshairs
hold on;
line([0 256],[256-curpoints(2) 256-curpoints(2)],'Color','w','linewidth',2);
line([curpoints(1) curpoints(1)],[0 256],'Color','w','linewidth',2);

% the slider: (z)
set(handles.slider3, 'Min', 1);
set(handles.slider3, 'Max', size(Volume,3));
set(handles.slider3, 'Value', curpoints(3));
set(handles.slider3, 'SliderStep', [1/size(Volume,3) , 10/size(Volume,3) ]);

% the slider: smoothing
set(handles.slider4, 'Min', 1);
set(handles.slider4, 'Max', 64);
set(handles.slider4, 'Value', handles.smooth);
set(handles.slider4, 'SliderStep', [1/64 , 10/64 ]);

%set(handles.axes4,'visible',0)

% % Axes 4: XYZ view
% %------------------------
% axes(handles.axes4); hold off;
% view(3)
% 
% cps = curpoints;
% xlim([0 256]); ylim([0 256]); zlim([0 256]);
% 
% ev = Volume*0;
% ev(cps(1),:     ,:     ) = xview;
% ev(:     ,cps(2),:     ) = yview;
% ev(:     ,:     ,cps(3)) = zview;
% h4  = slice(ev,cps(1),cps(2),cps(3));  hold on;
% 
% ov = Overlay*0;
% ov(cps(1),:     ,:     ) = xviewo;
% ov(:     ,cps(2),:     ) = yviewo;
% ov(:     ,:     ,cps(3)) = zviewo;
% 
% h42 = slice(ov,cps(1),cps(2),cps(3));
% 
% 
% rotate3d on;
% set(h4,'LineStyle','none')
% set(h42,'LineStyle','none')





% XS, YS, ZS
% XO, YO, ZO





% --- Outputs from this function are returned to the command line.
function varargout = VolView_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
xv = round(get(hObject,'Value'));
handles.CurrentView(1) = xv;
handles = UpdateViews(handles);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slider2_Callback(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
yv = round(get(hObject,'Value'));
handles.CurrentView(2) = yv;
handles = UpdateViews(handles);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function slider2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slider3_Callback(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
zv = round(get(hObject,'Value'));
handles.CurrentView(3) = zv;
handles = UpdateViews(handles);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function slider3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slider4_Callback(hObject, eventdata, handles)
% hObject    handle to slider4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sm = round(get(hObject,'Value'));
handles.smooth = sm;

handles = UpdateViews(handles);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function slider4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in radiobutton1.
function radiobutton1_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton1

onoff = get(hObject,'Value');

if onoff == 1
    handles.AlphaMask = 'S';
else
    handles.AlphaMask = 'O';
end

handles = UpdateViews(handles);
guidata(hObject, handles);