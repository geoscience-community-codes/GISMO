function [offset actualTime] = time2offset(w,whichTime)
%time2offset returns the offset within a waveform's data for time T
% If the time is prior to existing samples, then offset=0 and actualTime=[]
st = get(w,'start'); %get matlab starting time
F = get(w,'freq'); %number of samples/second
whichTime = datenum(whichTime);

%calculate the time offset within the waveform
relativeMatlabTime = (whichTime * 86400) - (st * 86400);
offset = round(relativeMatlabTime .* F + 1);
actualTime = (offset-1) .* get(w,'period');
actualTime = (actualTime ./ 86400) + st;
if (offset < 1)
    %time is before samples listed.
    offset = 0;
    actualTime = [];
    return;
end


% if...
% Scenario:         T   StartT  whichTime   relMatT  offset
% relMatT==Start    .01    1        1         0        0
% relMatT==start+1s .01    0        1sec      1sec     100    
