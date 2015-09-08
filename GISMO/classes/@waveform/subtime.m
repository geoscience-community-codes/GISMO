function w = subtime(inW, startt, endt)
%SUBTIME grabs time-indexed snippets of waveform data.
%   waveforms = subtime(waveform, starttimes, endtimes)
%
%   For the most part, this function has been superceded by EXTRACT.
%   Instead, use  w = extract(waveform, 'time', starttime, endtime)
%
%   Input Arguments
%       WAVEFORM: the waveform(s)to extract data from   Nx1 DIMENSIONS
%       STARTTIME: matlab date.  Both date & time should be included.
%       ENDTIME are given as absolute times (date included)
%
%       output wave has all same properties as original waves, except they
%       the subset of data and the new time signature.
%
%       if waveform is N-dimensional, all waveforms become rows in the output
%       if start times or end times are vectors, they must be the same size.
%         these will become the columns of the output variable
%
%     example 1:
%        % grab a waveform
%        w = waveform('OKCF','SHZ','11/5/2005 04:00:00', '11/5/2005 05:00:00')
%
%        % grab 5 minutes of data, starting at 4:30
%        littleW = subtime(w,'11/05/2005 04:30:00','11/05/2005 04:35');
%
%     example 1:
%        % grab a waveform
%        w(1) = waveform('OKCF','SHZ','11/5 04:00:00', '11/5 05:00:00')
%        w(2) = waveform('OKCD','BHZ','11/5 04:00:00', '11/5 05:00:00')
%        starttimes  = {'11/5 04:10', '11/5 04/20'};
%        endtimes = {'11/5 04:15', '11/5 04:25'};
%
%        snippets = subtime(w,starttimes,endtimes);
%
%        % Snippets should be a 2x2 waveform object, where
%           snippets(1,N) refers to OKCF
%           snippets(2,N) refers to OKCD
%           snippets(N,1) refers to 4:10 to 4:15
%           snippets(N,2) refers to 4:20 to 4:25
%
%     example 3:
%       %  this examplecreates a quick pseudohelicorder plot, of sorts
%       wDay = waveform('CRP','SHZ','11/3/2005','11/3/2005 24:00');
%       firstsnippet = datenum('11/3/2005 00:00:00');
%       lastsnippet = datenum('11/3/2005 24:00:00');
%       HourValue = datenum('0/0/0 01:00:00');
%       
%       alltimes = firstsnippet : HourValue : lastsnippet; 
%       starttimes = alltimes(1:end-1);
%       endtimes = alltimes(2:end);
%       
%       % grab each hour of time, and shove it into wHours
%       wHours = subtime(wDay, starttimes, endtimes);
%
%       for n = 1:length(wHours)
%         tempdata = double(wHours(n)); %grab the data
%         tempdata = tempdata ./ max(tempdata) %normalize
%         wHours(n) = set(wHours(n),'data', tempdata) % put back
%         wHours(n) = wHours(n) + n; %add offset for plotting
%       end
%       plot(wHours,'nm',[],'b'); %plot it in blue with at nm scaling
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
%   See Also WAVEFORM/EXTRACT

% VERSION: 1.0 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 2/15/2007

% Make sure we have legal arguments

startt = datenum(startt);
endt = datenum(endt);
%note: these values always end up as double, even if provided as cells

endt = endt(:); %shape as column vector
startt = startt(:); %shape as column vector

if length(endt) ~= length(startt)
    error('Waveform:subtime:timeLengthMismatch',...
      'length(starttimes) [%d] and length(endtimes) [%d] should be the same.',length(startt),length(endt));
end
inW = inW(:); %shape as column vector;

%create the output matrices (blank), with size = #waveforms x #times
w = repmat(set(inW,'data',[]), 1, length(startt));

%  The output of this function, for multiple waveforms and times will be:
%     t1   t2  t3 ... tn
%-----------------------
%w1 |
%w2 |
%w3 |
% . |
% . |
%wn |

for widx = 1 : length(inW) %for each waveform
    
    % get the reference times for this waveform
    timeidx = linspace(get(inW(widx),'start'),...
        get(inW(widx),'end'),...
        get(inW(widx),'data_length')+1);
    
        
    for n = 1 : length(startt) %for each time
        st = startt(n);
        et = endt(n);

        myData = get(inW(widx),'data');

        if any(et < st)
            warning('Waveform:subtime:reversedTimes',...
                'endt < startt, value will be [], but continuing anyway');
        end

        idxmask = find(timeidx >= st & timeidx < et);
        myData = myData(idxmask);
        if ~isempty(myData),
            myStart = timeidx(idxmask(1));
        else
            myStart = st;
        end

        if st < timeidx(1)
            st = timeidx(1);
            warning('Waveform:subtime:noData',...
                'start time was prior to data.  setting equal to first sample');
        end;
        if et > timeidx(end)
            et = timeidx(end);
            warning('Waveform:subtime:noData',...
                'end time was after data.  setting equal to last sample');
        end;
        if et < st
            warning('Waveform:subtime:reversedTimes',...
                'end time < start time');
            return
        end;

        w(widx,n) = set(w(widx,n),'start',myStart);
        w(widx,n) = set(w(widx,n),'data',myData);
    end % of each time
end %of each waveform