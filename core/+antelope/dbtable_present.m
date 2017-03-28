function present=dbtable_present(dbpath, tablename)
% DBTABLE_PRESENT Check if a Datascope database table exists and has more than 0 rows. 
%
%    PRESENT = DBTABLE_PRESENT(DBPATH, TABLENAME)

% AUTHOR: Glenn Thompson, UAF-GI
% $Date$
% $Revision$
present = 0;
if isa(dbpath,'cell')
    dbpath = dbpath{1};
end
if isa(tablename,'cell')
    tablename = tablename{1};
end
tablepath = sprintf('%s.%s',dbpath,tablename);
if exist(dbpath, 'file') || exist(tablepath, 'file')

   try
     db = dbopen(dbpath, 'r');
   catch
     debug.print_debug(0, 'Failure: database exists but dbopen fails');
     return;
   end
   try
       db = dblookup_table(db, tablename);
       numrows = dbquery(db, 'dbRECORD_COUNT');
       if numrows > 0
          present = numrows;
          debug.print_debug(3, 'Success: %d rows',numrows);
       else
          if exist(sprintf('%s.origin',dbpath)) 
            if numrows > 0
                present = numrows;
                debug.print_debug(3, 'Success: %d rows',numrows); 
            else
                debug.print_debug(3, 'Failure: %d rows',numrows);
            end
          else
                debug.print_debug(3,'Failure: %d rows',numrows);
          end
          
       end
    catch
         debug.print_debug(0, 'Failure: dblookup_table fails for %s',tablepath);
    end
else
	debug.print_debug(0,'Failure: cannot find %s or %s.%s on this computer.',dbpath,tablepath);
end
