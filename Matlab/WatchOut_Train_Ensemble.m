% WatchOut: Train From App--- Ensemble meta-algorithm
%% Parameters
% Need to add: PhoneChoice; UserCount; NFold
% Can't run directly!!!
% CHECK THESE!!!!!!
BiasTimeAdjust = 0;
ReProcess = 0;
PhoneChoice = 1;
NFold = 10;
% % % PhoneChoice = 1;
SimpleCost = [0,1;2,0];
AdvancedCost = [0,1;2,0];
UserCount = 6;
Userz = {'20180803-LJW';
'20180803-ZXY';
'20180804-WX';
'20180804-XZC';
'20180805-BHL';%5
'20180805-ORM';
'20180805-WZY';
'20180806-MZK';
'20180806-WM';
'20180807-QWY';%10
'20180807-TMM';
'20180808-HYT';%
'20180808-XYX';
'20180809-GZC';%
'20180810-LXX';%15
'20180810-MLK';
'20180811-HWL';
'20180811-LC';
'20180812-KCX';
'20180813-CYJ';%20
'20180813-YYX';
'20180814-CC';
'20180814-WF';
'20180915-Xu J.C';
'20180915-Zhang T.G'};%25
Phones = {'GalaxyNote3';'HuaWei';'Mi6X'};
% Unused = [2 12 14];
FigurePlot = 4;
% 0: not Draw;
% 1: Magnitude;
% 2: Azimuth;
% 3: Accelometer axis Z
PlotState = 1;
PlotAllLabel = false;
FileLike = '2018*.txt';
RecordRange = abs(BiasTimeAdjust) + 30; %s, for 60s before or after the RawFile recorded
StartStep = 10; % When to detect events
butter_fs_seg = 2.5; % Butterworth filter for segmentation
butter_fs_process = 20; % Butterworth filter for data processing
FeatureNum = 26;
% % % NFold = 10;
EventNum = 3;
AzimuthThreshold = 68;
CountStepThreshold = 0.73; % 0.73 The Threshold that contains all the steps
ClassifierNum = 9;
% EventKeyWord = {'Flat'; 'UpRamp'; 'DownRamp'; 'Curb';'Deleted'; 'Turn'; 'Unusual'};
% StateKeyWord = {'SIDE'; 'UPRAMP'; 'DOWNRAMP'; 'CURB'; 'ROAD'; 'Unusual'};
% Less likely to change
TrunThreshold = 10;
INTERVAL = 30;
Matlab_Event_Turn = 6;
SimpleClassifier = [2 3 5 8]; % Pitch Classifier, the most accurate in biodecision;
AdvancedClassifier = [1 2 3 5 8]; % Use Amizith as the classifier
%% inital
FileDir = fullfile('MobilePhoneSensor', Phones{PhoneChoice}, Userz{UserCount});
URFileDir = fullfile(FileDir, 'UpRamp');
DRFileDir = fullfile(FileDir, 'DownRamp');
disp([Userz{UserCount}(1:end) '; NFold = ' num2str(NFold)]);
HaveStepFile = true;
Temp = strfind(FileDir,'\');
if isempty(Temp)
    Temp = strfind(FileDir,'/');
end
UserName = FileDir(Temp(end) + 1 : end);
PhoneType = FileDir(Temp(end-1) + 1 : Temp(end) - 1);
if ~contains(FileDir,'Mi6X')
    SampleRate = 100;
else
    SampleRate = 200;
end
TrainData = cell(ClassifierNum,3);
for k = 1 : 3
    for j = 1 : 9
        TrainData{j,k} = zeros(0,FeatureNum);
    end
end
FileStep = cell(3,1);
TrainF = dir(fullfile('TrainData',PhoneType,'*.mat'));
TrainN = {TrainF.name}';
temp = strcmp(TrainN, [UserName '.mat']);
if any(temp) && (ReProcess == 0)
    load(fullfile('TrainData',PhoneType, [UserName '.mat']));
else
%% Process the file directory
for FileType = 1 : 3
    switch FileType
        case 1
            Files = dir(fullfile(FileDir,FileLike));
            FileDir_t = FileDir;
        case 2
            Files = dir(fullfile(URFileDir,FileLike));
            FileDir_t = URFileDir;
        case 3
            Files = dir(fullfile(DRFileDir,FileLike));
            FileDir_t = DRFileDir;
    end
    
    if isempty(Files)
        error(['No files in the directory:' FileDir]);
    end
    FileNames = {Files.name}';
    FileNum = length(FileNames);
    RawData = zeros(9,0);
    AccData = zeros(3,0);
    Time = zeros(1,0);
    S_AccMag = zeros(1,0);
    S_AccMagThr = zeros(1,0);
    S_EndTime  = zeros(1,0);
    S_States = zeros(1,0);
    StatePoints = zeros(1,0);
    ThresholdForMag = zeros(1,0);
%     Features = zeros(0,24);
    ButterMag = zeros(1,0);
    ButterMagMean = zeros(1,0);
    Locs = zeros(1,0);
    AbTimeSet = zeros(1,FileNum);
    AbstractTime = 0;
    AbstractIndex = 0;
    
    for FileCount = 1 : FileNum
        %% RawData

        RawFile = FileNames{FileCount};

        StepFile = ['StepData-' RawFile];
        SaveFile = ['TimeSeries-' RawFile(1:15) '.mat'];
        try
            FileHandle = fopen(fullfile(FileDir_t,RawFile));
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
        FileHandle = fopen(fullfile(FileDir_t,StepFile));
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
            warning(['Orm: No StepData File Found!'  FileNames{FileCount}]);
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
        if FileType == 1
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
            
        end
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
    clear AccData_t DateFloat Features_t TempString
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

%     PeakThreshold = min(sum(Weight .* magNoG_b...
%             (StartStep - WeightPre:StartStep + WeightPost)) ...
%             * CurbThreshold, CurbRange(2));
    PreAzimuth = RawData(7,locsnew(1):locsnew(StartStep));
    if std(PreAzimuth) > 20
        AzimuthBias = 180;
    else
        AzimuthBias = 180 - mean(PreAzimuth);
    end
%     ThresholdLine = PeakThreshold;
    Label = ones(1,NumPks);
    Truned = TrunThreshold;
    % For every step, detect its event and calculate its features;
    for k=2:NumPks
        if Truned > 0
            Truned = Truned - 1;
        end
        % ------------- missed label-----------
        if pksnew(k) == 0
            Label(k) = 0;
            if k >= 2
                Label(k - 1) = 0;
            end
%             ThresholdLine = cat(2, ThresholdLine, PeakThreshold);
            continue;
        end
        % -------------missed label end---------
        %--detect Turn : Matlab_Event_Turn--
        if k > StartStep
            if Truned == 0
                AzimuthTemp = rem(RawData(7,locsnew(k - StartStep):locsnew(k)) + AzimuthBias, 360);
                    % Add Bias to set the Nearby Step around 180; 
                Pre5Index = locsnew(k - 6) : locsnew(k - 4);
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
                    Truned = TrunThreshold;
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
%         ThresholdLine = cat(2, ThresholdLine, PeakThreshold);
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
    %         TrainData_t{ClassCount}(k,24) = corr(StepData,Y_EY,'type','Spearman');
            %----Simple Classifier end----
        end
    end
    clear AzimuthBias AzimuthChange AzimuthTemp f step
    if (FileType == 1)
        [HaveGTFile, State, Seq] = GenerateGroundTruth_Orm201807272112...
                (FileDir, FileRecordTime, FileNum,RecordRange, BiasTimeAdjust,AbTimeSet, locsnew, Time, Label);
        for t = 1 : ClassifierNum
            for Labels = 1 : 3
                TrainData{t,Labels} = cat(1,TrainData{t,Labels},TrainData_t{t}(Seq == Labels,:));
            end
        end
        FileStep_t = zeros(3,FileNum);
        LocsIn = locsnew(Seq > 0 & Seq < 4);
        Seq_t = Seq(Seq > 0 & Seq < 4);
        TempI = 1;
        for i = 1 : length(LocsIn)
            if TempI == FileNum  || Time(LocsIn(i)) < AbTimeSet(TempI + 1)
                FileStep_t(Seq_t(i),TempI) = FileStep_t(Seq_t(i),TempI) + 1;
            else
                TempI = TempI + 1;
                FileStep_t(Seq_t(i),TempI) = FileStep_t(Seq_t(i),TempI) + 1;
            end
        end
        FileStep{FileType} = FileStep_t;
        TFileNames = FileNames;
    else
        ExtraFileNum = size(FileStep{1},2);
        RampResult = cell(FileNum + ExtraFileNum, EventNum + 6);
        LocsIn = locsnew(Label ~= Matlab_Event_Turn & Label ~= 0);
        LocsInLen = length(LocsIn);
        FileStep_t = zeros(1, FileNum);
        TempI = 2;
        for i = 1 : LocsInLen
            if TempI == FileNum + 1 || Time(LocsIn(i)) < AbTimeSet(TempI)
                FileStep_t(TempI - 1) = FileStep_t( TempI - 1) + 1;
            else
                TempI = TempI + 1;
                FileStep_t(TempI - 1) = FileStep_t(TempI - 1) + 1;
            end
        end
        for FileCount = 1 : ExtraFileNum
            RampResult{FileCount, 1} = ['T' TFileNames{FileCount}];
            RampResult{FileCount, 2} = FileStep{1}(FileType,FileCount);
        end
        for FileCount = 1 : FileNum
            RampResult{FileCount + ExtraFileNum, 1} = FileNames{FileCount};
            RampResult{FileCount + ExtraFileNum, 2} = FileStep_t(FileCount);
        end
        FileStep_t = cat(2,FileStep{1}(FileType,:), FileStep_t);
        FileStep{FileType} = FileStep_t;
        if FileType == 2
            Result_Up = RampResult;
        else
            Result_Down = RampResult;
        end
        for t = 1 : ClassifierNum
            TrainData{t,FileType} = cat(1,TrainData{t,FileType},TrainData_t{t}(Label ~= Matlab_Event_Turn & Label ~= 0,:));
        end
    end
    clear LocsIn LocsInLen RampResult StartI TempI
%     if FileType ~= 1
%         figure;
%         plot(Time,RawData(7,:));
%         ylabel('Azimuth/°');
%     end
%     WatchOut_RampPlot_Orm201808070946;
    
    
end

clear *_t
clear BiasTimeAdjust ButterworthData DataLen DRFileDir 
clear FileHandle FileLike FileNames FileNum FileRecordTime Files
clear FilteredData i ii index IntervalIndex j k Labels locs Locs
clear locsTemp MissLoc n N Near2Index PeakThreshold pks pksf 
clear pksTemp Pre5Index PreAzimuth RawFile RecordRange RecordTimeMs 
clear RecordTimeString s
clear S_TLen StepData StepData_sort StepFile t temp Temp
clear TempData TempData2 TLen Truned URFileDir
clear Valley Weight_1 WeightPost WeightPre
if ~exist(fullfile('TrainData', PhoneType), 'dir')
    mkdir(fullfile('TrainData', PhoneType));
end
save(fullfile('TrainData',PhoneType,[UserName '.mat']),'TrainData','Result_Up','Result_Down','FileStep');
end
%% Classification
if NFold == 2 || ~exist('Results','var')
    disp(fprintf('TrainData:\nFlat: \t\t%d\nUpRamp: \t%d\nDownRamp: \t%d\n', ...
        size(TrainData{1,1},1) , size(TrainData{1,2},1),size(TrainData{1,3},1)));
end
MinRampNum = min(size(TrainData{1,2},1), size(TrainData{1,3},1));
if MinRampNum ~= size(TrainData{1,2},1) 
    Temp = 2;
end
if MinRampNum ~= size(TrainData{1,3},1) 
    Temp = 3;
end
if (Temp == 2)
    for t = 1 : ClassifierNum
        TrainData{t,Temp}(MinRampNum + 1:end,:) = [];
    end
end
Size_t = size(TrainData{1,1},1);
Size_Ramp = size(TrainData{1,2},1) * 2;
Temp = floor(Size_t / Size_Ramp);
Temp = max(2,Temp);
% if Temp > 2    
%     Temp = 2;
%     for t = 1 : ClassifierNum
%         TrainData{t,1} = TrainData{t,1}(1 : Size_Ramp * Temp,:);
%     end
% end
for t = 1 : ClassifierNum
    TrainData{t,1} = TrainData{t,1}(1 : Temp : min(Size_Ramp * Temp,Size_t),:);
end



Num_Sample_group = zeros(NFold, EventNum);
TrainDataLabel = cell(1,EventNum);
for t = 1 : EventNum
    TrainDataLabel{t} = ones(1,size(TrainData{1,t},1));
    yushu = rem(length(TrainDataLabel{t}), NFold);
    shang = (length(TrainDataLabel{t}) - yushu) / NFold;
    Num_Sample_group(:, t) = ones(NFold, 1) * shang;
    Num_Sample_group(1:yushu, t) = Num_Sample_group(1:yushu, t) + 1;
end
Accuracy_MajorVote = zeros(1, NFold);
Accuracy_Combine = zeros(1, NFold);
accuracy_BinaryClass = zeros(NFold, ClassifierNum + 1);
accuracy_classifier = zeros(NFold, ClassifierNum + 1);
% Row: real type, Column: predicted type
confusion_matrices = zeros(EventNum, EventNum, NFold);
start_indices = ones(1, EventNum);
x_test = cell(ClassifierNum,1);
PredictLabelTotal = cell(EventNum, 1);

% for i = 1 : EventNum
%     PredictLabelTotal{i} = zeros(size(TrainData{1, i}, 1));
% end
x_train = cell(ClassifierNum,1);
tic
Confidence = cell(ClassifierNum + 1, 3);
for round = 1 : NFold
    yfit_sum = cell(ClassifierNum, 1);
    % Prepare the train and test sample:
    % y_train do not need to be a cell
    for ClassCount = 1 : ClassifierNum
        x_test{ClassCount} = [];
        y_test = [];
        x_train{ClassCount} = [];
        y_train = [];
        for EventCount = 1 : EventNum
            samples = TrainData{ClassCount, EventCount};
            s = start_indices(EventCount);
            t = s + Num_Sample_group(round, EventCount) - 1;
            x_test{ClassCount} = [x_test{ClassCount};samples(s:t, :)];
            y_test = [y_test;EventCount * ones(t - s + 1, 1)];
            
            samples(s:t, :) = [];
            x_train{ClassCount} = [x_train{ClassCount};samples];
            y_train = [y_train;EventCount * ones(size(samples, 1), 1)];
            if ClassCount == ClassifierNum
                start_indices(EventCount) = t + 1;
            end
        end
    end
    % Simple Classifier:
    y_binary_train = y_train; 
    y_binary_train(y_binary_train > 2) = 2;    % set the train label with just 1 or 2
    y_test_binary = y_test;
    y_test_binary(y_test_binary > 2) = 2;   % the test label just 1 or 2
    t = templateTree('Surrogate','On','MaxNumSplits',20);
    
%     for ClassCount = 1 : ClassifierNum
%         x_binary_train = x_train{ClassCount}; 
%         binary_tree = fitcsvm(x_binary_train, y_binary_train,...
%             'Standardize',true,'CacheSize','maximal',...
%             'OutlierFraction',0.10,'Verbose',0,'Cost',SimpleCost,...
%             'ScoreTransform','doublelogit');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%1
%             binary_tree = fitcensemble(x_binary_train, y_binary_train,...
%                 'Method','GentleBoost','LearnRate',0.1,'Cost',SimpleCost,'NumLearningCycles',300,'Learners',t);
% %         'OptimizeHyperparameters','auto',...
% %             'HyperparameterOptimizationOptions',struct('AcquisitionFunctionName',...
% %     'expected-improvement-plus')
%         % Train the binary tree
%         yfit_binary = predict(binary_tree,x_test{ClassCount});
%         binary_correct = sum(y_test_binary == yfit_binary); % Calculate the accuracy
%         accuracy_BinaryClass(round, ClassCount) = binary_correct / length(y_test_binary);
%     end
    x_train_selected = x_train{SimpleClassifier(1)};
    x_test_selected = x_test{SimpleClassifier(1)};
    SCLen = length(SimpleClassifier);
    if SCLen > 1
        for ii = 2 : SCLen
            x_train_selected = cat(2,x_train_selected, x_train{SimpleClassifier(ii)});
            x_test_selected = cat(2,x_test_selected, x_test{SimpleClassifier(ii)});
        end
    end
%      binary_tree = fitcsvm(x_train_selected, y_binary_train,...
%             'Standardize',true,'CacheSize','maximal',...
%             'OutlierFraction',0.10,'Verbose',0,'Cost',SimpleCost,...
%             'ScoreTransform','doublelogit');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%2
    binary_tree = fitcensemble(x_train_selected, y_binary_train,...
        'Method','GentleBoost','LearnRate',0.12,'Cost',SimpleCost,'NumLearningCycles',200,'Learners',t);
    yfit_binary = predict(binary_tree,x_test_selected);
    binary_correct = sum(y_test_binary == yfit_binary); % Calculate the accuracy
    accuracy_BinaryClass(round, ClassCount + 1) = binary_correct / length(y_test_binary);
%     yfit_binary = yfit_binary_temp;
%     binary_tree = binary_tree_temp;
    % Advanced Classifier: 
    y_advanced_train = y_train(y_train > 1);
    y_final_test = y_test(yfit_binary == 2); % just use for the accuracy of the advanced classifier
    y_advanced_test = y_test(y_test > 1); 
    yfit_advanced = zeros(length(y_advanced_test), ClassifierNum + 1);
    yfit_final = zeros(length(y_final_test), ClassifierNum + 1);
    confidence_advanced = cell(ClassifierNum, 1);
    
%     advanced_tree = cell(1,ClassifierNum);
%     for ClassCount = 1 : ClassifierNum
%         x_advanced_train = x_train{ClassCount}(y_train > 1, :); % prepare the train data
%         x_final_test = x_test{ClassCount}(yfit_binary == 2, :); % prepare the test data just the binary tree result
%         x_advanced_test = x_test{ClassCount}(y_test > 1, :); 
%         advanced_tree{ClassCount} = fitcsvm(x_advanced_train, y_advanced_train,...
%              'Standardize',true,'CacheSize','maximal',...
%             'OutlierFraction',0.10,'Verbose',0,'Cost',AdvancedCost,...
%             'ScoreTransform','doublelogit');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%3
%         advanced_tree{ClassCount} = fitcensemble(x_advanced_train, y_advanced_train...
%             ,'Method','GentleBoost','LearnRate',0.1,'Cost',AdvancedCost,'NumLearningCycles',300);
%         yfit_advanced(:, ClassCount) =...
%             predict(advanced_tree{ClassCount}, x_advanced_test);
%         yfit_final(:, ClassCount) = predict(advanced_tree{ClassCount}, x_final_test);
        % The advanced classifier accuracy:
%         for i = 1 : 3
%             Confidence{ClassCount, i} = cat(1,Confidence{ClassCount, i},...
%                 ConfidenceTemp(y_final_test == i,:));
%         end
%         class_correct = sum(yfit_advanced(:, ClassCount) == y_advanced_test);
%         accuracy_classifier(round, ClassCount) = class_correct / length(y_advanced_test);
        % Process the confidence:
% %         Confidence{ClassCount} = zeros(size(confidence_binary,1), EventNum);
% %         Confidence{ClassCount}(:, 1 : 2) = confidence_binary(:, 1 : 2);
% %         for t = 2 : EventNum
% %             Confidence{ClassCount}(yfit_binary == 2, t) = confidence_binary(yfit_binary == 2, 2) ...
% %                 .* confidence_advanced{ClassCount}(:, t - 1);
% %         end
%     end
    x_advanced_train_selected = x_train{AdvancedClassifier(1)}(y_train > 1, :);
    x_advanced_test_selected = x_test{AdvancedClassifier(1)}(y_test > 1, :);
    x_final_test_selected = x_test{AdvancedClassifier(1)}(yfit_binary == 2, :);
    ACLen = length(AdvancedClassifier);
    if ACLen > 1
        for ii = 2 : ACLen
            x_advanced_train_selected = cat(2,x_advanced_train_selected,...
                x_train{AdvancedClassifier(ii)}(y_train > 1, :));
            x_advanced_test_selected = cat(2,x_advanced_test_selected,...
                x_test{AdvancedClassifier(ii)}(y_test > 1, :));
            x_final_test_selected = cat(2,x_final_test_selected,...
                x_test{AdvancedClassifier(ii)}(yfit_binary == 2, :));
        end
    end
%     AdvancedTree = fitcsvm(x_advanced_train_selected, y_advanced_train,...
%              'Standardize',true,'CacheSize','maximal',...
%             'OutlierFraction',0.10,'Verbose',0,'Cost',AdvancedCost,...
%             'ScoreTransform','doublelogit');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%4
    AdvancedTree = fitcensemble(x_advanced_train_selected, y_advanced_train...
        ,'Method','GentleBoost','LearnRate',0.12,'Cost',AdvancedCost,'NumLearningCycles',200,'Learners',t);
    yfit_advanced(:, ClassCount + 1) =...
            predict(AdvancedTree, x_advanced_test_selected);
    class_correct = sum(yfit_advanced(:, ClassCount + 1) == y_advanced_test);
    accuracy_classifier(round, ClassCount + 1) = class_correct / length(y_advanced_test);
    yfit_final(:, ClassCount + 1) = ...
        predict(AdvancedTree, x_final_test_selected);
%     for i = 1 : 3
%         Confidence{ClassCount + 1, i} = cat(1,Confidence{ClassCount + 1, i},...
%             ConfidenceTemp(y_final_test == i,:));
%     end
    % The following can use HMM:
    % Try One Classifier as the advanced Classifier
    % yfit_advanced = yfit_advanced(:, AdvancedClassifier);
    % Prepare for HMM:
% %     Confidence_t = Confidence{1};
% %     for t = 2 : ClassifierNum
% %         Confidence_t = [Confidence_t Confidence{t}];
% %     end
    PredictLabel = yfit_binary;
    PredictLabel(PredictLabel == 2) = mode(yfit_final(:,1:ClassifierNum), 2);%yfit_advanced; %
    num_correct = sum(PredictLabel == y_test);
    Accuracy_MajorVote(round) = num_correct / length(y_test);% Major Vote Accuracy
    PredictLabel = yfit_binary;
    PredictLabel(PredictLabel == 2) = yfit_final(:, ClassCount + 1);%yfit_advanced; %
    num_correct = sum(PredictLabel == y_test);
    Accuracy_Combine(round) = num_correct / length(y_test);% Major Vote Accuracy
    
    Count_t = 1;
    for k = 1 : EventNum
        PredictLabelTotal{k} = [PredictLabelTotal{k} ;...
            PredictLabel(Count_t : Count_t + Num_Sample_group(round, k) - 1) ];
        
        Count_t = Count_t + (Num_Sample_group(round, k));
    end

    for j = 1:length(y_test)
        confusion_matrices(y_test(j), PredictLabel(j), round) = confusion_matrices(y_test(j), PredictLabel(j), round) + 1;
    end
end % N_Fold End
clear ACLen binary_correct class_correct ConfidenceTemp Count_t samples SCLen 
clear shang start_indices x_* y_* yf yfit_* yushu round Y_EY
%% Result
Result = sum(confusion_matrices,3)%;
Accuracy = [diag(Result) ./ sum(Result,2); sum(diag(Result))/sum(sum(Result,2))]
if exist('Results','var')
    Results{PhoneChoice,UserCount,NFold} = Accuracy_Combine;
    Sizes{PhoneChoice,UserCount,NFold} = floor([size(TrainData{1,1},1),...
        size(TrainData{1,2},1), size(TrainData{1,3},1)] .* ((NFold-1)/NFold));
end
LabelCount = ones(EventNum, 1);
% Total H(x)
% Size = zeros(1,3);
% Size(1) = size(PredictLabelTotal{1},1);
% Size(2) = size(PredictLabelTotal{2},1);
% Size(3) = size(PredictLabelTotal{3},1);
% temp = Size(1) / sum(Size);
% ES = temp*log(temp);
% temp = sum(Size(2:3))/sum(Size);
% ES = ES + temp * log(temp);
% ES = -ES;
% % For Simple Classifier
% Bound = Size(1);
% TrainDataA = cell(ClassifierNum,1);
% SimpleIG = zeros(FeatureNum * length(SimpleClassifier),1);
% i = 0;
% for j = 1 : length(SimpleClassifier)
%     Class = SimpleClassifier(j);
%     for k = 1 : FeatureNum
%         Mean = mean(TrainDataA{Class}(:,k));
%         Logic = TrainDataA{Class}(:,k) > Mean;
%         Sum = length(Logic);
%         Sum1 = sum(Logic);
%         Pos1 = sum(Logic(1 : Bound));
%         Neg1 = sum(Logic(Bound+1 : end));
%         EG1 = -sum( (Pos1/Sum1) * log(Pos1/Sum1), Neg1/Sum1 * log(Neg1/Sum1));
%         Sum2 = Sum - Sum1;
%         Pos2 = Bound - Pos1;
%         Neg2 = Sum2 - Bound - Neg1;
%         EG2 = -sum( (Pos2/Sum2) * log(Pos2/Sum2), Neg2/Sum2 * log(Neg2/Sum2));
%         SimpleIG(i) = ES - Sum1/Sum * EG1 - Sum2/Sum * EG2;
%         i = i + 1;
%     end
% end


%% For Advanced Classifier
for i = 1 : ClassifierNum
    TrainDataA{i} = cat(1,TrainData{i,1},TrainData{i,2},TrainData{i,3});
end
for FileType = 2 : 3
    
    if (FileType == 2)
        RampResult = Result_Up;
    else
        RampResult = Result_Down;
    end
    for FileCount = 1 : size(RampResult,1)
        MaxLen = length(PredictLabelTotal{FileType});
        Predict_t = PredictLabelTotal{FileType}(min(LabelCount(FileType), MaxLen) :...
            min(LabelCount(FileType) + FileStep{FileType}(FileCount) - 1, MaxLen));
        LabelCount(FileType) = LabelCount(FileType) + FileStep{FileType}(FileCount);
        I = 3;
        Temp = I;
        for t = 1 : EventNum
            RampResult{FileCount, I} = sum(Predict_t == t); I = I + 1;
            if t == FileType
                Correct = sum(Predict_t == t);
                RampResult{FileCount, Temp + EventNum } = Correct/FileStep{FileType}(FileCount); 
            end
        end
    end
    if (FileType == 2)
        Result_Up = RampResult;
    else
        Result_Down = RampResult;
    end
end
SaveTime = datestr(datetime(),'yyyymmddHHMMSS');
SaveFileName = ['SVM_' SaveTime '.mat'];
% save([FileDir SaveFileName],'accuracy_BinaryClass','accuracy_classifier',...
%     'Accuracy_Combine', 'Accuracy_MajorVote',  ...
%     'AdvancedClassifier', 'AdvancedTree', 'binary_tree',...
%     'confusion_matrices', 'SimpleClassifier','Result_Up','Result_Down','TrainData');
% if ReProcess == 1
%     clear ReProcess
% end
save([FileDir SaveFileName],'accuracy_BinaryClass','accuracy_classifier',...
    'Accuracy_Combine', 'Accuracy_MajorVote',  ...
    'AdvancedClassifier', 'AdvancedTree', 'binary_tree',...
    'confusion_matrices','TrainData','PredictLabelTotal',...
    'SimpleClassifier','FeatureNum','ClassifierNum');
clear Correct Temp t I RampResult FileType i ii Index j k LabelCount locsnew mag 
clear magn magNoG MaxFlatStep Matlab_Event_Turn MeanDuration minPeakHeight
clear NFold num_correct Num_Sample_group NumPks pksnew Predict_t PredictLabel
clear RawData s SaveTime SimpleCost StartStep
clear StateKeyWord TrunThreshold Weight butter_fs_process butter_fs_seg




