function w = load_file(dataRequest)
%LOAD_FILE
% uses the DATASOURCE class

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
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
  variablesToLoad = ismember({fcontents.class},{'waveform', 'cell'});
  if ~any(variablesToLoad),
    %disp(['no items of the this class exist within the file:',filen]);
    return
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
    if isa(stuff.(thisfield),'waveform')
      holder(fieldidx) = {reshape(stuff.(thisfield),1,numel(stuff.(thisfield)))};
      myObjectMask(fieldidx) = true;
      stuff.(thisfield) = {};
    elseif isa(stuff.(thisfield),'cell')
      holder(fieldidx) = {myObjectsFromCells('waveform',stuff.(thisfield))};
      myObjectMask(fieldidx) = true;
    else
      stuff.(thisfield) = {};
    end
  end
  w = [holder{myObjectMask}];
  
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
