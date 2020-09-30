close 
Range = [1800 3300];
Scale = 180;
Colors = {'Purple';'Blue';'Green';'Orange'};
ColorValue = [126 47 142;
    0 114 189;
    119 172 48;
    217 83 25]./ 256;
XLabel = 'Size of Training Set';
YLabel = 'Step Classification Precision';
% Legend = {'Ensemble'; 'DecisionTree'; 'SVM'};
alpha = 0.15;
Classifiers = {'Ensemble'; 'DecisionTree'; 'SVM'};
CNum = length(Classifiers);
SizeI = zeros(1,50);

RangeS = round(Range ./ Scale);%[17 34];
Num = RangeS(2) - RangeS(1) + 1;
X = RangeS(1) : RangeS(2);
X = X .* Scale;
mu = zeros(CNum, Num);
muci = zeros(2, CNum, Num);
for C = 1 : CNum
    TotalR = cell(1, RangeS(2));
    ResultPath = ['TrainingResult/' Classifiers{C} '.mat'];
    load(ResultPath);
    Size = zeros(3, 25, 10); % 3 Phones, 25 Users, 10 Sizes
    for P = 1 : 3
        for U = 1 : 25
            for F = 2 : 10
                Size(P,U,F) = sum(Sizes{P,U,F});
                temp = round(Size(P,U,F) / Scale);
                if temp ~= 0
                    SizeI(temp) = SizeI(temp) + 1;
                end
                if temp >= RangeS(1) && temp <= RangeS(2)
                    TotalR{temp} = cat(2, TotalR{temp}, max(Results{P,U,F}));
                end
            end
        end
    end
    TotalR(1 : RangeS(1) - 1) = [];
    for i = 1 : Num
        [mu(C,i), ~, muci(:,C,i), ~] = normfit(TotalR{i},alpha);
    end
end
Areas = cell(1,length(TotalR));
figure('NumberTitle', 'off', 'Name', 'Effect of training set size');
hold on 
for C = 1 : CNum
    plot(X, mu(C,:), 'LineWidth',2,'Color',ColorValue(C,:));
end
for C = 1 : CNum
    muci_t = squeeze(muci(:,C,:));
    Areas{i} = fill([X,fliplr(X)],[muci_t(1,:),fliplr(muci_t(2,:))],...
        ColorValue(C,:),'FaceAlpha',0.2,'EdgeColor',ColorValue(C,:),...
        'EdgeAlpha',0.4,'EdgeLighting','flat','LineWidth',0.3);
end

hold off
grid on
box on
xlabel(XLabel);
ylabel(YLabel);
legend1 = legend(Classifiers);
% legend1 = legend(axes1,'show');
set(legend1,...
    'Position',[0.670119043736231 0.123968288709247 0.236071432454245 0.154761908167885]);
set(gca,'FontSize',14,'FontName','Times');
set(gca, 'xlim',[X(1) X(end)]);
set(gca,'GridLineStyle','--');
set(gcf,'Color','w');%设置窗口的底纹为白色
