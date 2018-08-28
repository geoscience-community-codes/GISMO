function w = load_seisan(request)
   %LOAD_SEISAN loads a waveform from SEISAN files
   % combineWaves isn't currently used!
   
   % Glenn Thompson 2016/05/25 based on load_miniseed
   % request.combineWaves is ignored
   w=[];
   if isstruct(request)
      [thisSource, chanInfo, startTimes, endTimes, ~] = unpackDataRequest(request);
      for i=1:numel(chanInfo)
         for j=1:numel(startTimes)
            thisfilename = getfilename(thisSource,chanInfo(i),startTimes(j))
            thisw = load_seisan_file(thisfilename{1}); %, startTimes(j), endTimes(j));
            w = [w thisw];
         end
      end
      w = w(:);
      
   else
      %request should be a filename
      thisFilename = request;
      if exist(thisFilename, 'file')
        w = load_seisan_file(thisFilename);
      else
          w = waveform();
          warning(sprintf('File %s does not exist',thisFilename));
      end
   end
end


function w = load_seisan_file(fn)%dataRequest)
   % Read a v7.0 or later SEISAN file
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
         st(1:80) = fread(fid,80,'char');
         if i== 1
            h = parseSeisanHeader(st);
            nsta = h.stationCount;
         end
         
         if i >= 3
            for j=1:3
               thisbit = st(((j-1) * 26 + 1):(j*26));
               ch = parseSeisamChannelHeader(thisbit);
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
   end
   fclose(fid);
end

function h = parseSeisanHeader(headerBlock)
   
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
end
