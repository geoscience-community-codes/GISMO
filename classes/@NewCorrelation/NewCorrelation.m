classdef NewCorrelation
   %Correlation
   % written by Mike West, rewritten into the new MATLAB classes by Celso Reyes
   
   properties
            traces %  % c.W
            trig % will be triggers; % c.trig
            corrmatrix
            lags % will be lags; % c.L
            stat % will be statistics; % c.stat
            link % might be links;% c.link
            clust % will be clusters;% c.clust
   end
   
   properties(Dependent)
      % properties that existed prior to rewrite
      W % traces as waveforms
      C % correlation matrix corrmatrix
      L % Lags
      
      % new properties
      ntraces % number of traces
      data_length % length of first trace (should all be same)
      % properties associated with the waveforms / traces
      stations % station name for each trace
      channels % channel name for each trace
      networks % network name for each trace
      locations % location name for each trace
      
      samplerate % sample rate (for first trace)
      data % all the trace's data as a matrix
      
   end
      
   methods
      function c = NewCorrelation(varargin)
         
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
         % TRIG must be the same length as WAVEFORM or be a scalar value.
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
         % fields are referred to as c.trig, c.W, c.corrmatrix, c.lags, c.stat, c.link, and
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
         
         for nm=1:numel(varargin)
            if isa(varargin{nm},'waveform')
               varargin{nm} = SeismicTrace(varargin{nm});
            end
         end
         %% NO DATA
         if nargin==0
            return
            
            %% ANOTHER CORRELATION OBJECT
         elseif nargin==1 && isa(varargin{1},'correlation')
            oldC = varargin{1};
            c.W = get(oldC,'waves'); %  % c.W
            c.trig = get(oldC,'trig'); % will be triggers; % c.trig
            c.corrmatrix = get(oldC,'corr');
            c.lags = get(oldC,'lag');% will be lags; % c.L
            c.stat = get(oldC,'stat'); % will be statistics; % c.stat
            c.link = get(oldC,'link'); % might be links;% c.link
            c.clust = get(oldC,'clust');% will be clusters;% c.clust
            
            %% REPLACE WAVEFORM IN EXISTING CORRELATION OBJECT
         elseif nargin==2 && isa(varargin{1},'correlation')
            c = varargin{1};
            w = varargin{2};
            if c.ntraces ~= numel(w)
               error('Correlation and waveform objects must have the same number of elements');
            end
            c.traces = w;
            
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
            c = verify(c);
            c = crop(c,pretrig,posttrig);
            
            %% DEMO DATASET
         elseif nargin==1 && strncmpi(varargin{1},'DEM',3)
            oldcorrobj = load('demo_data_100'); %stresstest
            c = NewCorrelation(oldcorrobj.c);
            
            %% OPEN HTML COOKBOOK
         elseif nargin==1 && strncmpi(varargin{1},'COO',3)
            %COOKBOOK
            p = which('cookbook');
            if isempty(p)
               error('Sorry. The correlation cookbook was not found.');
            end
            p = p(1:end-22);
            %slash = p(end);
            %web([p 'html' slash 'correlation_cookbook.html']);
            c = [];
            cookbook(correlation);
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
            
            %% FROM A WAVEFORM WITHOUT TRIGGERS
         elseif nargin==1 && isa(varargin{1},'SeismicTrace')
            c.traces = varargin{1};
            c.trig = c.traces.firstsampletime() + 0.25*(get(c.W,'END') - c.traces.firstsampletime());
            c.trig = reshape(c.trig,numel(c.trig),1);
            
            %% FROM A WAVEFORM WITH TRIGGERS
         elseif nargin==2 && isa(varargin{1},'SeismicTrace')
            c.traces = varargin{1};
            if isa(varargin{2},'double')
               c.trig = varargin{2};
               c.trig = reshape(c.trig,numel(c.trig),1);
            else
               error('Time format for TRIG field not recognized');
            end
            % adjust length of trigger field input
            if numel(c.trig)==1
               c.trig = c.trig*ones(size(c.W));
            elseif  numel(c.trig)~=numel(c.W)
               error('correlation:correlation:wrongTriggerLength','Trigger argument must be of length 1 or the same as the number of waveforms');
            end
         else
            error('Invalid input values to correlation');
         end;
         
         
         
         %% ADJUST DATA LENGTH AND SAMPLE RATE IF NECESSARY
         if ~isempty(c.traces)
            c = demean(c);
            c = detrend(c);
            if ~check(c,'FREQ')
               c = align(c);
            elseif ~check(c,'SAMPLES')
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
            good = true(size(trig));
            fprintf('Reading waveforms into a correlation object ...\n');
            w = waveform;
            nMax = length(trig);
            disp('     ');
            
            %all requests for waveforms are the same, and depend upon various triggers.
            wgetter = @(tr) waveform(ds, scnl, tr+pretrig/86400, tr+posttrig/86400);
            
            loaderrmsg = [get(scnl,'nscl_string'), ' at time %s could not be loaded\n     \n'];
            updatemsg.good = @(n) fprintf('\b\b\b\b\b\b%5.0f%%',n/nMax*100);
            updatemsg.bad = @(dv) fprintf(loaderrmsg, datestr(dv,'mm/dd/yyyy HH:MM:SS'));
            
            for n = 1:nMax
               try
                  w(n) = wgetter(trig(n));
                  updatemsg.good(n);
               catch
                  updatemsg.bad(trig(n));
                  good(n) = false;    % mark waveform as empty
               end;
            end;
            fprintf('\n');
            %
            % CHECK TO SEE IF ANY DATA WAS READ IN
            if numel(w)==0
               error('This data is not available from the specified database.');
            end
            
            % FILL DATA GAPS
            w = fillgaps(w,'MeanAll');
            
            %
            % STORE ONLY GOOD TRACES
            w = w(good);
            trig = trig(good);
            %
            % FILL CORRELATION STRUCTURE
            c.W = reshape(w,length(w),1);
            c.trig = reshape(trig,length(trig),1);
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %% FUNCTION: LOAD AN ANTELOPE DATABASE
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
         function c = loadfromantelope(stat,chan,trig,pretrig,posttrig,archive)
            
            % READ IN WAVEFORM OBJECTS
            good =true(size(trig));
            fprintf('Creating matrix of waveforms ...');
            wf = waveform;
            
            for i = 1:length(trig)
               try
                  if ~isnan(archive)
                     wf(i) = waveform(stat,chan,trig(i)+pretrig/86400,trig(i)+posttrig/86400,archive);
                  else
                     wf(i) = waveform(stat,chan,trig(i)+pretrig/86400,trig(i)+posttrig/86400);
                  end
                  freq(i) = get(wf(i),'Fs');
                  fprintf('.');
               catch
                  disp(' ');
                  disp([stat '_' chan ' at time ' datestr(trig(i),'mm/dd/yyyy HH:MM:SS.FFF') ' could not be loaded.']);
                  good(i) = false;    % mark waveform as empty
               end;
            end;
            disp(' ');
            %
            % CHECK TO SEE IF ANY DATA WAS READ IN
            if length(wf)==0
               error('This data not is available from the specified database.');
            end
            %
            % STORE ONLY GOOD TRACES
            wf = wf(good);
            trig = trig(good);
            freq = freq(good);
            %
            % FILL CORRELATION STRUCTURE
            c.W = reshape(wf,length(wf),1);
            c.trig = reshape(trig,length(trig),1);
         end
         
         
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         %% FUNCTION: LOAD FROM A WINSTON DATABASE
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
         function c = loadfromwinston(stat,chan,trig,pretrig,posttrig,netwk,loc,server,port)
            
            % READ IN WAVEFORM OBJECTS
            good = true(size(trig));
            fprintf('Creating matrix of waveforms ...');
            wf = waveform;
            for i = 1:length(trig)
               try
                  wf(i) = waveform(stat,chan,trig(i)+pretrig/86400,trig(i)+posttrig/86400,netwk,loc,server,port);
                  freq(i) = get(wf(i),'Fs');
                  fprintf('.');
               catch
                  disp(' ');
                  disp([stat '_' chan ' at time ' datestr(trig(i),'mm/dd/yyyy HH:MM:SS.FFF') ' could not be loaded.']);
                  good(i) = false;    % mark waveform as empty
               end;
            end;
            disp(' ');
            %
            % CHECK TO SEE IF ANY DATA WAS READ IN
            if numel(wf)==0
               error('This data not is available from the specified database.');
            end
            %
            % STORE ONLY GOOD TRACES
            wf = wf(good);
            trig = trig(good);
            freq = freq(good);
            %
            % RESAMPLE TRACES TO MAXIMUM FREQUENCY
            fmax = round(max(freq));
            for i = 1:length(trig)
               if get(wf(i),'FREQ') ~= fmax
                  wf(i) = align(wf(i),trig(i),fmax);
                  disp(['Trace no. ' num2str(i) ' is being resampled to ' num2str(fmax) ' Hz']);
               end
            end
            %
            % FILL CORRELATION STRUCTURE
            c.W = reshape(wf,length(wf),1);
            c.trig = reshape(trig,length(trig),1);
         end
         
         
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
               c = NewCorrelation(w,t); %was correlation
            else
               c = NewCorrelation(w); %was correlation
            end
            %c.W = reshape(w,length(w),1);
         end %convert_coral
      end %NewCorrelation

      function waves = get.W(obj)
         warning('getting waveform instead of traces');
         waves = waveform(obj.traces);
      end
      function obj = set.W(obj, waves)
         % warning('setting waveform instead of trace');
         obj.traces = SeismicTrace(waves);
      end
      function X = get.C(obj)
         warning('use c.corrmatrix instead of c.C')
         X = obj.corrmatrix;
      end
      function obj = set.C(obj, C)
         warning('use c.corrmatrix instead of c.C')
         obj.corrmatrix = C;
      end
      function X = get.L(obj)
         warning('use c.lags instead of c.L')
         X = obj.lags;
      end
      function obj = set.L(obj, lags)
         warning('use c.lags instead of c.L')
         obj.lags = lags;
      end
      
      function c = set.traces(c, T)
         c.traces = T(:); % ensure traces are in a column
         %TODO: Should this also wipe all the calculated values?
      end
            
      function sta = get.stations(obj)
         sta = {obj.traces.station};
      end
      function net = get.networks(obj)
         net = {obj.traces.network};
      end
      function loc = get.locations(obj)
         loc = {obj.traces.location};
      end
      function cha = get.channels(obj)
         cha = {obj.traces.channel};
      end
      
      function n = get.ntraces(obj)
         n = numel(obj.traces);
      end
      
      function sr = get.samplerate(obj)
         sr = obj.traces(1).samplerate;
      end
      function n = get.data_length(obj)
         n = obj.traces(1).nsamples;
      end
      
      function n = relativeStartTime(c, i)
         %relativeStartTime  relative start time (trigger is at zero)
         % t = c.relativeStartTime(index) will return the relativeStartTime
         % of the indexth trace, by subtracting the indexth trigger
         
         %old usage, before traces
         % wstartrel = 86400 *( get(c.W(i),'START_MATLAB') - c.trig(i));
         n = 86400 * (c.traces(i).firstsampletime()-c.trig(i));
      end
      
      
      function maybeReplaceYticksWithStationNames(c,ax)
         % replace dates with station names if stations are different
         if ~check(c,'STA')
            labels = strcat(c.stations , '_', c.channels);
            set( ax , 'YTick' , 1:1:c.ntraces);
            set( ax , 'YTickLabel' , labels );
         end
      end
      % ==> adjusttrig.m <==
      c = adjusttrig(c,varargin)
      
      % ==> agc.m <==
      c = agc(c,varargin)
      
      % ==> align.m <==
      c = align(c,varargin)
      
      % ==> butter.m <==
      c = butter(c,varargin)
      
      % ==> cat.m <==
      c = cat(varargin)
      
      % ==> check.m <==
      val = check(c,varargin)
      
      % ==> cluster.m <==
      c = cluster(c,varargin)
      
      % ==> colormap.m <==
      c = colormap(c,varargin)
      
      % ==> conv.m <==
      c = conv(c,varargin)
      
      % ==> crop.m <==
      c = crop(c,varargin)
      
      % ==> deconv.m <==
      c = deconv(c,varargin)
      
      % ==> demean.m <==
      c = demean(c,varargin);
      
      % ==> detrend.m <==
      c = detrend(c,varargin);
      
      % ==> diff.m <==
      c = diff(c)
      
      % ==> display.m <==
      display(c)
      
      % ==> find.m <==
      index = find(c,varargin)
      
      % ==> get.m <==
      val = get(c,prop_name)
      
      % ==> getclusterstat.m <==
      family = getclusterstat(c)
      
      % ==> getstat.m <==
      c = getstat(c)
      
      % ==> hilbert.m <==
      c = hilbert(c,n)
      
      % ==> integrate.m <==
      c = integrate(c)
      
      % ==> interferogram.m <==
      [c,t,i,CC,LL] = interferogram(c,varargin)
      
      % ==> linkage.m <==
      c = linkage(c,varargin);
      
      % ==> match.m <==
      [c1,c2] = match(c1,c2,varargin)
      
      % ==> minus.m <==
      c = minus(c,varargin)
      
      % ==> norm.m <==
      c = norm(c,varargin)
      
      %==> plot.m <==
      plot(c,varargin)
      
      %==> set.m <==
      c = set(c, prop_name, val)
      
      %==> sign.m <==
      c = sign(c,varargin);
      
      % ==> sort.m <==
      c = sort(c,varargin)
      
      % ==> stack.m <==
      c = stack(c,varargin)
      
      % ==> strip.m <==
      c = strip(c,varargin)
      
      % ==> subset.m <==
      c = subset(c,index)
      
      % ==> taper.m <==
      c = taper(c,varargin)
      
      % ==> verify.m <==
      c = verify(c)
      
      % ==> waveform.m <==
      w = waveform(c,varargin)
      
      % ==> writedb.m <==
      writedb(c,dbOut,varargin)
      
      %==> xcorr.m <==
      c = xcorr(c,varargin)
      
   end %methods
   
   methods(Access=private)
      % ==> corrplot.m <==
      corrplot(c)
      
      % ==> dendrogramplot.m <==
      dendrogramplot(c);
      
      % ==> eventplot.m <==
      eventplot(c,scale,howmany);
      
      % ==> getval.m <==
      A = getval(OBJ,PROP)
      
      % ==> lagplot.m <==
      lagplot(c);
      
      % ==> makesynthwaves.m <==
      c = makesynthwaves(n);
      
      % ==> occurrenceplot.m <==
      occurrenceplot(c,scale,clusternum)
      
      % ==> overlayplot.m <==
      overlayplot(c,scale,ord)
      
      % ==> sampleplot.m <==
      sampleplot(c,scale,ord)
      
      % ==> shadedplot.m <==
      shadedplot(c,scale,ord)
      
      % ==> statplot.m <==
      statplot(c);
      
      % ==> wiggleinterferogram.m <==
      wiggleinterferogram(c,scale,type,norm,range)
      
      % ==> wiggleplot.m <==
      wiggleplot(c,scale,ord,norm)
   end
   methods(Static)
      % ==> cookbook.m <==
      correlationVariables = cookbook(corr)
   end
   methods(Access=private, Static)
      % ==> xcorr1x1.m <==
      d = xcorr1x1(d);
      
      % ==> xcorr1xr.m <==
      d = xcorr1xr(d,style)
      
      % ==> xcorr1xr_orig.m <==
      d = xcorr1xr_orig(d)
      
      % ==> xcorrdec.m <==
      d = xcorrdec(d)
      
      % ==> xcorrrow.m <==
      d = xcorrrow(d,c,index)
   end
end


