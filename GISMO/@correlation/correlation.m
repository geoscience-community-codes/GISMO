function c = correlation(varargin)

%
% --------- DOCUMENTATION ------------------------------------------------
% | CORRELATION('COOKBOOK') View html-format correlation demo cookbook.  |
% | CORRELATION('README') View detailed version and install information. |
% |   (see below of description of fields within a correlation object)   |
% ------------------------------------------------------------------------
% 
%
% CORRELATION Correlation class constructor, version 1.5.
%
% C = CORRELATION creates an empty correlation object. For explanation see the 
% description below that follows the usage examples.
%
% C = CORRELATION(WAVEFORM)
% Create a correlation object from an existing waveform object. In a pinch
% this formulation can be used, however, it lacks one critical element.
% Without a trigger time, the correlation object has no information about
% how the traces should be aligned. With clean data this may be remedied
% with the XCORR routine. If possible however, it is better to use one of
% the CORRELATION uses which includes trigger times. In the absence of this
% information, trigger times are arbitrarily assigned to be one quarter of
% the time between the trace start and end times.
% 
% C = CORRELATION(WAVEFORM,TRIG)
% Create a correlation object from an existing waveform object and a column
% vector of trigger times. These times can be in the matlab numeric time
% format (serial day) or a recognized string format (see HELP DATENUM).
% TRIG and WAVEFORM must be of the same length.
%
% CORRELATION('DEMO')
% Opens the demo dataset for correlation. This dataset contains a single
% correlation object of 100 traces. It is the data source for the cookbook
% demos.
%
% C = CORRELATION(datasource,scnlobjects,trig,pretrig,posttrig)
% creates a correlation object using the sta/chan/net/loc codes contained 
% in SCNLOBJECT loaded from the datasource defined by DATASOURCE. For help
% in understanding the SCNLOBJECT and DATASOURCE object, see HELP
% SCNLOBJECT and HELP DATASOURCE respectively.
%
% Start and end trace times are based on an input list of trigger times
% cropped according to the pre/posttrig terms. All traces in the resulting
% correlation object have the same frequency and the same number of
% samples. If partial data is returned from the database request,
% traces are zero-padded accordingly. If a trace has a lower frequency than
% other traces in the object, a warning is issued and the trace is
% resampled to the highest frequency in the set of waveforms. For most uses
% this should be a rare occurence.
%
%The inputs are:
%       datasource:     station name
%       scnlobject:     scnlobject
%       trig:           vector of absolute trigger times
%                         (in matlab serial time format)
%       pre/posttrig:   these times in seconds define the width of the 
%                       window for each trace, where pretrig and posttrig 
%                       are times in seconds relative to the trigger
%                         time.
%
% C = CORRELATION(C,W) replaces the waveforms in correlation object C with
% the waveform object W. This is useful for manipulating waveforms with
% tools outside the correlation toolbox. 
% Example:
%   % square the amplitudes of each trace (sign-sensitive)
%   w  = waveform(c);
%   w1 = (w.^2)
%   w2 = sign(w);
%   for n = 1:numel(w)
%        w(n) = w1(n) .* w2(n);
%   end
%   c = correlation(c,w);
% This is a very convenient usage since the correlation toolbox will never
% incorporate all the possible waveform manipulations one might want.
% However it needs to be used with care. It is possible to manipulate the
% extracted waveform in ways that make it incompatible with the rest of the
% metadata in the correlation object - for example if the times stamps are
% altered. When replacing the waveform in a correlation object, all derived
% data fields (CORR, LAG, LINK, STAT, CLUST) are removed since this data is
% presumed no longer valid.
%
% C = CORRELATION(N) where N is a single number, creates a correlation
% object with N randomly generated simplistic synthetic traces. At times
% useful for offline testing.
%
% C = CORRELATION(CORAL) where CORAL is a data structure from the CORAL
% seismic package (K. Creager, Univ. of Washington). CORAL is a fairly
% comprehensive seismic data and metadata format. CORRELATION and
% the underlying WAVEFORM suite are not. A CORAL to CORRELATION conversion
% should usually be easy. The other direction may be more challenging as
% most correlation and waveform objects do not contain much of the "header"
% info stored by CORAL. If the pPick field exists in the CORAL structure,
% then it is used to set the trigger times inside the resulting correlation
% object. NOTE that little error checking is performed on the CORAL
% structure. If it is improperly constructed, then the conversion to a
% correlation object may fail without an intelligible error message.
%
%
%
% % ------- DESCRIPTION OF FIELDS IN CORRELATION OBJECT ------------------
% All calls to correlation return a "correlation object" containing
% the following fields where M is the number of traces:
%    TRIG:     trigger times in matlab serial time (Mx1)
%    WAVES:    vector of waveforms (Mx1)
%    CORR:     max correlation coefficients (MxM, single precision)
%    LAG:      lag times in seconds (MxM, single precision)
%                (Example: If the lag time in position (A,B) is positive,
%                 then similar features on trace A occur later in relative
%                 time than on trace B. To align the traces, the lag time
%                 in (A,B) must be added to the trigger time of A)
%    STAT:     statistics about each trace (Mx? see below)
%    LINK:     defines the cluster tree (Mx3)
%    CLUST:    defines individual clusters(families) of events (Mx1)
%
% The first two fields define the data traces. The last five fields are
% products derived from these data. (Programming note: Internally, these
% fields are referred to as c.trig, c.W, c.C, c.L, c.stat, c.link, and 
% c.clust, respectively.)
%
% The STAT field contains columns of statistics that can be assigned one 
% per trace. The number of columns may be expanded to accomodate 
% additional parameters. Currently it is 5 columns wide. Column 1 is the 
% mean maximum correlation. Column 2 is the high side rms error (1 sigma) 
% of the mean max correlation. Column 3 is the low side rms error (1 
% sigma) of the mean max correlation. Columns 4 is the unweighted least 
% squares best fit delay time for each trace. Column 5 is the rms error of 
% this delay time. See Vandecar and Crosson (BSSA 1990) and HELP GETSTAT 
% for details of how these statistics are calculated.
%
%
%
% ------- DEPRECATED USES -----------------------------------------------
% 
% The following uses are still recognized by CORRELATION. However they have
% been deprecated in favor of methods that make use of the datasource and
% sncl objects beginning in waveform 1.10.
%
% ANTELOPE
%    CORRELATION('stat','chan',trig,pretrig,posttrig)
%    CORRELATION('stat','chan',trig,pretrig,posttrig,'archive')
%
% WINSTON
%    CORRELATION('stat','chan',trig,pretrig,posttrig,'netwk','loc','server',port)
%
% While these calls to correlation may continue to work, they will not be
% maintained and may disappear. Best to migrate to the newer flavor of
% waveform. While the addition of two extra lines of code may seem a step
% backward, the new approach is significantly more robust and much faster.
% 
% EXAMPLE OF PREFERRED FORMAT:
% Deprecated usage:
%   correlation('stat','chan',trig,pretrig,posttrig,'archive')
% 
% Preferred usage:
%   ds = datasource('antelope','archive');
%   scnl = scnlobject('sta','chan');
%   correlation(ds,scnl,trig,pretrig,posttrig)
%
% It is worth first investing time to understand the WAVEFORM, DATASOURCE,
% SCNLOBJECT objects on which CORRELATION is built.
% See also datasource waveform scnlobject

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$




