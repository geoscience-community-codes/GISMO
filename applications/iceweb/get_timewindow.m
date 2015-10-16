function timewindow = get_timewindow(utdnum_stop, numMins, utdnum_start) 
% GET_TIMEWINDOW
%
% Usage:  timewindow = get_timewindow([utdnum, [numMins, [utdnum_start]]])
%
% get_timewindow returns the Matlab datenumbers corresponding to the start and end of a time window
% This time window is aligned such that if the numMins of data requested is 10, the start and end times
% are aligned at 0, 10, 20, 30, 40 or 50 minutes past the hour, in such a way that the end time is the
% most recent value that does not exceed dnum.
%
% If numMins is not given, it is set to 10.
%
% Example 1:
% 	[timewindow.start,timewindow.stop]=gettartAndEndTimes(datenum(2007,04,23,17,13,13), 15)
%	
%	In this case timewindow.start would be datenum(2007,04,23,16,45,00)
%	and timewindow.stop would be datenum(2007,04,23,17,00,00)
%
% Example 2:
% 	[timewindow.start,timewindow.stop]=getStartAndEndTimes(datenum(2007,04,23,17,13,13), 10)
%	
%	In this case timewindow.start would be datenum(2007,04,23,17,00,00)
%	and timewindow.stop would be datenum(2007,04,23,17,10,00)
%
% Glenn Thompson, 2007

global PARAMS


if nargin == 0
	utdnum_stop = utnow();
end

if nargin < 2
	numMins = 10;
end


if nargin > 3
	disp('get_timewindow([utdnum_stop [, numMins, [utdnum_start]]]')
	return;
end

timewindow.stop  = boundaryBeforeDnum(utdnum_stop, numMins);
timewindow.start = timewindow.stop - numMins/1440;

if (nargin == 3)
	snum = boundaryBeforeDnum(utdnum_start, numMins);
	snum_array = snum: numMins/1440: timewindow.start;
	enum_array = snum_array + numMins/1440;
	timewindow.start = snum_array;
	timewindow.stop = enum_array;
end	
	

%%%%%%%%%%%%%%%%%%%
function dnum1=boundaryBeforeDnum(dnum, numMins)
dayFraction		=	rem(dnum,1); 
minutesIntoThisDay	=	dayFraction*1440;
dnum1 			= 	dnum - rem(minutesIntoThisDay, numMins)/1440;

function dnum1=boundaryAfterDnum(dnum, numMins)
dnum1 = boundaryBeforeDnum(dnum, numMins) + numMins/1440; 


