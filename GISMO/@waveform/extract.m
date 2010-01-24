function outW = extract(w, method, startV, endV)
%EXTRACT creates a waveform with a subset of another's data.
%   waveform = extract(waveform, 'TIME', startTime, endTime)
%       returns a waveform with the subset of data from startTime to
%       endTime.  Both times are matlab formatted (string or datenum)
%
%   waveform = extract(waveform, 'INDEX', startIndex, endIndex)
%       returns a waveform with the subset of data from StartIndex to
%       EndIndex.  this is roughly equivelent to grabbing the waveform's
%       data into an array, as in D = get(W,'data'), then returning a
%       waveform with the subset of data,
%       ie. waveform = set(waveform,'data', D(startIndex:endIndex));
%
%   waveform = extract(waveform, 'INDEX&DURATION', startIndex, duration)
%       a hybrid method that starts from data index startIndex, and then
%       returns a specified length of data as indicated by duration.
%       Duration is a matlab formatted time (string or datenum).
%
%   waveform = extract(waveform, 'TIME&SAMPLES', startTime, Samples)
%       a hybrid method that starts from data index startIndex, and then
%       returns a specified length of data as indicated by duration.
%       Duration is a matlab formatted time (string or datenum).
%
%   Input Arguments:
%       WAVEFORM: waveform object        N-DIMENSIONAL
%       METHOD: 'TIME', or 'INDEX', or 'INDEX&DURATION'
%           TIME: starttime and endtime are absolute times
%                   (include the date)
%           INDEX: startt and endt are the offset (index) within the data
%           INDEX&DURATION: first value is an offset (index), the next says
%                           how much data to retrieve...
%           TIME&SAMPLES: grab first value at time startTime, and grab
%                         Samplength data points
%       STARTTIME:  Start time (matlab or text format)
%       ENDTIME:    End time (matlab or text format)
%       STARTINDEX: position within data array to begin extraction
%       ENDINDEX:   final grabbed position within data array
%       DURATION:   matlab format time indicating duration of data to grab
%       SAMPLES: the number of data points to grab.
%
%   the output waveform will have the new, appropriate start time.
%   if the times are outside the range of the waveform object, then the
%   output waveform will contain only the portion of the data that is
%   appropriate.
%
%   *MULTIPLE EXTRACTIONS* can be received if the time values are vectors.
%   Both starttime/startindex and endtime/endindex/endduration/samples must
%   have the same number of elements.  In this case the output waveforms
%   will be reshaped with each waveform represented by row, and each
%   extracted time represented by column.  that is...
%
%  The output of this function, for multiple waveforms and times will be:
%         t1   t2  t3 ... tn
%    -----------------------
%    w1 |
%    w2 |
%    w3 |
%     . |
%     . |
%    wn |
%
%
%%   examples:
%       % say that Win is a waveform that starts 1/5/2007 04:00, and
%       % contains 1 hour of data at 100 Hz (360000 samples)
%
%       % grab samples between 4:15 and 4:20
%       Wout = extract(Win, 'TIME', '1/5/2007 4:15:00','1/5/2007 4:20:00');
%
%       % grab 3 minutes, starting at the 10000th sample
%       Wout = extract(Win, 'INDEX&DURATION', 10000 , '0/0/0 00:03:00');
%
%
%%     example of multiple extract:
%  % declare the times we're interested in
%         firstsnippet = datenum('6/20/2003 00:00:00');
%         lastsnippet = datenum('6/20/2003 24:00:00');
%
%         % divide the day into 1-hour segments.
%         % note, 25 peices. equivelent to 0:1:24, including both midnights
%         alltimes = linspace(firstsnippet, lastsnippet, 25);
%         starttimes = alltimes(1:end-1);
%         endtimes = alltimes(2:end);
%
%         % grab each hour of time, and shove it into wHours
%         wHours = extract(wDay, 'time',starttimes, endtimes);
%
%         scaleFactor = 4 * std(double(wDay));
%         wHours = wHours ./ scaleFactor;
% %
%          for n = 1:length(wHours)
%            wHours(n) = -wHours(n) + n; %add offset for plotting
%          end
%          plot(wHours,'xunit','m','b'); %plot it in blue with at nm scaling
%          axis ([0 60 1 25])
%          set(gca,'ytick',[0:2:24],'xgrid', 'on','ydir','reverse');
%          ylabel('Hour');
%
%   See also WAVEFORM/SET -- Sample_Length

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 3/14/2009

%% Set up conditoin variables, and ensure validity of input
if numel(w) > 1,
  MULTIPLE_WAVES = true;
else
  MULTIPLE_WAVES = false;
