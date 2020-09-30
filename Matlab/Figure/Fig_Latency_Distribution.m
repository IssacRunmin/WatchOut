EvaluateWatchOut;
Color = [-20 -8 5 20];
ColorI = [-39 -30 -20 -12 -8 0 5 8 13 25 40];
ColorV = {[0 0 0];
    [1 0 0];    % Red
    [1 1 0];    % Yellow
    [84 130 53]./256; % Deep Green
    [0 0.75 0];
    [0 1 0];    % Green
    [84 130 53]./256; % Deep Green
    [1 1 0];    % Yellow
    [1 0 0];
    [0.75 0 0];    % Red
    [94 54 54]./256
    };
cm = zeros(80,3);
I = ColorI + 40;
for i = 2 : length(ColorI)
    for j = 1 : 3
        if ColorV{i}(j) == ColorV{i-1}(j)
            cm(I(i-1):I(i),j)= ColorV{i}(j);
        else
            R = (ColorV{i}(j) - ColorV{i-1}(j)) / (I(i) - I(i-1));
            temp = ColorV{i-1}(j) : R : ColorV{i}(j);
            cm(I(i-1):I(i),j) = temp;
        end
        
    end
end
X = -39:40;
Y = zeros(1,80);
Unique = unique(Entrance2);
Num = zeros(1,length(Unique));
for i = 1 : 80
    Y(i) = sum(Entrance2 == X(i));
end
Precision = sum(Y)/ length(Entrance2)
figure1 = figure('NumberTitle', 'off', 'Name', 'Influence of step frequency');
Y_1 = diag(Y);
b = bar(X,Y_1,'stack','LineWidth',0.8,'BarWidth',1);
for i = 1 : 80
    b(i).FaceColor = cm(i,:);
%     b(i).EdgeColor = cm(i,:);
end
% 创建 textarrow
annotation(figure1,'textarrow',[0.537142857142857 0.498367791077258],...
    [0.788571428571429 0.683725690890483],'String',{'ENTERING','STREET   '},...
    'FontSize',12,'FontName','Times');
annotation(figure1,'textarrow',[0.61 0.609357997823722],...
    [0.297142857142857 0.184237461617196],'String',{'IN-STREET  ','DETECTIONS'},...
    'FontSize',12,'FontName','Times');
annotation(figure1,'textarrow',[0.795714285714286 0.769314472252448],...
    [0.297142857142857 0.185261003070624],'String',{'NEXT     ','SIDEWALK'},...
    'FontSize',12,'FontName','Times');
annotation(figure1,'textarrow',[0.298571428571429 0.334285714285714],...
    [0.297142857142857 0.184761904761905],'String',{'APPROACHING','STREET       '},...
    'FontSize',12,'FontName','Times');
set(gca,'xlim',[-40 40]);
set(gca,'FontSize',14,'FontName','Times');
set(gcf,'Color','w');%设置窗口的底纹为白色
xlabel('Step before and after Entrance');
ylabel('Number of Detections');
box on