function [data]=remove_calibration_pulses(dnum, data)

    t=dnum-floor(dnum); % time of day vector
    y=[];
    for c=1:length(dnum)
        sample=round(t(c)*1440)+1;
        if length(y) < sample
            y(sample)=0;
        end
        y(sample)=y(sample)+data(c);
    end
    t2=t(1:length(y));
    m=nanmedian(y);
    calibOn = 0;
    calibNum = 0;
    calibStart = [];
    calibEnd = [];
    for c=1:length(t2)-1
        if y(c) > 10*m && ~calibOn
            calibOn = 1;
            calibNum = calibNum + 1;
            calibStart(calibNum) = c;
        end
        if y(c) <= 10*m && calibOn
            calibOn = 0;
            calibEnd(calibNum) = c-1;
        end
    end

    if length(calibStart) > 1
        fprintf('%d calibration periods found: nothing will be done\n',length(calibStart));
        %figure;
        %c=1:length(y);
        %plot(c,y,'.')
        %i=find(y>10*m);
        %hold on;
        %plot([c(1) c(end)],[10*m 10*m],':');
        %calibStart = input('Enter start sample');
        %calibEnd = input('Enter end sample');
    end
    if ~empty(calibStart)
        % mask the data according to time of day
        tstart = (calibStart - 2) / 1440
        tend = (calibEnd ) / 1440
        i=find(t >= tstart & t <=tend);
        data(i)=NaN;
    end
end  