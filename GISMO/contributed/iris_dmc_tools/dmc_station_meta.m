function [w,successList] = dmc_station_meta(w,varargin)

% 
%
% flag to check stations at all times?
%
%
% check input as a waveform
% get unique NS's
% initialize success mask
% loop through unique NS's
       % function: retrieve_station_metadata
            % ...
            % ...
            % ...
       % find all matching NS
       % add fields to waveform
       % create success mask
       % percentage counter
% reorder and reshape to original size



% SETTINGS
httpServer = 'http://www.iris.edu/ws/station/';


% CHECK ARGUMENT
if numel(varargin)>1
   error('dmc_station_meta:incorrectNumberArguments','Incorrect number of arguments'); 
end
if ~strcmpi(class(w),'waveform')
    error('dmc_station_meta:missingWaveform',...
        'First input must be a waveform object');
end


checkTime = 0;
if numel(varargin)>=1
    if strcmpi(varargin{1},'checkTime')
        checkTime = 1;
    end
end

% GET LIST OF UNIQUE CALLS TO SERVER
% note that this approach lumps waveforms regardless
% of their time attribute. This could be dangerous. Could flag it.

if checkTime
    for n =1:length(w)
        fList(n) = {n};  % a bit kludgy
    end
else
    scnl = get(w,'SCNLOBJECT');
    netSta = cellstr(strcat([char(get(scnl,'NETWORK')) char(get(scnl,'STATION')) ]));
    uniqueSta = unique(netSta);
    for n = 1:length(uniqueSta)
        fList(n) = {find(strcmpi(netSta,uniqueSta(n)))};
    end
end

% LOOP THROUGH THE SERVER CALLS
successList = zeros(size(w));
for n = 1:numel(fList)
    f = fList{n};
    scnlRequest = get(w(f(1)),'SCNLOBJECT');
    station = upper(get(scnlRequest,'STATION'));
    network = upper(get(scnlRequest,'NETWORK'));
    httpLink = [httpServer 'query?net=' network '&sta=' station '&level=sta'];
    disp(httpLink);
    %httpLink = 'query_AV_CRP.xml'; %%%%%%%%%%%%%%%%%%%%
    [s,success] = dmc_xml2struct(httpLink);
    if success
        w(f) = addfield(w(f),'STATION_STARTDATE',datenum(s.StaMessage.Station.StationEpoch.StartDate.Text,'yyyy-mm-ddTHH:MM:SS'));
        w(f) = addfield(w(f),'STATION_ENDDATE',datenum(s.StaMessage.Station.StationEpoch.EndDate.Text,'yyyy-mm-ddTHH:MM:SS'));
        w(f) = addfield(w(f),'STATION_LATITUDE',str2double(s.StaMessage.Station.StationEpoch.Lat.Text));
        w(f) = addfield(w(f),'STATION_LONGITUDE',str2double(s.StaMessage.Station.StationEpoch.Lon.Text));
        w(f) = addfield(w(f),'STATION_ELEVATION',str2double(s.StaMessage.Station.StationEpoch.Elevation.Text));
        w(f) = addfield(w(f),'STATION_NAME',char(s.StaMessage.Station.StationEpoch.Site.Country.Text));
        w(f) = addfield(w(f),'STATION_NUMBEROFCHANNELS',str2double(s.StaMessage.Station.StationEpoch.NumberChannels.Text));
        successList(f) = 1;
    end
end








% %%%%%%%%%%%%%%%%%%%%%%
% 
% tmp = xml2struct('query_AV_CRP.xml')
% lat = str2double(tmp.StaMessage.Station.StationEpoch.Lat.Text);
% lon = str2double(tmp.StaMessage.Station.StationEpoch.Lon.Text);
% 
% httpLink = 'http://www.iris.edu/ws/station/query?net=AV&sta=CRP&level=sta';
% 
% [s,success] = urlread(httpLink);
% [s,success] = urlread(surrogate_jar);%can we read the usgs.jar? if not don't bother to add it.
% 
% tmp = xml2struct('http://www.iris.edu/ws/station/query?net=AV&sta=CRP&level=sta')

% dmc_station_meta(w)