function allWaveforms = sac2waveform(sacStructure)
%SAC2WAVEFORM fill a waveform object from a sac header
%   waveform = sac2waveform(sacInfo) 
%     sacInfo is the output from readsacfile.m 
%
%    Each field from the header be either incorporated into the basic
%    structure of each waveform or will be added as user-defined fields.
%
%    See also:  waveform/private/readsacfile,
%    waveform/private/waveform2sacheader

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
%    modified from Michael Thorne (4/2004)  mthorne@asu.edu
% LASTUPDATE: 9/1/2009, improving readability in effort to be able to
% better maintain this code.

% first test to see if the sacInfo is indeed a sacfile
%---------------------------------------------------------------------------

allWaveforms = repmat(waveform,size(sacStructure));

for eachSacFile = 1:numel(sacStructure)
  sacInfo = sacStructure(eachSacFile);
  
  [fieldNames, fieldValues] =  parseHeader(sacInfo.header);
  
  % Take these results and create a structure with them
  %   fieldsPairedWithValues puts it all in an order that "struct()"
  %   understands. like so: {fieldname1,fieldval1,...,fieldNameN,fieldvalN}
  invalidFields = strcmp(fieldNames,'DUMMYVARIABLE');
  fieldNames = fieldNames(~invalidFields);
  fieldValues = fieldValues(~invalidFields);
  fieldsPairedWithValues = [fieldNames(:)'; fieldValues(:)'];
  headerDetails = struct(fieldsPairedWithValues{:});
  
  
  scnl = getSCNL(headerDetails); %network
  w = set(waveform,'scnlobject',scnl);
  
  for nrecs = 1:numel(fieldNames)
    thisfield = fieldNames{nrecs};
    thisvalue = fieldValues{nrecs};
    if ~isempty(thisvalue)
      w = addfield(w,thisfield,headerDetails.(thisfield));
    end
  end
  w = set(w,'start',getDate(headerDetails));
  w = set(w,'data',sacInfo.amplitudes);
  w = set(w,'freq', 1 ./ headerDetails.DELTA); %doesn't take into account ODELTA (observed freq)
  w = set(w,'units', idep2units(headerDetails.IDEP));
  w = clearhistory(w);
  allWaveforms(eachSacFile) = w;
end

% varargout = headerDetails;

function scnl = getSCNL(header)
%make scnl object from station channel and network.  no location info
%exists
scnl = scnlobject(deblank(header.KSTNM),... station
  deblank(header.KCMPNM), ... channel
  deblank(header.KNETWK)); %network

function mydate = getDate(header)
mydate= datenum(header.NZYEAR, 0, header.NZJDAY, ...
  header.NZHOUR, header.NZMIN, ...
  header.NZSEC + .001 * header.NZMSEC + header.B);

function measurementUnits = idep2units(IDEP)
% look up the proper units based on the SAC IDEP value
if isempty(IDEP), IDEP = 5; end
switch IDEP
  case 6 %idisp
    measurementUnits = 'nm';
  case 7 %ivel
    measurementUnits = 'nm / sec';
  case 8 %iacc
    measurementUnits = 'nm / sec / sec';
  case 50 %ivolts
    measurementUnits = 'volts';
  otherwise %case 5 = iunkn
    measurementUnits = 'Counts';
end

function [headerFields,value] = parseHeader(h)
emptyNumber = -12345;
emptyString = '-12345';

headerDefinitions = getHeaderDefinitions();
headerFields = headerDefinitions(:,1);
fieldType = headerDefinitions(:,2);
%startPositions = [headerDefinitions{:,3}];
%endPositions = (startPositions - 1) + [ headerDefinitions{:,4}];
value = cell(size(headerFields));

for thisField=1:numel(headerFields)
  %ensure each field is of the right type, and get rid of any default
  %values, replacing with '' or [] as appropriate
  
  value(thisField) = h(thisField);
  
  switch (fieldType{thisField})
    case 'double'
      if value{thisField} == emptyNumber
        value(thisField) = {[]};
      end
      
    case 'char'
      %get rid of all beginning/ending whitespace
      value(thisField) = {strtrim(char(value{thisField}))};
      
      if strcmpi(value(thisField),emptyString)
        value(thisField) = {''};
      end
      
    case 'integer'
      value(thisField) = {round(value{thisField})};
      if value{thisField} == emptyNumber
        value(thisField) = {[]};
      end
      
    case 'logical'
      if strcmp(value{thisField},emptyString)
        value(thisField) = {false};
      end
      value(thisField) = {logical(value{thisField})};
      
    otherwise
      error('Waveform:sac2waveform:unknownHeaderTypedef',...
        'Unknown type definition within the SAC header');
  end
end

function headerDefinitions = getHeaderDefinitions()
% Create a cell with one row for each variable represented in the SAC
% header.  Each row contains the information required to decode the header
% into a matlab variable.
%
% columns : variablename, type, startPos, length
% startPos is no longer used.

