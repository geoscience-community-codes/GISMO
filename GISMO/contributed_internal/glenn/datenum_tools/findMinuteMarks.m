function [Xtickmarks,Xticklabels]=findMinuteMarks(timewindow);

% calculate where minute marks should be, and labels
snum = ceilminute(timewindow.start);
enum = floorminute(timewindow.stop);


% Number of minute marks should be no greater than 20
numMins = (enum - snum) * 1440;
stepMinOptions = [1 2 3 5 10 15 20 30 60 120 180 240 360 480 720 1440];
c = 1;
while (numMins / stepMinOptions(c) > 20)
	c = c + 1;
end
stepMins = stepMinOptions(c);

Xtickmarks = snum:stepMins/1440:enum;
Xticklabels = datestr(Xtickmarks,15); 
