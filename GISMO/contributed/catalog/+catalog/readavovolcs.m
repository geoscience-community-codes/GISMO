function [sourcelon, sourcelat, minlon, maxlon, minlat, maxlat] = readavovolcs(volcano, pffile)
% READAVOVOLCS Read the avo_volcs.pf file.
%    Usage:
%          [sourcelon, sourcelat, minlon, maxlon, minlat, maxlat] = readavovolcs(volcano [, pffile])
%
%    Given a string (volcano), READAVOVOLCS will attempt to find that string in a file called
%    avo_volcs.pf, and then read in the corresponding summit (source) longitude and latitude, along
%    with a region that corresponds to the geographical areas used in the AVO histogram.
%
%    The avo_volcs.pf file was developed as part of the AVO histogram application, and it has been used
%    by several other applications since, though it would make more sense to store these data in a
%    database (e.g. using the Datascope places1.2 schema).
%
%    If an explicit path to the parameter file is not given, READAVOVOLCS will attempt to use
%    pf/avo_volcs.pf and then /avort/oprun/pf/avo_volcs.pf. By using an explicit path, a user could
%    create an arbitrarily named file like /home/username/config/myvolcanoes.txt, where each line
%    consists of:
%           volcanoname sourcelon sourcelat minlon maxlon minlat maxlat


% Author: Glenn Thompson

debug.print_debug(sprintf('> %s', mfilename),4)

if ~exist('pffile', 'var') 
	pffile=(['pf/avo_volcs.pf']);
	if ~exist('pffile', 'file') 
        classdir = fileparts(which('catalog'));
		pffile=matlab_extensions.catpath(classdir, 'demo', 'avo_volcs.pf');
	end
end
if exist(pffile, 'file')
	volcano = camelcase2underscore(volcano);
	
	debug.print_debug(sprintf('Trying to read %s for %s\n', pffile,volcano),2)
	A=importdata(pffile);
	
	for c=1:length(A.rowheaders)
		if strcmp(lower(A.rowheaders{c}), lower(volcano))
			sourcelon = A.data(c, 2);
			sourcelat = A.data(c, 1);
			minlon = A.data(c, 5);
			maxlon = A.data(c, 6);
            
			minlat = A.data(c, 3);
			maxlat = A.data(c, 4);
		end
	end
else
	error(sprintf('%s: %s does not exist',mfilename, pffile));
end

debug.print_debug(sprintf('< %s', mfilename),4)

function str = camelcase2underscore(str)
str = strcat(str(1) ,regexprep(str(2:end), '[A-Z]', '_$0') );
