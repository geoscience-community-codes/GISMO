function [response] = response_get_from_db(station, channel, time, frequencies, dbName)

%DB_GET_RESPONSE Get instrument response from database.
%  RESPONSE = DB_GET_RESPONSE(STATION, CHANNEL,TIME, FREQUENCIES, DBNAME) 
%  returns a structure which contains the full instrument response for the
%  input STATION and CHANNEL at the given TIME. TIME is specified in
%  standard Matlab serial date (output of DATENUM). FREQUENCIES is a vector
%  of frequencies, specified in Hz, for which the response will be
%  calculated. DBNAME is the name of the database which must contain a
%  sensor, instrument and calibration table.
%
% Specific assignments from  Antleope databases: 
%       time:        Matlab time used in database query
%       calib:       Calib value from the **calibration** table
%       source:      The name of the actual response file
%       status:      The status line returned by dbfilename
%
%  The salient components of this code are from Kent Lindquist's
%  Antelope Toolbox for Matlab.
%
%
% see also response_structure_description

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
%         (includes ideas borrowed from G. Thompson's db2response.m)
% $Date:  $
% $Revision: $ 




% CHECK ARGUMENTS
% % % % % % if ~antelope_exists
% % % % % %     error('This function requires Antelope');
% % % % % % end
if (nargin ~= 5)
    error('Incorrect number of arguments');
end
% if  ~exist([dbName '.sensor'], 'file') ||  ~exist([dbName '.instrument'], 'file') ||  ~exist([dbName '.calibration'], 'file')
%     error(['Database ' dbName '  is missing sensor, instrument and/or calibration tables']);
% end
if ~isvector(frequencies)
    error('FREQUENCIES argument must be a 1xn or nx1 vector');
end
frequencies = reshape(frequencies,1,numel(frequencies));





% GET DATABASE RECORDS
try
    db = dbopen(dbName,'r');
catch
    error(['Could not open database: ' dbname]);
end
dbSensor = dblookup_table(db, 'sensor');
if ~dbquery(dbSensor,'dbTABLE_PRESENT')
    error('Database does not contain a sensor table.');
end
epochTime = datenum2epoch(time);
db = dbsubset(dbSensor, sprintf('sta=="%s" && chan=="%s" && time<%f && endtime>%f',station, channel, epochTime, epochTime));
if dbquery(db,'dbRECORD_COUNT')==0     % check for open channels
    db = dbsubset(db, sprintf('sta=="%s" && chan=="%s" && time<%f',station, channel, epochTime));
end
dbInst = dblookup_table(db, 'instrument');
if ~dbquery(dbInst,'dbTABLE_PRESENT')
    error('Database does not contain a sensor table.');
end
dbCalib = dblookup_table(db, 'calibration');
if ~dbquery(dbCalib,'dbTABLE_PRESENT')
    error('Database does not contain a sensor table.');
end
db = dbjoin(db, dbInst);
db = dbjoin(db, dbCalib);



% HANDLE EXCEPTIONS
if dbquery(db,'dbRECORD_COUNT')>1
    warning(['Database contains more than one response for ' station '_' channel ' at ' datestr(time,31)  '. Using first one']);
elseif dbquery(db,'dbRECORD_COUNT')==0
    error(['Database does not contain response information for ' station '_' channel ' at ' datestr(time,31)]);
end



% INITIALIZE THE OUTPUT ARGUMENT
response.scnl = scnlobject(station,channel,'','');
response.time = time;
response.frequencies = [];
response.values = [];
response.calib = [];
response.units = [];
response.sampleRate = [];
response.source = [];
response.status = [];



% READ IN RESPONSE INFO (POSITIVE VALUES ONLY)
db.record = 0;
[response.sampleRate, response.calib, segtype,dir,dfile] = dbgetv(db, 'samprate', 'calib', 'segtype','dir','dfile');
[response.units] = segtype2units(segtype);
%response.frequencies = 0 : response.sampleRate/numSamples : response.sampleRate/2;
response.frequencies = frequencies;
[response.respFile,response.status] = dbfilename(db);
if exist(response.respFile, 'file')
    respObject = dbresponse(response.respFile);
    response.values = eval_response(respObject, 2 * pi * response.frequencies);
    free_response(respObject);
else
    warning(['File ' response.respFile ' cannot be opened.']);
    disp(['** Response for ' station '_' channel ' at ' datestr(time,31) ' will be set to an array of zeros']);
    response.values = 0 * response.frequencies;
end
dbclose(db);
response.frequencies = reshape( response.frequencies , numel(response.frequencies) , 1 ) ;
response.values = reshape( response.values , numel(response.values) , 1 ) ;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONVERT SEGTYPE TO UNITS
%   (this function was lifted from @waveform/private/load_antelope)
%
function [units, type_of_data] = segtype2units(segtype)
%'segtype' in antelope datasets indicate the natural units of the detector
segTypes = 'ABDHIJKMPRSTVWabcdfhimnoprstuvw-';
segUnits = {'A','nm / sec / sec','acceleration';
  'B', '25 mw / m / m','UV (sunburn) index(NOAA)';
  'D', 'nm', 'displacement';
  'H','Pa','hydroacoustic';
  'I','Pa','infrasound';
  'J','watts','power (Joulses/sec) (UCSD)';
  'K','kPa','generic pressure (UCSB)';
  'M','mm','Wood-Anderson drum recorder';
  'P','mb','barometric pressure';
  'R','mm','rain fall (UCSD)';
  'S','nm / m','strain';
  'T','sec','time';
  'V','nm / sec','velocity';
  'W','watts / m / m', 'insolation';
  'a','deg', 'azimuth'
  'b','bits/ sec', 'bit rate';
  'c','counts', 'dimensionless integer';
  'd','m', 'depth or height (e.g., water)';
  'f','micromoles / sec / m /m', 'photoactive radiation flux';
  'h','pH','hydrogen ion concentration';
  'i','amp','electric curent'
  'm','bitmap','dimensionless bitmap';
  'n','nanoradians','angle (tilt)';
  'o','mg/l','diliution of oxygen (Mark VanScoy)';
  'p','percent','percentage';
  'r','in','rainfall (UCSD)';
  's','m / sec', 'speed (e.g., wind)';
  't','C','temperature';
  'u','microsiemens/cm','conductivity';
  'v','volts','electric potential';
  'w','rad / sec', 'rotation rate';
  '-','null','null'};
if ~ismember(segtype,segTypes)
  segtype=  '-';
end
thisseg = find(segtype==segTypes);
units = segUnits{thisseg,2};
type_of_data = segUnits{thisseg,3};



