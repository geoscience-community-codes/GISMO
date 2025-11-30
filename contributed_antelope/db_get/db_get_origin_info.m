function [origin,W] = db_get_origin_info(INorigin,dbname,varargin)
%DB_GET_ORIGIN_INFO  Retrieve origin info by ORID or by time.
%
%   ORIGIN = DB_GET_ORIGIN_INFO(EVENT, DBNAME)
%   [ORIGIN, W] = DB_GET_ORIGIN_INFO(EVENT, DBNAME, W)
%
%   EVENT may be:
%     • A numeric vector of ORIDs
%     • A character array of date/time strings (one per row)
%
%   If time strings are given, the nearest PREFERRED origin is returned.
%   Using ORIDs is more precise, since ORIDs may change between catalogs.
%
%   If WAVEFORM is supplied, origin metadata are injected into each
%   waveform object via addfield().
%
%   This is a LEGACY WORKFLOW-LEVEL utility, refactored to use:
%       • antelope.dbgetorigins
%
%   Author: Michael West, GI/UAF
%   Refactored: G. Thompson (GISMO modernization)
%

%==================================================================
% 1) RESOLVE INPUT ORIGINS
%==================================================================

if isnumeric(INorigin)

    origin.orid = reshape(INorigin, numel(INorigin), 1);

elseif ischar(INorigin)

    % Convert time strings to epoch
    nevt = size(INorigin,1);
    t_epoch = zeros(nevt,1);
    for n = 1:nevt
        t_epoch(n) = str2epoch(INorigin(n,:));
    end

    % Resolve to nearest preferred orid
    origin.orid = reshape(getorids_refactored(t_epoch,dbname), nevt, 1);

else
    error('First input must be either origin ids or string-formatted times');
end

%==================================================================
% 2) OPTIONAL WAVEFORM INPUT
%==================================================================

W = [];
if numel(varargin) == 1
    W = varargin{1};
    if ~isa(W,'waveform')
        error('Third argument must be a WAVEFORM object');
    end
elseif numel(varargin) > 1
    error('Too many arguments');
end

if nargout==2 && nargin~=3
    error('Mismatched number of input and/or output arguments');
end

%==================================================================
% 3) LOAD ORIGINS (CORE BACKEND)
%==================================================================

O = antelope.dbgetorigins(dbname,'orid',origin.orid);

% Build ORID → origin map
omap = containers.Map('KeyType','double','ValueType','any');
for k = 1:numel(O)
    omap(O(k).orid) = O(k);
end

%==================================================================
% 4) POPULATE OUTPUT STRUCTURE
%==================================================================

n = numel(origin.orid);

origin.lat        = nan(n,1);
origin.lon        = nan(n,1);
origin.depth      = nan(n,1);
origin.time_epoch = nan(n,1);
origin.ml         = nan(n,1);

for i = 1:n
    if isKey(omap,origin.orid(i))
        o = omap(origin.orid(i));
        origin.lat(i)        = o.lat;
        origin.lon(i)        = o.lon;
        origin.depth(i)      = o.depth;
        origin.time_epoch(i)= o.time;
        origin.ml(i)         = o.ml;
    end
end

origin.time_matlab = datenum(strtime(origin.time_epoch));

%==================================================================
% 5) OPTIONAL WAVEFORM ENRICHMENT (LEGACY CONTRACT)
%==================================================================

if ~isempty(W)
    for i = 1:numel(W)

        disp(['Retrieving origin info for orid: ' num2str(origin.orid(i)) ' ... '])

        W(i) = addfield(W(i),'ORIGIN_LAT',origin.lat(i));
        W(i) = addfield(W(i),'ORIGIN_LON',origin.lon(i));
        W(i) = addfield(W(i),'ORIGIN_DEPTH',origin.depth(i));
        W(i) = addfield(W(i),'ORIGIN_TIME_EPOCH',origin.time_epoch(i));
        W(i) = addfield(W(i),'ORIGIN_ML',origin.ml(i));
        W(i) = addfield(W(i),'ORIGIN_TIME_MATLAB',origin.time_matlab(i));
        W(i) = addfield(W(i),'ORIGIN_ORID',origin.orid(i));

    end
end

end

%======================================================================
% LOCAL UTILITY — RESOLVE NEAREST PREFERRED ORIGIN BY TIME (REFACTORED)
%======================================================================
function neworigin = getorids_refactored(origin_epoch, dbname)

% Load preferred origins only
O = antelope.dbgetorigins(dbname);

orid_all  = [O.orid];
time_all  = [O.time];   % still in epoch inside core structure

neworigin = zeros(size(origin_epoch));

for n = 1:numel(origin_epoch)
    [~,index] = min(abs(origin_epoch(n) - time_all));
    neworigin(n) = orid_all(index);
end

end
