function [HaveGTFile, State,Seq] = GenerateGroundTruth_Orm201807272112(...
FileDir, FileRecordTime, LinkFileNum, RecordRange, BiasTimeAdjust,...
AbTimeSet, locsnew, Time, Label)
%% Generate GroundTruth
% for AndroidStepEvaluation & LookUp_Evaluation
GroundTruth_Android = false; % Using Android's Step Segmentation to generate ground truth
% For Ground Truth generation
    Event_FL = 1;
    Event_UR = 2;
    Event_DR = 3;
    Event_UC = 4;
    Event_DC = 5;
    Event_LT = 6;
    Event_RT = 7;
    MaxRampMiss = 15;
    State_FL = 1;
    State_UR = 2;
    State_DR = 3;
    State_UC = 4;
    State_DC = 5;
    State_Road = 6;
    Matlab_Event_Turn = 6;
    State = [];
    Seq = [];
HaveGTFile = true;
GTFiles = dir(fullfile(FileDir,'GT*.txt'));
GTFiles = {GTFiles.name}';
if ~isempty(GTFiles)
    Index = strfind(GTFiles,'-');% maybe a cell array
    if iscell(Index)
        FileNum = length(Index);
    else
        FileNum = 1;
        GTFiles{1} = GTFiles; % Change this to cell Array
        Index{1} = Index;
    end
    GTRecordTimeString = cell(FileNum, 1);
    GTFile = cell(1,LinkFileNum);
    DFileI = 1;
    BiasTime = cell(1,LinkFileNum);
    % Find Ground Truth File which Match it 
    for FileCount = 1 : FileNum
        TempString = GTFiles{FileCount}(3:Index{FileCount}(2)-1);
        GTTimeMs = str2double(GTFiles{FileCount}...
            (Index{FileCount}(2)+1:Index{FileCount}(3)-1));
        TempString(Index{FileCount}(1)-2) = ' ';
        TempString = insertBefore(TempString,5,'-');
        TempString = insertBefore(TempString,8,'-');
        TempString = insertBefore(TempString,14,':');
        GTRecordTimeString{FileCount} = insertBefore(TempString,17,':');
        GTRecordTime= datenum(GTRecordTimeString{FileCount},'yyyy-mm-dd HH:MM:SS');
        GTRecordTime = GTRecordTime .* 3600 .* 24 + GTTimeMs / 1000;
        Bias = GTRecordTime - FileRecordTime(DFileI);
        if abs(Bias) < RecordRange
            GTFile{DFileI} = GTFiles{FileCount};
            BiasTime{DFileI} = Bias;
            DFileI = DFileI + 1;
            if (DFileI > LinkFileNum)
                break;
            end
        end
    end
    if ~isempty(GTFile{LinkFileNum})
        GTEvent = zeros(1,0);
        GT_Time = zeros(1,0);
        for FileCount = 1 : LinkFileNum
            FileHandle = fopen(fullfile(FileDir,GTFile{FileCount}));
            GTData = fscanf(FileHandle,'%f',[2,inf]);
            fclose(FileHandle);
            GT_Time_t = GTData(1,:) ./ 1000 + BiasTime{FileCount} +...
                BiasTimeAdjust + AbTimeSet(FileCount);
            GT_Time = cat(2,GT_Time,GT_Time_t);
            GTEvent = cat(2, GTEvent, GTData(2,:));
        end
        if GroundTruth_Android
            GTSteps = Locs;
        else
            GTSteps = locsnew;
        end
        StepsNum = length(GTSteps);
        GTEventNum = length(GTEvent);
        GTSeq = zeros(1,StepsNum);
        Step_i = 1;
        GTEvent_i = 1;
        while GT_Time(GTEvent_i) < 0
            GTEvent_i = GTEvent_i + 1;
        end

        while GTEvent_i < GTEventNum && Step_i < StepsNum
            if abs(Time(GTSteps(Step_i)) - GT_Time(GTEvent_i)) < 0.3 || ...
                    Time(GTSteps(Step_i)) > GT_Time(GTEvent_i)
                GTSeq(Step_i) = GTEvent(GTEvent_i);
                GTEvent_i = GTEvent_i + 1;
            end
            Step_i = Step_i + 1;
        end

        LastEvent = Event_FL;
        LastIndex = 0;
        Step_i = 1;
        % Event Process
        while Step_i <= StepsNum
            switch GTSeq(Step_i)
                case Event_FL % Flat Event Logged
                    if (LastEvent ~= Event_UC)
                        GTSeq(LastIndex + 1 : Step_i) = LastEvent;
                    else
                        GTSeq(LastIndex + 1 : Step_i) = Event_FL;
                    end
                    LastIndex = Step_i;
                    LastEvent = Event_FL;

                case Event_UR % Up Ramp Event Logged
                    if Step_i - LastIndex < MaxRampMiss && ...
                            (LastEvent == Event_UR || LastEvent == Event_UC)
                        % 2 0 0 0 2 ¡ú 2 2 2 2 2
                        GTSeq(LastIndex + 1 : Step_i) = Event_UR;
                    else
                        % 1 1 0 0 0 2 ¡ú 1 1 1 1 1 2
                        GTSeq(LastIndex + 1 : Step_i) = Event_FL;
                        LastEvent = Event_UR;
                    end
                    LastIndex = Step_i;
                case Event_DR % the same as Up Ramp
                    if Step_i - LastIndex < MaxRampMiss && LastEvent == Event_DR
                        GTSeq(LastIndex + 1 : Step_i) = Event_DR;
                    else
                        GTSeq(LastIndex + 1 : Step_i) = Event_FL;
                        LastEvent = Event_DR;
                    end
                    LastIndex = Step_i;


                case Event_UC
                    % 1 0 0 0 4 ¡ú 1 1 1 1 4
                    GTSeq(LastIndex + 1 : Step_i) = LastEvent;
                    if (Step_i > 1) && Label(Step_i - 1) == Event_UC
                        % 1 1 1 1 4 0¡ú 1 1 1 4 4 0
                        GTSeq(Step_i - 1: Step_i) = Event_UC;
                        LastIndex = Step_i;
                    else
                        % 1 1 1 1 4 0¡ú 1 1 1 1 4 4 
                        GTSeq(Step_i: Step_i + 1) = Event_UC;
                        LastIndex = Step_i + 1;
                        Step_i = Step_i + 1; % Add 2 totally
                    end
                    LastEvent = Event_UC;
                    % 1 1 1 4 4 0(2?)0 ...
                    % detect 1: 1 1 1 4 4 1 1 1
                    % detect 2: 1 1 1 4 4 2 2 2
                case Event_DC % The same as Up Curb
                    GTSeq(LastIndex + 1 : Step_i) = LastEvent;
                    if Label(Step_i - 1) == Event_DC
                        GTSeq(Step_i - 1: Step_i) = Event_DC;
                        LastIndex = Step_i;
                    else
                        GTSeq(Step_i: Step_i + 1) = Event_DC;
                        LastIndex = Step_i + 1;
                        Step_i = Step_i + 1;
                    end
                    LastEvent = Event_FL;

                case Event_LT
                    % * 0 0 LT 0 ¡ú * * * LT 0
                    GTSeq(LastIndex + 1 : Step_i) = LastEvent;
                    if Label(Step_i - 1) == Matlab_Event_Turn && Label(Step_i - 2) == Matlab_Event_Turn
                        GTSeq(Step_i - 2: Step_i - 1) = Event_LT;
                        LastIndex = Step_i - 1;
                    else
                        if Label(Step_i - 1) == Matlab_Event_Turn
                            % * * * LT 0 ¡ú * * LT LT 0
                            GTSeq(Step_i - 1: Step_i) = Event_LT;
                            LastIndex = Step_i;
                        else
                            % * * * LT 0 ¡ú * * * LT LT
                            GTSeq(Step_i: Step_i + 1) = Event_LT;
                            LastIndex = Step_i + 1;
                            Step_i = Step_i + 1;
                        end
                    end
                    % * * * LT LT 0(*?) 0
                    % not change LastEvent
                case Event_RT % The same as Left Trun
                    GTSeq(LastIndex + 1 : Step_i) = LastEvent;
                    if Label(Step_i - 1) == Matlab_Event_Turn && Label(Step_i - 2) == Matlab_Event_Turn
                        GTSeq(Step_i - 2: Step_i - 1) = Event_RT;
                        LastIndex = Step_i - 1;
                    else
                        if Label(Step_i - 1) == Matlab_Event_Turn
                            GTSeq(Step_i - 1: Step_i) = Event_RT;
                            LastIndex = Step_i;
                        else
                            GTSeq(Step_i: Step_i + 1) = Event_RT;
                            LastIndex = Step_i + 1;
                            Step_i = Step_i + 1;
                        end
                    end
                    % not change LastEvent
            end
          Step_i = Step_i + 1;
        end
        GTSeq(LastIndex + 1 : Step_i - 1) = Event_FL;
       % Generate States
        GTState = ones(1,StepsNum);
        CurrentState = 1;
        Step_i = 2;
        while Step_i < StepsNum
            switch GTSeq(Step_i)
                case Event_FL
                    % if 3333663333366 occured (normal: 3333663331166)
                    Temp_i = Step_i - 1;
                    while (GTSeq(Temp_i) == Event_LT || GTSeq(Temp_i) == Event_RT)...
                            && (Temp_i >1)
                        Temp_i = Temp_i - 1;
                    end
                    switch GTSeq(Temp_i)
                        case Event_UR
                            CurrentState = State_FL;
                        case Event_UC
                            CurrentState = State_FL;
                        case Event_DC
                            CurrentState = State_Road;
                        case Event_DR
                            CurrentState = State_Road;

                    end

                case Event_DC
                    CurrentState = State_DC;%State_Road4;%State_Down;%State_DC;
                case Event_UC
                    CurrentState = State_UC;%State_FL;%State_Up;%State_UC;
                case Event_LT

                case Event_RT

                case Event_UR
                    CurrentState = State_UR;%State_FL;%State_Up;%State_UR;
                case Event_DR
                    CurrentState = State_DR;%State_Road4;%State_Down;%State_DR;
                otherwise
                    CurrentState = GTSeq(Step_i);
            end
            GTState(Step_i) = CurrentState;
            Step_i = Step_i + 1;
        end

        % Adjust Ground Truth
        CurbEventsIndex_U = GTSeq == Event_UC;
        CurbEventsIndex_D = GTSeq == Event_DC;
        TurnEventsIndex = GTSeq == Event_LT | GTSeq == Event_RT;
        OutSeq = GTSeq;
        OutSeq(CurbEventsIndex_U) = 4;
        OutSeq(CurbEventsIndex_D) = 5;
        OutSeq(TurnEventsIndex) = 6;
        Seq = OutSeq;
        State = GTState;
        
        clear Step_i GTEvent_i GTData FileHandle TempString LastIndex LastEvent
        clear CurrentState AzimuthBias AzimuthChange AzimuthTemp AzimuthThreshold
        clear Bias BiasTime ButterworthData ClassCount CurbEventsIndex
        clear CurbRange CurrentState f 
    else
        error('Orm: No (ALL) Ground Truth File Matched!');
        HaveGTFile = false;
    end
else
    warning('Orm: No Ground Truth File Found!');
    HaveGTFile = false;
end