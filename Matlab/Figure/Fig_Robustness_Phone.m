close all
Colors = {'Purple';'Blue';'Green';'Orange'};
ColorValue = [126 47 142;
    0 114 189;
    119 172 48;
    217 83 25]./256;
EvaluateWatchOut;
% CDF for all Uers
temp = squeeze(sum(PhoneResult,1));
temp = zeros(2,0);
for i = 1 : PhoneNum
    temp = cat(2, temp, squeeze(PhoneResult(i,:,:)));
end
Precision = temp(1,:) ./ temp(2,:);
Precision(isnan(Precision)) = [];
% Precision(7) = [];
% Precision = 
pd = fitdist(Precision','Normal');
X = 0 : 0.1 : 1;
Y = cdf(pd,X);
figure('NumberTitle', 'off', 'Name', 'Entrance detection precision');
% plot(X,Y,'LineWidth',1.4,'Color','blue');
cdfplot(Precision);
title('');
box on
set(gca,'FontSize',14,'FontName','Times');
set(gcf,'Color','w');%设置窗口的底纹为白色
xlabel('Entrance Detection Precision');
ylabel('CDF');
xlim([0 1]);
% CDF for different smartphones
figure('NumberTitle', 'off', 'Name', 'Impact of smartphone sensors');
hold on
for i = 1 : PhoneNum
    temp = PhoneResult(i, 1, :) ./ PhoneResult(i, 2, :);
    Precision = squeeze(temp);
    Precision(isnan(Precision)) = [];
%     pd = fitdist(Precision,'Normal');
%     X = 0 : 0.1 : 1;
%     Y = cdf(pd,X);
%     plot(X,Y,'Color',ColorValue(i,:),'LineWidth',1.6);
    cdfplot(Precision);
    title('');
end
hold off
box on
set(gca,'FontSize',14,'FontName','Times');
set(gcf,'Color','w');%设置窗口的底纹为白色
xlabel('Detection Precision');
ylabel('CDF');
legend1 = legend('Samsung','Huawei','Xiaomi');
set(legend1,...
    'Position',[0.721547616390955 0.123968250562274 0.184642859799521 0.154761908167885]);