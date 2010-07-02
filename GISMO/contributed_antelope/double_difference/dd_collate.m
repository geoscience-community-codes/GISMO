function dd_collate(eventdat,varargin)

%  dd_collate('event.dat')
%
% DD_COLLATE(EVENT.DAT) creates a hypoDD cross correlation input file
% (referred to in hypoDD nomenclature as file dt.cc). Cross correlation
% information is read from a directory containing pre-computed correlation
% files as produced by DD_PROCESS_SCP. If not specified, DD_CORRELATE
% assumes that correlation files live in a directory named
% 'TMP_MATDD_CORR'.  By default, the output file is named 'dt.cc'.
% EVENT.DAT is the name of the double difference input 'event file'. The
% event file is used as a catalog of all events.

% DD_COLLATE(EVENT.DAT,DIRECTORYNAME) is the same as above except that
% correlation files are expected to live in DIRECTORYNAME. 
%
% DD_COLLATE(EVENT.DAT,DIRECTORYNAME,OUTFILE) is the same as above.
% However, the output file is named OUTFILE instead of ct.dt.
%
% Defaults:
%   DD_COLLATE(EVENT.DAT) is the same as
%   DD_COLLATE(EVENT.DAT,'TMP_MATDD_CORR','dt.cc')

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$



if length(varargin)>2
    error('Too many inputs');
end
    
if length(varargin)==2
    outfile = varargin{2};
else
    outfile = 'dt.cc';
end

if length(varargin)>=1
    directoryname = varargin{1};
else
    directoryname = 'TMP_MATDD_CORR';
end


% GET CORRELATION FILE NAMES
files = dir([directoryname '/*.mat' ]);
disp(files);


% READ LIST OF EVENTNAME
% DATE TIME LAT LON DEP MAG EH EV RMS ID
fid = fopen(eventdat,'r');
filein = textscan(fid,'%n %n %n %n %n %n %n %n %n %n');
fclose(fid);
event.date = filein{:,1};
event.time = filein{:,2};
event.orid = filein{:,10};
clear filein;


% SORT EVENTS BY ORID (THIS AFFECTS THE ORDER OF DT.CC)
[tmp index] = sort(event.orid);
event.date = event.date(index);
event.time = event.time(index);
event.orid = event.orid(index);


% LOAD ALL XCORR LINES
disp('Loading correlation data files ...');
linenums = [];
linestrs = [];
maximumLags = [];
minimumCorrelations = [];
for n = 1:numel(files)
    disp( [directoryname '/' files(n).name] );
    load( [directoryname '/' files(n).name] );
    clear C;
    linenums = cat(1,linenums,linenum);
    linestrs = cat(1,linestrs,linestr);
    maximumLags = cat(1,maximumLags,maximumLag);
    minimumCorrelations = cat(1,minimumCorrelations,minimumCorrelation);
end
clear linenum linestr maximumLag minimumCorrelation


% SUBSET CORRELATIONS BASED ON SCP MinCorr AND MaxLag VALUE
linestrLag = zeros(numel(linestrs),1);
linestrCorWeighted = zeros(numel(linestrs),1);
disp('Throwing out pairs that do not meet MaxCorr or MinLag values ...');
for n = 1:length(linestrs)
    linestrParsed = textscan(linestrs{n},'%s %n %n %s');
    linestrLag(n) = linestrParsed{2};
    linestrCorWeighted(n) = (linestrParsed{3});
    if mod(n,100000)==0;
        disp(['Completed ' num2str(n) ' of ' num2str(length(linestrs) ) ' (' num2str(100*n/length(linestrs),'%3.0f') '%) ...' ]);
    end
end
f = find( abs(linestrLag)<maximumLags & linestrCorWeighted>(minimumCorrelations).^2 );
linenumsSubset = linenums(f,:);
linestrsSubset = linestrs(f);



% LOOP THROUGH EVENTS
numevents = length(event.orid);
fid = fopen(outfile,'w');
for n = 1:numevents-1
    disp(['orid: ' num2str(event.orid(n)) ' (' num2str(n) ' of ' num2str(numevents)    ') ...']);
    for m = n+1:numevents
        fprintf(fid,'# %8d %8d %5.1f\n',event.orid(n),event.orid(m),0);
        f1 = find( event.orid(n)==linenumsSubset(:,1) & event.orid(m)==linenumsSubset(:,2) );
        f2 = find( event.orid(n)==linenumsSubset(:,2) & event.orid(m)==linenumsSubset(:,1) );
        f = [f1 ; f2];
        for k = 1:numel(f)
             fprintf(fid,'     %s\n',char(linestrsSubset(f(k))) );
        end
    end
end
fclose(fid);

