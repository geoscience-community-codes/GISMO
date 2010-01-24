function [origin,W] = db_get_origin_info(INorigin,dbname,varargin)


% ORIGIN = DB_GET_ORIGIN_INFO(EVENT,DATABASE_NAME) If EVENT is a vector
% of origin id numbers (orid) then the returned structure ORIGIN contains
% fields pulled from the origin table.
%
% If EVENT is a vector of string times (one time per row) then the database
% is searched for the origin occuring closest in time to each element of
% EVENT (preferred origins only). Using the ORID is a more precise way to
% pull events from the database, however, orid's have no inherent meaning
% and may change. Using (approximate) origin times avoids this.
%
% [ORIGIN,WAVEFORM] = DB_GET_ORIGIN_INFO(EVENT,DATABASE_NAME,WAVEFORM) Add 
% origin information as new fields in WAVEFORM object. 

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks



%  FOR TESTING ONLY
%dbname = '/home/admin/databases/AU06/wf/au06wf_2006_01';
%INorigin = [
%	'1/26/2006 11:58:59'
%	'1/27/2006 04:10:13'
%	'1/11/2006 07:01:49'
%	'1/31/2006 22:02:10'
%];
%INorigin = [
%	31301880
%	31301918
%	31300878
%	31302068
%];



if isa(INorigin,'double')
	origin.orid = reshape( INorigin , numel(INorigin), 1 );
elseif isa(INorigin,'char')
	for n = 1:size(INorigin,1)
		tmp(n) = str2epoch(INorigin(n,:));
	end
	tmp = getorids(tmp,dbname);
	origin.orid = reshape( tmp , numel(tmp), 1 );

else
    error('First input must be either origin ids or sting-formatted times');
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
db = dblookup_table(db,'origin');
nlist = [];
for n = 1:length(origin.orid);
	db1 = dbsubset(db,['orid==' num2str(origin.orid(n))]);
	[ origin.lat(n),origin.lon(n),origin.depth(n),origin.time_epoch(n),origin.ml(n),origin.orid(n)] = dbgetv(db1,'lat','lon','depth','time','ml','orid');
end
dbclose(db);
origin.lat = reshape( origin.lat , numel(origin.lat), 1 );
origin.lon = reshape( origin.lon , numel(origin.lon), 1 );
origin.depth = reshape( origin.depth , numel(origin.depth), 1 );
origin.time_epoch = reshape( origin.time_epoch , numel(origin.time_epoch), 1 );
origin.ml = reshape( origin.ml , numel(origin.ml), 1 );
origin.time_matlab = datenum(strtime(origin.time_epoch));
origin.orid = reshape( origin.orid , numel(origin.orid), 1 );
if exist('W')
	for n = 1:numel(W)
		disp([ 'Retreiving origin info for orid: ' num2str(origin.orid(n)) ' ... '])
		W(n) = addfield(W(n),'ORIGIN_LAT',origin.lat(n));
		W(n) = addfield(W(n),'ORIGIN_LON',origin.lon(n));
		W(n) = addfield(W(n),'ORIGIN_DEPTH',origin.depth(n));
		W(n) = addfield(W(n),'ORIGIN_TIME_EPOCH',origin.time_epoch(n));
		W(n) = addfield(W(n),'ORIGIN_ML',origin.ml(n));
		W(n) = addfield(W(n),'ORIGIN_TIME_MATLAB',origin.time_matlab(n));
		W(n) = addfield(W(n),'ORIGIN_ORID',origin.orid(n));
	end
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RETURN ORID FOR EVENT CLOSEST IN TIME TO INPUT
function neworigin = getorids(origin,dbname);

db = dbopen(dbname,'r');
db = dblookup_table(db,'origin');
db1 = dblookup_table(db,'event');
db = dbjoin(db,db1);
db = dbsubset(db,'orid==prefor');
nrecords = dbquery(db,'dbRECORD_COUNT');
%display(['Number of records: ' num2str(nrecords)]);
[orid,time] = dbgetv(db,'orid','time');
dbclose(db);

for n = 1:length(origin)
	[tmp,index] = min(abs(origin(n)-time));
	neworigin(n) = orid(index);
end;


