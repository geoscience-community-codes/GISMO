function allObj = load_objects_from_file(ds,searchClass,scnl,startt,endt)
%grab all the variables in a matlab file, and flip through them, returning
%those that match the criteria
% allObj = load_file(datasource,searchClass,scnl,starttime,endtime)
%   DATASOURCE is a single datasource object (of type "file")
%   SEARCHCLASS is a string containing the name of the class you are
%   searching for.  eg, 'double','waveform', etc.
%   SCNL is an array of scnlobjects which hold
%   station/channel/network/location matches.
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
%
% Any object can be loaded from file, however since this was designed to
% work with seismic data, it must have an ISMEMBER function that takes as
% it's parameters the object itself and a SCNLobject.  Also required is the
% [Starts Ends] = GETTIMERANGE(obj) function. (see waveform/gettimerange
% for an example implementation.
%
% see also ISMEMBER, WAVEFORM/GETTIMERANGE

%The file looks a little opaque because it deals generically with classes
%and objects, rather than tying itself down to any particular object.
allfilen = getfilename(ds,scnl,startt);
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
  stuff =load(filen,fcontents(variablesToLoad).name);
  
  fieldn = fieldnames(stuff);

  %Look through all variables that were loaded, looking for the desired
  %class.  If a cell is encountered, then look for occurrences of that class
  %within the cell (recursively).

  myObjectMask = false(size(fieldn));
  holder = cell(size(fieldn));
  for fieldidx = 1:numel(fieldn)
    thisfield =  fieldn{fieldidx};
    %grab all myObjects
    if isa(stuff.(thisfield),searchClass)
      holder(fieldidx) = {reshape(stuff.(thisfield),1,numel(stuff.(thisfield)))};
      myObjectMask(fieldidx) = true;
      stuff.(thisfield) = {};
    elseif isa(stuff.(thisfield),'cell')
      holder(fieldidx) = {myObjectsFromCells(searchClass,stuff.(thisfield))};
      myObjectMask(fieldidx) = true;
    else
      stuff.(thisfield) = {};
    end
  end
  myObj = [holder{myObjectMask}];
  myObj = myObj(ismember(myObj,scnl));
  
  
  %now get rid of any that don't match the time criteria.
  hasValidRange = isWithinTimeRange(myObj,startt,endt);
  allObj(thisfile) = {myObj(hasValidRange)};
  
  
end


if ~exist('allObj','var')
	warning('no %ss found',searchClass);
	allObj = {};
end

allObj = [allObj{:}];


function hasValidRange = isWithinTimeRange(myObj,startt,endt)

  [theseStarts theseEnds] = gettimerange(myObj);
  hasValidRange = false(size(theseStarts));
  
%   if isempty(theseStarts) || isempty(theseEnds)
%     warning('Datasource:ObjectNoTimes',...
%       'One or more objects have no start or end times associated with them');
%     return;
%   end
  
  %check each object's range against all requested ranges
  for timeidx = 1:numel(startt)
    requestedStart = startt(timeidx);    
    requestedEnd = endt(timeidx);
    
    % make sure the data doesn't start AFTER requested data...
    validStarts = (theseStarts <=requestedEnd); 
    % ...and make sure the data deosn't end BEFORE requested data
    validEnds = (theseEnds >= requestedStart);
    
    %add objects that match the criteria to the OK list
    hasValidRange = hasValidRange | (validStarts & validEnds);
  end


function mObj = myObjectsFromCells(searchClass, mycell)
myObjectMask = false(size(mycell));
for i=1:numel(mycell);
  if isa(mycell{i},searchClass), 
    myObjectMask(i) = true;
    mycell(i) = {reshape(mycell{i},1,numel(mycell{i}))}; %make all myObjects 1xN    
  elseif isa(mycell{i},'cell') %it's a cell, let's recurse
    mycell(i) = {myObjectsFromCells(mycell{i})};  %pull myObjects from the cell and bring them to this level.  
  end
end
  mObj= [mycell{myObjectMask}];
