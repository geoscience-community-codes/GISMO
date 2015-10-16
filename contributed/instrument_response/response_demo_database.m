function dbName = response_demo_database

%RESPONSE_DEMO_DATABASE returns the absolute path to the demo database
%  DBNAME = RESPONSE_DEMO_DATABASE



file = which('response_cookbook');
path = fileparts(file);

if ~exist([path '/demo'])
	error('response_demo_database: demo database not found');
else
	dbName = [path '/demo/plutons'];
end
