function present=dbtable_present(dbpath, table)
% DBTABLE_PRESENT Check if a Datascope database table exists and has more than 0 rows. 
%
%    PRESENT = DBTABLE_PRESENT(DBPATH, TABLE)

% AUTHOR: Glenn Thompson, UAF-GI
% $Date:$
% $Revision:$
present = 0;
libgt.print_debug(sprintf('%s: checking %s.%s has > 0 rows\n',mfilename,dbpath,table),2);
if exist(dbpath, 'file')
   db = dbopen(dbpath, 'r');
   try
       db = dblookup_table(db, table);
       numrows = dbquery(db, 'dbRECORD_COUNT');
       if numrows > 0
          present = 1;
          libgt.print_debug(sprintf('Success: %f rows\n',numrows),3);
       else
          libgt.print_debug(sprintf('Failure: %f rows\n',numrows),3);           
       end
    catch
         libgt.print_debug(sprintf('Failure: could not open %s.%s\n',dbpath,table),3);
    end
end
