function allWaves = load_winston(dataRequest, COMBINE_WAVEFORMS)
   % LOAD_WINSTON handles retrieval of data from a winston waveserver.
   %  all times are matlab formatted datenums
   %  allWaves = load_winston(allSCNLs, sTime, eTime, server, port)
   
   % INPUT: waveform (station, channel, start, end, network,
   %                  location, server, port)
   
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
   
   [myDataSource, channelInfo, sTime, eTime] = unpackDataRequest(dataRequest);
   validTimes = eTime > sTime;
   sTime = sTime(validTimes);
   eTime = eTime(validTimes);
   
   sTime_epoch = mep2dep(sTime);
   eTime_epoch = mep2dep(eTime);
   
   timefn = @(t1, t2) grab_for_time(channelInfo, t1, t2, myDataSource);
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
   if ~exist('gov.usgs.winston.server.WWSClient', 'class')
      giveNoJarWarning();
      return
   end
   
   w = set(waveform,'channeltag',chanTag);  %initialize a waveform
   WWS = gov.usgs.winston.server.WWSClient(get(ds,'server'),get(ds,'port'));
   
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

function giveNoJarWarning()
   warning('Waveform:load_winston:missingJars',...
      'The winston files may not be on this system.')
   disp('To correct, acquire the files listed above');
   disp('If you have already installed SWARM, then these .jar files already');
   disp('exist in your swarm/lib directory (or something close to it...');
   disp('');
   %disp('Edit Matlab''s classpath.txt file (located in the toolbox/local');
   %disp('directory) and add the location of these .jar files.');
end

%% Adding the Java path
function success = getWinstonWorking()
   if usejava('jvm')
      introuble = ~exist('gov.usgs.winston.server.WWSClient', 'class');
   else
      disp('Java not enabled on this machine. Winston will not work.')
      return
   end

   if introuble
      error('waveform:load_winston:noDefaultJar',[...
         'please add the winston java file to your javaclasspath.'...
         'One such file is usgs.jar, found in the swarm/lib directory (if swarm is installed)\n'...
         '  ex.  javaaddpath(''/usr/local/swarm/lib/usgs.jar'')\n'...
         'to obtain a jar, try contacting the manager of your swarm or winston database']);
      
      % will no longer attempt to connect to jar on internet, since that
      % could potentially not be safe!
      %{
      % surrogate_jar = 'http://www.avo.alaska.edu/Input/celso/swarmstuff/usgs.jar';
      % [~,success] = urlread(surrogate_jar);%can we read the usgs.jar? if not don't bother to add it.
      if success
         javaaddpath(surrogate_jar);
         introuble = ~exist('gov.usgs.winston.server.WWSClient', 'class');
      end
      %}
   end;
   success = ~introuble;
end


function [dataSource, scnls, startTimes, endTimes] = unpackDataRequest(dataRequest)
   dataSource = dataRequest.dataSource;
   scnls = dataRequest.scnls;
   startTimes = dataRequest.startTimes;
   endTimes = dataRequest.endTimes;
end