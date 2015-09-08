function [scnls starttimes endtimes] = query_file(ds, filename)
% QUERY_FILE retrieves scnl, starttime and endtime information for all
% objects of intrest with a file
% [scnls starttimes endtimes] = query_file(datasource, filename);

if ~requires_file(ds)
  warning('irrelevent request, no filenames associated with this datasource');
  scnls = scnlobject;
  return
end
if isa(filename,'cell')
  filename = filename{1};
end;
if ~exist(filename,'file')
  warning('file does not exist');
  scnls =  scnlobject;
  return
end

obj = ds.interpreter(filename);
scnls = get(obj,'scnlobject');
starttimes = get(obj,'start');
endtimes = get(obj,'end');


  

%interpret file
%keep scnls only

