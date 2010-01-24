function dd_process_scp(dbname,scpfile,varargin)

%    dd_process_scp('dbclust','matdd_scp.txt')

% DD_PROCESS_SCP(DBNAME,SCP_FILE) cross correlates arrivals for the same
% phase and station. SCP_FILE follows the format written by the program
% DD_MAKE_SCP. For each line in an SCP_FILE, DD_PROCESS_SCP reads all
% available waveforms, performs cross correlations and stores the results
% is a temporary directory. If no directory name is specified the files are
% written into TMP_MATDD_CORR.
%
% DD_PROCESS_SCP(DBNAME,SCP_FILE,DIRNAME) same as above, except
% that the correlation files are written into a directory named DIRNAME.

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks



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

% directoryname = 'TMP_MATDD_CORR';
% scpfile = 'matdd_scp.txt';


% READ AND PARSE SCP FILE
try
    fid = fopen(scpfile);
catch
   error(['Unable to open scp file: ' scpfile]); 
end
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
minC = C{7};
maxL = C{8};
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
        W = load_by_orid(dbname,sta{n},chan{n},iphase{n},pretrig(n),posttrig(n));
        [linenum,linestr,C] = correlate(W,pretrig(n),posttrig(n),hpf(n),lpf(n),sta{n},iphase{n});
        save([directoryname '/corr_' sta{n} '_' chan{n} '_' iphase{n}],'C','linenum','linestr');
    end
end





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAD DATA FOR AN INDIVIDUAL STATION, CHANNEL, IPHASE TRIPLET

function W = load_by_orid(dbname,STA,CHAN,IPHASE,pretrig,posttrig)


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
db = dbsubset(db,['chan=="' CHAN '"']);
db = dbsubset(db,['iphase=="' IPHASE '"']);

% nrecords = dbquery(db,'dbRECORD_COUNT')
[sta,chan,or_time,orid,ar_time,arid,iphase] = dbgetv(db,'sta','chan','origin.time','orid','arrival.time','arid','iphase');
ar_time = epoch2datenum(ar_time);
or_time = epoch2datenum(or_time);
dbclose(db)

% save

% LOAD WAVEFORMS
disp(['Loading ' STA '_' CHAN ' ' IPHASE ' phase (' num2str(numel(ar_time)) ' arrivals) ...']);
W = [];
for n = 1:numel(ar_time)
   try
      w = waveform( sta{n} , chan{n} , ar_time(n)+(pretrig-3)/86400 , ar_time(n)+(posttrig+3)/86400 , dbname );
      w = addfield(w,'ORID',orid(n));
      w = addfield(w,'ORIGIN_TIME',or_time(n));
      w = addfield(w,'ARRIVAL_TIME',ar_time(n));
      W = cat(1,W,w);
   catch
      disp(['    Not able to load arrival at ' datestr(ar_time(n),31) ]);
   end
end

%%%%%%%% TESTING ONLY
% c = correlation('demo');
% r = round(48*rand(1))+2;
% r = round(98*rand(r,1))+2;
% c = subset(c,r);
% c = adjusttrig(c,2);
% c = crop(c,pretrig-3,posttrig+3);
% W = get(c,'WAVEFORM');
% ntrace = length(W);
% for n = 1:ntrace
%    W(n) = addfield(W(n),'ORID',3002012+n); 
% end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CORRELATE WAVEFORMS

function [linenum,linestr,C] = correlate(W,pretrig,posttrig,hpf,lpf,sta,iphase)

orid = get(W,'ORID');
ar_time = get(W,'ARRIVAL_TIME');
C = correlation(W,ar_time);
C = butter(C,[hpf lpf]);
C = xcorr(C,[pretrig posttrig],'interp');
corr = get(C,'CORR');
lag = get(C,'LAG');
%plot(C,'corr');

linestr = [];
linenum = [];
for n = 1:length(orid)
    for m = n+1:length(orid)
        %params = [sta '    ' iphase '    ' num2str(lag(n,m),'%4.3f') '    ' num2str(corr(n,m),'%4.3f') ];
        params = sprintf('%-8s %6.3f %6.3f %-3s' , sta , lag(n,m) , (corr(n,m))^2 , iphase );
        linenum = cat(1,linenum,[orid(n) orid(m)] );
        linestr = cat(1,linestr,{params});
    end
end