headerDefinitions={
  'DELTA','double',1,1;
  'DEPMIN','double',2,1;
  'DEPMAX','double',3,1;
  'SCALE','double',4,1;
  'ODELTA','double',5,1;
  'B','double',6,1;
  'E','double',7,1;
  'O','double',8,1;
  'A','double',9,1; %10 not represented
  'DUMMYVARIABLE','double',10,1;
  'T0','double',11,1;
  'T1','double',12,1;
  'T2','double',13,1;
  'T3','double',14,1;
  'T4','double',15,1;
  'T5','double',16,1;
  'T6','double',17,1;
  'T7','double',18,1;
  'T8','double',19,1;
  'T9','double',20,1;
  'F','double',21,1;
  'RESP0','double',22,1;
  'RESP1','double',23,1;
  'RESP2','double',24,1;
  'RESP3','double',25,1;
  'RESP4','double',26,1;
  'RESP5','double',27,1;
  'RESP6','double',28,1;
  'RESP7','double',29,1;
  'RESP8','double',30,1;
  'RESP9','double',31,1;
  'STLA','double',32,1;
  'STLO','double',33,1;
  'STEL','double',34,1;
  'STDP','double',35,1;
  'EVLA','double',36,1;
  'EVLO','double',37,1;
  'EVEL','double',38,1;
  'EVDP','double',39,1;
  'MAG','double',40,1;
  'USER0','double',41,1;
  'USER1','double',42,1;
  'USER2','double',43,1;
  'USER3','double',44,1;
  'USER4','double',45,1;
  'USER5','double',46,1;
  'USER6','double',47,1;
  'USER7','double',48,1;
  'USER8','double',49,1;
  'USER9','double',50,1;
  'DIST','double',51,1;
  'AZ','double',52,1;
  'BAZ','double',53,1;
  'GCARC','double',54,1; %55 - 56 not represented
  'DUMMYVARIABLE','double',55,1;
  'DUMMYVARIABLE','double',56,1;
  'DEPMEN','double',57,1;
  'CMPAZ','double',58,1;
  'CMPINC','double',59,1;
  'XMINIMUM','double',60,1;
  'XMAXIMUM','double',61,1;
  'YMINIMUM','double',62,1;
  'YMAXIMUM','double',63,1; %64 - 70 not represented
  'DUMMYVARIABLE','double',64,1;
  'DUMMYVARIABLE','double',65,1;
  'DUMMYVARIABLE','double',66,1;
  'DUMMYVARIABLE','double',67,1;
  'DUMMYVARIABLE','double',68,1;
  'DUMMYVARIABLE','double',69,1;
  'DUMMYVARIABLE','double',70,1;
  'NZYEAR','integer',71,1;
  'NZJDAY','integer',72,1;
  'NZHOUR','integer',73,1;
  'NZMIN','integer',74,1;
  'NZSEC','integer',75,1;
  'NZMSEC','integer',76,1;
  'NVHDR','integer',77,1;
  'NORID','integer',78,1;
  'NEVID','integer',79,1;
  'NPTS','integer',80,1; %81 not represented
  'DUMMYVARIABLE','integer',81,1;
  'NWFID','integer',82,1;
  'NXSIZE','integer',83,1;
  'NYSIZE','integer',84,1; %85 not represented
  'DUMMYVARIABLE','integer',85,1;
  'IFTYPE','integer',86,1;
  'IDEP','integer',87,1;
  'IZTYPE','integer',88,1; %89 not represented
  'DUMMYVARIABLE','integer',89,1;
  'IINST','integer',90,1;
  'ISTREG','integer',91,1;
  'IEVREG','integer',92,1;
  'IEVTYP','integer',93,1;
  'IQUAL','integer',94,1;
  'ISYNTH','integer',95,1;
  'IMAGTYP','integer',96,1;
  'IMAGSRC','integer',97,1; %98 - 105 not represeneted
  'DUMMYVARIABLE','integer',98,1;
  'DUMMYVARIABLE','integer',99,1;
  'DUMMYVARIABLE','integer',100,1;
  'DUMMYVARIABLE','integer',101,1;
  'DUMMYVARIABLE','integer',102,1;
  'DUMMYVARIABLE','integer',103,1;
  'DUMMYVARIABLE','integer',104,1;
  'DUMMYVARIABLE','integer',105,1;
  'LEVEN','logical',106,1;
  'LPSPOL','logical',107,1;
  'LOVROK','logical',108,1;
  'LCALDA','logical',109,1; %110 not represented.
  'DUMMYVARIABLE','integer',110,1;
  'KSTNM','char',111,8;
  'KEVNM','char',119,16;
  'KHOLE','char',135,8;
  'KO','char',143,8;
  'KA','char',151,8;
  'KT0','char',159,8;
  'KT1','char',167,8;
  'KT2','char',175,8;
  'KT3','char',183,8;
  'KT4','char',191,8;
  'KT5','char',199,8;
  'KT6','char',207,8;
  'KT7','char',215,8;
  'KT8','char',223,8;
  'KT9','char',231,8;
  'KF','char',239,8;
  'KUSER0','char',247,8;
  'KUSER1','char',255,8;
  'KUSER2','char',263,8;
  'KCMPNM','char',271,8;
  'KNETWK','char',279,8;
  'KDATRD','char',287,8;
  'KINST','char',295,8};