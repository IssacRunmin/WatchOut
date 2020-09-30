% 
PhoneChoice = [1 2 3];%[1 2 3];
AccRange = [-12 8];
Threshold = 360; %s
% inital
Event_DR = 3;
Event_DC = 5;
PhoneTypes = {'GalaxyNote3';'HuaWei';'Mi6X'};
load('Userz.mat');
load('AntiRecordTime.mat');
FilesLike = '2018*.txt';
UNum = length(Userz);
Entrance2 = zeros(1,0);
Sum_ED = 0;
Sum_Acc = 0;
PhoneNum = length(PhoneChoice);
PhoneResult = zeros(PhoneNum,2,UNum);
FeqResult = zeros(0,3);% kthUser Fequency Precision
StepSeg = zeros(2,3); % (MissSteps, TotalSteps) * Phones 
Confusion_R = zeros(6,6);
Confusion_E = zeros(7,7);
Dir = zeros(2,0);
AntiDir = zeros(2,0);
for i = 1 : PhoneNum
    PhoneType = PhoneTypes{PhoneChoice(i)};
    ResultPath = fullfile('Result',[PhoneType '.mat']);
    load(ResultPath);
    Entrance = cell(length(Users),1);
%     PhoneResult{i} = zeros(2,UNum);
    
    for U = 1 : length(Users)
        Seq = Result{U,1};
        Label = Result{U,2}';

        %% Step Segmentation Precision
        MSI = find(Label == 0);
        if ~isempty(MSI)
            MSE = [MSI(MSI(2 : end) - MSI(1 : end - 1)>1) MSI(end)]; 
            MSS = [MSI(1) MSI(find(MSI(2 : end) - MSI(1 : end - 1)>1) + 1)];
            MDis = MSE - MSS;
            MissSteps = sum(MDis(MDis < 4));
        else
            MissSteps = 0;
        end
        StepSeg(1,i) = StepSeg(1,i) + MissSteps;
        StepSeg(2,i) = StepSeg(2,i) + length(Label);
        %% Step Event confusion matrix
        % Step-based: 
        Confusion_t = zeros(6,6);
        for t1 = 1 : 6
            for t2 = 1 : 6
                Confusion_t(t1,t2) = sum(Seq == t1 & Label == t2);
            end
        end
        Confusion_R = Confusion_R + Confusion_t;
        % Event-based:
        WindowLen = 80;
        SeqE = zeros(1,0);
        SeqI = zeros(1,0);
        LabelE = zeros(1,0);
        LabelI = zeros(1,0);
        for event = 2 : 6
            EI = find(Seq == event);% Event index
            if ~isempty(EI)
                EIE = [EI(EI(2 : end) - EI(1 : end - 1)>1) EI(end)];
                SeqI = [SeqI EIE];
                SeqE = [SeqE ones(1,length(EIE)) .* event];
            end
            EI = find(Label == event);% Event index
            if ~isempty(EI)
                EIE = [EI(EI(2 : end) - EI(1 : end - 1)>1) EI(end)];
                LabelI = [LabelI EIE];
                LabelE = [LabelE ones(1,length(EIE)) .* event];
            end
        end
        [SeqI, I_t] = sort(SeqI);
        SeqE = SeqE(I_t);
        [LabelI, I_t] = sort(LabelI);
        LabelE = LabelE(I_t);
        LabelUsed = ones(1,length(LabelE));
        for t1 = 1 : length(SeqE)
            LT = LabelI(LabelE == SeqE(t1));
            
            [MinDis,I_t] = min(abs(LT - SeqI(t1)));
            if MinDis < WindowLen
                Confusion_E(SeqE(t1),SeqE(t1)) = Confusion_E(SeqE(t1),SeqE(t1)) + 1;
            else
                [MinDis,I_t] = min(abs(LabelI - SeqI(t1)));
                if MinDis < WindowLen
                    Confusion_E(SeqE(t1),LabelE(I_t)) = Confusion_E(SeqE(t1),LabelE(I_t)) + 1;
                    LabelUsed(I_t) = 0;
                else
                    Confusion_E(SeqE(t1),7) = Confusion_E(SeqE(t1),7) + 1;
                end
            end
        end
        for t2 = 1 : length(LabelE)
            if LabelUsed(t2) ~= 0
                [MinDis,I_t] = min(abs(SeqI - LabelI(t2)));
                if MinDis < WindowLen
                    Confusion_E(SeqE(I_t),LabelE(t2)) = Confusion_E(SeqE(I_t),LabelE(t2)) + 1;
                else
                    Confusion_E(7,LabelE(t2)) = Confusion_E(7,LabelE(t2)) + 1;
                end
            end
        end
        %% Latency Distrubition
        SSI = find(Seq == Event_DR | Seq == Event_DC);
        Entrance_GT = [SSI(SSI(2 : end) - SSI(1 : end - 1)>1) SSI(end)]; % Entrance事件的结束
        EntranceDis = ones(1,length(Entrance_GT)) .* 50;
        Correct = 0;
        for k = 1 : length(Entrance_GT)
            I = Entrance_GT(k);
            Flag = false;
            for j = I - 40 : I + 40
                if j <= 0 || j > length(Seq)
                    continue;
                end
                if (Label(j) == Event_DR || Label(j) == Event_DC) || Label(j) == 6%% && Label(j+1) == 1 
                    Flag = true;
                    if (abs(j-I + 6) < abs(EntranceDis(k) + 6))
                        EntranceDis(k) = j - I;
                    end
                    if (j - I) > -1
                        break;
                    end
                end
            end
            if Flag
                Correct = Correct + 1;
            end
        end
        Entrance{U} = EntranceDis;
        Entrance2 = cat(2,Entrance2,EntranceDis);
        %% Precision
        Index = 0;
        Name = upper(Users{U});
        for k = 1 : UNum
            if ~isempty(strfind(Name,upper(Userz{k})))
                Index = k;
            end
        end
        if Index ~= 0
            temp = sum(EntranceDis > AccRange(1) & EntranceDis < AccRange(2));
            PhoneResult(i, 1, Index) = PhoneResult(i, 1, Index) + temp;
            PhoneResult(i, 2, Index) = PhoneResult(i, 2, Index) + length(EntranceDis);
            FeqResult = cat(1,FeqResult, [Index Result{U,3} temp/length(EntranceDis)]);
        end
       %% Different Direction
