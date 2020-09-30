
% Now For Point-TimeStamps-accLinear-gry-ori-acc-...
%% Parameters 
% CHECK THESE!!!!
clear
close all
Phone = 1;
UserCount = 6;
FileChoice = 1;

ClassifierChoice = 0;
BiasTimeAdjust = 0;
SaveIntoResult = 0;

Phones = {'GalaxyNote3';'HuaWei';'Mi6X'};
Userz = {
'20180803-LJW';% GHM
'20180803-ZXY';% X
'20180804-WX'; % GHM
'20180804-XZC';% GHM
'20180805-BHL';% GHM 5
'20180805-ORM';% GHM
'20180805-WZY';% GHM
'20180806-MZK';% GHM
'20180806-WM'; % GHM
'20180807-QWY';% GHM 10
'20180807-TMM';% GHM
'20180808-HYT';%-G-
'20180808-XYX';% GHM
'20180809-GZC';%---
'20180810-LXX';% GHM  15
'20180810-MLK';% GHM
'20180811-HWL';% GHM
'20180811-LC'; % GHM
'20180812-KCX';% GHM
'20180813-CYJ';%   M 20
'20180813-YYX';% GHX
'20180814-CC'; % GHM
'20180814-WF'; % GHM
'20180915-Xu J.C';% GHM
'20180915-Zhang T.G'};%25 GHX

% Change These:
FileDir = fullfile('MobilePhoneSensor', Phones{Phone}, Userz{UserCount});   % 路径名，就是所在文件夹，绝对路径或相对此脚本的路径
% XJC_GalaxyNote3: [23 24 25 26]
 % 0: the lastest 
CurbThreshold = 1.34;%1.28;%1.22;%1.32;1.28
CurbThreshold2 = 1.32;
CurbRange = [-6.1 -2.3];%[-3.8 -5.2];%[-3.5 -2.2]; %[-6.7 -4.7];%[-3 -1.95];%;
CurbRange2 = [2.1 5.8];%[3.8 5.2];%[2.5 3.8];
EvenSteps = 2; % 1 : No EvenStep; 2: Even Step
CurbAccX = [1.5 1.75];%[1.5 1.75];

FigurePlot = 1;% 画图0：Pitch和Yaw；1：Pitch；2：Yaw 3: acc_mag
%-13;0606  % Bias Time, due to the different time of two phones
FilesLike = '2018*.txt'; % The Raw Data Files Like
GroundTruth_Android = false; % Using Android's Step Segmentation to generate ground truth
PlotState = 0;
PlotAllLabel = false;  % Plot all the label including flat
RecordRange = abs(BiasTimeAdjust) + 30; %s, for 60s before or after the RawFile recorded
Convert = 0;  % Peak OR Valley to detect curbs
SaveGTPath = 'MobilePhoneSensor/GroundTruthSeq/';
% -----------------------------------------

% % 3 States
%     State_Transfer = 2;
%     State_Road2 = 3;
% % 4 States
%     State_Up = 2;
%     State_Down = 3;
%     State_Road3 = 4;
% % 2 States
%     State_Road4 = 2;

Matlab_Event_Turn = 6;
Event_DR = 3;
Event_DC = 5;


% For Matlab
FeatureNum = 26;
butter_fs_seg = 2; %2 Butterworth filter for segmentation
butter_fs_process = 5; % Butterworth filter for data processing
StartStep = 10; % When to detect events
AzimuthThreshold = 75;
CountStepThreshold = 0.5; % 0.73 The Threshold that contains all the steps


% CurbRange = [2.7 3.5];% [2.6 3.5]
Weight = [0.18 0.32 0.25 0 0.11 0.14];
Scale = [0.01 0.1 0.08 0.01 0.008 0.01 0.01 0.01 0.08]; % Entropy
ClassifierNum = 9;
TurnThreshold = 3;

INTERVAL = 10; % Interval between each file
EMITGUESS = [   0.950 0.005 0.005 0.000 0.000 0.040;...
                0.000 0.980 0.000 0.010 0.000 0.010;...
                0.000 0.000 0.980 0.000 0.010 0.010;...
                0.000 0.000 0.000 1.000 0.000 0.000;...
                0.000 0.000 0.000 0.000 1.000 0.000;...
                0.910 0.010 0.010 0.010 0.010 0.050];

