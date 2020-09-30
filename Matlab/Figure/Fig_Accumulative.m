close all
EvaluateWatchOut;
load('LookUpAcc.mat');
Range = -12:5;
Len = length(Range);
Accumulative = zeros(1,Len);

Temp = Entrance2;
Temp = Temp(Temp >= Range(1) & Temp <= Range(end));
SUM = length(Temp);
for i = 1 : Len
    Accumulative(i) = sum(Temp <= Range(i)) / SUM;
end
Temp = LookUpAcc;
Temp = Temp(Temp >= Range(1) & Temp <= Range(end));
Accumulative_LookUp = zeros(1,Len);
SUM = length(Temp);
for i = 1 : Len
    Accumulative_LookUp(i) = sum(Temp <= Range(i)) / SUM;
end

% Accumulative = Accumulative .* 100;
figure('NumberTitle', 'off', 'Name', 'Cumulative entrance detection');
hold on
bar(Range,Accumulative_LookUp.*100,'r');
bar(Range,Accumulative.*100,0.5,'b');

hold off
box on
set(gca,'FontSize',14,'FontName','Times');
set(gcf,'Color','w');%设置窗口的底纹为白色
set(gca,'xlim',[Range(1)-1 Range(end)+1]);
xlabel('Steps Near an Entrance');
ylabel('Detection Percentage');
legend1 = legend('LookUp','WatchOut');
set(legend1,...
    'Position',[0.130119044655845 0.820396823126172...
    0.197500002963202 0.105952383223034]);


