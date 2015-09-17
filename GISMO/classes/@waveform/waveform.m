function w = waveform(varargin)
   %WAVEFORM Waveform Class constructor
   %   w = WAVEFORM(datasource, channeltags, starttimes, endtimes)
   %          loads waveform from the specified DATASOURCE
   %          SCNL stands for STATION-CHANNEL-NETWORK-LOCATION.
   %          multiple start-endtime pairs may be used, while station-channel
   %          pairs can be provided as an array of channeltags
   %
   %  w = WAVEFORM() creates a blank waveform
   %
   %  w = WAVEFORM(channeltag, samplerate, starttime, data, units) creates
   %      a waveform from consituent parts.
   %
   %      CHANNELTAG - either 'net.sta.loc.cha' or a channeltag 
   %             (channeltag replaces the old scnlobject)
   %      SAMPLERATE - Sampling frequency, in Hz       (default nan)
   %      DATA - a vector of seismic amplitudes        (default [])
   %      STARTTIME - Start time, in most any format   (default '1/1/1970')
   %      UNITS - a string describing the data units
   %
   %  w = WAVEFORM(...,'nocombine')
   %    If the data requested by waveform consists of multiple segments, then
   %    these segments will be combined, with NaN filling any data gaps. 
   %    'nocombine' overrides this behavior.
   %
   %
   %    ---------- USING WAVEFORM WITH ANTELOPE ------------
   %    The Antelope Toolbox must be installed.
   %    w = WAVEFORM(..., 'noexit') attempts to avoid antelope segfaults
   %
   %    ---------- USING WAVEFORM WITH WINSTON -------------
   %    To use the waveform files with winston, you need to have the usgs.jar
   %    file. If you have already installed SWARM, then this .jar file already
   %    exist in your swarm/lib directory (or thereabouts).
   %
   %    Edit Matlab's classpath.txt file (located in the toolbox/local
   %    directory) and add the location of this .jar files.
   %
   %    WINSTON WARNING: Data received through winston is in COUNTS, and is
   %        not adjusted for instrument gain. To fix this, you'll
   %        need to scale the data by the correct gain.  
   %            Ex: W = W .* instGain
   % 
   %    % WINSTON EXAMPLE: This example gets a few minutes of data 
   %    % (starting a day ago) from a ficticious winston server.  
   %    % Data returned is for the EHZ channel at each of the three 
   %    % selected stations.
   %
   %      tags = channeltag({'AV.OKCF..EHZ','AV.PV6..EHZ','AV.SSLS..EHZ'});
   %      mySource = datasource('winston','servername.here.edu',1255);
   %      w = waveform(mySource, tags, now - 1, now - .98);
   %
   % see also channeltag, datasource
   
   % VERSION: 2.0 of waveform objects
   % AUTHOR: Celso Reyes
   
   % considerations when changing the internals:
   %  when replacing scnl with channeltag, affects loadobj!
   
   global WaveformNamespaceIsLoaded
   if isempty(WaveformNamespaceIsLoaded)
      WaveformNamespaceIsLoaded = loadGlobalNamespace();
   end;
   persistent waveformversion
   if isempty(waveformversion)
      waveformversion = 2.0;
   end
   
   % usage: [optExists, value, vargs] = peel_option(vargs, searchValue, searchClass, minPos)
   [COMBINE_WAVES, ~, varargin] = peel_option(varargin, 'nocombine', 'char', 5);
   [NOEXIT_OPTION, bwkaround, varargin] = peel_option(varargin, [], 'logical', 5);
   
   argCount = numel(varargin);
   
   updateWarningID = 'Waveform:waveform:oldUsage';
   
   switch argCount
      case 0
         w = genericWaveform();
      %{
      case 1   %"copy" a waveform object. Matlab naturally bypasses this.
         if isa(varargin{1}, 'waveform')
            w = varargin{1};
         end;
      %}
         
      case 4
         [arg1, arg2, arg3, arg4] = deal(varargin{:});
         switch class(arg1)
            case 'datasource' %datsource, channeltag/scnl/text, starttimes, endtimes
               w = waveformFromDatasource(arg1, as_channeltag(arg2), arg3, arg4);
            otherwise % assumed to be Channeltag or something that can be converted into it
               w = waveformFromParts(as_channeltag(arg1), arg2, arg3, arg4, 'Counts');
         end
      case 5
         [arg1, arg2, arg3, arg4, arg5] = deal(varargin{:});
         switch class(arg1)
            case 'datasource' %INPUT(datasource, channeltag, starttimes, endtimes)
               error(updateWarningID,'Should never get to this section of code');
            otherwise
               if ischar(arg1) && ischar(arg2) %given station, channel
                  warning(updateWarningID,... % could make this a ERROR instead
                     ['ancient usage.\nInstead of:\n   waveform(''%s'', ''%s'', ...\n',...
                     'use the ''NET.STA.LOC.CHA'' form:\n   waveform(''.%s..%s'', ...\n',...
                     'however, it is recommended that you include network and location info if available'],...
                     arg1, arg2, arg1, arg2);
                  arg1 = ['.' arg1 '..' arg2];
                  [arg2, arg3, arg4, arg5] = deal(arg3, arg4, arg5, 'Counts');
               end
               arg1 = as_channeltag(arg1);
               w = waveformFromParts(arg1, arg2, arg3, arg4, arg5);
         end
         
      case 8
         w = winston_access(varargin{:});
      otherwise
         disp('Invalid arguments in waveform constructor:');
         disp(varargin);
         error('Waveform:waveform:InvalidWaveformArugments',...
            ['Valid ways of calling waveform include: \n',...
            '   w = WAVEFORM()\n',...
            '   w = WAVEFORM(datasource, channeltag, starttimes, endtimes)\n',...
            '   w = WAVEFORM(channeltag, samplefreq, starttime, data, units)\n']);
   end
   
   function w = genericWaveform()
      persistent blankW
      persistent wCreated
      if ~isempty(wCreated)
         w = blankW;
         w.history = {'created', now};
      else
         %create a fresh waveform.  All calls to the waveform object, aside
         %from the "copy" call (case nargin==1) will be initated HERE.
         blankW.cha_tag = channeltag();
         blankW.Fs = nan;
         blankW.start = 719529; % datenum for 1970-01-01
         blankW.data = double([]);
         blankW.units = 'Counts';
         blankW.version = waveformversion; %version of waveform object (internal)
         blankW.misc_fields = {}; %add'l fields, such as "comments", or "trig"
         blankW.misc_values = {}; %values for these fields
         blankW.history = {'created',[]};
         blankW = class(blankW, 'waveform');
         wCreated = true;
         w = blankW;
      end
   end
   
   function w = waveformFromParts(chaTag, freq, starttime, data, units)
      w = genericWaveform();
      w.cha_tag = chaTag;%(DEFAULT_STATION,DEFAULT_CHAN);
      w.Fs = freq;
      w.start = datenum(starttime);
      w.data = double(data(:));
      w.units = units; %units for data (nm? counts?)
      w.version = waveformversion; %version of waveform object (internal)
      w.misc_fields = {}; %add'l fields, such as "comments", or "trig"
      w.misc_values = {}; %values for these fields
   end
   
   function w = waveformFromDatasource(ds, chans, startt, endt)
         startt = ensure_dateformat(startt);
         endt = ensure_dateformat(endt);
         w = load_from_datasource(ds, chans, startt, endt, COMBINE_WAVES);
   end
end

function out = ensure_dateformat(t)
   % returns a matrix of datenums of same shape as t
   if isnumeric(t)
      out = t;
   elseif ischar(t),
      for n = size(t,1) : -1 : 1
         out(n) = datenum(t(n,:));
      end
   elseif iscell(t)
      out(:) = datenum(t);
   end
end

