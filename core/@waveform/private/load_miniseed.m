function w = load_miniseed(request)
   %LOAD_MINISEED loads a waveform from MINISEED files
   % combineWaves isn't currently used!
   
   % Glenn Thompson 2016/05/25 based on load_sac
   % request.combineWaves is ignored
   
   if isstruct(request)
      [thisSource, chanInfo, startTime, endTime, ~] = unpackDataRequest(request);
      filenamelist={};
      
      % Work out which files we need
      % Modified by GT on 20181120 to handle multiple chantags
      for i=1:numel(chanInfo)
            thisfilename = getfilename(thisSource,chanInfo(i),startTime);
            found=false;
            listlength = numel(filenamelist);
            for c=1:listlength
                if strcmp(thisfilename,filenamelist{c})
                    found=true;
                end
            end
            if ~found
                filenamelist{listlength+1} = thisfilename;
                listlength=listlength+1;
            end
      end
      wfiles = [];
      % GT 20181120
      % we now have filenamelist which is a cell array of cell arrays (1
      % per chantag, but possibly more than 1 file per chantag is the
      % request crosses file boundaries
      
      % Load waveforms from all these files
      % Modified by GT 20181120 to loop over filenamelist and
      % filenamelist{c}
      for c=1:numel(filenamelist)
          for cc=1:numel(filenamelist{c})
             wtmp = []; 
             %wtmp = mseedfilename2waveform(thisfilename{1}, startTime, endTime);
             wtmp = mseedfilename2waveform(filenamelist{c}{cc}, startTime, endTime);
             wtmp = reshape(wtmp, [1 numel(wtmp)]);
             wfiles = [wfiles wtmp];
          end
      end
      w = combine(wfiles);
      
      % Extract based on time
      w = extract(w, 'time', startTime, endTime);
      
      % Pad GT added 20181120
      w = pad(w, startTime, endTime, 0);
    
      
      % Extract based on ChannelTag
      %w = matchChannelTag(w);
      
   else
      %request should be a filename
      thisFilename = request;
      if exist(thisFilename, 'file')
        w = mseedfilename2waveform(thisFilename);
      else
          w = waveform();
          warning(sprintf('File %s does not exist',thisFilename));
      end
   end
end

function w = mseedfilename2waveform(thisfilename, snum, enum)
    s = ReadMSEEDFast(thisfilename); % written by Martin Mityska
     for c=1:numel(s)
        w(c) = waveform(ChannelTag(s(c).network, s(c).station, s(c).location, s(c).channel), ...
            s(c).sampleRate, epoch2datenum(s(c).startTime), s(c).data);
     end
end