end


%if either of our times are strings, it's 'cause they're actually dates
if ischar(startV)
  startV = datenum(startV);
end
if ischar(endV)
  endV = datenum(endV);
end

if numel(startV) ~= numel(endV)
  error('Waveform:extract:indexMismatch',...
    'Number of start times (or indexes) must equal number of end times')
end

% are we getting a series of extractions from each waveform?
if numel(endV) > 1,
  MULTIPLE_EXTRACTION = true;
else
  MULTIPLE_EXTRACTION = false;
end

if MULTIPLE_WAVES && MULTIPLE_EXTRACTION
  w = w(:);
end

%%
if numel(w)==0 || numel(startV) ==0
  warning('Waveform:extract:emptyWaveform','no waveforms to extract');
  return
end
outW(numel(w),numel(startV)) = waveform;

for m = 1: numel(startV) %loop through the number of extractions
  for n=1:numel(w); %loop through the waveforms
    inW = w(n);
    myData = get(inW,'data');
    
    switch lower(method)
      case 'time'
        
        % startV and endV are both matlab formated dates
        %sampleTimes = get(inW,'timevector');
        
        %   ensure the format of our times
        if startV(m) > endV(m)
          warning('Waveform:extract:reversedValues',...
            'Start time prior to end time.  Flipping.');
          [startV(m), endV(m)] = swap(startV(m), endV(m));
        end
        
        
        %if requested data is outside the existing waveform, change the
        %start time, and clear out the data.
        startsAfterWave = startV(m) > get(inW,'end') ;
        endsBeforeWave = endV(m) < get(inW,'start');
        if startsAfterWave || endsBeforeWave
          myStart = startV(m);
          myData = [];
        else
          %some aspect of this data must be represented by the waveform
          [myStartI myStartTime] = time2offset(inW,startV(m));
          [myEndI] = time2offset(inW,endV(m));
          if isempty(myStartTime)
            %waveform starts sometime after requested start
            myStartTime = get(inW,'start');
            myStartI = 1;
          end
          
          if myEndI > numel(myData)
            myEndI = numel(myData);
          end
          myData = myData(myStartI:myEndI);
          myStart = myStartTime;
        end
      case 'index'
        %startV and endV are both indexes into the data
        
        
        if startV(m) > numel(myData)
          warning('Waveform:extract:noDataFound',...
            'no data after start index');
          return
        end;
        if endV(m) > numel(myData)
          endV(m) = length(myData);
          warning('Waveform:extract:truncatingData',...
            'end index too long, truncating to match data');
        end
        
        if startV(m) > endV(m)
          warning('Waveform:extract:reversedValues',...
            'Start time prior to end time.  Flipping.');
          [startV(m), endV(m)] = swap(startV(m), endV(m));
        end
        
        myData = myData(startV(m):endV(m));
        sampTimes = get(inW,'timevector'); % grab individual sample times
        myStart = sampTimes(startV(m));
        
      case 'index&duration'
        % startV is an index into the data, endV is a matlab date
        myData = myData(startV(m):end); %grab the data starting at our index
        
        sampTimes = get(inW,'timevector'); % grab individual sample times
        sampTimes = sampTimes(startV(m):end); % truncate to match data
        
        myStart = sampTimes(1); %grab our starting date before hacking it
        
        sampTimes = sampTimes - sampTimes(1); %set first time to zero
        count = sum(sampTimes <= endV(m));
        myData = myData(1:count);
        
        
      case 'time&samples'
        % startV is a matlab date, while endV is an index into the data
        sampTimes = get(inW,'timevector'); % grab individual sample times
        
        index_to_times = sampTimes >= startV(m); %mask of valid times
        goodTimes = find(index_to_times,endV(m));%first howevermany of these good times
        
        myData = myData(goodTimes); % keep matching samples
        
        try
          myStart = sampTimes(goodTimes(1)); %first sample time is new waveform start
        catch
          warning('Waveform:NoDataFound',...
            'no data');
          myStart = startV(1);
        end
        
      otherwise
        error('Waveform:extract:unknownMethod','unknown method: %s', method);
    end
    
    if MULTIPLE_EXTRACTION
      outW(n,m) = set(inW,'start',myStart, 'data', myData);
      outW(n,m) = addhistory(outW(n,m) ,['Extracted, using ' method]);
    else
      outW(n) = set(inW,'start',myStart, 'data', myData);
      outW(n) = addhistory(outW(n),['Extracted, using ' method]);
    end
  end % n-loop (looping through waveforms)
end % m-loop (looping through extractions)

%% the helper function
function  [B,A] = swap(A,B)
%do nothing