function scnlfound=miniseedExists(ds, scnl, snum, enum)
%MINISEEDEXISTS check if there are miniseed files corresponding to the scnl, ds, and time range given
%scnlfound=miniseedExists(ds, scnl, snum, enum)
%
%    see also:  listMiniseedFiles

% AUTHOR: Glenn Thompson, UAF-GI
% $Date: $
% $Revision: -1 $
scnlfound = [];
for c=1:length(scnl)
	debug.print_debug(5,'Calling listMiniseedFiles for %s.%s',get(scnl(c),'station'),get(scnl(c),'channel'));
	mseedfiles = listMiniseedFiles(ds, scnl(c), snum, enum);
	try	
    		if(getpref('runmode', 'debug') >= 5)
			for k=1:length(mseedfiles)
				f=mseedfiles(k).filepath;
				for m=1:length(f)
					debug.print_debug(5,'MiniSEED file: %s',f{m});
				end
			end
		end
	end
	if mean([mseedfiles.exists])==2
		scnlfound = [scnlfound scnl(c)];
	end
end

