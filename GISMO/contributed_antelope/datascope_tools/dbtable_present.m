function present=dbtable_present(dbpath, table)
% DBTABLE_PRESENT Check if a Datascope database table exists and has more than 0 rows. 
%
%    PRESENT = DBTABLE_PRESENT(DBPATH, TABLE)

% AUTHOR: Glenn Thompson, UAF-GI
% $Date$
% $Revision$
present = 0;

if exist(dbpath, 'file') || exist(sprintf('%s.%s',dbpath,table), 'file')
   try
     db = dbopen(dbpath, 'r');
   catch
     debug.print_debug(sprintf('Failure: database exists but dbopen fails'),0);
     return;
   end
   try
       db = dblookup_table(db, table);
       numrows = dbquery(db, 'dbRECORD_COUNT');
       if numrows > 0
          present = numrows;
          debug.print_debug(sprintf('Success: %d rows',numrows),3);
       else
          if exist(sprintf('%s.origin',dbpath)) 
            if numrows > 0
                present = numrows;
                debug.print_debug(sprintf('Success: %d rows',numrows),3); 
            else
                debug.print_debug(sprintf('Failure: %d rows',numrows),3);
            end
          else
                debug.print_debug(sprintf('Failure: %d rows',numrows),3);
          end
          
       end
    catch
         debug.print_debug(sprintf('Failure: dblookup_table fails for %s.%s',dbpath,table),0);
    end
else
	debug.print_debug(sprintf('Failure: cannot find %s or %s.%s on this computer.',dbpath,dbpath,table),0);
end
