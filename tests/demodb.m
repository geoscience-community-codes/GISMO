function dbpath = demodb(name)
%DEMODB
% dbpath = demodb('avo')
% dbpath = demodb('rt')
if admin.antelope_exists
	if strcmp(lower(name),'antelope')
	    dbpath = '/opt/antelope/data/db/demo/demo';
	else
	    dirname = getenv('GISMODATAPATH');
	    dbpath = fullfile(dirname,'css3.0', sprintf('%sdb200903',name));
	end
else
	warning('Antelope not installed')
end

