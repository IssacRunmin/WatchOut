function varargout = ComHelper(varargin)
% COMHELPER MATLAB code for ComHelper.fig
%      COMHELPER, by itself, creates a new COMHELPER or raises the existing
%      singleton*.
%
%      H = COMHELPER returns the handle to a new COMHELPER or the handle to
%      the existing singleton*.
%
%      COMHELPER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in COMHELPER.M with the given input arguments.
%
%      COMHELPER('Property','Value',...) creates a new COMHELPER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ComHelper_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ComHelper_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ComHelper

% Last Modified by GUIDE v2.5 15-Oct-2017 17:00:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ComHelper_OpeningFcn, ...
                   'gui_OutputFcn',  @ComHelper_OutputFcn, ...
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


% --- Executes just before ComHelper is made visible.
function ComHelper_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ComHelper (see VARARGIN)

% Choose default command line output for ComHelper
handles.output = hObject;
forbluetooth = 1;

% Update handles structure
guidata(hObject, handles);
% Get the COM Serial information
serial_info = instrhwinfo('serial');
% Bluetooth_info = instrhwinfo('Bluetooth');
% for COMs
try
    if forbluetooth == 1
        error('For bluetooth');
    end
    serial_info = instrhwinfo('serial');
    if size(serial_info.SerialPorts,1) ~= 0
        %serial_choice = serial_info.RemoteNames;
        serial_choice = serial_info.SerialPorts;
        set(handles.COM, 'String', char(serial_choice));
    else
        set(handles.COM, 'String', ' ');
    end
catch
% for bluetooth
    serial_info = instrhwinfo('Bluetooth');
    if size(serial_info.RemoteNames,1) ~= 0
        serial_choice = serial_info.RemoteNames;
        %serial_choice = serial_info.SerialPorts;
        set(handles.COM, 'String', char(serial_choice));
    else
        set(handles.COM, 'String', ' ');
    end
end
% UIWAIT makes ComHelper wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ComHelper_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in COM.
function COM_Callback(hObject, eventdata, handles)
% hObject    handle to COM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns COM contents as cell array
%        contents{get(hObject,'Value')} returns selected item from COM
get(hObject,'String');

% --- Executes during object creation, after setting all properties.
function COM_CreateFcn(hObject, eventdata, handles)
% hObject    handle to COM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu2.
function popupmenu2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu2


% --- Executes during object creation, after setting all properties.
function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu4.
function popupmenu4_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu4 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu4


% --- Executes during object creation, after setting all properties.
function popupmenu4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu5.
function popupmenu5_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu5 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu5


% --- Executes during object creation, after setting all properties.
function popupmenu5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu6.
function popupmenu6_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu6 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu6


% --- Executes during object creation, after setting all properties.
function popupmenu6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


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

% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function a_X_Callback(hObject, eventdata, handles)
% hObject    handle to a_X (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of a_X as text
%        str2double(get(hObject,'String')) returns contents of a_X as a double


% --- Executes during object creation, after setting all properties.
function a_X_CreateFcn(hObject, eventdata, handles)
% hObject    handle to a_X (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over pushbutton3.
function pushbutton3_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)





function a_Y_Callback(hObject, eventdata, handles)
% hObject    handle to a_Y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of a_Y as text
%        str2double(get(hObject,'String')) returns contents of a_Y as a double


% --- Executes during object creation, after setting all properties.
function a_Y_CreateFcn(hObject, eventdata, handles)
% hObject    handle to a_Y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function a_Z_Callback(hObject, eventdata, handles)
% hObject    handle to a_Z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of a_Z as text
%        str2double(get(hObject,'String')) returns contents of a_Z as a double


% --- Executes during object creation, after setting all properties.
function a_Z_CreateFcn(hObject, eventdata, handles)
% hObject    handle to a_Z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function g_X_Callback(hObject, eventdata, handles)
% hObject    handle to g_X (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of g_X as text
%        str2double(get(hObject,'String')) returns contents of g_X as a double


% --- Executes during object creation, after setting all properties.
function g_X_CreateFcn(hObject, eventdata, handles)
% hObject    handle to g_X (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function g_Y_Callback(hObject, eventdata, handles)
% hObject    handle to g_Y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of g_Y as text
%        str2double(get(hObject,'String')) returns contents of g_Y as a double


% --- Executes during object creation, after setting all properties.
function g_Y_CreateFcn(hObject, eventdata, handles)
% hObject    handle to g_Y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function g_Z_Callback(hObject, eventdata, handles)
% hObject    handle to g_Z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of g_Z as text
%        str2double(get(hObject,'String')) returns contents of g_Z as a double


% --- Executes during object creation, after setting all properties.
function g_Z_CreateFcn(hObject, eventdata, handles)
% hObject    handle to g_Z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function m_X_Callback(hObject, eventdata, handles)
% hObject    handle to m_X (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of m_X as text
%        str2double(get(hObject,'String')) returns contents of m_X as a double


% --- Executes during object creation, after setting all properties.
function m_X_CreateFcn(hObject, eventdata, handles)
% hObject    handle to m_X (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function m_Y_Callback(hObject, eventdata, handles)
% hObject    handle to m_Y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of m_Y as text
%        str2double(get(hObject,'String')) returns contents of m_Y as a double


% --- Executes during object creation, after setting all properties.
function m_Y_CreateFcn(hObject, eventdata, handles)
% hObject    handle to m_Y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function m_Z_Callback(hObject, eventdata, handles)
% hObject    handle to m_Z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of m_Z as text
%        str2double(get(hObject,'String')) returns contents of m_Z as a double


% --- Executes during object creation, after setting all properties.
function m_Z_CreateFcn(hObject, eventdata, handles)
% hObject    handle to m_Z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1
function edit14_Callback(hObject, eventdata, handles)
% hObject    handle to edit14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit14 as text
%        str2double(get(hObject,'String')) returns contents of edit14 as a double


% --- Executes during object creation, after setting all properties.
function edit14_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit15_Callback(hObject, eventdata, handles)
% hObject    handle to edit15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit15 as text
%        str2double(get(hObject,'String')) returns contents of edit15 as a double


% --- Executes during object creation, after setting all properties.
function edit15_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.pushbutton2,'enable','off');
drawnow;
try
% for COMs
    forbluetooth = get(handles.checkbox1,'Value');
    if forbluetooth == 1
    error('For bluetooth');
    end
    serial_info = instrhwinfo('serial');
    if size(serial_info.SerialPorts,1) ~= 0
        %serial_choice = serial_info.RemoteNames;
        serial_choice = serial_info.SerialPorts;
        set(handles.COM, 'String', char(serial_choice));
    else
        set(handles.COM, 'String', ' ');
    end
catch
% for bluetooth
    serial_info = instrhwinfo('Bluetooth');
    if size(serial_info.RemoteNames,1) ~= 0
        serial_choice = serial_info.RemoteNames;
        %serial_choice = serial_info.SerialPorts;
        set(handles.COM, 'String', char(serial_choice));
    else
        set(handles.COM, 'String', ' ');
    end
end
set(handles.pushbutton2,'enable','on');


% --- Executes on button press in pushbutton3.
% Open/Close the Serial
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Data;
global XData;
global pitch;
global L1;

set(handles.pushbutton3,'enable','off');
drawnow;
forbluetooth = get(handles.checkbox1,'Value');
button_state = get(handles.pushbutton3,'String');
if 1 == strcmpi(button_state, 'OpenCOM')
    Data = ones(1,9);
    XData = 1:100;%初始化坐标轴的数据为0
    pitch = ones(1,100);
    serial_info = get(handles.COM,'String');
    if serial_info == ' '
        msgbox('Unavailable COMs','Error!');
        return;
    end
    info_baud = str2double(get(handles.popupmenu2,'String'));
    info_data = str2double(get(handles.popupmenu4,'String'));
    info_stop = str2double(get(handles.popupmenu5,'String'));
    choice_baud = get(handles.popupmenu2,'Value');
    choice_data = get(handles.popupmenu4,'Value');
    choice_stop = get(handles.popupmenu5,'Value');
    baud_rate = info_baud(choice_baud);
    data_bits = info_data(choice_data);
    stop_bits = info_stop(choice_stop);
    switch get(handles.popupmenu6, 'value')
    case 1
        jiaoyan = 'none';
    case 2
        jiaoyan = 'odd';
    case 3
        jiaoyan = 'even';
    end
    % 创建串口对象
    choice_serial = get(handles.COM,'Value');
    % For COMs
    if forbluetooth == 0
    scom = serial(serial_info(choice_serial,:));
    % 配置串口属性，指定其回调函数
     set(scom, 'BaudRate', baud_rate, 'Parity', jiaoyan, 'DataBits',...
     data_bits, 'StopBits', stop_bits,...
     'BytesAvailableFcnMode', 'Terminator', 'BytesAvailableFcn', {@my_callback, handles});
    % 将串口对象的句柄作为用户数据，存入窗口对象
     set(handles.figure1, 'UserData', scom);
    else
    %for Bluetooth
    stopb = strfind(serial_info(choice_serial,:),' ');
    if isempty(stopb)
        stopb = size(serial_info,2);
    else
        stopb = stopb(1) - 1;
    end
    scom = Bluetooth(serial_info(choice_serial,1:stopb),1);
    L1 = stem(handles.axes1, XData, pitch);
    set(scom,'BytesAvailableFcnMode', 'Terminator', 'BytesAvailableFcn', {@my_callback, handles});
    % 将串口对象的句柄作为用户数据，存入窗口对象
    %set(handles.figure1, 'UserData', scom);
    % 尝试打开串口
    end
    try
        fopen(scom);
        tic;
    catch   % 若串口打开失败，提示“串口不可获得！”
    msgbox('Unavailable COM','Error!');
    set(handles.pushbutton3,'enable','on');
    
    return;
    end
    set(handles.edit1,'enable','on');
    set(handles.pushbutton1,'enable','on');
    set(handles.pushbutton5,'enable','on');
    set(handles.pushbutton6,'enable','on');
    set(handles.pushbutton3,'String','CloseCOM');
    set(handles.pushbutton3,'enable','on');
    set(handles.pushbutton2,'enable','off');
    set(handles.COM,'enable','inactive');
    set(handles.popupmenu2,'enable','inactive');
    set(handles.popupmenu4,'enable','inactive');
    set(handles.popupmenu5,'enable','inactive');
    set(handles.popupmenu6,'enable','inactive');
    set(handles.pushbutton7,'enable','on');
    
else
    scoms = instrfind;
    fclose(scoms);
    clear Data pitch XData
    delete(scoms);
    set(handles.edit1,'enable','inactive');
    set(handles.pushbutton1,'enable','off');
    set(handles.pushbutton5,'enable','off');
    set(handles.pushbutton6,'enable','off');
    set(handles.pushbutton3,'String','OpenCOM');
    set(handles.pushbutton2,'enable','on');
    set(handles.COM,'enable','on');
    set(handles.popupmenu2,'enable','on');
    set(handles.popupmenu4,'enable','on');
    set(handles.popupmenu5,'enable','on');
    set(handles.popupmenu6,'enable','on');
    set(handles.pushbutton7,'enable','off');
    set(handles.pushbutton8,'enable','off');
end
set(handles.pushbutton3,'enable','on');




function my_callback(obj,~,handles)
%   串口的BytesAvailableFcn回调函数
% 定义一些全局变量
    g = 9.80665;
    sel_a = 16384;
    sel_g = 131;
    sel_m = 0.3;
    global Data;
    global L1;
    global XData;
    global pitch;
    global time;
% 每运行一次本函数X轴的数据+1
    T = 0.02;
    k = 20.5; % empirically
    MaxLen = 500; % The longest range that drawtime
% 接收串口发送过来的数据（这里有时会出现BUG，具体原因不详）
    outdata = fscanf(obj);
    while ~isempty(strfind(outdata,'i'))
        outdata = fscanf(obj);
    end
    YData = str2num(outdata);%将字符串转化成数值类型
    while size(YData,2) ~= 9
        outdata = fscanf(obj);
        YData = str2num(outdata);%将字符串转化成数值类型
    end
    % process the bits to physical data
    YData(:, 1:3) = YData(:, 1:3) ./ sel_a .* g; % accelerator
    YData(:, 4:6) = YData(:, 4:6) ./ sel_g; %gyroscope
    YData(:, 7:9) = YData(:, 7:9) .* sel_m; %Magnetometer
    Data = cat(1,Data,YData);
    if mod(size(Data,1),10) == 0 %every 0.2s plot the figure;
        time = toc;
        len = size(Data,1);
        if len > MaxLen
            TData = Data(len - MaxLen + 1: len,:);
            XData = len - MaxLen + 1: len;
            len = MaxLen;
        else
            TData = Data;
            XData = 1:len;
        end
        alpha_i = zeros(1,len);
        v = zeros(1,len);
        w = zeros(1,len);
        pitch = zeros(1,len);
    % Processing the pitch & Yaw

        for i = 1:len
            alpha_i(i) = atan(TData(i,1) ./ TData(i,3));
            if i == 1
                v(i) = T * k * k * alpha_i(i);
                w(i) = v(i) + 2 * k * alpha_i(i) + TData(i,4);
                pitch(i) = T * w(i);
            else
                v(i) =  T * k * k * (alpha_i(i) - pitch(i-1)) + v(i-1);
                w(i) = v(i) + 2 * k *(alpha_i(i) - pitch(i-1)) + TData(i,4);
                pitch(i) = T * w(i) + pitch(i - 1);
            end
        end

    % 将数值数据格式化成字符串
        txt_a_x = sprintf('%f',YData(:,1));
        txt_a_y = sprintf('%f',YData(:,2));
        txt_a_z = sprintf('%f',YData(:,3));
        txt_g_x = sprintf('%f',YData(:,4));
        txt_g_y = sprintf('%f',YData(:,5));
        txt_g_z = sprintf('%f',YData(:,6));
        txt_m_x = sprintf('%f',YData(:,7));
        txt_m_y = sprintf('%f',YData(:,8));
        txt_m_z = sprintf('%f',YData(:,9));
    % 显示接收的字符串
    % time = cputime();
        set(handles.a_X,'String',[txt_a_x 'm/s^2']);
        set(handles.a_Y,'String',[txt_a_y 'm/s^2']);
        set(handles.a_Z,'String',[txt_a_z 'm/s^2']);
        set(handles.g_X,'String',[txt_g_x '°/s']);
        set(handles.g_Y,'String',[txt_g_y '°/s']);
        set(handles.g_Z,'String',[txt_g_z '°/s']);
        set(handles.m_X,'String',[txt_m_x 'μT/s']);
        set(handles.m_Y,'String',[txt_m_y 'μT/s']);
        set(handles.m_Z,'String',[txt_m_z 'μT/s']);
        set(handles.edit15, 'String', num2str(size(Data,1)));
        XData = XData ./ 50;
        if mod(size(Data,1),20) == 0
            set(L1,'XData', XData, 'YData', pitch);
            set(handles.axes1,'XLim',[XData(1) XData(len)]);
    %         drawnow
        end
        drawnow;
    end
%      plot(XData,pitch);
%      axis tight;
%     duration = cputime() - time;
%       set(handles.m_Z,'String','Done');
    


% --- Executes on button press in pushbutton7.
function pushbutton7_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Data;
Data = ones(1,9);
set(handles.pushbutton7,'enable','off');
set(handles.pushbutton8,'enable','on');
tic;



% --- Executes on button press in pushbutton8.
function pushbutton8_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% End & Save the file
    global time;
    global Data;
    file_path = get(handles.edit14,'String');
    index = strfind(file_path,'/');
    if isempty(index) %Save the data in the current workspace
        save([file_path '.mat'],'Data');
    else % Save the data in the directory
        try
            save([file_path '.mat'], 'Data','time');
        catch
            file_dir = file_path(1:index(size(index,2)) - 1);
            try
                mkdir(file_dir);
                save([file_path '.mat'],'Data','time');
            catch
                msgbox('Saving failed!','ERROR');
            end
        end
    end
    set(handles.pushbutton7,'enable','on');
    
