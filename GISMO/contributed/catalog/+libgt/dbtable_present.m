function present=dbtable_present(dbpath, table)
% DBTABLE_PRESENT Check if a Datascope database table exists and has more than 0 rows. 
%
%    PRESENT = DBTABLE_PRESENT(DBPATH, TABLE)

% AUTHOR: Glenn Thompson, UAF-GI
% $Date$
% $Revision$
libgt.print_debug(sprintf('> %s',mfilename),3);
present = 0;
if exist(dbpath, 'file')
   db = dbopen(dbpath, 'r');
   try
       db = dblookup_table(db, table);
       numrows = dbquery(db, 'dbRECORD_COUNT');
       if numrows > 0
          present = numrows;
          libgt.print_debug(sprintf('Success: %d rows',numrows),3);
       else
          libgt.print_debug(sprintf('Failure: %d rows',numrows),3);           
       end
    catch
         libgt.print_debug(sprintf('Failure: could not open %s.%s',dbpath,table),3);
    end
else
	libgt.print_debug(sprintf('Failure: could not find %s. The descriptor may be missing.',dbpath),3);
end
libgt.print_debug(sprintf('< %s',mfilename),3);