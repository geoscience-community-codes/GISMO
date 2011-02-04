function [w,successList] = dmc_station_meta(w,varargin)

%DMC_STATION_META adds station metadata to a waveform
%  W = DMC_STATION_META(W) looks up station metadata at the IRIS Data 
%  Management Center (DMC) based on the network, station and time of each 
%  waveform. These fields are added to the waveform. W may be of aritrary 
%  size and dimension. If a particular network-station-time combination is
%  not found at the DMC, that particular waveform is returned as is with no
%  additional fields.
%    STATION_STARTDATE        On date of the station (Matlab date format)
%    STATION_ENDDATE          Off date of the station (Matlab date format)
%    STATION_LATITUDE         latitude in degrees (double)
%    STATION_LONGITUDE        longitude in degress (double)
%    STATION_ELEVATION        elevation above sea level in meters (double)
%    STATION_NAME             full station name (text string)
%    STATION_NUMBEROFCHANNELS no. channels from station (double)
%        
%  [W,SUCCESS] = DMC_STATION_META(W) returns a matrix SUCCESS which is the
%  same size as W. SUCCESS is a mask containing ones and zeros that can be
%  used to identify which waveforms where successfully tagged with metadata
%  from the DMC. Reasons that the metadata lookup might fail include:
%       - this network-station is not on record at the DMC
%       - this network-station is not on record at the time range requested
%       - there was no internet connection at the time of connection
%       - the DMC's web services were down (rare, but does happen)
%
%  [W,SUCCESS] = DMC_STATION_META(W,'CheckEach') For speed, this function
%  only looks up a given network-station combination once and applies it 
%  to all elements of W that match the network-station. This is reasonable
%  for most W that might contain many waveforms from the same station and
%  general time range (e.g. a swarm of earthquakes over a few months). In
%  cases where the user suspects station data may have changed (e.g. a 
%  decade of earthquakes from an unfamiliar network), the CheckEach flag 
%  rerequests metadata for each individual waveform

%  AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
%  $Date: 2011-01-31 09:16:48 -0900 (Mon, 31 Jan 2011) $
%  $Revision: 259 $



% SETTINGS
httpServer = 'http://www.iris.edu/ws/station/';


% CHECK ARGUMENTS
if numel(varargin)>1
   error('dmc_station_meta:incorrectNumberArguments','Incorrect number of arguments'); 
end
if ~strcmpi(class(w),'waveform')
    error('dmc_station_meta:missingWaveform','First input must be a waveform object');
end
checkEach = 0;
if numel(varargin)>=1
    if strcmpi(varargin{1},'checkEach')
        checkEach = 1;
    end
end


% GET LIST OF UNIQUE CALLS TO SERVER
indexList = {[]};
if ~checkEach
    scnl = get(w,'SCNLOBJECT');
    netSta = cellstr(strcat([char(get(scnl,'NETWORK')) char(get(scnl,'STATION')) ]));
    uniqueSta = unique(netSta);
    for n = 1:length(uniqueSta)
        indexList(n) = {find(strcmpi(netSta,uniqueSta(n)))};
    end
else
    for n =1:length(w)
        indexList(n) = {n}; 
    end
end


% LOOP THROUGH THE SERVER CALLS
successList = zeros(size(w));
for n = 1:numel(indexList)
    index = indexList{n};
    scnlRequest = get(w(index(1)),'SCNLOBJECT');
    station = upper(get(scnlRequest,'STATION'));
    network = upper(get(scnlRequest,'NETWORK'));
    timeStart =  datestr(floor(get(w(index(1)),'START')),'yyyy-mm-dd');
    timeEnd   =  datestr(ceil(get(w(index(1)),'END')),'yyyy-mm-dd');
    httpLink = [httpServer 'query?net=' network '&sta=' station  '&timewindow=' timeStart ',' timeEnd '&level=sta'];
    %disp(httpLink);
    [s,success] = dmc_xml2struct(httpLink);
    if success
        w(index) = addfield(w(index),'STATION_STARTDATE',datenum(s.StaMessage.Station.StationEpoch.StartDate.Text,'yyyy-mm-ddTHH:MM:SS'));
        w(index) = addfield(w(index),'STATION_ENDDATE',datenum(s.StaMessage.Station.StationEpoch.EndDate.Text,'yyyy-mm-ddTHH:MM:SS'));
        w(index) = addfield(w(index),'STATION_LATITUDE',str2double(s.StaMessage.Station.StationEpoch.Lat.Text));
        w(index) = addfield(w(index),'STATION_LONGITUDE',str2double(s.StaMessage.Station.StationEpoch.Lon.Text));
        w(index) = addfield(w(index),'STATION_ELEVATION',str2double(s.StaMessage.Station.StationEpoch.Elevation.Text));
        w(index) = addfield(w(index),'STATION_NAME',char(s.StaMessage.Station.StationEpoch.Site.Country.Text));
        w(index) = addfield(w(index),'STATION_NUMBEROFCHANNELS',str2double(s.StaMessage.Station.StationEpoch.NumberChannels.Text));
        successList(index) = 1;
    end
end


