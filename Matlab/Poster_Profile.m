Phone = 1;
UserCount = 6;
FileChoice = 1;
figure(4);
clf;
plot(Time,RawData(9,:),'Linewidth',1.5);
% hold on
% plot(Time(locsnew) - 0.4,ThresholdLine,'k--', 'Linewidth',2);
% plot(Time(locsnew),ThresholdLine2,'k--', 'Linewidth',2);
% hold off
xlim([815 823]);
% legend1 = legend('Acceleration','ThresholdLine');
% set(gca,'FontSize',18,'FontName','Times');
set(gcf,'Color','w');%设置窗口的底纹为白色
axis off