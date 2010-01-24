function resp = response_read(sta,chan,dbname)

%RESPONSE_READ   Read instrument response from Antelope database.
%  RESP = RESPONSE_READ(STA,CHAN,DBNAME) opens a database and reads in
%  response information for the station and channel specified by STA_CHAN.
%  The output RESP is a dbresponse object as defined in the Matlab toolbox
%  for Antelope. RESPONSE_READ is really just a convenient wrapper.


% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks




% TEST FOR ANTELOPE
if ~exist('dbopen','file') ||  ~exist('trload_css','file'); 
  error('Antelope toolbox not found. RESPONSE_READ requires this toolbox.');
end


% OPEN DB TABLES
try
    db = dbopen(dbname,'r');
    db=dblookup_table(db,'sensor');
    dbinst=dblookup_table(db,'instrument');
    db=dbjoin(db,dbinst);
catch
    error(['Database ' dbname ' could not be opened or did not contain sensor and instrument tables.']);
end


% READ RESPONSE OBJECT
try
    db.record=dbfind(db,['sta == "' sta '" && chan == "' chan '"']);
    respfile = dbfilename(db);
    resp = dbresponse(respfile);
catch
    error(['No repsonse could be extracted for ' sta '_' chan '.']);
end
