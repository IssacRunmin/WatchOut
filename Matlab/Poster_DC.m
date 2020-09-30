Phone = 1;
UserCount = 6;
FileChoice = 1;
figure(2);
clf;
plot(Time,magNoG_b,'Linewidth',1.5);
hold on
plot(Time(locsnew) - 0.4,ThresholdLine,'k--', 'Linewidth',2);
plot(Time(locsnew),ThresholdLine2,'k--', 'Linewidth',2);
hold off
xlim([815 823]);
legend1 = legend('Acceleration','ThresholdLine');
set(gca,'FontSize',18,'FontName','Times');
set(gcf,'Color','w');%设置窗口的底纹为白色
xlabel('Time/s');
ylabel('Magnitude m/s^2');
% title('Down Curb');
set(legend1,...
    'Position',[0.661607142857143 0.826190476190476 ...
    0.24375 0.0988095238095238]);

figure(3);
clf;
plot(Time,magNoG_b,'Linewidth',1.5);
hold on
plot(Time(locsnew) - 0.4,ThresholdLine,'k--', 'Linewidth',2);
plot(Time(locsnew),ThresholdLine2,'k--', 'Linewidth',2);
hold off
xlim([831 838]);
legend1 = legend('Acceleration','ThresholdLine');
set(gca,'FontSize',18,'FontName','Times');
set(gcf,'Color','w');%设置窗口的底纹为白色
xlabel('Time/s');
ylabel('Magnitude m/s^2');
% title('Down Curb');
set(legend1,...
    'Position',[0.661607142857143 0.826190476190476 ...
    0.24375 0.0988095238095238]);