% CHECK THAT WAVEFORM OBJECT IS SET UP
if exist('waveform','file') ~= 2
    error('The @WAVEFORM suite must be in the path to use the correlation toolbox.')
end


% LOAD DATA VIA WAVEFORM. SEND SPECIAL CASES TO SUBROUTINE

%% NO DATA
if nargin==0
        c.W = [];
        c.trig = [];
        c.C = [];
        c.L = [];
        c.stat = [];
        c.link = [];
        c.clust = [];
        c = class(c,'correlation');
        
%% ANOTHER CORRELATION OBJECT
elseif nargin==1 & isa(varargin{1},'correlation')
    c = varargin{1};
        
%% REPLACE WAVEFORM IN EXISTING CORRELATION OBJECT
elseif nargin==2 & isa(varargin{1},'correlation')
    c = varargin{1};
    w = varargin{2};
    if get(c,'TRACES') ~= numel(w)
        error('Correlation and waveform objects must have the same number of elements');
    end
    c.W = w;
    c.C = [];
    c.L = [];
    c.stat = [];
    c.link = [];
    c.clust = [];
    
%% BUILD FROM A STRUCTURE (CORAL)
elseif isa(varargin{1},'struct')
    %if isfield(varargin{1}(1),'data') && isfield(varargin{1}(1),'staCode') && isfield(varargin{1}(1),'staChannel')
    if isfield(varargin{1},'data') && isfield(varargin{1},'staCode') && isfield(varargin{1},'staChannel')
        c = convert_coral(varargin{1});
    end
    % add other "struct" processing blocks here as an embedded elseif

