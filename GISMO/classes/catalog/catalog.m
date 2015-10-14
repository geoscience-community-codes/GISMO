function cobj = catalog(filepath, dataformat, varargin)
%CATALOG
% This is a "skin" added to provide a bridge between the old catalog class and the new catalog family of classes
% which comprises of Catalog_lite and Catalog_full which both inherit Catalog_base
% 
% The idea is to support the old calls to catalog by translating them into calls to readEvents
% 
% TO DO:
% 	Also need to translate attributes and methods


% Parse required, optional and param-value pair arguments,
% set default values, and add validation conditions
p = inputParser;
p.addRequired('filepath', @isstr);
p.addRequired('dataformat', @isstr);
p.parse(filepath, dataformat, varargin{:});
fields = fieldnames(p.Results);
for i=1:length(fields)
	field=fields{i};
   val = p.Results.(field);
	cobj = cobj.set(field, val);
end

% Calls to Antelope
%	Reading an Antelope database using name/value pairs:
%		OLD: 
%			cobj = catalog('/Seis/catalogs/aeic/Total/Total', 'antelope', 'snum', datenum(2009,1,1), 'enum', datenum(2010,1,1), 'minmag', 4.0, 'region', [-170.0 -135.0 55.0 65.0]);
%		NEW: 
%			cobj = readEvents('antelope', 'dbpath', '/Seis/catalogs/aeic/Total/Total', 'snum', datenum(2009,1,1), 'enum', datenum(2010,1,1), 'minmag', 4.0, 'region', [-170.0 -135.0 55.0 65.0]);
%
%	Reading an Antelope database using a subset expression:
%		OLD: 
%			cobj = catalog('/Seis/catalogs/aeic/Total/Total', 'antelope', 'dbeval', 'time > "1989/1/1" && time < "2006/1/1" && deg2km(distance(61.2989, -152.2539, lat, lon))<10.0');
%		NEW: 
			cobj = readEvents('antelope', 'dbpath', '/Seis/catalogs/aeic/Total/Total', 'subset_expression', 'time > "2009/1/1" & time < "2010/1/1"' & ml > 4 & lon > -170.0 & lon < -135.0 & lat > 55.0 & lat < 65.0');

if strcmp(dataformat, 'antelope')
	% Check if 'dbeval' name-value pair exists
	% SKELETON: need to replace dbeval in field array and replace with subset_expression
	% then find out if name-value pairs translate from old to new catalog
	if exists('p.Results.dbeval','var') 
		%cobj = readEvents('antelope', 'dbpath', filepath, 'subset_expression', p.Results.dbeval, varargin{:})
	else
		%cobj = readEvents('antelope', 'dbpath', filepath, vargarin{:})
	end
end



