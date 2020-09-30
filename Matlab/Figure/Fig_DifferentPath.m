XLabel = 'Number of folds';
YLabel = 'Precision';
X = {'Path#1'; 'Path#2'};
close 
EvaluateWatchOut;
figure('NumberTitle', 'off', 'Name', 'Step Segmentation Precision');
Path1 = sum(AntiDir(1,:)) / sum(AntiDir(2,:));
Path2 = sum(Dir(1,:)) / sum(Dir(2,:));
Y = [Path1 Path2];
n = [1 2];
bar(n, Y, 'b', 'BarWidth',0.3);
box on

set(gca,'ylim',[0.82 0.90]);

for i = 1 : length(Y)
    Text = sprintf('%2.3f%%',Y(i)*100);
    text(n(i), Y(i) + 0.005, Text,'VerticalAlignment','middle',...
        'HorizontalAlignment','center','FontSize',14,...
        'FontName','Times');
end
set(gca,'XTickLabel',X);
ylabel(YLabel);
set(gca,'FontSize',14,'FontName','Times');
set(gca,'GridLineStyle','--');
set(gcf,'Color','w');%设置窗口的底纹为白色