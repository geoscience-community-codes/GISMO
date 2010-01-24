function [startTimeList endTimeList] = gettimerange(w)
%GETTIMERANGE returns the list of start and end times from a waveform array
%[startTimeList endTimeList] = gettimerange(w)

%preallocate the times
startTimeList=  zeros(size(w));
endTimeList = startTimeList;

%fill 'em.  
for i=1:numel(w)
  %if isempty(get(w(i),'start') );
  %  error('Waveform:gettimerange','no start time exists');
  %end
  startTimeList(i) = get(w(i),'start'); %start time
  endTimeList(i) = get(w(i),'end'); % end time
end