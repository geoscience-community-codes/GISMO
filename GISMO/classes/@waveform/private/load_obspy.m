function w = load_obspy(dataRequest)
   %LOAD_OBSPY loads matlab files that were saved by ObsPy as per the ObsPy tutorial
   % it expects one waveform per file, with variables stored individually, not
   % as a struct.
   %
   % uses the DATASOURCE class
   
   % VERSION: 1.1 of waveform objects
   % AUTHOR: Celso Reyes (celso@iris.washington.edu)
   % LASTUPDATE: 3/5/2009
   w = waveform; w = w();
   if isstruct(dataRequest)
      ds = dataRequest.dataSource;
      w = load_objects_from_file(ds,...
         'waveform',...
         dataRequest.scnls,...
         dataRequest.startTimes,...
         dataRequest.endTimes);
      w = w(:);
   else
      filen = dataRequest;
      
      if ~exist(filen,'file')
         disp(['unable to find file: ', filen]);
         return
      end
      
      %find out which variables exist within the file...
      fcontents = whos('-file',filen);
      
      %if this is an obspy generated .mat file, then it will have the following
      %fields:
      if ~all(ismember({'data','network','station','channel','location','sampling_rate','starttime','calib','mseed'},{fcontents.name}))
         return
      end
      
      stuff =load(filen);
      chanInfo = channeltag(stuff.network, stuff.station, stuff.location, stuff.channel);
      
      w = set(w,...
         'channelinfo',chanInfo,...
         'data',stuff.data,...
         'freq',str2double(stuff.sampling_rate),...
         'start',[stuff.starttime(1:10),' ',stuff.starttime(12:end-1)],...
         'units','UNKNOWN');
      w = addfield(w,'calib',stuff.calib);
      w = addfield(w,'mseed_info',stuff.mseed);
      
   end
end
