function [arrival,assoc,origin,W] = db_get_arrival_info(INorigin,dbname,varargin)


% ARRIVAL = DB_GET_ARRIVAL_INFO(ARRIVAL_LIST,DATABASE_NAME) Returns pertinent 
% fields from teh arrival, assoc and origin tables based on input arrival id numbers (arid);
% ARRIVAL_LIST must be a vector of arrival id numbers (arid). The returned structures ARRIVAL contains
% fields pulled from each of the corresponding tables.
%
% Unlike db_get_origin_info, there is currently no method for entering arrivals by time. 
% arid's must be used.

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks




if isa(INorigin,'double')
	arrival.arid = reshape( INorigin , numel(INorigin), 1 );
else
    error('First input must be either arrival ids (arid)');
end


% Check for waveform
if numel(varargin) == 1
	W = varargin{1};
	if ~isa(W,'waveform')
		error('Third argument must be a WAVEFORM object');
	end
elseif numel(varargin) > 1
	error('Too many arguments');
end


% GET ORIGIN TIME
db = dbopen(dbname,'r');
db = dblookup_table(db,'arrival');
nlist = [];
for n = 1:length(arrival.arid);
	db1 = dbsubset(db,['arid==' num2str(arrival.arid(n))]);
	db2 = dblookup_table(db,'assoc');
	db1 = dbjoin(db1,db2);
	db2 = dblookup_table(db,'origin');
	db1 = dbjoin(db1,db2);
	[ origin.lat(n),origin.lon(n),origin.depth(n),origin.time_epoch(n),origin.ml(n),origin.orid(n)] = dbgetv(db1,'origin.lat','origin.lon','origin.depth','origin.time','origin.ml','origin.orid');
	[ arrival.time(n),arrival.iphase(n),arrival.deltim(n)] = dbgetv(db1,'arrival.time','arrival.iphase','arrival.deltim');
	[ assoc.delta(n),assoc.seaz(n),assoc.esaz(n),assoc.timeres(n) ] = dbgetv(db1,'assoc.delta','assoc.seaz','assoc.esaz','assoc.timeres');
end
dbclose(db);
origin.lat = reshape( origin.lat , numel(origin.lat), 1 );
origin.lon = reshape( origin.lon , numel(origin.lon), 1 );
origin.depth = reshape( origin.depth , numel(origin.depth), 1 );
origin.time_epoch = reshape( origin.time_epoch , numel(origin.time_epoch), 1 );
origin.time_matlab = datenum(strtime(origin.time_epoch));
origin.ml = reshape( origin.ml , numel(origin.ml), 1 );
origin.orid = reshape( origin.orid , numel(origin.orid), 1 );
%
arrival.time_epoch = reshape( arrival.time , numel(arrival.time), 1 );
arrival.time_matlab =  datenum(strtime(arrival.time_epoch));
arrival.iphase = reshape( arrival.iphase , numel(arrival.iphase), 1 );
arrival.deltim = reshape( arrival.deltim , numel(arrival.deltim), 1 );
%
assoc.delta = reshape( assoc.delta , numel(assoc.delta), 1 );
assoc.seaz = reshape( assoc.seaz , numel(assoc.seaz), 1 );
assoc.esaz = reshape( assoc.esaz , numel(assoc.esaz), 1 );
assoc.timeres = reshape( assoc.timeres , numel(assoc.timeres), 1 );


if exist('W')
	for n = 1:numel(W)
		disp([ 'Retreiving origin, arrival and assoc info for orid: ' num2str(origin.orid(n)) ' ... '])
		W(n) = addfield(W(n),'ORIGIN_LAT',origin.lat(n));
		W(n) = addfield(W(n),'ORIGIN_LON',origin.lon(n));
		W(n) = addfield(W(n),'ORIGIN_DEPTH',origin.depth(n));
		W(n) = addfield(W(n),'ORIGIN_TIME_EPOCH',origin.time_epoch(n));
		W(n) = addfield(W(n),'ORIGIN_ML',origin.ml(n));
		W(n) = addfield(W(n),'ORIGIN_TIME_MATLAB',origin.time_matlab(n));
		W(n) = addfield(W(n),'ORIGIN_ORID',origin.orid(n));
		%
		W(n) = addfield(W(n),'ARRIVAL_TIME_EPOCH',arrival.time_epoch(n));
		W(n) = addfield(W(n),'ARRIVAL_TIME_MATLAB',arrival.time_matlab(n));
		W(n) = addfield(W(n),'ARRIVAL_IPHASE',arrival.iphase(n));
		W(n) = addfield(W(n),'ARRIVAL_DELTIME',arrival.deltime(n));
		%
		W(n) = addfield(W(n),'ASSOC_DELTA',assoc.delta(n));
		W(n) = addfield(W(n),'ASSOC_SEAZ',assoc.seaz(n));
		W(n) = addfield(W(n),'ASSOC_ESAZ',assoc.esaz(n));
		W(n) = addfield(W(n),'ASSOC_TIMERES',assoc.timeres(n));
	end
end





