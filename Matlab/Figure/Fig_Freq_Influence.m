close all
% Colors = {'Purple';'Blue';'Green';'Orange'};
ylimm = [0.78 1.02];
ColorValue = [0 0 0
    87 96 105;
    39 72 98;
    153 80 84;
    217 104 49;
    230 179 61;
    196 226 216;
    ]./256;
Dots = 'dhpsx+*^<>vo';
Select = [4 6 9 10 15 17 18 19 21 22 23 24 25];
EvaluateWatchOut;
UserI = FeqResult(:,1);
SelectResult = zeros(0,3);
for i = 1 : length(Select)
    In = find(UserI==Select(i));
    SelectResult = cat(1, SelectResult, FeqResult(In,:));
end

SelectResult(:,2) = SelectResult(:,2) .* 60;
S = SelectResult;
SelectResult(S(:,3) < 0.82,:) = [];
figure('NumberTitle', 'off', 'Name', 'Influence of step frequency');
j = 0;
hold on
Total = size(SelectResult,1);
for i = 1 : Total
    ColorT = ColorValue(rem(j,size(ColorValue,1))+1,:);
    DD = Dots(rem(j,size(ColorValue,1))+1);
    scatter(SelectResult(i,2),SelectResult(i,3),'Marker',DD,...
        'MarkerEdgeColor',ColorT,'MarkerFaceColor',ColorT,...
        'LineWidth',1.2);
    if i < Total && SelectResult(i,1) ~= SelectResult(i+1,1)
        j = j + 1;
    end
end
hold off
box on
set(gca,'FontSize',14,'FontName','Times');
set(gcf,'Color','w');%设置窗口的底纹为白色
set(gca,'ylim',ylimm);
xlabel('Step Frequency: steps/min');
ylabel('Precision');

