function [self, CAT] = COMCAT(varargin)
% READ_CATALOG.COMCAT load events from COMCAT

    debug.printfunctionstack('>')
    self = 0;

    % Process input arguments
    p = inputParser;
    p.addParamValue('startTime', now-30);  
    p.addParamValue('endTime', now);
    p.addParamValue('minimumMagnitude', 4, @isnumeric);
    p.addParamValue('maximumMagnitude', 10, @isnumeric);
    p.addParamValue('minimumLatitude', 32, @isnumeric);
    p.addParamValue('maximumLatitude', 45, @isnumeric);
    p.addParamValue('minimumLongitude', -125, @isnumeric);
    p.addParamValue('maximumLongitude', -106, @isnumeric);  
    p.addParamValue('minimumDepth', -5, @isnumeric);
    p.addParamValue('maximumDepth', 1000, @isnumeric); 
%     p.addParamValue('minimumRadius', [], @isnumeric);
%     p.addParamValue('maximumRadius', [], @isnumeric);     
%     p.addParamValue('boxcoordinates', @isnumeric);    %[minLat, maxLat, minLon, maxLon]   % use NaN as a wildcard
%     p.addParamValue('radialcoordinates', @isnumeric); % [Lat, Lon, MaxRadius, MinRadius]   % MinRadius is optional
    p.parse(varargin{:});
    p.Results
    
    % Call to queryCOMCAT
    CAT = queryCOMCAT('minlongitude', num2str(p.Results.minimumLongitude), ...
        'maxlongitude', num2str(p.Results.maximumLongitude), ...
        'minlatitude', num2str(p.Results.minimumLatitude), ...
        'maxlatitude', num2str(p.Results.maximumLatitude), ...
        'minmagnitude', num2str(p.Results.minimumMagnitude), ...
        'maxmagnitude', num2str(p.Results.maximumMagnitude), ...
        'mindepth', num2str(p.Results.minimumDepth), ...
        'maxdepth', num2str(p.Results.maximumDepth), ...   
        'starttime', datestr(p.Results.startTime, 'yyyy-mm-dd'), ...
        'endtime', datestr(p.Results.endTime, 'yyyy-mm-dd'))

    % Put into Catalog object
    self = Catalog(CAT.time, CAT.longitude, CAT.latitude, CAT.depth, CAT.mag, {}, {});
end


function CAT = queryCOMCAT(varargin)
    % The interface with the EQ server can only handle a max of 20000 output
    % lines, so to replace the whole catalog, you must do each year independently
    % (back several years, after which you can do multiple years).
    %
    % Provide paramter/value pairs to change the defaults.  All values must be
    % STRINGS (even if they are numbers).
    %
    % %% Parameters and Default Flags (all of California)
    % 'minlongitude','-125'
    % 'maxlongitude','-106'
    % 'minlatitude','32'
    % 'maxlatitude','45'
    % 'starttime','2020-01-01'
    % 'endtime','2020-02-01'
    % 'minmagnitude','-3'
    % 'maxmagnitude','10'
    % 'mindepth','-100'
    % 'maxdepth','1000'


    URL = 'https://earthquake.usgs.gov/fdsnws/event/1/query?';

    p = inputParser;
    p.addParameter('minlongitude','-125');
    p.addParameter('maxlongitude','-106');
    p.addParameter('minlatitude','32');
    p.addParameter('maxlatitude','45');
    p.addParameter('starttime','2020-01-01');
    p.addParameter('endtime','2020-02-01');
    p.addParameter('minmagnitude','-3');
    p.addParameter('maxmagnitude','10');
    p.addParameter('mindepth','-100');
    p.addParameter('maxdepth','1000');

    % varargin
    p.parse(varargin{:});
    p.Results
        

    allParams = [fieldnames(p.Results) repmat({'='},10,1) struct2cell(p.Results),repmat({'&'},10,1)]';
    URLfull = [URL,horzcat(allParams{:}),'&format=csv&orderby=time'];

    outfilename = websave('queryCOMCAT.csv',URLfull);
    CAT = readtable('queryCOMCAT.csv');
    CAT.time = datenum(CAT.time,'yyyy-mm-ddTHH:MM:SS.FFFZ');
end