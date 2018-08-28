function dd_process_scp(dbname,scpfile,varargin)

%DD_PROCESS_SCP Process correlations by station and channel
%
% DD_PROCESS_SCP(DBNAME,SCP_FILE) cross correlates arrivals for the same
% phase and station. SCP_FILE follows the format written by the program
% DD_MAKE_SCP. For each line in an SCP_FILE, DD_PROCESS_SCP reads all
% available waveforms, performs cross correlations and stores the results
% is a temporary directory. If no directory name is specified the files are
% written into TMP_MATDD_CORR.
%
% DD_PROCESS_SCP(DBNAME,SCP_FILE,DIRNAME) same as above, except
% that the correlation files are written into a directory named DIRNAME.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$ 



% CHECK FOR VALID DATABASE
try
    db = dbopen(dbname,'r');
    dbclose(db);
catch
    error(['Could not open database: ' dbname]);
end


% CHECK INPUTS
if nargin==3
    directoryname = varargin{1};
elseif nargin==2
    directoryname = 'TMP_MATDD_CORR';
else
    error('Incorrect number of inputs');
end


% READ AND PARSE SCP FILE
try
    fid = fopen(scpfile);
catch
   error(['Unable to open scp file: ' scpfile]); 
end
% check for header file
C = textscan(fid,'%s %s %s %s %s %s %s %s %s %s',1);
test1 = C{4};
test2 = C{8};
test1 = str2num(test1{1});
test2 = str2num(test2{1});
if ~isempty(test1) || ~isempty(test2)
    error('SCP file is formatted incorrectly or missing a header line');
end
C = textscan(fid,'%s %s %s %n %n %n %n %n %n %n');
fclose(fid);
sta = C{1};
chan = C{2};
iphase = C{3};
npick = C{4};
pretrig = C{5};
posttrig = C{6};
minCorr = C{7};
maxLag = C{8};
hpf = C{9};
lpf = C{10};
clear C test1 test2 


% CREATE OUTPUT DIRECTORY IF NEEDED
tmp = exist(directoryname,'dir');
if (tmp~=7)
    disp(['Creating directory: ' directoryname ' ...']);
    mkdir(directoryname);
end
    

% CYCLE THROUGH ALL SCP LINES
for n =1:length(sta)
    if npick(n)>3
        [W,tracesFound] = load_by_orid(dbname,sta{n},chan{n},iphase{n},pretrig(n),posttrig(n));
        if tracesFound && ~isempty(W)
            [linenum,linestr,C,minimumCorrelation,maximumLag] = correlate(W,pretrig(n),posttrig(n),hpf(n),lpf(n),sta{n},iphase{n},minCorr(n),maxLag(n));
            save([directoryname '/corr_' sta{n} '_' chan{n} '_' iphase{n}],'C','linenum','linestr','minimumCorrelation','maximumLag');
        end
    end
end





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD DATA FOR AN INDIVIDUAL STATION, CHANNEL, IPHASE TRIPLET

function [W,tracesFound] = load_by_orid(dbname,STA,CHAN,IPHASE,pretrig,posttrig)


W = [];

% LOAD VALUES FROM DATABASE
try
    db = dbopen(dbname,'r');
    db = dblookup_table(db,'origin');
    db1 = dblookup_table(db,'event');
    db = dbjoin(db,db1);
    db = dbsubset(db,'orid==prefor');
    db1 = dblookup_table(db,'assoc');
    db = dbjoin(db,db1);
    db1 = dblookup_table(db,'arrival');
    db = dbjoin(db,db1);
catch
    error(['Could not open all required database tables in: ' dbname]);
end

% subset required rows
db = dbsubset(db,['sta=="' STA '"']);
db = dbsubset(db,['iphase=="' IPHASE '"']);
tracesFound= dbquery(db,'dbRECORD_COUNT')
if tracesFound == 0
    warning(['No arrivals found. Skipping ' STA '_' CHAN ' ' IPHASE']);
    return
end

    
% nrecords = dbquery(db,'dbRECORD_COUNT')
[or_time,orid,ar_time] = dbgetv(db,'origin.time','orid','arrival.time');
ar_time = epoch2datenum(ar_time);
or_time = epoch2datenum(or_time);
dbclose(db)



% LOAD WAVEFORMS
disp(['Loading ' STA '_' CHAN ' ' IPHASE ' phase (' num2str(numel(ar_time)) ' arrivals) ...']);
ds = datasource('antelope',dbname);
for n = 1:numel(ar_time)
    scnl = scnlobject(STA,CHAN);
    startTime = ar_time(n)+(pretrig-3)/86400;
    endTime = ar_time(n)+(posttrig+3)/86400;
   try
      w = waveform(ds,scnl,startTime,endTime);
      w = addfield(w,'ORID',orid(n));
      w = addfield(w,'ORIGIN_TIME',or_time(n));
      w = addfield(w,'ARRIVAL_TIME',ar_time(n));
      W = cat(1,W,w);
   catch
      disp(['    Not able to load arrival at ' datestr(ar_time(n),31) '   (no. ' num2str(n) ')' ]);
   end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CORRELATE WAVEFORMS

function [linenum,linestr,C,minimumCorrelation,maximumLag] = correlate(W,pretrig,posttrig,hpf,lpf,sta,iphase,minCorr,maxLag)

orid = get(W,'ORID');
ar_time = get(W,'ARRIVAL_TIME');
C = correlation(W,ar_time);
C = butter(C,[hpf lpf]);
C = xcorr(C,[pretrig posttrig],'interp');
corr = get(C,'CORR');
lag = get(C,'LAG');


% PRE-ALLOCATE ARRAYS
numberOfRows = sum(1:numel(orid)-1);
linestr = repmat({'placeHolder'},[numberOfRows 1]);
linenum = zeros(numberOfRows,1);
minimumCorrelation = -999 * ones(numberOfRows,1);
maximumLag = -999 * ones(numberOfRows,1);


% WRITE STRINGS OF CORRELATION VALUES
rowNumber = 0;
fprintf('   writing cross correlation pairs:       ');
for n = 1:length(orid)
    for m = n+1:length(orid)
        rowNumber = rowNumber+1;
        params = sprintf('%-8s %6.3f %6.3f %-3s' , sta , lag(n,m) , (corr(n,m))^2 , iphase );
        linenum(rowNumber,1:2) = [orid(n) orid(m)];
        linestr(rowNumber) = {params};
        minimumCorrelation(rowNumber) = minCorr;
        maximumLag(rowNumber) = maxLag;
    end
    fprintf('\b\b\b\b\b\b%5.0f%%',rowNumber/numberOfRows*100);
end
fprintf('\n');