%% BUILD FROM A DATASOURCE
elseif isa(varargin{1},'datasource')
    ds = varargin{1};
    scnl = varargin{2};
    trig = reshape(varargin{3},length(varargin{3}),1);
    pretrig = varargin{4};
    posttrig = varargin{5};
    c = loadfromdatasource(ds,scnl,trig,pretrig,posttrig);
    c.C = [];
    c.L = [];
    c.stat = [];
    c.link = [];
    c.clust = [];
    c = class(c,'correlation');
    c = verify(c);
    c = crop(c,pretrig,posttrig);
    
%% DEMO DATASET
elseif nargin==1 && strncmpi(varargin{1},'DEM',3)
    load demo_data_100; %stresstest
    
%% OPEN HTML COOKBOOK
elseif nargin==1 && strncmpi(varargin{1},'COO',3)
    p = which('correlation_cookbook');
    if isempty(p)
        error('Sorry. The correlation cookbook was not found.');
    end
    p = p(1:end-22);
    slash = p(end);
    web([p 'html' slash 'correlation_cookbook.html']);
    c = [];
    
%% OPEN README FILE
elseif nargin==1 && strncmpi(varargin{1},'REA',3)
    p = which('correlation/correlation');
    p = p(1:end-13);
    web([p 'README.txt']);
    c = [];
    
%% WITH SYNTHETIC DATA
elseif nargin==1 && isa(varargin{1},'double')
    co = makesynthwaves(varargin{1});
    c.W = co.W;
    c.trig = co.trig;
    c.C = [];
    c.L = [];
    c.stat = [];
    c.link = [];
    c.clust = [];
    c = class(c,'correlation');
    
%% FROM A WAVEFORM WITHOUT TRIGGERS
elseif nargin==1 && isa(varargin{1},'waveform')
    c.W = varargin{1};
    c.W = reshape(c.W,length(c.W),1);
    c.trig = get(c.W,'START') + 0.25*(get(c.W,'END')-get(c.W,'START'));
    c.trig = reshape(c.trig,length(c.trig),1);
    c.C = [];
    c.L = [];
    c.stat = [];
    c.link = [];
    c.clust = [];
    c = class(c,'correlation');
    
%% FROM A WAVEFORM WITH TRIGGERS
elseif nargin==2 && isa(varargin{1},'waveform')
    c.W = varargin{1};
    c.W = reshape(c.W,length(c.W),1);
    if isa(varargin{2},'double')
        c.trig = varargin{2};
        c.trig = reshape(c.trig,length(c.trig),1);
    else
        error('Time format for TRIG field not recognized');
    end
    c.C = [];
    c.L = [];
    c.stat = [];
    c.link = [];
    c.clust = [];
    c = class(c,'correlation');
    
