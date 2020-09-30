%% Parameters 
% Change These:
Phone = 1;
UserCount = 6;

BiasTimeAdjust = 0;
SaveIntoResult = 0;



Phones = {'GalaxyNote3';'HuaWei';'Mi6X'};
Userz = {
'20180803-LJW\';% GHM
'20180803-ZXY\';% X
'20180804-WX\'; % GHM
'20180804-XZC\';% GHM
'20180805-BHL\';% GHM 5
'20180805-ORM\';% GHM
'20180805-WZY\';% GHM
'20180806-MZK\';% GHM
'20180806-WM\'; % GHM
'20180807-QWY\';% GHM 10
'20180807-TMM\';% GHM
'20180808-HYT\';%-G-
'20180808-XYX\';% GHM
'20180809-GZC\';%---
'20180810-LXX\';% GHM  15
'20180810-MLK\';% GHM
'20180811-HWL\';% GHM
'20180811-LC\'; % GHM
'20180812-KCX\';% GHM
'20180813-CYJ\';%   M 20
'20180813-YYX\';% GHX
'20180814-CC\'; % GHM
'20180814-WF\'; % GHM
'20180915-Xu J.C\';% GHM
'20180915-Zhang T.G\'};%25 GHX


FileDir = ['MobilePhoneSensor\' Phones{Phone} '\' Userz{UserCount}];
% FileDir = 'MobilePhoneSensor/GalaxyNote3/20180731_ORM_GalaxyNote3/';% 路径名，就是所在文件夹，绝对路径或相对此脚本的路径
FileChoice = 1;
FigurePlot = 5;% 画图0：Pitch和Yaw；1：Pitch；2：Yaw 3: acc_mag
%-11;0606  % Bias Time, due to the different time of two phones
% Accuracy
MissCount = zeros(1,2);
TotalCount = zeros(1,2);
EntranceNum = 0;
CorrectNum = 0;
% EntranceDis; 
% FSM 
Neg_Thr = -30;

PlotState = 1;
PlotAllLabel = false;  % Plot all the label including flat
% ??
CutoffFreq_Pitch = 5; % Cutoff Frequency Pitch
CutoffFreq_Yaw = 2; % Cutoff Frequency Yaw
CutoffFreq_AccMag = 5;
TurnStartStep = 15;
TurnThreshold = 65;
StepWindow = 4;
ThRamp = 4; % °
ThCurb = 60; % m/s^2



RecordRange = abs(BiasTimeAdjust) + 10; %s, for 60s before or after the RawFile recorded
% For Ground Truth generation
    Event_FL = 1;
    Event_UR = 2;
    Event_DR = 3;
    Event_UC = 4;
    Event_DC = 5;
    Event_LT = 6;
    Event_RT = 7;
    MaxRampMiss = 10;
    State_FL = 1;
    State_UR = 2;
    State_DR = 3;
    State_UC = 4;
    State_DC = 5;
    State_Road = 6;
    Matlab_Event_Turn = 6;
SampleRate = 70; % Hz
StartStep = 6; % When to detect events
butter_fs_mag = 2;
butter_fs_yaw = 4;
AzimuthThreshold = 75;
INTERVAL = 10; % Interval between each file
%% initial
for LookUpT = 1 : 2
    FilesLike = [ 'LookUp' num2str(LookUpT)  '-2018*.txt']; % The Raw Data Files Like
    LinkFileNum = length(FileChoice);
    FileRecordTime = zeros(LinkFileNum, 1);
    Files = dir(fullfile(FileDir,FilesLike));
    if isempty(Files)
        error(['No files in the directory:' FileDir]);
    end
    FileNames = {Files.name}';
    FileNum = length(FileNames);
    RawData = zeros(6,0);
    S_AccMag = zeros(1,0);
    StatePoints = zeros(1,0);
    S_EndTime  = zeros(1,0);
    S_States = zeros(1,0);
    S_Pitch = zeros(1,0);
    S_ButterYaw = zeros(1,0);
    Time = zeros(1,0);
    Locs = zeros(1,0);
    Features = zeros(0,7);
    AbstractTime = 0;
    AbstractIndex = 0;
    AbTimeSet = zeros(1,LinkFileNum);
    for FileCount = 1 : LinkFileNum
    %% RawData
    %               1    2    3  4  5 6  7  8     9         10        11    12
    % File Style: Count Time Ax Ay Az Gx Gy Gz ButterYaw CircleLen FSM_State
    % StateLen
        RawFile = FileNames{FileChoice(FileCount)};
        StepFile = ['LookUp' num2str(LookUpT) '-ForStep' RawFile(9:end)];
        HaveStepFile = true;
        try
            FileHandle = fopen(fullfile(FileDir,RawFile));
            RawData_t = fscanf(FileHandle,'%f',[12 inf]);

            fclose(FileHandle);
        catch
            error('Orm: 文件路径有误，无法读取文件……');
        end
        if RawData_t(1,2) - RawData_t(1,1) ~= 1
            error('Orm: BTFile - Wrong Data Format');
        end
        Time_t = RawData_t(2,:) ./ 1000  + AbstractTime;
        StatePoints_t = RawData_t(11,:);
        S_ButterYaw_t = RawData_t(9,:);
        RawData_t = RawData_t(3:8,:);

        % Android Step Process
        try
            FileHandle = fopen(fullfile(FileDir,StepFile));
            %
            % Time StancePitch StanceYaw maxAccMag StanceLength StepLength State
            Features_t = fscanf(FileHandle,'%f',[7,inf]);
            fseek(FileHandle,-30,'eof');
            TempStr = fgetl(FileHandle);
            PitchStatic = str2double(TempStr(strfind(TempStr,'=') + 1 : end)); % rad
            PitchStatic = PitchStatic .* 180 ./ pi;
            fclose(FileHandle);
            S_States_t = Features_t(7,:);

            S_Pitch_t = Features_t(2,:);
            S_EndTime_t = Features_t(1,:) ./ 1000 + AbstractTime;
            S_AccMag_t = Features_t(4,:);
        catch
            error('Orm: No StepData File Found!');
            HaveStepFile = false;
        end
        if HaveStepFile
            S_TLen = length(S_EndTime_t);
            TLen = length(Time_t);
            Time_i = 1;
            STime_i = 1;
            Locs_t = zeros(1,S_TLen);
            while (STime_i <= S_TLen)
                if abs(Time_t(Time_i) - S_EndTime_t(STime_i)) < 0.005 || Time_t(Time_i) > S_EndTime_t(STime_i)
                    Locs_t(STime_i) = Time_i;
                    STime_i = STime_i + 1;
                end
                Time_i = Time_i + 1;
                if Time_i > TLen
                    break;
                end
            end
            clear Time_i STime_i
        end
        %% Record the File Create Time
        Index = strfind(RawFile, '-');
        RecordTimeMs = str2double(RawFile(Index(3)+1:Index(4)-1));
        TempString = RawFile(Index(1)+1:(Index(3)-1));
        TempString(strfind(TempString, '-')) = ' ';
        TempString = insertBefore(TempString,5,'-');
        TempString = insertBefore(TempString,8,'-');
        TempString = insertBefore(TempString,14,':');
        RecordTimeString = insertBefore(TempString,17,':');
        DateFloat = datenum(RecordTimeString ,'yyyy-mm-dd HH:MM:SS');
        FileRecordTime(FileCount) = DateFloat * 24 * 3600 + RecordTimeMs / 1000;
        %% Link Files
        Time = cat(2,Time,Time_t);
        StatePoints = cat(2,StatePoints,StatePoints_t);
        S_ButterYaw = cat(2,S_ButterYaw,S_ButterYaw_t);
    %     RawData_t(1:6,[1 end]) = 0;
        RawData = cat(2,RawData,RawData_t);
        if HaveStepFile
            S_States = cat(2,S_States,S_States_t);
            S_Pitch = cat(2,S_Pitch,S_Pitch_t);
            S_EndTime = cat(2,S_EndTime,S_EndTime_t);
            S_AccMag = cat(2,S_AccMag,S_AccMag_t);
            Locs = cat(2,Locs,Locs_t + AbstractIndex);
            AbstractIndex = Locs(end);
        end
        AbTimeSet(FileCount) = AbstractTime;
        AbstractTime = Time_t(end) + INTERVAL;
    end
    %% Pitch & Yaw & AccMag 
    k=10; %BANDWIDTH????
    i=1;
    T=1/SampleRate; 
    acc_x = RawData(1,:);
    acc_z = RawData(3,:);
    gyro_y = RawData(5,:);
    DataLen = length(acc_x);
    pitch = zeros(1,length(acc_x));
    alpha = zeros(1,DataLen);
    beta = zeros(1,DataLen);
    v = zeros(1,DataLen);
    w = zeros(1,DataLen);
    alpha(i)=atan(acc_x(i)/acc_z(i));
    beta(i)=alpha(i);
    v(i)=T*k*k*beta(i);
    w(i)=v(i)+2*k*beta(i)+gyro_y(i)/180*pi;
    pitch(i)=T*w(i);
    for i=2:length(acc_x)
      alpha(i)=atan(acc_x(i)/acc_z(i));
      beta(i)=alpha(i)-pitch(i-1);
      v(i)=T*k*k*beta(i)+v(i-1);
      w(i)=v(i)+2*k*beta(i)+gyro_y(i)/180*pi;
      pitch(i)=T*w(i)+pitch(i-1);
    end;
    pitch = pitch .* 180 ./ pi;
    % yaw = IMU(RawData',5,0.005);
    % yaw = yaw';
    % for i=2:length(yaw)
    %     if(abs(yaw(i)-yaw(i-1))>180)
    %         kkk=round((yaw(i-1)-yaw(i))/360);
    %         yaw(i)=yaw(i)+kkk*360;
    %     end;
    % end;
    AccMag = sqrt(RawData(2,:) .^2 + RawData(3,:) .^2);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FSM: 
    PitchStatic_M = mean(pitch);
    WLen = 25;
    ALen = length(pitch);
    StdSeries = zeros(1, ALen - WLen);
    for i = 1 : ALen - WLen
        temp = std(pitch(i : i + WLen));
        StdSeries(i) = temp;
    end
    
    
    
    % Use FSM in Mobilephone as Step Segmentation
    S_Pitch = S_Pitch .* 180 ./ pi;
    SS = find(StdSeries < 5); % StanceState
    EndPoints = [SS(SS(2 : end) - SS(1 : end - 1) > 1) SS(end)];
    StartPoints = [SS(1) SS(find(SS(2 : end) - SS(1 : end - 1) > 1) + 1)];
    Yaw = IMU(RawData',5,0.005);
    %Circle Yaw
    Len_t = length(Yaw);
    for i = 2 : Len_t
        if abs(Yaw(i) - Yaw(i-1)) > 180
            temp = round((Yaw(i-1) - Yaw(i))/360);
            Yaw(i) = Yaw(i) + temp * 360;
        end
    end
    
    % Miss Label
    MeanInterval = mean(StartPoints(2 : end) - StartPoints(1 : end-1)); % Points
    MeanDuration = round(mean(EndPoints-StartPoints));
    MissLoc = find(StartPoints(2 : end) - StartPoints(1 : end-1) > MeanInterval * 1.5);
    MissCount(LookUpT) = length(MissLoc);
    
    if ~isempty(MissLoc)
        locs = StartPoints;
        locsE = EndPoints;
        locsE_t = EndPoints(1 : MissLoc(1));
        locs_t = StartPoints(1 : MissLoc(1));
        clear round
        % Find Missed Steps and Label it
        for i = 1 : length(MissLoc)
            temp = floor((locs(MissLoc(i) + 1) - locs(MissLoc(i))) / MeanInterval - 0.4) ;
            locsTemp = [];
            locsETemp = [];
            for j = 1 : temp
                locsTemp(j) = locs(MissLoc(i)) + round(MeanInterval * j);
                %pksTemp(j) = pks(MissLoc(i)) + (pks(MissLoc(i) + 1) - pks(MissLoc(i))) / 2;
                locsETemp(j) = locsTemp(j) + MeanDuration;
            end
            if i ~= length(MissLoc)
                locs_t = [locs_t, locsTemp, locs((MissLoc(i) + 1) : (MissLoc(i+1)))];
                locsE_t = [locsE_t, locsETemp, locsE((MissLoc(i) + 1) : (MissLoc(i+1)))];
            else
                locs_t = [locs_t, locsTemp, locs((MissLoc(end) + 1) : end)];
                locsE_t = [locsE_t, locsETemp, locsE((MissLoc(end) + 1) : end)];
            end
        end
        StartPoints = locs_t(2:end);%cancel some possible false peaks
        EndPoints = locsE_t(2:end);
    else
        StartPoints = StartPoints(2:end);%cancel some possible false peaks
        EndPoints = EndPoints(2:end);
    end
    StepNum = length(StartPoints);
    TotalCount(LookUpT) = StepNum;
    % Get Slope
    Slope = zeros(1,StepNum);
    for i = 1 : StepNum
        Slope(i) = mean(pitch(StartPoints(i) : EndPoints(i))) - PitchStatic;
    end
    % Get Force
    Force = zeros(1,StepNum);
    for i = 1 : StepNum-1
        Force(i) = max(AccMag(StartPoints(i) : StartPoints(i+1)));
    end
    % Get Angle
    Angle = zeros(1,StepNum);
    for i = 1 : StepNum-1
        Angle(i) = mean(Yaw(StartPoints(i):EndPoints(i)));
    end
    % Events Detect
    Label = ones(1,StepNum);
    Turned = TurnStartStep;
    for i = 1 : StepNum
        if Turned > 0
            Turned = Turned - 1;
            continue;
        end
        YawPre = Angle(i-TurnStartStep : i - floor(TurnStartStep/2));
        YawNear = Angle(i - 2:i);
        if abs(mean(YawPre) - mean(YawNear)) > TurnThreshold
            Label(i) = Matlab_Event_Turn;
            Turned = TurnStartStep;
        end
    end
    for i = 1 + StepWindow : StepNum
        if range(Slope(i-StepWindow : i)) > ThRamp
            diff = Slope(i) - Slope(i-StepWindow);
            if (diff > ThRamp)
                Label(i) = Event_UR;
            else
                if diff < -ThRamp
                    Label(i) = Event_DR;
                end
            end
            if Force(i) > ThCurb
                Label(i) = Event_DC;
            end
        end
    end
    Labels{LookUpT} = Label;
end
%% Generate GroundTruth
[HaveGTFile, State, Seq] = GenerateGroundTruth_Orm201807272112...
                (FileDir, FileRecordTime, FileNum,RecordRange, BiasTimeAdjust,AbTimeSet, StartPoints, Time, Label);
            
%% Accuracy

SSI = find(Seq == Event_DR | Seq == Event_DC);
SeqI = [SSI(SSI(2 : end) - SSI(1 : end - 1)>1) SSI(end)]; % Entrance事件的结束
EntranceDis = zeros(1,length(SeqI));
Correct = 0;
for i = 1 : length(SeqI)
    Index = SeqI(i);
    First_ = ones(1,2) .* (Index + 5);
    RampPair = [false false];
    for j = Index - 12 : Index + 5
        if j <= 0 || j > length(Seq)
            continue;
        end
        if Labels{1}(j) == Event_DC || Labels{2}(j) == Event_DC % Curb Detected
            Correct = Correct + 1;
            EntranceDis(i) = j - SeqI(i);
            break;
        end
        for L = 1 : 2
            if Labels{L}(j) == Event_DR % The First Ramp in this foot
                if RampPair(L) && ~RampPair(3-L) % Two DR For One Foot
                    RampPair(3 - L) = true;
                    First_(3 - L) = j;
                end
                RampPair(L) = true;
                if First_(L) > j 
                    First_(L) = j;
                end
            end
        end
        if RampPair(1) && RampPair(2)
            Correct = Correct + 1;
            EntranceDis(i) = min(First_) - SeqI(i);
            if EntranceDis(i) < - 8
                EntranceDis(i) = max(First_) - SeqI(i);
            end
            break;
        end
    end
end
%% Draw Figure;
High = 6.5/10;
[b,a] = butter(6,CutoffFreq_Pitch/(SampleRate/2));
ProcessPitch = filter(b,a,pitch);
[b,a] = butter(10,CutoffFreq_Yaw/(SampleRate/2));
ProcessYaw = filter(b,a,Yaw);
[b,a] = butter(6,CutoffFreq_AccMag/(SampleRate/2));
ProcessAccMag = filter(b,a,AccMag);
close all


% Pitch
if FigurePlot == 1 || FigurePlot == 0
    figure;
    subplot(2,1,1);
    plot(Time,pitch);
    hold on
    if HaveStepFile
        plot(S_EndTime, S_Pitch,'LineStyle','none','Marker', 'v');
        A_StateIndex = find(StatePoints == 3);
        scatter(Time(A_StateIndex),pitch(A_StateIndex),'.');
        scatter(Time(StdSeries < 5), pitch(StdSeries), 'r,');
        legend('Matlab\_Pitch','Android\_Pitch');
    else
        legend('Matlab\_Pitch');
    end
    Plot_GroundTruth_Android_Bluetooth_160424_1155;
    title(['FileName: ' strrep(RawFile,'_','\_')]);
    xlabel('Time/s');
    ylabel('Pitch/°');
    subplot(2,1,2);
    plot(Time,ProcessPitch);
    hold on
    if exist('A_Time','var')
        plot(A_Time, A_Pitch,'LineStyle','none','Marker', 'v');
        legend('Matlab\_Pitch','Android\_Pitch');
    else
        legend('Matlab\_Pitch');
    end
    Plot_GroundTruth_Android_Bluetooth_160424_1155;
    title(['ProcessedPitch. FileName: ' strrep(RawFile,'_','\_')]);
    xlabel('Time/s');
    ylabel('Pitch/°');
end
% Yaw
if FigurePlot == 2 || FigurePlot == 0
    figure;
    subplot(2,1,1);
    plot(Time,Yaw);
    hold on
    plot(Time,S_ButterYaw);
    if HaveStepFile
%         plot(S_EndTime, S_Pitch,'LineStyle','none','Marker', 'v');
%         ylim_m = get(gca,'ylim');
%         Y_1 = ones(1,length(StartPoints)) .* ylim_m(2);
%         stem(Time(StartPoints), Y_1, 'LineStyle', '--', 'Marker', 'none', 'Color', 'red');
%         stem(Time(EndPoints), Y_1, 'LineStyle', '--', 'Marker', 'none', 'Color', 'yellow');
        legend('Matlab\_Yaw','Android\_Yaw');
    else
        legend('Matlab\_Yaw');
    end
    Plot_GroundTruth_Android_Bluetooth_160424_1155;
    title(['FileName: ' strrep(RawFile,'_','\_')]);
    xlabel('Time/s');
    ylabel('Yaw/°');
    subplot(2,1,2);
    plot(Time,ProcessYaw);
    hold on
    plot(Time,S_ButterYaw);
    plot(Time,S_ButterYaw .* 0.8);
    if HaveStepFile
%         plot(S_EndTime, S_Pitch,'LineStyle','none','Marker', 'v');
        legend('Matlab\_Yaw',' ','Android\_Yaw');
    else
        legend('Matlab\_Yaw');
    end
    Plot_GroundTruth_Android_Bluetooth_160424_1155;
    title(['ProcessYaw. FileName: ' strrep(RawFile,'_','\_')]);
    xlabel('Time/s');
    ylabel('Yaw/°');
end
% Acc magnitude
if FigurePlot == 3 || FigurePlot == 0
    figure;
    subplot(2,1,1);
    plot(Time,AccMag);
    hold on
    if exist('A_Time','var')
        plot(A_Time, A_mag,'LineStyle','none','Marker', 'v');
        legend('Matlab\_Acc\_Mag','Android\_ACC\_Mag');
    else
        legend('Matlab\_Acc\_Mag');
    end
    Plot_GroundTruth_Android_Bluetooth_160424_1155;
    title(['FileName: ' strrep(RawFile,'_','\_')]);
    
    xlabel('Time/s');
    ylabel('Magnitude: m/s^2');
    subplot(2,1,2);
    plot(Time,ProcessAccMag);
    hold on
    if exist('A_Time','var')
        plot(A_Time, A_mag,'LineStyle','none','Marker', 'v');
        legend('Matlab\_Acc\_Mag','Android\_ACC\_Mag');
    else
        legend('Matlab\_Acc\_Mag');
    end
    Plot_GroundTruth_Android_Bluetooth_160424_1155;
    title(['ProcessAccMag. FileName: ' strrep(RawFile,'_','\_')]);
    
    xlabel('Time/s');
    ylabel('Magnitude: m/s^2');
end
% figure;
% plot(Time,ProcessYaw)
% hold on
% % plot(Time,AWhole_Yaw)
% plot(Time,AWhole_Yaw .* 0.8)
% legend('ProcessYaw','A\_yaw');
