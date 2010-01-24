function dd_make_scp(dbname,varargin)

% dd_make_scp('dbclust')

% DD_MAKE_SCP(DBNAME) reads database DBNAME and writes out a text
% files OUTFILE containing one row for each unique combination of station,
% channel and iphase in the database. The database must contain a the
% tables: origin, event, assoc and arrival. Only preferred origins are
% included. All remaining columns in the 'SCP' file are filed with default
% values.
%
% DD_MAKE_SCP(DBNAME,PRETRIG,POSTTRIG,MINCORR,MAXLAG,HPF,LPF,PREFHORZ,SCPFILE)
% writes the same file using the specified pre-trigger times, post-trigger,
% minimum correlation values, maximum lag times, high and low pass filter,
% preferred horizontal component, and name of output scp file.
% 
% DD_MAKE_SCP(DBNAME) is the same as
% DD_MAKE_SCP(DBNAME, -0.3, 0.5, 0.7, 0.2, 2, 20, 'N', 'matdd_scp.txt')
%
% SCP OUTPUT FILE FORMAT
%   col 1       station 
%   col 2       channel
%   col 3       iphase
%   col 4       no. of arrivals matching this sta/chan/iphase combo
%   col 5       pre-trig (time included before the pick time)
%   col 6       post-trig (time included after the pick time)
%   col 7       The minimum correlation value required for inclusion
%   col 8       The maximum lag time required for inclusion
%   col 9-10    Bandpass filter applied to waveforms before correlating

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks




%% SET CONSTANTS
if nargin==4
    pretrig = varargin{1};
    posttrig = varargin{2};
    minC = varargin{3};
    maxL = varargin{4};
    hpf = varargin{5};
    lpf = varargin{6};
    prefhorz = varargin{7};
    outfile = varargin{8};
elseif nargin==1
    pretrig = -0.3;
    posttrig = 0.5;
    minC = 0.7;
    maxL = 0.2;
    hpf = 2;
    lpf = 20;
    prefhorz = 'N';
    outfile = 'matdd_scp.txt';
else
    error('Incorrect number of inputs');
end

    
%% LOAD VALUES FROM DATABASE
try
    db = dbopen(dbname,'r');
catch
    error(['Could not open database: ' dbname]);
end
db = dblookup_table(db,'origin');
db1 = dblookup_table(db,'event');
db = dbjoin(db,db1);
db = dbsubset(db,'orid==prefor');
db1 = dblookup_table(db,'assoc');
db = dbjoin(db,db1);
db1 = dblookup_table(db,'arrival');
db = dbjoin(db,db1);
nrecords = dbquery(db,'dbRECORD_COUNT')
[sta,chan,or_time,orid,ar_time,arid,iphase] = dbgetv(db,'sta','chan','origin.time','orid','arrival.time','arid','iphase');
ar_time = epoch2datenum(ar_time);
or_time = epoch2datenum(or_time);
dbclose(db)
stalist = unique(sta);



%% ADJUST HORIZONTAL CHANNELS TO THE "PREFFERED" CHANNEL
%load junk

chanchar = char(chan);
f = find( 'N'==chanchar(:,3) | 'E'==chanchar(:,3) );
chanlist = unique(chan(f));
chanlistchar = char(chanlist);
prefix = unique(chanlistchar(:,1:2),'rows');

if prefhorz=='N'
    unprefhorz='E';
elseif prefhorz=='E'
    unprefhorz='N';
else
   error('Preferred horizontal component must be either E or N'); 
end

for n = 1:size(prefix,1)
    prefchan =   [ prefix(n,:) prefhorz ];
    unprefchan = [ prefix(n,:) unprefhorz ];
    disp(['Changing any ' unprefchan ' channels to ' prefchan ' ...']);
    f = find( strcmp(unprefchan,chan) );
    chan(f) = {prefchan};  
end




%% PREPARE LIST OF UNIQUE STA/CHAN/IPHASE
scp = [];       % sta/chan/phase combinations
for ns = 1:length(stalist)
    fs = find( strcmp(stalist{ns},sta) );
    chanlist = unique(chan(fs));
    for nc = 1:length(chanlist)
        fc = find(  strcmp(stalist{ns},sta) & strcmp(chanlist{nc},chan) );
        iphaselist = unique(iphase(fc));
        for np = 1:length(iphaselist)
            fp = find(  strcmp(stalist{ns},sta) & strcmp(chanlist{nc},chan) & strcmp(iphaselist{np},iphase) );
            scp = cat(1,scp,[stalist(ns) chanlist(nc) iphaselist(np) numel(fp) ]);
        end
    end
end



%% WRITE OUT SCP FILE
fid = fopen(outfile,'w');
fprintf(fid,'sta     chan   phase   picks  pretrig posttrig  MinCorr   MaxLag    hpf      lpf\n');
for n = 1:size(scp,1)
    fprintf(fid,'%-8s %-6s %-5s %5.0f %8.3f %8.3f %8.3f %8.3f %8.3f %8.3f\n',scp{n,1},scp{n,2},scp{n,3},scp{n,4},pretrig,posttrig,minC,maxL,hpf,lpf);
end
fclose(fid);