%% FROM DEFAULT ANTELOPE ARCHIVE
elseif nargin==5
    warning('This call to correlation is depricated. Use the datasource and scnlobject as described in HELP CORRELATION.');
    stat = varargin{1};
    chan = varargin{2};
    trig = reshape(varargin{3},length(varargin{3}),1);
    pretrig = varargin{4};
    posttrig = varargin{5};
    c = loadfromantelope(stat,chan,trig,pretrig,posttrig,[]);
    c.C = [];
    c.L = [];
    c.stat = [];
    c.link = [];
    c.clust = [];
    c = class(c,'correlation');
    c = verify(c);
    c = crop(c,pretrig,posttrig);
    
%% FROM CUSTOM ANTELOPE ARCHIVE
elseif nargin==6
    warning('This call to correlation is depricated. Use the datasource and scnlobject as described in HELP CORRELATION.');
    stat = varargin{1};
    chan = varargin{2};
    trig = reshape(varargin{3},length(varargin{3}),1);
    pretrig = varargin{4};
    posttrig = varargin{5};
    archive = varargin{6};
    c = loadfromantelope(stat,chan,trig,pretrig,posttrig,archive);
    c.C = [];
    c.L = [];
    c.stat = [];
    c.link = [];
    c.clust = [];
    c = class(c,'correlation');
    c = verify(c);
    c = crop(c,pretrig,posttrig);
    
%% FROM WINSTON WAVE SERVER
elseif nargin==9
    warning('This call to correlation is depricated. Use the datasource and scnlobject as described in HELP CORRELATION.');
    stat = varargin{1};
    chan = varargin{2};
    trig = reshape(varargin{3},1,length(varargin{3}));
    pretrig = varargin{4};
    posttrig = varargin{5};
    netwk = varargin{6};
    loc = varargin{7};
    server = varargin{8};
    port = varargin{9};
    c = loadfromwinston(stat,chan,trig,pretrig,posttrig,netwk,loc,server,port);
    c.C = [];
    c.L = [];
    c.stat = [];
    c.link = [];
    c.clust = [];
    c = class(c,'correlation');
    whos
    c = verify(c);
    c = crop(c,pretrig,posttrig);
    
else
    error('Invalid input values to correlation');
end;



%% ADJUST DATA LENGTH AND SAMPLE RATE IF NECESSARY
if get(c,'TRACES')
    c = demean(c);
    c = detrend(c);
    if ~check(c,'FREQ')
        c = align(c);
    elseif ~check(c,'SAMP')
        c = verify(c);
    end    
end





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FUNCTION: LOAD WAVEFORM DATA FROM A DATASOURCE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function c = loadfromdatasource(ds,scnl,trig,pretrig,posttrig);
    
% TODO: This function needs to rewritten if/when waveform is able to
% identify which traces are empty instead of skipping them. This should
% improve the spead considerably. - MEW, May 25, 2009.

% READ IN WAVEFORM OBJECTS
good = ones(size(trig));
fprintf('Reading waveforms into a correlation object ...\n');
w = waveform;
nMax = length(trig);
disp('     ');
for n = 1:nMax
try
        w(n) = waveform(ds,scnl,trig(n)+pretrig/86400,trig(n)+posttrig/86400);
        freq(n) = get(w(n),'Fs');
        fprintf('\b\b\b\b\b\b%5.0f%%',n/nMax*100);
    catch
        scnlstr = [get(scnl,'network') '_' get(scnl,'station') '_' get(scnl,'channel') '_' get(scnl,'location')];
        disp([scnlstr ' at time ' datestr(trig(n),'mm/dd/yyyy HH:MM:SS') ' could not be loaded.']);
        disp('     ');
        good(n) = 0;    % mark waveform as empty
    end;
end;
fprintf('\n');
%
% CHECK TO SEE IF ANY DATA WAS READ IN
if length(w)==0
	error('This data is not available from the specified database.');
end

% FILL DATA GAPS
 w = fillgaps(w,'MeanAll');

