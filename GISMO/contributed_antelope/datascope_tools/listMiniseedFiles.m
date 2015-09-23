function [mseedfiles] = listMiniseedFiles(ds, chantag, snum, enum)
% LISTMINISEEDFILES retrieve a list of the Miniseed files referenced by a datasource, channeltag object and start/end times.
% mseedfiles = listMiniseedFiles(ds, chantag, snum)
% 
% Input:
%   ds - a datasource object
%   chantag - a channeltag object
%   snum - start time in Matlab datenum format 
%       e.g. snum = datenum('1999-01-12 10:00:00')
%   enum - end time, used only for subsetting database, not for finding
%       database with getfilename
%
% Output:
%   a structure with two elements:
%       filepath = path from current directory to MiniSEED file as given by
%                   database dir & dpath fields
%       exists = whether that path exists on the current system
%
%    See also miniseedExists

% AUTHOR: Glenn Thompson, UAF-GI
% $Date: $
% $Revision: -1 $

for c=1:length(chantag)
	mseedfiles(c).filepath={};
	mseedfiles(c).exists=[];
	try
		debug.print_debug(2, 'Calling getfilename');
		dbname = getfilename(ds, chantag(c), snum); % this is a cell array
        for k=1:numel(dbname)
            debug.print_debug(2, sprintf('dbname = %s\n',dbname{k}));
        end
	catch
		debug.print_debug(1,sprintf('getfilename failed for %s',string(chantag(c))));
		continue;
    end

	if exist(sprintf('%s.wfdisc',dbname{1}), 'file') | exist(dbname{1}, 'file')
		try
			debug.print_debug(5,'Opening database %s',dbname{1});
			db=dbopen(dbname{1},'r');
		catch
			debug.print_debug(1,sprintf('Could not dbopen database %s or %s.wfdisc - possibly no descriptor',dbname{1}, dbname{1}));
            try
                db=dblookup_table(db,sprintf('%s.wfdisc',dbname{1}));
            catch
                continue;
            end
		end
		try
			debug.print_debug(2,'Opening table %s.wfdisc\n',dbname{1});
			db=dblookup_table(db,'wfdisc');
		catch
			disp('Failed on dblookup_table wfdisc\n');
			continue;
		end
		expr = sprintf('sta=="%s" && chan=="%s" && time <= %f && endtime >= %f',chantag(c).station,chantag(c).channel,datenum2epoch(enum),datenum2epoch(snum));
		try
			debug.print_debug(2, 'Trying dbsubset with: %s\n',expr);
			db=dbsubset(db,expr);
		catch
			debug.print_debug(2,'Failed on dbsubset');
			continue;
		end
		try
			debug.print_debug(2,'Trying dbquery for RECORD_COUNT\n');
			nrecs = dbquery(db, 'dbRECORD_COUNT');
		catch
			debug.print_debug(2,'Failed on dbquery');
			continue;
		end
		debug.print_debug(2, 'Number of records = %d\n',nrecs);
        dbdir = fileparts(dbname{1});
		if nrecs>0
			try
				debug.print_debug(2, 'Getting dir, dfile, time, endtime\n');
				[ddir, ddfile] = dbgetv(db, 'dir', 'dfile', 'time', 'endtime');
                ddfullfile = fullfile(dbdir, ddir, ddfile); % ddir and ddfile are both cell arrays & file paths are relative to db dir
                uniquefile = unique(ddfullfile); % if there are two time segments pointing to same file, there are two wfdisc records. but we want only the unique dir/dfile combos here
                % could check here if enum <= endtime, and if not repeat
                % this for "dbname = getfilename(ds, chantag, enum)" 
                
			catch
				debug.print_debug(2,'Failed on dbgetv');
			end
			if ~(strcmp(class(ddir),'cell'))
				ddir={ddir};
				ddfile={ddfile};
            end
%           GT 20150916 I do not think it is possible to have multiple uniquefiles because getfilename returns database for a specific time, not time range            
% 			for k=1:numel(uniquefile)
% 				mseedfiles(c).filepath{k} = uniquefile{k};
% 				mseedfiles(c).exists(k) = exist(mseedfiles(c).filepath{k}, 'file');
% 			end
            mseedfiles(c).filepath = uniquefile{1};
            mseedfiles(c).exists = exist(uniquefile{1}, 'file');
        else
            mseedfiles(c).filepath = {};
            mseedfiles(c).exists(k) = 0;
			debug.print_debug(1,'no records selected for %s matching %s\n',dbname{1}, expr);
		end
	else
		debug.print_debug(1,'database %s not found\n',dbname{1});
    end
    
end

			
