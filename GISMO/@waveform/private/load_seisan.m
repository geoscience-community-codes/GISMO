function w = load_seisan(fn)%dataRequest)
% Read a v7.0 or later SEISAM file
% example file is currently :'c:\2008-05-12-0630-00S.INSN__054'
% dataRequest has the fields dataSource, scnls, startTimes, and endTimes
% only looks in first file, currently.
%dataRequest.startTimes = subdivide_files_by_date(dataRequest.dataSource,dataRequest.startTimes,dataRequest.endTimes);
%fn = getfilename(dataRequest.dataSource,dataRequest.scnls,dataRequest.startTimes);
w  = waveform; %initialize, in case nothing works
MACHINEFORMAT = 'l';
%disp('Little Endian');
fid = fopen(fn,'r',MACHINEFORMAT);
bytesToRead = fread(fid,1,'uint32');
if bytesToRead ~= 80
  fclose(fid);
  MACHINEFORMAT = 'b';
  %disp('Switching to Big Endian');
  fid = fopen(fn,'r',MACHINEFORMAT);
  bytesToRead = fread(fid,1,'uint32');
  if bytesToRead ~= 80
    
    warning('Waveform:load_seisan:invalidFileFormat',['File does not appear to be a SEISAN file,]'...
      '[ or is an old PC version.\n This program is currently]',...
      '[ incapable of opening PC SEISAN files older than V7.0']);
    fclose(fid);
    return
  end
end


fseek(fid,0,-1);

nsta = 0;
for i=1:333;
  bytesToRead = fread(fid,1,'uint32');
  if bytesToRead == 80
    %  disp('skipline')
    %else
    st(1:80) = fread(fid,80,'char');
    if i== 1
      h = parseSeisamHeader(st);
      %for n=1:numel(headerparse)
      % disp(strcat(headerparse{n},': [',st([headerloc{n}]),']'));
      %end
      nsta = h.stationCount;
    end
    
    if i >= 3
      for j=1:3
        %for n=1:numel(subheaderparse)
        thisbit = st(((j-1) * 26 + 1):(j*26));
        ch = parseSeisamChannelHeader(thisbit);
        %  disp(strcat(subheaderparse{n},': [',thisbit([subheaderloc{n}]),']'));
        %end
      end
    end
    bytesRead = fread(fid,1,'uint32');
    
  else
    break
  end
end

for j = 1: nsta
  dt = fread(fid,1040,'char');
  mydata = parseSeisamData(dt);
  w(j) = waveform;
  w(j) = set(w(j),'station',mydata.station,'channel',mydata.channel,...
    'start',getStartTime(mydata),'freq',mydata.sampleRate);
  
  nbytesread = fread(fid,1,'uint32'); %bytecount
  bytestoread = fread(fid,1,'uint32'); %bytecount
  
  
  rawdata = fread(fid,bytestoread / 4,'int32');
  w(j) = set(w(j),'data',rawdata);
  
  nbytesread = fread(fid,1,'uint32'); %bytecount
  nbytesToread2 = fread(fid,1,'uint32'); %bytecount
  %disp(rawdata);
  %disp(['D',num2str(i),' [',double(dt)',']']);
  % ftell(fid)
end
fclose(fid);

% %% now, sift through and subset the waveform based on our criteria
% if ~isempty(dataRequest.scnls)
%   w = w(ismember(w,dataRequest.scnls));
% end
% if ~isempty(dataRequest.startTimes) 
%   startFilters = dataRequest.startTimes;
% else
%   startFilters = min(get(w,'start'));
% end
% if ~isempty(dataRequest.endTimes)
%   endFilters = dataRequest.endTimes;
% else
%   endFilters = max(get(w,'end'));
% end
% w = extract(w,'time',startFilters,endFilters);
% 
% if all(isempty(w)),
%   warning('No data appears to exist for these times, for these stations or channels');
% end

function h = parseSeisamHeader(headerBlock)

hFieldName = {'network','stationCount','centuryCode','year','doy','month','day','hr','min','sec','totalTime'};
hFieldpos = {2:30,31:33,34,35:36,38:40,42:43,45:46,48:49,51:52,54:59,61:69};
hFieldType = ['sddddddddff']; %s=string, d=integer, f=float

for n=1:numel(hFieldName)
  switch hFieldType(n)
    case 's'
      h.(hFieldName{n}) = deblank(char(headerBlock([hFieldpos{n}])));
    case 'd'
      h.(hFieldName{n}) = str2double(char(headerBlock([hFieldpos{n}]')));
    case 'f'
      h.(hFieldName{n}) = str2double(char(headerBlock([hFieldpos{n}]')));
  end
end

function ch = parseSeisamChannelHeader(channelBlock)

chFieldName= {'station','comp','lastStaLetter','startRelToEvent','staDataInterval'};
chFieldpos = {2:5,6:9,10,11:17,19:26};
chFieldType = ['sssff']; %s=string, d=integer, f=float

for n=1:numel(chFieldName)
  switch chFieldType(n)
    case 's'
      ch.(chFieldName{n}) = deblank(char(channelBlock([chFieldpos{n}])));
    case 'd'
      ch.(chFieldName{n}) = str2double(char(channelBlock([chFieldpos{n}]')));
    case 'f'
      ch.(chFieldName{n}) = str2double(char(channelBlock([chFieldpos{n}]')));
  end
end

function d = parseSeisamData(dataBlock)

dFieldName= {'station','channel','centuryCode','year','doy',...
  'month','day','hr','min','timingIndicator','second','sampleRate',...
  'nsamp','lat','lon','elev','gainFactor','howManyBits'};
dFieldpos = {1:5,6:9,10,11:12,14:16,...
  18:19,21:22,24:25,27:28,29,30:35,37:43,...
  45:50,52:59,61:69,71:75,76,77};
dFieldType = ['ssdddddddsffdffdsd']; %s=string, d=integer, f=float

for n=1:numel(dFieldName)
  switch dFieldType(n)
    case 's'
      temp = char(dataBlock([dFieldpos{n}]));
      d.(dFieldName{n}) = deblank(temp(:)');
    case 'd'
      d.(dFieldName{n}) = str2double(char(dataBlock([dFieldpos{n}]')));
    case 'f'
      d.(dFieldName{n}) = str2double(char(dataBlock([dFieldpos{n}]')));
  end
end

function st = getStartTime(myData)

switch myData.centuryCode
  case 0
    baseyear = 1900;
  case 1
    baseyear = 2000;
  otherwise
    baseyear = 0;
end
st = datenum(myData.year + baseyear,...
  myData.month,...
  myData.day,...
  myData.hr,...
  myData.min,...
  myData.second);

return

