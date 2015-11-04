function allObj = load_objects_from_file(ds,searchClass,chanTag,startt,endt)
   %grab all the variables in a matlab file, and flip through them, returning
   %those that match the criteria
   % allObj = load_file(datasource,searchClass,scnl,starttime,endtime)
   %   DATASOURCE is a single datasource object (of type "file")
   %   SEARCHCLASS is a string containing the name of the class you are
   %   searching for.  eg, 'double','waveform', etc.
   %   CHANTAG is an array of ChannelTags which hold
   %   network/station/location/channel/network matches.
   %   STARTTIME is the starting time in matlab datenum format
   %   ENDTIME is the ending time in matlab datenum format
   %
   %   This function returns a 1xN dimesional array of all relevent objects
   %   found within the searched file(s).  All variable identity from within
   %   the files is lost.
   %   - - -
   %   SO, for example, in the context of searching for waveform data...
   %   if there is a searchfile, that contians the variables: W (1x3
   %   waveform), W2 (1x1 waveform), MyWc (2x2 cell with waveforms in it), and
   %   D (double).
   %
   %   the load_file method will rip out each and every waveform (recursing
   %   through cells), then lump all of them into a large 1xN waveform.  Each
   %   waveform that doesn't meet the SCNL criteria is discarded.  Then, all
   %   waveforms that don't have data somewhere within the starttime-endtime
   %   timeframe will be discarded as well.
   %
   %   It is important to note that the recovered objects aren't trimmed to
   %   the starttime-endtime timeeframe.  That is, individual objects are not
   %   altered through the use of this function.
   %
   %   IF CHANNELTAG is empty, then all channels don't matter.
   %   If STARTTIME or ENDTIME are empty, then time doesn't matter.
   %
   % Any object can be loaded from file, however since this was designed to
   % work with seismic data, it must have an ISMEMBER function that takes as
   % it's parameters the object itself and a ChannelTag.  Also required is the
   % [Starts Ends] = GETTIMERANGE(obj) function. (see waveform/gettimerange
   % for an example implementation.
   %
   % see also ISMEMBER, WAVEFORM/GETTIMERANGE
   
   %The file looks a little opaque because it deals generically with classes
   %and objects, rather than tying itself down to any particular object.
   allfilen = getfilename(ds,chanTag,startt);
   allObj = cell(size(allfilen));   %preallocate
   for thisfile = 1 : numel(allfilen)
      filen = allfilen{thisfile};
      
      if ~exist(filen,'file')
         disp(['unable to find file: ', filen]);
         continue
      end
      
      %find out which variables exist within the file...
      fcontents = whos('-file',filen);
      variablesToLoad = ismember({fcontents.class},{searchClass, 'cell'});
      if ~any(variablesToLoad),
         %disp(['no items of the this class exist within the file:',filen]);
         continue
      end
      
      % load all variables into a big cell.
      % each variable becomes a cell within this big cell, so variable names are lost)
      fileAsCell = struct2cell(load(filen,fcontents(variablesToLoad).name));
      myObj = getFromCells(searchClass, fileAsCell);

      if ~isempty(chanTag)
         myObj = myObj(ismember(myObj,chanTag));
      end
      
      if ~(isempty(startt) || isempty(endt))
         hasValidRange = isWithinTimeRange(myObj,startt,endt);
         allObj(thisfile) = {myObj(hasValidRange)};
      else
         allObj(thisFile) = {myObj};
      end
      
   end
   
   if ~exist('allObj','var')
      warning('no %ss found',searchClass);
      allObj = {};
   end
   
   allObj = [allObj{:}];
end

function hasValidRange = isWithinTimeRange(myObj,startt,endt)
   % TODO: split out each test to provide more flexibility
   [theseStarts, theseEnds] = gettimerange(myObj);
   hasValidRange = false(size(theseStarts));
   
   %check each object's range against all requested ranges
   for timeidx = 1:numel(startt)
      requestedStart = startt(timeidx);
      requestedEnd = endt(timeidx);
      
      % make sure the data doesn't start AFTER requested data...
      validStarts = (theseStarts <=requestedEnd);
      % ...and make sure the data doesn't end BEFORE requested data
      validEnds = (theseEnds >= requestedStart);
      
      %add objects that match the criteria to the OK list
      hasValidRange = hasValidRange | (validStarts & validEnds);
   end
end

function mObj = getFromCells(searchClass, mycell)
   % returns an 1xN array of objects
   
   %might break if searchClass == 'cell'. but I haven't tested it
   searchFn = @(x) isa (x, searchClass);
   makeRows = @(x) reshape(x,1,numel(x));
   
   target = cellfun(searchFn, mycell);
   objs = cellfun(makeRows, mycell(target), 'uniformoutput', false);
  
   holdsCell = cellfun(@iscell, mycell);
   if any(holdsCell)
      mObj = getFromCells(searchClass, mycell{holdsCell}); %recurse
   else
      mObj = {};
   end
   mObj = [mObj{:} objs{:}];
end