%% initial
HaveStepFile = true;
HaveGTFile = true;
Seq = [];
State = [];
if isempty(strfind(FileDir,'Mi6X'))
    SampleRate = 100;
else
    SampleRate = 200;
end
Temp = strfind(FileDir,'\');
if isempty(Temp)
    Temp = strfind(FileDir,'/');
end
UserName = FileDir(Temp(end) + 1 : end);
PhoneType = FileDir(Temp(end - 1) + 1 : Temp(end) - 1);
LinkFileNum = length(FileChoice);
FileRecordTime = zeros(LinkFileNum, 1);
Files = dir(fullfile(FileDir,FilesLike));
if isempty(Files)
    error(['No files in the directory:' FileDir]);
end
FileNames = {Files.name}';
FileNum = length(FileNames);
SVMFiles = dir(fullfile(FileDir,'SVM_*.mat'));
if isempty(Files)
    error(['No Trained Classifier in : ' FileDir]);
end
if (ClassifierChoice == 0)
    load(fullfile(FileDir,SVMFiles(end).name)); % Load classifier
else
    load(fullfile(FileDir,SVMFiles(ClassifierChoice).name)); % Load classifier
end


RawData = zeros(9,0);
AccData = zeros(3,0);
Time = zeros(1,0);
S_AccMag = zeros(1,0);
S_AccMagThr = zeros(1,0);
S_EndTime  = zeros(1,0);
S_States = zeros(1,0);
StatePoints = zeros(1,0);
ThresholdForMag = zeros(1,0);
Features = zeros(0,24);
ButterMag = zeros(1,0);
ButterMagMean = zeros(1,0);
Locs = zeros(1,0);
AbTimeSet = zeros(1,LinkFileNum);
AbstractTime = 0;
AbstractIndex = 0;
for FileCount = 1 : LinkFileNum
    %% RawData

    RawFile = FileNames{FileChoice(FileCount)};
    
    StepFile = ['StepData-' RawFile];
    SaveFile = ['TimeSeries-' RawFile(1:15) '.mat'];
    try
        FileHandle = fopen(fullfile(FileDir,RawFile));
        RawData_t = fscanf(FileHandle,'%f',[19 inf]);
        fclose(FileHandle);
    catch
        error('Orm: 文件路径有误，无法读取文件……');
    end
    if RawData_t(1,2) ~= 2
        error('Orm: Error Data Structure In File')
    end
    % 1             2       3       4       5       6       7       8     9     
    % PointsNO.---Time/ms--AccLX--AccLY--AccLZ---GyroX---GyroY---GyroZ---Azi---
    % 10      11      12    13     14         15          16             
    % Pitch---Roll---AccX---AccY---AccZ---PointState---ThresholdForMag---
    % 17             18           19--
    % MagButter---MagButterMean- Exp-    
    Time_t = RawData_t(2,:) ./ 1000  + AbstractTime;
    StatePoints_t = RawData_t(15,:);
    ThresholdForMag_t = RawData_t(16,:);
    ButterMag_t = RawData_t(17,:);
    ButterMagMean_t = RawData_t(18,:);
    AccData_t = RawData_t(12:14,:);
    RawData_t = RawData_t(3:11,:);



    %% Process for Android
    FileHandle = fopen(fullfile(FileDir,StepFile));
    try
        %                      StepNo State EndTime AccMag AccThre Features[24]
        Features_t = fscanf(FileHandle,'%f\t',[5,inf]);
        fclose(FileHandle);
        S_States_t = Features_t(2,:);
        S_EndTime_t = Features_t(3,:) + AbstractTime;
        S_AccMag_t = Features_t(4,:);
        S_AccMagThr_t = Features_t(5,:);
    %     Features_t = Features_t(6:end,:);
    %     Features_t = Features_t';
    catch
        warning('Orm: No StepData File Found!');
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
    RecordTimeMs = str2double(RawFile(Index(2)+1:Index(3)-1));
    TempString = RawFile(1:Index(2)-1);
    TempString(Index(end - 2)) = ' ';
    TempString = insertBefore(TempString,5,'-');
    TempString = insertBefore(TempString,8,'-');
    TempString = insertBefore(TempString,14,':');
    RecordTimeString = insertBefore(TempString,17,':');
    DateFloat = datenum(RecordTimeString ,'yyyy-mm-dd HH:MM:SS');
    FileRecordTime(FileCount) = DateFloat * 24 * 3600 + RecordTimeMs / 1000;
    %% Link Files

    Time = cat(2,Time,Time_t);
    StatePoints = cat(2,StatePoints,StatePoints_t);
    ThresholdForMag = cat(2,ThresholdForMag,ThresholdForMag_t);
    ButterMag = cat(2,ButterMag,ButterMag_t);
    ButterMagMean = cat(2,ButterMagMean,ButterMagMean_t);
    AccData_t(:,[1 end]) = 0;
    AccData = cat(2,AccData,AccData_t);
    RawData_t(1:6,[1 end]) = 0;
    RawData = cat(2,RawData,RawData_t);

    if HaveStepFile
        S_States = cat(2,S_States,S_States_t);
        S_EndTime = cat(2,S_EndTime,S_EndTime_t);
        S_AccMag = cat(2,S_AccMag,S_AccMag_t);
        S_AccMagThr = cat(2,S_AccMagThr,S_AccMagThr_t);
    %     Features = cat(1,Features,Features_t);  
        Locs = cat(2,Locs,Locs_t + AbstractIndex);
        AbstractIndex = Locs(end);
    end
    AbTimeSet(FileCount) = AbstractTime;
    AbstractTime = Time_t(end) + INTERVAL;
end
%% Process for Matlab
% if Convert == 0
%     mag = sqrt(AccData(1,:).^2 + AccData(2,:).^2 + AccData(3,:).^2);
% else
%     mag = -sqrt(AccData(1,:).^2 + AccData(2,:).^2 + AccData(3,:).^2);
% end
% mag = sqrt( RawData(2,:).^2 + RawData(3,:).^2);
mag = sqrt(AccData(1,:).^2 + AccData(2,:).^2 + AccData(3,:).^2);
magNoG = mag - mean(mag);
magNoG_b = butterworth(magNoG,SampleRate,butter_fs_seg);
WeightPre = find(Weight == 0) - 1; %3
WeightPost = length(Weight) - find(Weight == 0); % 2
minPeakHeight = CountStepThreshold * std(magNoG_b);
[pks, locs] = findpeaks(magNoG_b, 'MINPEAKHEIGHT', minPeakHeight);
% Log the missed label: assume that user walk continuously
MeanDuration = mean(locs(2 : end) - locs(1 : end - 1));
MissLoc = find(locs(2 : end) - locs(1 : end - 1) > MeanDuration * 1.5);
if ~isempty(MissLoc)
    pks_t = pks(1 : MissLoc(1));
    locs_t = locs(1 : MissLoc(1));
    clear round
    % Find Missed Steps and Label it
    for i = 1 : length(MissLoc)
        temp = floor((locs(MissLoc(i) + 1) - locs(MissLoc(i))) / MeanDuration - 0.4) ;
        locsTemp = [];
        pksTemp = [];
        for j = 1 : temp
            locsTemp(j) = locs(MissLoc(i)) + round(MeanDuration * j);
            %pksTemp(j) = pks(MissLoc(i)) + (pks(MissLoc(i) + 1) - pks(MissLoc(i))) / 2;
            pksTemp(j) = 0;
        end
%         locsTemp = locsTemp';
%         pksTemp = pksTemp';
        if i ~= length(MissLoc)
            locs_t = [locs_t, locsTemp, locs((MissLoc(i) + 1) : (MissLoc(i+1)))];
            pks_t = [pks_t, pksTemp, pks((MissLoc(i) + 1) : (MissLoc(i+1)))];
        else
            locs_t = [locs_t, locsTemp, locs((MissLoc(end) + 1) : end)];
            pks_t = [pks_t, pksTemp, pks((MissLoc(end) + 1) : end)];
        end
    end
    pksnew = pks_t(2:end);
    locsnew = locs_t(2:end);%cancel some possible false peaks
else
    pksnew = pks(2:end);
    locsnew = locs(2:end);%cancel some possible false peaks
end
NumPks = length(locsnew);
if HaveStepFile && NumPks < length(Locs)
    Locs = Locs(2:NumPks + 1);
end
ButterworthData = cell(1,ClassifierNum);
TrainData_t = cell(1,ClassifierNum);
for i = 1 : ClassifierNum
    ButterworthData{i} = butterworth(RawData(i,:), SampleRate, butter_fs_process);
    TrainData_t{i} = zeros(NumPks,FeatureNum);
end
Valley = zeros(1, NumPks);
for step = 2 : NumPks
    Valley(step) = min(magNoG_b(locsnew(step - 1):locsnew(step)));
end

%% High Confidence Event Detect
% PeakThreshold = min(sum(Weight .* magNoG_b...
%         (locsnew(StartStep - WeightPre:StartStep + WeightPost))) ...
%         * CurbThreshold, CurbRange(2));

PeakThreshold = min(sum(Weight .* magNoG_b...
        (StartStep - WeightPre:StartStep + WeightPost)) ...
        * CurbThreshold, CurbRange(2));
PeakThreshold2 = max(sum(Weight .* magNoG_b...
        (StartStep - WeightPre:StartStep + WeightPost)) ...
        * CurbThreshold2, CurbRange2(1));
PreAzimuth = RawData(7,locsnew(1):locsnew(StartStep));
if std(PreAzimuth) > 20
    AzimuthBias = 180;
else
    AzimuthBias = 180 - mean(PreAzimuth);
end
ThresholdLine = PeakThreshold;
ThresholdLine2 = PeakThreshold2;
Label = ones(1,NumPks);
Turned = TurnThreshold;
% For every step, detect its event and calculate its features;
for k=2:NumPks
    if Turned > 0
        Turned = Turned - 1;
    end
    % ------------- missed label-----------
    if pksnew(k) == 0
        Label(k) = 0;
        if k >= 2
            Label(k - 1) = 0;
        end
        ThresholdLine = cat(2, ThresholdLine, PeakThreshold);
        ThresholdLine2 = cat(2, ThresholdLine2, PeakThreshold2);
        continue;
    end
    % -------------missed label end---------
    %--detect Turn : Matlab_Event_Turn--
    if k > StartStep
        if Turned == 0
            AzimuthTemp = rem(RawData(7,locsnew(k - StartStep):locsnew(k)) + AzimuthBias, 360);
                % Add Bias to set the Nearby Step around 180; 
            Pre5Index = locsnew(k - 7) : locsnew(k - 5);
            Pre5Index = Pre5Index - locsnew(k - StartStep) + 1;
            Near2Index = locsnew(k - 2) : locsnew(k);
            Near2Index = Near2Index - locsnew(k - StartStep) + 1;
                % Steps:
                % --------------+++++++++++++++++++++
                %               ↑k-7    ↑k-5↑k-2↑k
                % -------------{+++++++++++}--{++++++}mean
            AzimuthChange = mean(AzimuthTemp(Pre5Index)) - ...
                mean(AzimuthTemp(Near2Index));
            AzimuthChange = abs(AzimuthChange);
            %&& abs(mean(Azimuth(locsnew(k):locsnew(k+1),1))...
            %-mean(Azimuth(locsnew(k-8):locsnew(k-5),1))) > 65
            if AzimuthChange > AzimuthThreshold
                Turned = TurnThreshold;
                Label(k - 4) = Matlab_Event_Turn;
                Label(k - 3) = Matlab_Event_Turn;
                % Turned, This step is important because is curb? so 
                % continue;
            else
                PreAzimuth = RawData(7,locsnew(k - StartStep):locsnew(k));
                if std(PreAzimuth) > 20
                    AzimuthBias = 180;
                else
                    AzimuthBias = 180 - mean(PreAzimuth);
                end
            end
        end
    end
   %-----------detect Turn end-------
   %---------Label Curb : 4&5----------------
    if k > StartStep && k < NumPks -2
        WalkMag = ones(2,length(Weight));
        NoCurb = WeightPre;
        temp = k;
        while NoCurb > 0 
            TempLabel = Label(temp);
            if 4 ~= TempLabel 
                WalkMag(1,NoCurb) = Valley(temp);
                WalkMag(2,NoCurb) = magNoG_b(locsnew(temp));
                NoCurb = NoCurb - 1;
            end
            temp = temp - EvenSteps;
        end
        WalkMag(1,4:6) = Valley(k:k + WeightPost);
        WalkMag(2,4:6) = magNoG_b(locsnew(k:k + WeightPost));
        PeakThreshold = min(max(sum(Weight .* WalkMag(1,:)) * CurbThreshold, CurbRange(1)), CurbRange(2));
        PeakThreshold2 = min(CurbRange2(2),max(sum(Weight .* WalkMag(2,:)) * CurbThreshold2, CurbRange2(1)));
        if Valley(k) < PeakThreshold
%             TrainData_t{ClassCount}(k-1,:) = zeros(1,FeatureNum);
            clear Temp
            Temp(1) = max(RawData(1,locsnew(k-3):locsnew(k-1)));
            Temp(2) = max(RawData(1,locsnew(k-2):locsnew(k)));
            if (Temp(2) > CurbAccX(2))
                Label(k-1 : k) = [5 5];
            else
                if (Temp(1) > CurbAccX(1))
                    Label(k-2 : k-1) = [4 4];
                end % Else: Down Ramp
            end
        end
    end
    %------- Detect curb end-------- 
    ThresholdLine = cat(2, ThresholdLine, PeakThreshold);
    ThresholdLine2 = cat(2, ThresholdLine2, PeakThreshold2);
    %% -----------Prepare Features-------
    for ClassCount = 1 : 9 % 9
        TrainData_t{ClassCount}(k,1) = ...
            (ButterworthData{ClassCount}(locsnew(k-1)+1)+ButterworthData{ClassCount}(locsnew(k)))/2;
        %average of magnitude of each step: mean (startY,endY)
        TrainData_t{ClassCount}(k,2) = Time(locsnew(k)) - Time(locsnew(k-1)+1);%time
        FilteredData = ButterworthData{ClassCount}(locsnew(k-1)+1:locsnew(k));
        %ti_f = Duration{ceil(ClassCount / 3)}(locsnew(k):locsnew(k+1),1); % t1 t2 t3
        %-----fftpeaks begin-----
        fs = 100;
        N = length(FilteredData); 
        n = 0:N-1;
        t = n/fs;
        yf = fft(FilteredData,N);
        magn = abs(yf(1:ceil(end/2)));
        f = n*fs/N;
        [pksf, ~] = findpeaks(magn, 'MINPEAKHEIGHT', 0);
%         Temp_Sum = sum(magn);
        TrainData_t{ClassCount}(k,14) = -sum(magn .* log10(magn)) / sum(magn) + log10(sum(magn)); %entropy
        if ~isempty(pksf)
            TrainData_t{ClassCount}(k,3) = pksf(1);
        else
            TrainData_t{ClassCount}(k,3) = NaN;
        end
        if length(pksf)>1
            TrainData_t{ClassCount}(k,4) = pksf(2);
        else
            TrainData_t{ClassCount}(k,4)= NaN;
        end
        %---fftpeaks end
        StepData = ButterworthData{ClassCount}(locsnew(k-1)+1:locsnew(k));
        TrainData_t{ClassCount}(k,5) = mean(StepData);%mean
        TrainData_t{ClassCount}(k,6) = max(StepData);%max
        TrainData_t{ClassCount}(k,7) = min(StepData);%min
        TrainData_t{ClassCount}(k,8) = prctile(StepData,90);%max90th
        TrainData_t{ClassCount}(k,9) = prctile(StepData,10);%min10th
        TrainData_t{ClassCount}(k,10) = TrainData_t{ClassCount}(k,6)-TrainData_t{ClassCount}(k,7);%range = max - min
        TrainData_t{ClassCount}(k,11) = std(StepData);%standard deviation
        TrainData_t{ClassCount}(k,12) = skewness(StepData);%skewness
        TrainData_t{ClassCount}(k,13) = kurtosis(StepData);%kurtosis
        StepData_sort = sort(StepData);
%         TrainData_t{ClassCount}(k,14) = getEntropy(StepData_sort,length(StepData),Scale(ClassCount));%entropy
        TrainData_t{ClassCount}(k,15) = TrainData_t{ClassCount}(k,11)/TrainData_t{ClassCount}(k,5)*100;%CV
        TrainData_t{ClassCount}(k,16) = median(StepData);% Median
        TrainData_t{ClassCount}(k,17) = prctile(StepData,75);% Q3
        TrainData_t{ClassCount}(k,18) = prctile(StepData,25);% Q1
        TrainData_t{ClassCount}(k,19) = TrainData_t{ClassCount}(k,17) - TrainData_t{ClassCount}(k,18);% Q3 - Q1
        Weight_1 = [0.25 0.5 0.25];
        TrainData_t{ClassCount}(k,20) = Weight_1 * prctile(StepData,[25 50 75])';% SM(...Mean)
        TrainData_t{ClassCount}(k,21) = mean(StepData .^ 2);% E(X^2)
        Y_EY = Time(locsnew(k-1)+1:locsnew(k)) - mean(Time(locsnew(k-1)+1:locsnew(k)));
        Temp = cov(StepData,Y_EY);
        TrainData_t{ClassCount}(k,22) = Temp(1,2);
        % Cov(step,time)
        Temp  = corrcoef(StepData,Y_EY);
        TrainData_t{ClassCount}(k,23) = Temp(1,2);
%         TrainData_t{ClassCount}(k,24) = corr(StepData,Y_EY,'type','Spearman');
        if (k > 2)
%                 PreStepData = ButterworthData{ClassCount}(locsnew(k-2):locsnew(k));
            TrainData_t{ClassCount}(k,24) = TrainData_t{ClassCount}(k,2) - ...
                TrainData_t{ClassCount}(k-1,2);
            TrainData_t{ClassCount}(k,25) = TrainData_t{ClassCount}(k,5) - ...
                TrainData_t{ClassCount}(k-1,5);
            TrainData_t{ClassCount}(k,26) = TrainData_t{ClassCount}(k,6) - ...
                TrainData_t{ClassCount}(k-1,6);
        else
            TrainData_t{ClassCount}(k,24) = 0;
            TrainData_t{ClassCount}(k,25) = 0;
            TrainData_t{ClassCount}(k,26) = 0;
        end
        %----Simple Classifier end----
    end
end

%% Generate GroundTruth
[HaveGTFile, State, Seq] = GenerateGroundTruth_Orm201807272112...
                (FileDir, FileRecordTime, LinkFileNum,RecordRange, BiasTimeAdjust,AbTimeSet, locsnew, Time, Label);
save([SaveGTPath RawFile(1:end - 5) '.mat'],'Seq','State','HaveGTFile');
Seq_t = Seq;
State_t = State;
%% Classify & HMM
DataIn = TrainData_t{SimpleClassifier(1)};
SCLen = length(SimpleClassifier);
if SCLen > 1 
    for ii = 2 : SCLen
        DataIn = cat(2, DataIn, TrainData_t{SimpleClassifier(ii)});
    end
end
% [yfit_binary, confidence_binary, ~] = predict(binary_tree,TrainData_t{SimpleClassifier});
% [yfit_binary, confidence_binary, ~] = predict(binary_tree,DataIn);
yfit_binary = predict(binary_tree,DataIn);
% advanced Classifier 
temp = find(yfit_binary == 2);
yfit_advanced = zeros(length(temp), ClassifierNum);
% confidence_advanced = cell(ClassifierNum, 1);
% for ClassCount = 1 : ClassifierNum
%     x_advanced_test = TrainData_t{ClassCount}(yfit_binary == 2, :); 
%     % prepare the test data just the binary tree result
% %     [yfit_advanced(:, ClassCount), confidence_advanced{ClassCount}, ~] =...
% %         predict(advanced_tree{ClassCount}, x_advanced_test);
%     yfit_advanced(:, ClassCount) =...
%         predict(advanced_tree{ClassCount}, x_advanced_test);
% end
% ClassifyOutput = yfit_binary;
% ClassifyOutput(ClassifyOutput == 2) = mode(yfit_advanced, 2);% major vote
AdvDataIn = TrainData_t{AdvancedClassifier(1)}(yfit_binary == 2,:);
ACLen = length(AdvancedClassifier);
if ACLen > 1
    for ii = 2 : ACLen
        AdvDataIn = cat(2, AdvDataIn, TrainData_t{AdvancedClassifier(ii)}(yfit_binary == 2,:));
    end
    
end
% [AdvanceOut,Confidence,~] = predict(AdvancedTree, AdvDataIn);
AdvanceOut = predict(AdvancedTree, AdvDataIn);

%--------------Advanced Classify End--------------
MLOut = yfit_binary;
MLOut(MLOut == 2) = AdvanceOut;
Predict_t = MLOut;
AdLabel = Label;
Predict_t(AdLabel ~= 1) = AdLabel(AdLabel ~= 1);
% refine the output of machine learning:
Len = length(Predict_t);
Temp = Predict_t(1:40);
Temp(Temp == 2 | Temp == Event_DR) = 1;
Predict_t(1:40) = Temp;
for step = 2 : Len - 2
    % 1111-2-111
    % 111123111 || 111 32 111
    CurrentStep = Predict_t(step,1);
    
    if (CurrentStep == 2 || CurrentStep == 3) && ...
            (CurrentStep ~= Predict_t(step - 1) && CurrentStep ~= Predict_t(step + 1))
        Predict_t(step,1) = 1;
    end   
    if (CurrentStep == Event_DC && Predict_t(step + 1) == 4)
        Predict_t(step-1:step+2,1) = 1;
    end
    if (CurrentStep == 4 && Predict_t(step + 1) == 5)
        Predict_t(step-1:step+2,1) = 1;
    end
end
    Label = Predict_t; % Label is the output of the machine learning
% HMMInput = Predict_t;
% HMMInput(HMMInput == 0) = 1;
%     %--------------Decesion Tree End--------------
% SeqFiles = dir(fullfile(SaveGTPath,'*.mat'));
% SeqFileName = {SeqFiles.name}';
% SeqLen = length(SeqFileName);
% SeqTrain = cell(SeqLen,1);
% SeqTotal = zeros(1,0);
% for i = 1 : SeqLen
%     load(fullfile(SaveGTPath,SeqFileName{i}));
%     SeqTrain{i} = Seq;
%     SeqTotal = cat(2,SeqTotal,Seq);
% end

% AllState = [];
% K = SeqLen;
% for i=1:K    
%     AllState = [AllState, unique(SeqTrain{i})];
% end
% N = length(unique(AllState));
% PI = zeros(N,1);
% A = zeros(N);
% pseudoPI  = ones(size(PI))-1;
% pseudoA = ones(size(A))-1;
% % calculate PI and A
% for i = 1:N
%     data{i} = [];
% end
% for k = 1:K 
%     Tk = length(SeqTrain{k});
%     PI(SeqTrain{k}(1)) = PI(SeqTrain{k}(1)) + 1;     
%     for t=1:Tk-1
%         A(SeqTrain{k}(t),SeqTrain{k}(t+1)) = A(SeqTrain{k}(t),SeqTrain{k}(t+1)) + 1;   
%         % xi{k}(:,:,t) =      % full( sparse(training_y{k}(1:Tk-1) ,training_y{k}(2:Tk) ,1,N,N) );
%         % gamma{k}(:,t) = 
%     end
%     
% end
% PI = PI + pseudoPI;
% A = A + pseudoA;
% PI = PI/sum(PI);
% A = bsxfun(@rdivide,A,sum(A,2));
% ESTTR = A;
% [ESTTR,ESTEMIT] = hmmtrain(SeqTrain,ESTTR,EMITGUESS);
% STATES_t = hmmviterbi(HMMInput,ESTTR,ESTEMIT);
% State = State_t; % State & Seq of this file
% Seq = Seq_t;
% SS = find(STATES_t == 6);
% Entrance_HMM = [SS(1) SS(find(SS(2 : end) - SS(1 : end-1) > 1)+1)];
%% Accuracy
Seq_t = Seq;
Label_t = Label;
Seq(Label == 0) = [];
Label(Label == 0) = [];
SSI = find(Seq == Event_DR | Seq == Event_DC);
Entrance_GT = [SSI(SSI(2 : end) - SSI(1 : end - 1)>1) SSI(end)]; % Entrance事件的结束
EntranceDis = ones(1,length(Entrance_GT)) .* 50;
Correct = 0;
for i = 1 : length(Entrance_GT)
    Index = Entrance_GT(i);
    Flag = false;
    for j = Index - 40 : Index + 40
        if j <= 0 || j > length(Seq)
            continue;
        end
        if Label(j) == Event_DR || Label(j) == Event_DC || Label(j) == 6
            Flag = true;
            if (abs(j-Index + 6) < abs(EntranceDis(i) + 6))
                
                EntranceDis(i) = j - Index;
            end
            if (j - Index) > -12
                break;
            end
        end
    end
    if Flag
        Correct = Correct + 1;
    end
    
end
Label = Label_t;
Seq = Seq_t;
%% Draw Figures
% close all
% ThresholdLine2 = [ThresholdLine2(2:end) ThresholdLine2(1)];
% ThresholdLine = [ThresholdLine(1) ThresholdLine(1:end-1)];
if ~HaveStepFile
    Locs = [];
end
if ~HaveGTFile
    GTSeq = [];
end
HaveStepFile = 0;
if FigurePlot == 0 || FigurePlot == 1
    figure;
    plot(Time,magNoG_b,'Linewidth',1.5);
    hold on
    plot(Time(locsnew) - 0.4,ThresholdLine,'Linewidth',2);
    plot(Time(locsnew),ThresholdLine2,'Linewidth',2);
%     plot(Time,ButterMagMean,'Linewidth',1.2);
    if HaveStepFile
        plot(S_EndTime,S_AccMagThr);
        plot(S_EndTime,S_AccMag,'bo');
    end
    ylabel('Magnitude:m/s^2');
    
    DrawGroundTruth_Orm201807292021(Time,Locs,locsnew,Label,Seq,State,HaveStepFile,HaveGTFile,RawFile,PlotState,FileChoice);
    
    if HaveStepFile
        legend('M:MagMean','M:ThresholdLine','A:ThresholdLine','A:MeanMag');
    else
        legend('M:MagMean','M:ThresholdLine','A:MagMean');
    end
end
if FigurePlot == 0 || FigurePlot == 2
    figure;
    plot(Time,RawData(7,:));
    hold on
%     plot(Time(locsnew),ThresholdLine,'Linewidth',2);
%     plot(Time,ButterMagMean,'Linewidth',1.2);
%     if HaveStepFile
%         plot(S_EndTime,S_AccMagThr);
%     end
ylabel('Azimuth/°');
    DrawGroundTruth_Orm201807292021(Time,Locs,locsnew,Label,Seq,State,HaveStepFile,HaveGTFile,RawFile,PlotState,FileChoice);
end
if FigurePlot == 0 || FigurePlot == 3
    figure;
    plot(Time,RawData(2,:));
    hold on
%     plot(Time,RawData(2,:));
%     plot(Time,RawData(3,:));
%     Temp = butterworth(sqrt(RawData(1,:).^2 .* 2 + RawData(3,:).^2),SampleRate,5);
%     Temp = sqrt(RawData(1,:).^2 .* 2 + RawData(3,:).^2);
%     plot(Time,Temp);
%     plot(Time(locsnew),ThresholdLine,'Linewidth',2);
%     plot(Time,ButterMagMean,'Linewidth',1.2);
%     if HaveStepFile
%         plot(S_EndTime,S_AccMagThr);
%     end
%     legend('Acc\_X','Acc\_Y','Acc\_Z','Acc\_XZ');
ylabel('Acc:m/s^2');
    DrawGroundTruth_Orm201807292021(Time,Locs,locsnew,Label,Seq,State,HaveStepFile,HaveGTFile,RawFile,PlotState,FileChoice);
end
% 
% save('MobilePhoneSensor/FigData/Temp.mat','AccData','Label','locsnew','mag'...
%     ,'magNoG_b','MissLoc','MLOut','pksnew','RawData','Seq','ThresholdLine','Time','ThresholdLine2');
EntranceDis
%% Save Result
% Including following result: 
% 1. Enterance Distance; 
% 2. Step Frequency; 
% 3. Event Accuracy;
% 4. Confusion Matrix
% Step Frequency
% SS = find(Label == 0);
% StandS = [SS(1);SS(find(SS(2 : end) - SS(1 : end - 1)>1) + 1)]; % Start of Stand
% StandE = [SS(SS(2 : end) - SS(1 : end - 1)>1);SS(end)] + 1; % End of stand
if SaveIntoResult == 1
ResultPath = fullfile('Result',[PhoneType '.mat']);
load(ResultPath);
Result_in = cell(1,3);
Result_in{1,1} = Seq;
Result_in{1,2} = Label;
Result_in{1,3} = 1 / (Time(end) / length(Label));
SaveInfo = [UserName '_' num2str(FileChoice)];
temp = strcmp(Users, SaveInfo);
if any(temp)
    I = find(temp);
    BackUp(I,:) = Result(I,:);
    Result(I,:) = Result_in;
else
    Result = cat(1,Result,Result_in);
    Users = cat(1,Users,{SaveInfo});
    BackUp = cat(1, BackUp, {[] [] []});
    I = length(Users);
end
LogTime = fix(clock);
LastIndex = I;
save(ResultPath,'Result','BackUp','Users','LogTime','Info','LastIndex');
EntranceDis
clear Result_in SaveInfo temp
% save(fullfile('MobilePhoneSensor\','TimeSeries',SaveFile),'AccData','RawData','locsnew','TrainData_t','Seq','State','Label','magNoG_b','Time');
end

