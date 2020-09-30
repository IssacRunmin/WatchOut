Result = [0.00000 	0.00000 	0.00000 	0.00000 ;
0.00000 	0.00000 	0.00000 	0.00000 ;
0.09091 	0.36364 	0.09091 	0.36364 ;
0.72727 	0.63636 	0.63636 	0.18182 ;
0.18182 	0.00000 	0.27273 	0.45455 ];
Result = Result'.*100;
str = 'ABCD';
X = 1 : 5;
XLabel = {{'A. Is WatchOut helpful?'; '(1- Useless, 5- Very helpful)'};
    {'B. Is WatchOut sensitive to the entrance?'; '(1- Very Insensitive, 5- Very sensitive)'};
    {'C. Is the alert of WatchOut timely?'; '(1- Very slowly, 5- Very timely)'};
    {'D. Is the way of training is easy?'; '(1- Extremely Difficult, 5- Extremely easy)'}};
close all
figure('NumberTitle', 'off', 'Name', 'User Study');
for i = 1 : 4
    subplot(2,2,i);
    bar(Result(i,:), 'b', 'BarWidth',0.4 );
    Y = Result(i,:);
    n = 1 : 5;
    for j = 1 : length(Y)
        Text = sprintf(' %2.2f%%',Y(j));
        text(n(j), Y(j) + 5, Text,'VerticalAlignment','middle',...
            'HorizontalAlignment','center','FontSize',8,...
            'FontName','Times');
    end
    box on
    grid on
    set(gca,'FontSize',8,'FontName','Times');
    set(gcf,'Color','w');%设置窗口的底纹为白色
%     set(gca,'yTickLabel',[0 20 40 60 80 100]);
    ylim([0 100]);
    ylabel('%');
    xlabel(XLabel{i});
    set(gca,'XTickLabel',X);
end