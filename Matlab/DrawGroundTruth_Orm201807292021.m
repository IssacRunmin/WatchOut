function Result = DrawGroundTruth_Orm201807292021...
    (Time,Locs,locsnew,Label,Seq,State,HaveStepFile,HaveGTFile,RawFile,PlotState,FileChoice)
PlotAllLabel = false;
ylim_m = get(gca,'ylim');
    if HaveStepFile
        Y_1 = ones(1,length(Locs)) .* ylim_m(1);
        stem(Time(Locs), Y_1, 'LineStyle', '--', 'Marker', 'none', 'Color', 'red');
    else
        Y_1 = ones(1,length(locsnew)) .* ylim_m(1);
        stem(Time(locsnew), Y_1, 'LineStyle', '--', 'Marker', 'none', 'Color', 'red');
    end
    Y_2 = ones(1,length(locsnew)) .* ylim_m(2);
    stem(Time(locsnew), Y_2, 'LineStyle', '--', 'Marker', 'none', 'Color', 'red');
    set(gca,'FontSize',14,'FontName','Times');
    set(gcf,'Color','w');%设置窗口的底纹为白色
    xlabel('Time/s');
    
    set(gcf,'outerposition',get(0,'screensize'));
    TxtIndex = Time(locsnew);
    for i = 1 : length(Label) - 2
        if HaveGTFile
            if Label(i) ~= 1 || PlotAllLabel || Seq(i) ~= 1
                text(TxtIndex(i),ylim_m(2),[' ' num2str(Label(i))]);
                temp = ylim_m(2) - (ylim_m(2) - ylim_m(1)) * 0.03;
                text(TxtIndex(i),temp,[' ' num2str(Seq(i))]);
                
            end
            if PlotState
                temp = ylim_m(2) - (ylim_m(2) - ylim_m(1)) * 0.06;
                if (State(i) ~= 1)
                    text(TxtIndex(i),temp,[' ' num2str(State(i))]);
                end
            end
        else
            if Label(i) ~= 1 || PlotAllLabel
                text(TxtIndex(i),ylim_m(2),[' ' num2str(Label(i))]);
            end
        end
    end
    temp = min(120,Time(locsnew(end)));
    axis([0 temp ylim_m]);
    hold off

    title([RawFile '-' num2str(FileChoice)]);
    Result = true;
end
