function w = filter_by_time(w, myStartTime, myEndTime)
   % filter_by_time 
   % w = filter_by_time(w, startTime, endTime)
   
   % subset and consolidate
   [wstarts, wends] = gettimerange(w);
   wavesWithinWindow = wstarts < myEndTime & wends > myStartTime;
   if any(wavesWithinWindow)
      w = extract(w(wavesWithinWindow),'time',myStartTime,myEndTime);
   else
      w(:)=[]; %return an empty waveform
   end
end