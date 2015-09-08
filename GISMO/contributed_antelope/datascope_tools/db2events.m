function [lon, lat, depth, dnum, evid, orid, nass, mag, mb, ml, ms, etype, auth] = db2events(dbname, dbeval)
% DB2EVENTS Load preferred origins from a Datascope CSS3.0 event database
%   [lon, lat, depth, dnum, evid, orid, nass, mag, mb, ml, ms, etype, auth] = db2events(dbname, dbeval)
%
%   INPUT:
%     dbname = path to database
%     dbeval = a dbeval expression. This can be '' if no
%     subsetting is desired.
%
% 
%   Example: Import all events from the demo database
%     dirname = fileparts(which('catalog')); % get the path to the catalog directory
%     dbroot = [dirname,'/demo/avodb200903']; 
%     [lon, lat, depth, dnum, evid, orid, nass, mag, mb, ml, ms, etype, auth] = db2events(dbroot, '')
%
%   Note: the use of this function is discouraged. It is better to use the
%   catalog class ('help catalog', for more details).
%
%   Used by: CATALOG
%
% See also CATALOG
%
%% AUTHOR: Glenn Thompson

% $Date: $
% $Revision: $
   	    numorigins = 0;
        [lat, lon, depth, dnum, time, evid, orid, nass, mag, ml, mb, ms, etype, auth] = deal([]);
        auth = {};
	    if ~admin.antelope_exists
            error('This function requires the Antelope toolbox for Matlab'); 
            return;
	    end

      	    debug.print_debug(3, 'Loading data from %s',dbname);
          
            ORIGIN_TABLE_PRESENT = dbtable_present(dbname, 'origin');

            if (ORIGIN_TABLE_PRESENT)
                db = dblookup_table(dbopen(dbname, 'r'), 'origin');
                numorigins = dbquery(db,'dbRECORD_COUNT');
                debug.print_debug(1, 'Got %d records from %s.origin',numorigins,dbname);
                if numorigins > 0
                    EVENT_TABLE_PRESENT = dbtable_present(dbname, 'event');           
                    if (EVENT_TABLE_PRESENT)
                        db = dbjoin(db, dblookup_table(db, 'event') );
                        numorigins = dbquery(db,'dbRECORD_COUNT');
                        debug.print_debug('Got %d records after joining event with %s.origin',numorigins,dbname);
                        if numorigins > 0
                            db = dbsubset(db, 'orid == prefor');
                            numorigins = dbquery(db,'dbRECORD_COUNT');
                            debug.print_debug(1,'Got %d records after subsetting with orid==prefor',numorigins);
                            if numorigins > 0
                                db = dbsort(db, 'time');
                            else
				% got no origins after subsetting for prefors - already reported
                                debug.print_debug(0,'%d records after subsetting with orid==prefor',numorigins);
                                return
                            end
                        else
			    % got no origins after joining event to origin table - already reported
                            debug.print_debug(0,'%d records after joining event table with origin table',numorigins);
                            return
                        end
		    else
                        debug.print_debug(0,'No event table found, so will use all origins from origin table, not just prefors');
                    end
                else
		    % got no origins after opening origin table - already reported
                    debug.print_debug(0,'origin table has %d records',numorigins);
                    return
                end
            else
                debug.print_debug(0, 'no origin table found');
                return
            end

	    numorigins = dbquery(db,'dbRECORD_COUNT');
	    debug.print_debug(2,'Got %d prefors prior to subsetting',numorigins);
	
			% Do the subsetting
            if ~isempty(dbeval)
                db = dbsubset(db, dbeval);
                numorigins = dbquery(db,'dbRECORD_COUNT');
                debug.print_debug(2,'Got %d prefors after subsetting',numorigins);
        	end

	    if numorigins>0
                if EVENT_TABLE_PRESENT
                    [lat, lon, depth, time, evid, orid, nass, ml, mb, ms, auth] = dbgetv(db,'lat', 'lon', 'depth', 'time', 'evid', 'orid', 'nass', 'ml', 'mb', 'ms', 'auth');
                else
                    [lat, lon, depth, time, orid, nass, ml, mb, ms, auth] = dbgetv(db,'lat', 'lon', 'depth', 'time', 'orid', 'nass', 'ml', 'mb', 'ms', 'auth');  
                    disp('Setting evid == orid');
                    evid = orid;
                end
                etype0 = dbgetv(db,'etype');
     
 			   	if isempty(etype0)
			        	etype = char(ones(numorigins,1)*'R');
			    else
  			     	% convert etypes
					etype0=char(etype0);
					etype(etype0=='a')='t';
                    etype(etype0=='b')='l';
                    etype(etype0=='-')='u';
                    etype(etype0==' ')='u';
                end
                etype = char(etype); % sometimes etype gets converted to ASCII numbers

				% get mag
				mag = max([ml mb ms], [], 2);

 			   	% convert time from epoch to Matlab datenumber
				dnum = epoch2datenum(time);

            end

	
			% close database
			dbclose(db);
        end
