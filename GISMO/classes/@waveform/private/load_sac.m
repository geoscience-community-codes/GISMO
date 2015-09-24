function w = load_sac(request)
   %LOAD_SAC loads a waveform from SAC files
   % combineWaves isn't currently used!
   
   % request.combineWaves is ignored
   
   if isstruct(request)
      [thisSource, chanInfo, startTimes, ~, ~] = unpackDataRequest(request);
      for i=1:numel(chanInfo)
         for j=1:numel(startTimes)
            thisfilename = getfilename(thisSource,chanInfo(i),startTimes(j));
            w(i,j) = loadSacByFilenames(thisfilename);
         end
      end
      w = w(:);
      
   else
      %dataRequest should be a filename
      w = loadSacByFilenames(request);
   end
end

function w = loadSacByFilenames(filename)
   %LOADSAC  creates a waveform from a SAC file
   % waveform = loadSacByFilenames(waveform, filename);
   % To call, the first argument must be a waveform.  However this waveform
   % will never be accessed-- it will be overwritten by the SAC information.
   % Therefore, you can use "waveform" as your first argument, so that a
   % generic waveform object will be created for you
   %
   % If the filename is a cell of several SAC file names, such as:
   % fn = {'BOB.SHZ.AV','TOM.EHZ.AV','HARRY.EHZ.AV'}
   % then, w = loadSacByFilenames(waveform,fn) will return a matrix of waveforms, the
   % same size and shape  as fn.   fn(N,M) will be the SAC file name for the
   % waveform denoted by w(N,M).  In the example above, loadSacByFilenames will return a
   % 1x3 waveform object, with all three files.
   %
   % Programming suggestion???select files using a dialog box, by using the
   % following code:
   %   % display the dialog box used for selecting files, and
   %   % allow for multiple selections
   %   [f,d] = uigetfile({'*.*','all Files (*.*)'}, 'MultiSelect', 'on');
   %
   %   % f will have one or more file names, so concatenate them
   %   % with the directory
   %   filename = strcat(d,f);
   %
   %   %call loadSacByFilenames to load all these files into waveform objects
   %   w = loadSacByFilenames(waveform, filename);
   %
   % The SAC header is parsed out, with the following equivelent fields used
   % by waveform:
   % _waveform_ 	_sac_
   % STATION		KSTNM
   % CHANNEL		KCMPNM
   % FREQUENCY		1 / DELTA (ODELTA is not used)
   % START			NZYEAR, NZJDAY, NZHOUR, NZMIN, NZSEC, NZMSEC
   % UNITS			IDEP is parsed.  IUNK becomes "Counts"
   % All header fields with values - that is, header fields that do not
   % contain the value  -12345 (either numeric or text) - are put into
   % user-defined fields within the waveform.
   % These fields can then be accessed via get/set.  User-defined fields
   % includes those that are parsed into waveform's predefined  fields as
   % listed above.
   %
   % loadSacByFilenames uses routines originating in code borrowed from
   % Mike Thorn
   %
   % For more information about the SAC header, and the interpretation of the
   % fields, check out Lawrence Livermore's web site.  Search for "seismic
   % sac" and you'll find it.
   
   if ~iscell(filename)
      filename = {filename};
   end
   
   sacdata = readsacfile(filename{:});
   w = sac2waveform(sacdata);
   w = removeSacDuplicates(w);
   for n=1:numel(filename)
      w(n) = addhistory(w(n),'Loaded SAC file: %s',filename{n});
   end
end

function w = removeSacDuplicates(w)
   % because all the files are loaded with fields blindly filled in, several
   % of the duplicated (and easily outdated and contradictory) fields are
   % henceforth removed
   % These fields are regenerated when the SAC file is written back to disk.
   noHistory = true;
   w = delfield(w,'B',noHistory); %covered by get(w,'start_epoch');
   w = delfield(w,'E',noHistory); %covered by get(w,'end_epoch');
   w = delfield(w,'DEPMIN',noHistory); %covered by min(w);
   w = delfield(w,'DEPMAX',noHistory);%covered by max(w);
   w = delfield(w,'DEPMEN',noHistory);%covered by mean(w);
   w = delfield(w,'NPTS',noHistory); %covered by get(w,'data_length');
   w = delfield(w,'KSTNM',noHistory); %covered by get(w,'station');
   w = delfield(w,'KCMPNM',noHistory); %covered by get(w,'channel');
   w = delfield(w,'KNETWK',noHistory); %covered by get(w,'network');
   w = delfield(w,'DELTA',noHistory); %covered by get(w,'period');
   w = delfield(w,'NVHDR',noHistory); %covered by get(w,'data_length');
   w = delfield(w,'IDEP',noHistory); %covered by get(w,'units'); %idEP is just a code.
   
   w = delfield(w,'LEVEN',noHistory); %by nature, data is evenly spaced
   w = delfield(w,'IDEP',noHistory); %covered by get(w,'units'); %idEP is just a code.
   
   %the following date values are convenient, but also may be outdated easily.
   %w = delfield(w,'NZYEAR',noHistory); %covered by get(w,'start');
   %w = delfield(w,'NZJDAY',noHistory); %covered by get(w,'start');
   %w = delfield(w,'NZHOUR',noHistory); %covered by get(w,'start');
   %w = delfield(w,'NZMIN',noHistory); %covered by get(w,'start');
   %w = delfield(w,'NZSEC',noHistory); %covered by get(w,'start');
   %w = delfield(w,'NZMSEC',noHistory); %covered by get(w,'start');
end