%
% STORE ONLY GOOD TRACES
w = w(find(good));
trig = trig(find(good));
freq = freq(find(good));
%
% FILL CORRELATION STRUCTURE
c.W = reshape(w,length(w),1);
c.trig = reshape(trig,length(trig),1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FUNCTION: LOAD AN ANTELOPE DATABASE 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function c = loadfromantelope(stat,chan,trig,pretrig,posttrig,archive);

% READ IN WAVEFORM OBJECTS
good = ones(size(trig));
fprintf('Creating matrix of waveforms ...');
w = waveform;
for i = 1:length(trig)
    try
	if ~isnan(archive)
        	w(i) = waveform(stat,chan,trig(i)+pretrig/86400,trig(i)+posttrig/86400,archive);
	else
        	w(i) = waveform(stat,chan,trig(i)+pretrig/86400,trig(i)+posttrig/86400);
	end
        freq(i) = get(w(i),'Fs');
        fprintf('.');
    catch
        disp(' ');
        disp([stat '_' chan ' at time ' datestr(trig(i),'mm/dd/yyyy HH:MM:SS.FFF') ' could not be loaded.']);
        good(i) = 0;    % mark waveform as empty
    end;
end;
disp(' ');
%
% CHECK TO SEE IF ANY DATA WAS READ IN
if length(w)==0
	error('This data not is available from the specified database.');
end
%
% STORE ONLY GOOD TRACES
w = w(find(good));
trig = trig(find(good));
freq = freq(find(good));
%
% FILL CORRELATION STRUCTURE
c.W = reshape(w,length(w),1);
c.trig = reshape(trig,length(trig),1);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FUNCTION: LOAD FROM A WINSTON DATABASE 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function c = loadfromwinston(stat,chan,trig,pretrig,posttrig,netwk,loc,server,port);

% READ IN WAVEFORM OBJECTS
good = ones(size(trig));
fprintf('Creating matrix of waveforms ...');
w = waveform;
for i = 1:length(trig)
    try
       	w(i) = waveform(stat,chan,trig(i)+pretrig/86400,trig(i)+posttrig/86400,netwk,loc,server,port);
        freq(i) = get(w(i),'Fs');
        fprintf('.');
    catch
        disp(' ');
        disp([stat '_' chan ' at time ' datestr(trig(i),'mm/dd/yyyy HH:MM:SS.FFF') ' could not be loaded.']);
        good(i) = 0;    % mark waveform as empty
    end;
end;
disp(' ');
%
% CHECK TO SEE IF ANY DATA WAS READ IN
if length(w)==0
	error('This data not is available from the specified database.');
end
%
% STORE ONLY GOOD TRACES
w = w(find(good));
trig = trig(find(good));
freq = freq(find(good));
%
% RESAMPLE TRACES TO MAXIMUM FREQUENCY
fmax = round(max(freq))
for i = 1:length(trig)
	if get(w(i),'FREQ') ~= fmax
		w(i) = align(w(i),trig(i),fmax);
		disp(['Trace no. ' num2str(i) ' is being resampled to ' num2str(fmax) ' Hz']);
	end
end
%
% FILL CORRELATION STRUCTURE
c.W = reshape(w,length(w),1);
c.trig = reshape(trig,length(trig),1);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FUNCTION: CONVERT FROM CORAL STRUCTURE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function c = convert_coral(coral)

w = waveform;
t = zeros(size(coral));
for i = 1:length(coral)
    w(i) = waveform;
    w(i) = set( w(i) , 'Station' , coral(i).staCode );
    w(i) = set( w(i) , 'Channel' , coral(i).staChannel );
    w(i) = set( w(i) , 'Data' , coral(i).data );
    w(i) = set( w(i) , 'Start' , datenum(coral(i).recStartTime') );
    w(i) = set( w(i) , 'FREQ' , 1/coral(i).recSampInt );
    if isfield(coral(i),'pPick')
        t(i) = datenum(coral(i).pPick');
    end
end

if length(find(t))==length(t)
    disp('Trigger times are being applied from coral pPick field');
    c = correlation(w,t);
else
    c = correlation(w);
end
%c.W = reshape(w,length(w),1);


