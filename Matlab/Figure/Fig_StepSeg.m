close all
EvaluateWatchOut;
figure('NumberTitle', 'off', 'Name', 'Step Segmentation Precision');
SegSteps = StepSeg(2,:) - StepSeg(1,:);
X = {'Samsung'; 'Huawei'; 'Xiaomi'};
Y = SegSteps ./ StepSeg(2,:) .* 100;
n = 1:3;
bar( Y,'b', 'BarWidth',0.4 );
for i = 1 : length(Y)
    Text = sprintf('%2.2f%%',Y(i));
    text(n(i), Y(i) + 0.3, Text,'VerticalAlignment','middle',...
        'HorizontalAlignment','center','FontSize',14,...
        'FontName','Times');
end
box on
set(gca,'FontSize',14,'FontName','Times');
set(gcf,'Color','w');%设置窗口的底纹为白色

set(gca,'ylim',[90 100]);
ylabel('Step Segmentation Accuracy');
set(gca,'XTickLabel',X);