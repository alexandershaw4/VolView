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

% Last Modified by GUIDE v2.5 18-Dec-2018 10:19:07

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


% Check whether filenames or structures have been passed instead 3D double
if ischar(varargin{1})
    fprintf('Loading file with fieldtrip\n');
    S = ft_read_mri(varargin{1});
    S = ft_volumereslice([],S);
    varargin{1} = S.anatomy;
elseif isstruct(varargin{1}) && isfield(varargin{1},'anatomy')
    fprintf('Input is struct: asusming ft (has .anatomy)\n');
    S = ft_volumereslice([],varargin{1});
    varargin{1} = S.anatomy;
end
if ischar(varargin{2})
    fprintf('Loading file with fieldtrip\n');
    S = ft_read_mri(varargin{2});
    S = ft_volumereslice([],S);
    varargin{2} = S.anatomy;
elseif isstruct(varargin{2}) && isfield(varargin{2},'anatomy')
    fprintf('Input is struct: asusming ft (has .anatomy)\n');
    S = ft_volumereslice([],varargin{2});
    varargin{2} = S.anatomy;
end


% Save volumes into handles
Volume         = varargin{1};
handles.Volume = Volume;

Overlay         = varargin{2};
handles.Overlay = Overlay;
handles.Orig    = Overlay;

% use a constant colorbar caxis
handles.limz = max(abs(Overlay(:)));
handles.s    = size(Volume);

% Set range for thresholding
TR = max(abs(Overlay(:)));

% set initial slider position
set(handles.slider5, 'min',0);
set(handles.slider5, 'max',TR);
set(handles.slider5,'Value',0);


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
s    = handles.s;
    
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
XS = imsharpen(XS,'Radius',3,'Amount',2);
XS = imadjust(XS);
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
line([0 s(3)],[s(3)-curpoints(3) s(3)-curpoints(3)],'Color','w','linewidth',2);
line([curpoints(2) curpoints(2)],[0 s(2)],'Color','w','linewidth',2);
%title(sprintf('x = %d y = %d, z = %d',curpoints(1),curpoints(2),s(3)-curpoints(3)));
%hold off;

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
YS = imsharpen(YS,'Radius',3,'Amount',2);
YS = imadjust(YS);
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
line([0 s(3)],[s(3)-curpoints(3) s(3)-curpoints(3)],'Color','w','linewidth',2);
line([s(1)-curpoints(1) s(1)-curpoints(1)],[0 s(1)],'Color','w','linewidth',2);

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
ZS = imsharpen(ZS,'Radius',3,'Amount',2);
ZS = imadjust(ZS);
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
line([0 s(2)],[s(2)-curpoints(2) s(2)-curpoints(2)],'Color','w','linewidth',2);
line([s(1)-curpoints(1) s(1)-curpoints(1)],[0 s(1)],'Color','w','linewidth',2);

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

% print current points [x,yz] to edit text box
set(handles.edit1,'String',[num2str(curpoints)]);




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



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double
Vx = get(hObject,'String');
Vx = str2num(Vx);
handles.CurrentView = Vx;
handles = UpdateViews(handles);
guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Find peaks pushbutton!
O = handles.Overlay;
S = std(O(:));


[idx] = find(abs(O(:)) >= (S*3));
[ix,iy,iz] = ind2sub(size(O),idx);

v     = O(idx);
[B,I] = sort(abs(v),'descend');

np = 25;

% generate a pop-up table
%-----------------------------------
f0 = get(gca,'parent');
f = figure('position',[1531         560         560         420]);
t = uitable(f);
for i = 1:np
    d{i,1} = v(I(i));
    d{i,2} = ix(I(i));
    d{i,3} = iy(I(i));
    d{i,4} = iz(I(i));
    d{i,5} = false;
end

t.Data = d;
t.ColumnName = {'Value','x','y','z'};
t.ColumnEditable = true;

table_extent = get(t,'Extent');
set(t,'Position',[1 1 table_extent(3) table_extent(4)])
figure_size = get(f,'outerposition');
desired_fig_size = [figure_size(1) figure_size(2) table_extent(3)+15 table_extent(4)+65];
set(f,'outerposition', desired_fig_size);

%waitfor(f) % while the peaks box is open
fprintf('Waiting: Click in peaks table to view peaks!\n');
while isvalid(f)
    
    waitfor(t,'Data')
    i = find(cell2mat(t.Data(:,5))); % wait for click in column 5
    if any(i)
        if i < length(d)
            this = t.Data(i,:);
            
            CP = [this{2} this{3} this{4}];
            handles.CurrentView = CP;
            handles = UpdateViews(handles);
            
        end
    end
    
end
        











% --- Executes on slider movement.
function slider5_Callback(hObject, eventdata, handles)
% hObject    handle to slider5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% Overlay threshold slider!
T = get(hObject,'Value');

% backup original overlay data
O = handles.Overlay;
I = find(abs(O(:)) < T);
O(I) = 0;
handles.Overlay = O;
handles = UpdateViews(handles);
guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function slider5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in radiobutton2.
function radiobutton2_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton2

% reset threshold button - just a trigger
handles.Overlay = handles.Orig;
handles = UpdateViews(handles);
set(handles.radiobutton2, 'Value',0);
set(handles.slider5,'Value',0);
guidata(hObject, handles);



