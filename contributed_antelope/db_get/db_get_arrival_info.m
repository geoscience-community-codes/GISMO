function [arrival,assoc,origin,W] = db_get_arrival_info(arid,dbname,varargin)
%DB_GET_ARRIVAL_INFO  Retrieve arrival, assoc, and origin info for ARIDs.
%
%   [ARRIVAL, ASSOC, ORIGIN] = DB_GET_ARRIVAL_INFO(ARID, DBNAME)
%   [ARRIVAL, ASSOC, ORIGIN, W] = DB_GET_ARRIVAL_INFO(ARID, DBNAME, W)
%
%   Returns pertinent fields from the CSS3 arrival, assoc, and origin
%   tables for the given vector of arrival IDs (arid).
%
%   If a waveform object W is provided, the origin, arrival, and assoc
%   metadata are injected into each waveform using addfield().
%
%   This is a LEGACY WORKFLOW-LEVEL utility retained for backward
%   compatibility. Internally, all database access is now routed through
%   core/+antelope functions:
%
%       • antelope.dbgetarrivals
%       • antelope.dbgetorigins
%
%   Unlike db_get_origin_info, arrivals must currently be indexed by ARID
%   (not by time).
%
%   Author: Michael West, GI/UAF
%   Refactored: G. Thompson (GISMO modernization)
%

%---------------------------
% Input validation
%---------------------------
if ~isnumeric(arid)
    error('First input must be arrival ids (arid)');
end

arrival.arid = reshape(arid, numel(arid), 1);

%---------------------------
% Optional waveform argument
%---------------------------
W = [];
if numel(varargin) == 1
    W = varargin{1};
    if ~isa(W,'waveform')
        error('Third argument must be a WAVEFORM object');
    end
elseif numel(varargin) > 1
    error('Too many input arguments');
end

%==========================================================================
% 1) GET ARRIVALS (core backend)
%==========================================================================

A = antelope.dbgetarrivals(dbname,'arid',arrival.arid);

% Map arrival fields
arrival.sta   = reshape({A.sta}.',[],1);
arrival.chan  = reshape({A.chan}.',[],1);
arrival.time_epoch = reshape([A.time].',[],1);
arrival.time_matlab = datenum(strtime(arrival.time_epoch));
arrival.iphase = reshape({A.iphase}.',[],1);
arrival.deltim = reshape([A.deltim].',[],1);

%==========================================================================
% 2) GET ASSOC INFO (via arrivals)
%==========================================================================

assoc.delta   = reshape([A.delta].',[],1);
assoc.seaz    = reshape([A.seaz].',[],1);
assoc.esaz    = reshape([A.esaz].',[],1);
assoc.timeres = reshape([A.timeres].',[],1);

%==========================================================================
% 3) GET ORIGINS (core backend)
%==========================================================================

orids = unique([A.orid]);
O = antelope.dbgetorigins(dbname,'orid',orids);

% Build map orid → origin struct
orid_map = containers.Map('KeyType','double','ValueType','any');
for k = 1:numel(O)
    orid_map(O(k).orid) = O(k);
end

% Resolve per-arrival origins
n = numel(arrival.arid);

origin.lat        = nan(n,1);
origin.lon        = nan(n,1);
origin.depth      = nan(n,1);
origin.time_epoch = nan(n,1);
origin.ml         = nan(n,1);
origin.orid       = nan(n,1);

for i = 1:n
    this_orid = A(i).orid;
    if isKey(orid_map,this_orid)
        o = orid_map(this_orid);
        origin.lat(i)        = o.lat;
        origin.lon(i)        = o.lon;
        origin.depth(i)      = o.depth;
        origin.time_epoch(i)= o.time;
        origin.ml(i)         = o.ml;
        origin.orid(i)       = o.orid;
    end
end

origin.time_matlab = datenum(strtime(origin.time_epoch));

%==========================================================================
% 4) DERIVED FIELDS
%==========================================================================

assoc.traveltime = arrival.time_matlab - origin.time_matlab;

%==========================================================================
% 5) OPTIONAL WAVEFORM ENRICHMENT (LEGACY CONTRACT)
%==========================================================================

if ~isempty(W)
    for i = 1:numel(W)

        disp(['Retrieving origin, arrival and assoc info for orid: ' ...
              num2str(origin.orid(i)) ' ... '])

        % ---- Origin ----
        W(i) = addfield(W(i),'ORIGIN_LAT',origin.lat(i));
        W(i) = addfield(W(i),'ORIGIN_LON',origin.lon(i));
        W(i) = addfield(W(i),'ORIGIN_DEPTH',origin.depth(i));
        W(i) = addfield(W(i),'ORIGIN_TIME_EPOCH',origin.time_epoch(i));
        W(i) = addfield(W(i),'ORIGIN_ML',origin.ml(i));
        W(i) = addfield(W(i),'ORIGIN_TIME_MATLAB',origin.time_matlab(i));
        W(i) = addfield(W(i),'ORIGIN_ORID',origin.orid(i));

        % ---- Arrival ----
        W(i) = addfield(W(i),'ARRIVAL_TIME_EPOCH',arrival.time_epoch(i));
        W(i) = addfield(W(i),'ARRIVAL_TIME_MATLAB',arrival.time_matlab(i));
        W(i) = addfield(W(i),'ARRIVAL_IPHASE',arrival.iphase{i});
        W(i) = addfield(W(i),'ARRIVAL_DELTIME',arrival.deltim(i));

        % ---- Assoc ----
        W(i) = addfield(W(i),'ASSOC_DELTA',assoc.delta(i));
        W(i) = addfield(W(i),'ASSOC_SEAZ',assoc.seaz(i));
        W(i) = addfield(W(i),'ASSOC_ESAZ',assoc.esaz(i));
        W(i) = addfield(W(i),'ASSOC_TIMERES',assoc.timeres(i));

    end
end

end
