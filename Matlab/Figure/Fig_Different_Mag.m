% close all
load('Eva_Mag.mat');
AXIS_X = [212.5 223.5] - 2.5;%[815.14 821.72];
AXIS_Y = [-6 7];
LABEL = 213.4;
LABEL_HIGH = 0.05;
figure('NumberTitle', 'off', 'Name', 'Different magnitude');
plot(Time,magNoG_b,'LineWidth',1.4,'Color','blue');
hold on
plot(Time(locsnew) - 0.4,ThresholdLine,'r-.','LineWidth',1.2);
plot(Time(locsnew),ThresholdLine2,'r-.','LineWidth',1.2);
set(gca,'xlim',AXIS_X);
if ~isempty(AXIS_Y)
    set(gca,'ylim',AXIS_Y);
end

YLIM = get(gca,'ylim');
Seg_Max = ones(1,length(locsnew)) .* YLIM(2);
Seg_Min = ones(1,length(locsnew)) .* YLIM(1);
stem(Time(locsnew),Seg_Max,'LineStyle','--','Marker','none','Color','black','LineWidth',0.2);
stem(Time(locsnew),Seg_Min,'LineStyle','--','Marker','none','Color','black','LineWidth',0.2);

LABEL_SET = YLIM(2) - (YLIM(2) - YLIM(1)) * LABEL_HIGH;
text(LABEL(1)+0.12,LABEL_SET,'\bfCurb','FontSize',10,'FontName','Times');
text(LABEL(1)-0.20,LABEL_SET,'\bf┣         ┫','FontSize',9);
hold off
legend1 = legend('Acceleration','Thr\_C','Segment');
set(gca,'FontSize',14,'FontName','Times');
set(gcf,'Color','w');%设置窗口的底纹为白色
xlabel('Time/s');
ylabel('Magnitude: m/s^2');

set(legend1,...
    'Position',[0.678333184104749 0.754087298544628 0.227500003678458 0.171904765719459]);