%         Index = 0;
%         Name = upper(Users{U});
%         I_t = strfind(Users{U},'_');
%         FileChoice = str2double(Users{U}(I_t(end) + 1 : end));
%         if isnan(FileChoice)
%             tt = Users{U}(I_t(end) + 1 : end);
%             FileChoice = str2double(tt(1));
%         end
%         for k = 1 : UNum
%             if ~isempty(strfind(Name,upper(Userz{k})))
%                 Index = k;
%             end
%         end
%         if Index ~= 0
%             FileDir = ['MobilePhoneSensor\' PhoneTypes{i} '\' Userz{Index}];
%             Files = dir(fullfile(FileDir,FilesLike));
%             FileNames = {Files.name}';
%             RawFile = FileNames{FileChoice};
%             Index = strfind(RawFile, '-');
%             RecordTimeMs = str2double(RawFile(Index(2)+1:Index(3)-1));
%             TempString = RawFile(1:Index(2)-1);
%             TempString(Index(end - 2)) = ' ';
%             TempString = insertBefore(TempString,5,'-');
%             TempString = insertBefore(TempString,8,'-');
%             TempString = insertBefore(TempString,14,':');
%             RecordTimeString = insertBefore(TempString,17,':');
%             DateFloat = datenum(RecordTimeString ,'yyyy-mm-dd HH:MM:SS');
%             FileRecordTime = DateFloat * 24 * 3600 + RecordTimeMs / 1000;
%             [MinT, I_t] = min(abs(AntiRecordTime - FileRecordTime));
%             if MinT < Threshold
%                 AntiDir = cat(2, AntiDir, [temp ; length(EntranceDis)]);
%             else
%                 Dir = cat(2, AntiDir, [temp ; length(EntranceDis)]);
%             end
%         end
    end
    
    %% FP
    LI = find(Label == Event_DR | Label == Event_DC);
    E_Det = [LI(LI(2 : end) - LI(1 : end - 1)>1) LI(end)];
    Sum_ED = Sum_ED + length(E_Det);
    for k = 1 : length(E_Det)
        I = E_Det(k);
        Left = max(I+AccRange(1),1);
        Right = min(I+AccRange(2), length(Label));
        if isempty(find(Seq(Left:Right) == Event_DR | Seq(Left:Right) == Event_DC ,1))
            Sum_Acc = Sum_Acc + 1;
        end
    end
end
% FalsePositiveRate = Sum_Acc / Sum_ED
