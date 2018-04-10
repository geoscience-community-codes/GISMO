function combined_waveforms = combine (waveformlist)
   %COMBINE merges waveforms based on start/end times and ChannelTag info.
   % combined_waveforms = combine (waveformlist) takes a vector of waveforms
   % and combines them based on SCNL information and start/endtimes.
   % DOES NO OTHER CHECKS
   
   % AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   % Glenn Thompson 2018/01/09: replaced splice_waveform routine as it was
   % failing as part of drumplot.plot 
   
   if numel(waveformlist) < 2  %nothing to do
      combined_waveforms = waveformlist;
      return
   end
   
   channelinfo = get(waveformlist,'channeltag');
   [uniquescnls, idx, scnlmembers] = unique(channelinfo);
   
   %preallocate
   combined_waveforms = repmat(waveform,size(uniquescnls));
   
   for i=1:numel(uniquescnls)
      w = waveformlist(scnlmembers == i);
      w = timesort(w);
      for j=(numel(w)-1):-1:1
         w(j) = piece_together(w(j:j+1));
         w(j+1) = waveform;
      end
      combined_waveforms(i) = w(1);
   end
end

function w = piece_together(w)
   if numel(w) > 2
      for i = numel(w)-1: -1 : 1
         w(i) = piece_together(w(i:i+1));
      end
      w = w(1);
      return;
   elseif numel(w) == 1
      return
   end
   if isempty(w(1))
      w = w(2);
      return;
   end;
   dt = dt_seconds(w(1),w(2));  %time overlap in seconds.
   sampleRates = round(get(w,'freq'));
   sampleInterval = 1 ./ sampleRates(1);
   
   if overlaps(dt, sampleInterval)
      w = spliceWaveform(w(1), w(2));
   else
      paddingAmount = round((dt * sampleRates(1))-1);
      w = spliceAndPad(w(1),w(2), paddingAmount);
   end
   w = w(1);
end

function w = spliceAndPad(w1, w2, paddingAmount)
   if paddingAmount > 0 && ~isinf(paddingAmount)
      toAdd = nan(paddingAmount,1);
   else
      toAdd = [];
   end
   
   w = set(w1,'data',[w1.data; toAdd; w2.data]);
end

% function w = spliceWaveform(w1, w2)
% 
%    % NOTE * Function uses direct field access
%    timesToGrab = sum(get(w1,'timevector') < get(w2,'start'));
%    
%    samplesRemoved = numel(w1.data) - timesToGrab;
%    
%    w = set(w1,'data',[double(extract(w1,'index',1,timesToGrab)); w2.data]);
%    
%    w= addhistory(w,'SPLICEPOINT: %s, removed %d points (overlap)',...
%       datestr(get(w2,'start')),samplesRemoved);
% end

function w = spliceWaveform(w1, w2)
% 
%    % NOTE * Function uses direct field access
    snum1 = get(w1,'start');
    snum2 = get(w2,'start');
    enum1 = get(w1,'end');
    enum2 = get(w2,'end');
    [snummin, snuminindex] = min([snum1 snum2]);
    [enummax, enumaxindex] = max([enum1 enum2]);
    dnum1 = get(w1,'timevector');
    dnum2 = get(w2,'timevector');
    data1 = get(w1,'data');
    data2 = get(w2,'data');
    w = w1;
    dnum=dnum1;
    data=data1;
    ind = find(dnum2<snum1);
    if numel(ind)>0
        dnum = [dnum2(ind); dnum];
        data = [data2(ind); data];
    end
    ind = find(dnum2>enum1);
    if numel(ind)>0
        dnum = [dnum; dnum2(ind)];
        data = [data; data2(ind)];
    end    
    snum = dnum(1);
    w = set(w, 'start', snum, 'data', data);


end

function result = overlaps(dt, sampleInterval)
   result = (dt- sampleInterval .* 1.25) < 0;
end

function t = dt_seconds(w1,w2)
   %  w1----] t [----w2
   firstsampleT = get(w2,'start');
   lastsampleT = get(w1,'timevector'); lastsampleT = lastsampleT(end);
   t = firstsampleT*86400 - lastsampleT * 86400;
end

function w = timesort(w)
   [~, I] = sort(get(w,'start'));
   w = w(I);
end
