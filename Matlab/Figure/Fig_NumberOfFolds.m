load('Result\NumberOfFolds_Galaxy.mat')
%% Parameters
select = [3 23 15 21];
select2 = [3 4 6 15 16 18 23 25];
Results(:,1) = [];
DataIn = Results(select,:);
x = 2 : 10;
XLabel = 'Number of folds';
YLabel = 'Classification Precision';
Legend = {'User #1';'User #2';'User #3';'User #4'};
Colors = {'Purple';'Blue';'Green';'Orange'};
ColorValue = {[126 47 142];
    [0 114 189];
    [119 172 48];
    [217 83 25]};
%% Preprocessing
for i =  1 : length(ColorValue)
    ColorValue{i} = ColorValue{i} ./ 256;
end
if ~iscell(DataIn)
    error('Unhandled Input Data Size!');
end
Xn = size(DataIn,2);
LineNum = size(DataIn,1);
alpha = 0.75;
if (Xn ~= length(x))
    warning('incorrect x axis index!');
    x = 1 : Xn;
end
mu = zeros(LineNum,Xn);
muci = zeros(LineNum,2,Xn);
%% Calculate μ & 95% confidence intervals 
for j = 1 : LineNum
    for i = 1 : Xn
        [mu(j,i),sigmahat,muci(j,:,i),sigmaci] = normfit(DataIn{j,i},alpha);
    end
end
%% Plot Figure
figure;
Areas = cell(1,LineNum); 
hold on
for i = 1 : LineNum
    mu_t = mu(i,:);
    plot(x,mu_t,'LineWidth',2,'Color',ColorValue{i});    
end
for i = 1 : LineNum % Final: change LineNum
    muci_t = squeeze(muci(i,:,:));
    Areas{i} = fill([x,fliplr(x)],[muci_t(1,:),fliplr(muci_t(2,:))],...
        ColorValue{i},'FaceAlpha',0.2,'EdgeColor',ColorValue{i},...
        'EdgeAlpha',0.4,'EdgeLighting','flat','LineWidth',0.3);
    % ,'FaceLighting','gouraud'

end
hold off
grid on
box on
xlabel(XLabel);
ylabel(YLabel);
legend(Legend);
set(gca,'FontSize',14,'FontName','Times');
set(gca,'GridLineStyle','--');
set(gcf,'Color','w');%设置窗口的底纹为白色