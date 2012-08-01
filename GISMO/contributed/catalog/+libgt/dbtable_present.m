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
          if exist(sprintf('%s.origin',dbpath)) 
            if numrows > 0
                present = numrows;
                libgt.print_debug(sprintf('Success: %d rows',numrows),3); 
            else
                libgt.print_debug(sprintf('Failure: %d rows',numrows),3);
            end
          else
                libgt.print_debug(sprintf('Failure: %d rows',numrows),3);
          end
          
       end
    catch
         libgt.print_debug(sprintf('Failure: could not open %s.%s. Does it open with dbe?',dbpath,table),0);
    end
else
	libgt.print_debug(sprintf('Failure: could not find %s. Is the descriptor missing? A database is Antelope must have a descriptor, otherwise MATLAB cannot load it.',dbpath),0);
end
libgt.print_debug(sprintf('< %s',mfilename),3);