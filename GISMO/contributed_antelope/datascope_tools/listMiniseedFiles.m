function [mseedfiles] = listMiniseedFiles(ds, scnl, snum, enum)
% LISTMINISEEDFILES retrieve a list of the Miniseed files referenced by a datasource, scnlobject and start/end times.
% mseedfiles = listMiniseedFiles(ds, scnl, snum, enum)
% 
%    See also miniseedExists

% AUTHOR: Glenn Thompson, UAF-GI
% $Date: $
% $Revision: -1 $
if length(scnl)==0
	disp('Error: no scnls');
end
for c=1:length(scnl)
	mseedfiles(c).filepath={};
	mseedfiles(c).exists=[];
	try
		debug.print_debug(5, 'Calling getfilename');
		dbname = getfilename(ds, scnl(c), snum)
	catch
		disp('getfilename failed');
		continue;
	end
	if exist(dbname{1}, 'file')
		try
			debug.print_debug(5,'Opening database %s',dbname{1});
			db=dbopen(dbname{1},'r');
		catch
			disp(sprintf('Failed on dbopen database %s',dbname{1}));
			continue;
		end
		try
			debug.print_debug(5,'Opening database %s.wfdisc',dbname{1});
			db=dblookup_table(db,'wfdisc');
		catch
			disp('Failed on dblookup_table wfdisc');
			continue;
		end
		expr = sprintf('sta=="%s" && chan=="%s" && time <= %f && endtime >= %f',get(scnl(c),'station'),get(scnl(c),'channel'),datenum2epoch(enum),datenum2epoch(snum));
		try
			debug.print_debug(5, 'Trying dbsubset with: %s',expr);
			db=dbsubset(db,expr);
		catch
			disp('Failed on dbsubset');
			continue;
		end
		try
			debug.print_debug(5,'Trying dbquery for RECORD_COUNT');
			nrecs = dbquery(db, 'dbRECORD_COUNT');
		catch
			disp('Failed on dbquery');
			continue;
		end
		debug.print_debug(5, 'Number of records = %d',nrecs);
		if nrecs>0
			try
				debug.print_debug(5, 'Getting dir, dfile, time, endtime');
				[ddir, ddfile] = dbgetv(db, 'dir', 'dfile', 'time', 'endtime');
			catch
				disp('Failed on dbgetv');
			end
			if ~(strcmp(class(ddir),'cell'))
				ddir={ddir};
				ddfile={ddfile};
			end
			for k=1:nrecs
				mseedfiles(c).filepath{k} = sprintf('%s/%s/%s',fileparts(dbname{1}),ddir{k},ddfile{k});
				mseedfiles(c).exists(k) = exist(mseedfiles(c).filepath{k}, 'file');
			end
		else
			fprintf('no records selected for %s matching %s\n',dbname{1}, expr);
		end
	else
		fprintf('database %s not found\n',dbname{1});
	end
end

			
