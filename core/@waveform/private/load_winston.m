function allWaves = load_winston(request)
   % LOAD_WINSTON handles retrieval of data from a winston waveserver.
   %  all times are matlab formatted datenums
   %  allWaves = load_winston(request)
   %  server and port are dictatd by the datasource included within the request. 
   
   % 2015 - CR refractored.  winstonNotWorking is now an error, so this
   % should be used within some try-catch statement.
   
   persistent winstonIsWorking
   
   if isempty(winstonIsWorking) || ~winstonIsWorking
      winstonIsWorking = getWinstonWorking();
   end
   
   if ~winstonIsWorking
      error('waveform:load_winston:winstonNotWorking',...
         'failed to access winston');
   end
   
   [ds, channelInfo, sTime, eTime, ~] = unpackDataRequest(request);
   validTimes = eTime > sTime;
   sTime = sTime(validTimes);
   eTime = eTime(validTimes);
   
   sTime_epoch = mep2dep(sTime);
   eTime_epoch = mep2dep(eTime);
   
   timefn = @(t1, t2) grab_for_time(channelInfo, t1, t2, ds);
   allWaves = arrayfun(timefn, sTime_epoch, eTime_epoch, 'uniformoutput',false);
   allWaves = [allWaves{:}];
end

function w = grab_for_time(chanInfo, t1, t2, ds)
      myfn = @(nslc) getFromWinston(nslc, t1, t2, ds);
      w = arrayfun(myfn, chanInfo, 'uniformoutput', false);
      w = [w{:}];
end

function [w, successful] = getFromWinston(chanTag,stime,etime,ds)
   %include
   successful = false;
   
   w = set(waveform,'channeltag',chanTag);  %initialize a waveform
   WWS = gov.usgs.volcanoes.winston.legacyServer.WWSClient(get(ds,'server'),get(ds,'port'));
   
   %grab the winston data, then close the database
   mychan = chanTag.channel;
   mynet = chanTag.network;
   mysta = chanTag.station;
   myloc = chanTag.location;
   
   try
      d = WWS.getRawData(mysta,mychan,mynet,myloc,stime,etime);
      WWS.close;
   catch er
      warning('Waveform:load_winston:noServerAccess', 'Unable to access Winston Wave Server');
      rethrow(er)
   end
   
   if ~exist('d','var') || isempty(d)
      fprintf('%s %s - %s not found on server\n', char(chanTag), datestr(dep2mep(stime),31), datestr(dep2mep(etime),31));
      return;
   end
   fs = d.getSamplingRate;
   data_start = dep2mep(d.getStartTime);
   data_end = dep2mep(d.getEndTime);
   spikes = d.buffer == intmin('int32');
   data = double(d.buffer); % d.buffer must be converted from int32
   data(spikes) = nan; % spikes used to be set to 0
   w = set(w,'start', data_start,'freq',fs,'data',data);
   
   %if a greater range of data was found, then truncate to the desired times.
   if data_start < dep2mep(stime) || data_end > dep2mep(etime)
      w = extract(w,'time', dep2mep(stime),dep2mep(etime));
   end
   w = addhistory(set(w,'history',{}),'CREATED');
   successful = true; %successfully completed
end


%% Adding the Java path
function success = getWinstonWorking()
   success = false;
   if usejava('jvm') 
       % path updated by Glenn Thompson 20160526 based on tar -tvf
       % swarm.jar | grep WWSClient
      if exist('gov.usgs.volcanoes.winston.legacyServer.WWSClient', 'class');
          success = true;
      else
        warning('gov.usgs.volcanoes.winston.legacyServer.WWSClient not found');
      end
   else
      warning('Java not enabled on this machine. Winston will not work.')
   end
end
