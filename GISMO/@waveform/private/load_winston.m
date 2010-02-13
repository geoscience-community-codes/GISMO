function allWaves = load_winston(dataRequest)
% LOAD_WINSTON handles retrieval of data from a winston waveserver.
%  all times are matlab formatted datenums
%  allWaves = load_winston(allSCNLs, sTime, eTime, server, port)
%
%
%
% scnl is the StationChannelNetworkLocation. this may be migrated into an
% object in the near future.  For now, it is a structure with fields:
% 'station','channel','network','location'

% INPUT: waveform (station, channel, start, end, network,
%                  location, server, port)

[myDataSource, allSCNLs, sTime, eTime] = unpackDataRequest(dataRequest);
persistent winstonIsWorking

if isempty(winstonIsWorking) || ~winstonIsWorking
  winstonIsWorking = getWinstonWorking();
end

if ~winstonIsWorking
  %well, if winston isn't working, there's really no point now, is there?
  return;
end

w = waveform;
allWaves = repmat(w,numel(allSCNLs),numel(sTime)); %preallocate
allWaves = allWaves(:);

sTime_epoch = mep2dep(sTime);
eTime_epoch = mep2dep(eTime);

nWaves = 0;
for idxTime = 1:numel(sTime)
  t1 = sTime_epoch(idxTime);
  t2 = eTime_epoch(idxTime);
  if ~timesAreOK(t1,t2)
    continue;
  end

  for idxSCNL = 1:numel(allSCNLs);
    scnl = allSCNLs(idxSCNL);
    [w, status] = getFromWinston(scnl,t1,t2,myDataSource);
    if (status)
      nWaves = nWaves+1;
      allWaves(nWaves) = w;
    end
  end
end
if nWaves < numel(allWaves)
  allWaves = allWaves(1:nWaves);
end



%%
function [w, successful] = getFromWinston(scnl,stime,etime,mydatasource)
%include 
successful = false;

w = scnl2waveform(scnl);
try
 
  WWS=gov.usgs.winston.server.WWSClient(get(mydatasource,'server'),get(mydatasource,'port'));
catch
  if missingWinstonJars()
    giveNoJarWarning();
    return;
  end
end

%grab the winston data, then close the database
try
  mychan = get(scnl,'channel');
  mynet = get(scnl,'network');
  mysta = get(scnl,'station');
  myloc = get(scnl,'location');
  %don't know why "eval" works and the line below doesn't...
  %d = javaMethod(getRawData,WWS,mysta,mychan,mynet,myloc,stime,etime);
  d = eval('WWS.getRawData(mysta,mychan,mynet,myloc,stime,etime)');

  WWS.close;
catch
  warning('Waveform:load_winston:noServerAccess',...
    'Unable to access Winston Wave Server');
  rethrow(lasterror)
  return
end

if ~exist('d','var') || isempty(d)
  warning('Waveform:load_winston:noInformation',...
    'information was not retrieved from the server. Did you remember to include a network in the SCNL?');
  return;
end
fs=d.getSamplingRate;

data_start = dep2mep(d.getStartTime);
data_end = dep2mep(d.getEndTime);
d.buffer(d.buffer == intmin('int32')) = 0; %fix odd spikes
data = double(d.buffer); % d.buffer is int32, and must be converted
w = set(w,'start', data_start,'freq',fs,'data',data);

%if a greater range of data was found, then truncate to the desired times.
if data_start < dep2mep(stime) || data_end > dep2mep(etime)
  w = extract(w,'time', dep2mep(stime),dep2mep(etime));
end

w = addhistory(set(w,'history',{}),'CREATED');

successful = true; %successfully completed

function jars_are_missing = missingWinstonJars()
%oops, winston's jar files may not exist on this system
jcp = javaclasspath('-all');
RequiredFiles = {'usgs.jar'};
jars_are_missing = false;
for FN = RequiredFiles
  if isempty(strfind([jcp{:}],FN{1}))
    disp(['Missing ' FN{1}]);
    jars_are_missing = true;
  end
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

function tf = timesAreOK (t1, t2)
%test to make sure times are valid.
tf = true;
if t1 > t2,
  warning('Waveform:load_winston:invertedTimes','StartTime > End time.  ignored');
  tf = false;
end
if t2 > (t1 + (24 *60 * 60))
  warning('Waveform:load_winston:timerangeTooLarge',...
    'EndTime is more than a day past starttime.  ignored.');
  tf = false;
end

function w = scnl2waveform(scnl)
%w = set(waveform,'station',get(scnl,'station'),...
%  'channel',get(scnl,'channel'));
w = set(waveform,'scnlobject',scnl);
%w = addfield(w,'net',get(scnl,'network'));
%w = addfield(w,'loc',get(scnl,'location'));

% w = set(waveform,'station',scnl.station,...
%   'channel',scnl.channel);
% w = addfield(w,'net',scnl.network);
% w = addfield(w,'loc',scnl.location);


%% Adding the Java path
function success = getWinstonWorking()
success = false;
%Check for required jar file for winston
try
  jcp = javaclasspath('-all');

catch
  disp('Java not enabled on this machine.  Winston will not work.');
  return
end

RequiredFiles = {'usgs.jar'};

introuble = false;

for FN = RequiredFiles
  if isempty(strfind([jcp{:}],FN{1}))
    disp(['Missing ' FN{1}]);
    introuble = true;
  end
end

if introuble
  disp('please add the usgs.jar file (from swarm/lib directory) to your javaclasspath');
  disp('ex.  javaaddpath(''/usr/local/swarm/lib/usgs.jar'');');

  surrogate_jar = 'http://www.avo.alaska.edu/Input/celso/swarmstuff/usgs.jar';

  [s,success] = urlread(surrogate_jar);%can we read the usgs.jar? if not don't bother to add it.
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % MODIFY FOLLOWING LINE TO POINT TO YOUR LOCAL Swarm/lib/usgs.jar
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if success
    javaaddpath(surrogate_jar);
  else
    warning('Waveform:load_winston:noDefaultJar',...
      'Unable to access the default jar.  Please add the usgs.jar file to your javaclasspath.  Winston access will not work.');
  end
end;
success = true;


function [dataSource, scnls, startTimes, endTimes] = unpackDataRequest(dataRequest)
dataSource = dataRequest.dataSource;
scnls = dataRequest.scnls;
startTimes = dataRequest.startTimes;
endTimes = dataRequest.endTimes;
