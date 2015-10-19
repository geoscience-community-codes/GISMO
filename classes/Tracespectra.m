classdef Tracespectra
   %Tracespectra makes examining Trace spectra easy
   %   replaces spectralobject
   
   properties
      nfft = 1024; % length of the fft
      over = 1024 * 0.8; %amount of overlap
      freqmax = 8; % maximum frequency for display
      dBlims =  [50 100]; %  decible limits
      scaling = 's'; % scaling factor (one of 's','m','h','d','date','doy')
   end
   properties(Dependent, Hidden)
      map
   end
   properties(Hidden)
      SPECTRAL_MAP = Tracespectra.loadmap;
   end
   
   methods
      function s = Tracespectra(varargin)
         % s = Tracespectra(spectralobject)
         %      s = Tracespectra(nfft, overlap, freqmax, dBlims)
         %            manually puts together a spectralobject object
         %
         %      SPECTRALOBJECT - an existing spectral object
         %      NFFT - Fourier transform window               (default [1024])
         %      OVERLAP - how much of the window to overlap   (default [NFFT * 0.8])
         %      FREQMAX - how high a freq to display          (default [8])
         %      DBLIMS - dB range over which to display data  (default [50 100])
         %      SCALING - 's', 'm', 'h', 'date': x axis scale (default 's' (second))
         %      to get default value, use []
         switch nargin
            case 1  % convert from spectralobject
               if isa(varargin{1}, 'spectralobject')
                  s.nfft = get(varargin{1},'nfft');
                  s.over = get(varargin{1},'over');
                  s.freqmax = get(varargin{1},'freqmax');
                  s.dBlims = get(varargin{1},'dBlims');
               else
                  error('Do not know how to create the Tracespectra from a %s', class(varargin{1}));
               end
            case 4
               s.nfft = varargin{1};
               s.over = varargin{2};
               s.freqmax = varargin{3};
               s.dBlims = varargin{4};
         end
      end
      function m = get.map(s)
         m = s.SPECTRAL_MAP;
      end
      function s = set.map(s, alternateMap)
         %SETMAP   sets the default colormap used with spectrograms
         %   USAGE: tracespec.setmap(alternateMap)
         %
         %   EXAMPLE: s.map = bone(64);
         %     this sets the map to the 'bone' colormap, with 64 shading  values.
         %     If you don't specify the # of values, MatLab will assign the colormap
         %     to your current figure.  If no figure exists, MatLab will create one.
         %
         %   Please Type HELP GRAPH3D to see a number of useful colormaps.
         
         if size(alternateMap,2) ~= 3,
            warning('Map ignored.  alternateMap has  incorrect # columns; should be 3');
            return
         end
         s.SPECTRAL_MAP = alternateMap;
      end
      %% plotting and spectra-taking functions
      function h = specgram(s, ws, varargin)
         %SPECGRAM - plots spectrogram of waveforms
         %  h = specgram(spectralobject, waveforms) Generates a spectrogram from the
         %  waveform(s), overwriting the current figure.  The return value is a
         %  handle to the spectrogram, and is optional. The spectrograms will be
         %  created in the same shape as the passed waveforms.  ie, if W is a 2x3
         %  matrix of waveforms, then specgram(spectralobject,W) will generate a 2x3
         %  plot of spectra.
         %
         %  Many additional behaviors can be modified through the passing of
         %  additional parameters, as listed further below.  These parameters are
         %  always passed in pairs, as such:
         %
         %  specgram(spectralobject, waveforms,'PARAM1',VALUE1,...,'PARAMn',VALUEn)
         %    Any number of these parameters may be passed to specgram.
         %
         %  specgram(..., 'axis', AXIS_HANDLE)
         %    Specify the axis AXIS_HANDLE within which the spectrogram will be
         %    generated.  The boundary of the axis becomes the boundary for the
         %    entire spectra plot.  For a matrix of waveforms, this area is
         %    subdivided into NxM subplots, where N and M are the size of the
         %    waveform matrix.
         %
         %  specgram(..., 'xunit', XUNIT)
         %    Spedifies the x-unit scale to be used with the spectrogram.  The
         %    default unit is 'seconds'.
         %    valid xunits:
         %     'seconds','minutes','hours','days','doy' (day of year),and 'date'
         %
         %  specgram(..., 'colormap', ALTERNATEMAP)
         %    Instead of using the default colormap, any colormap may be used.  An
         %    alternate way of setting the global map is by using the SETMAP
         %    function.  ALTERNATEMAP will either be a name (eg. grayscale) or an
         %    Nx3 numeric. Type HELP GRAPH3D to see additional useful colormaps.
         %
         %
         %  specgram(..., 'colorbar', COLORBAR_OPTION)
         %    Generates a spectrogram from the waveform and uses a specific map
         %    valid COLORBAR_OPTION values: 'horiz' (default),'vert','none',
         %      'HORIZ' places a single colorbar below all plots
         %      'VERT' places a single colorbar to the right of all plots
         %      'NONE' supresses the colorbar placement
         %
         %  specgram(..., 'yscale', YSCALE)
         %    Choosing 'log' Allows the y-axis to be generated on a log-frequency
         %    scale, with uneven vertical cell spacing.  The default value is
         %    'normal', and provides the standard spectrogram view.
         %    valid yscales: 'normal', 'log' (see NOTE below)
         %
         %    NOTE: In order to use the log scale, UIMAGESC needs to be available on
         %    the matlab path.  This routine was created by Frederic Moisy, and may
         %    be downloaded from the maltabcentral fileexchange (File ID: 11368).
         %    If this routine is not found,then the original spectrogram will be
         %    created.
         %
         %   h = specgram(..., 'fontsize', FONTSIZE)
         %   Specify the font size for a spectrogram.  The default font size is 8.
         %
         %  specgram2(..., 'innerLabels', SHOWINNERLABELS)
         %    Suppress the labling of the inside graphs by setting SHOWINNERLABELS
         %    to false.  If this is false, then the frequency label only shows on
         %    the leftmost spectrograms, and the X-unit label only shows on the
         %    bottommost spectrograms.
         %
         %  The following plots a waveform using an alternate mapping, an xunit of
         %  'hours', and with the y-axis plotted using a log scale.
         %  ex. specgram(spectralobject, waveform,...
         %      'colormap', alternateMap,'xunit','h','yscale','log')
         %
         %
         %  Example:
         %    % create an arbitrary subplot, and then plot multiple spectra
         %    a = subplot(3,2,1);
         %    specgram(spectralobject,waves,'axis',a); % waves is an NxM waveform
         %
         %
         %  See also SPECTRALOBJECT/SPECGRAM2, WAVEFORM/PLOT, WAVEFORM/FILLGAPS

         
         % Thanks to Jason Amundson for providing the way to do log scales
                  
         currFontSize = 8;
         %enforce input arguments.
         if ~isa(ws,'TraceData')
            error('Second input argument should be a TraceData, not a %s',class(ws));
         end
        
         hasExtraArg = mod(numel(varargin),2);
         if hasExtraArg
            error('Spectralobject:specgram:DepricatedArgument',...
               ['%s/n%s/n%s','spectralobject/specgram now requires parameter pairs.',...
               'See help spectralobject/specgram for new usage instructions',...
               'most likely you tried to call specgram with an alternate ',...
               'color map without specifying the property ''colormap''']);
         else
            proplist=  Tracespectra.parseargs(varargin);
         end
         
         %% search for relevent property pairs passed as parameters
         
         % AXIS: a handle to the axis, defining the area to be used
         [~,myaxis,proplist] = Tracespectra.getproperty('axis',proplist,0);
         
         % POSITION: 1x4 vector, specifying area in which to plot
         %          [left, bottom, width, height]
         %[~,~,proplist] = Tracespectra.getproperty('position',proplist,[]);
         
         % XUNIT: Specify the time units for the plot. eg, hours, minutes, doy, etc.
         [~, xChoice, proplist] =...
            Tracespectra.getproperty('xunit',proplist,s.scaling); %'s' is default value for xChoice
         
         % FONTSIZE: specify the font size to be used for all labels within the plot
         [~, currFontSize, proplist] =...
            Tracespectra.getproperty('fontsize',proplist,currFontSize);%default font size or override?
         
         %%take care of additional parsing that affects all waveforms
         
         [~, alternateMap, proplist] = ...
            Tracespectra.getproperty('colormap',proplist, s.SPECTRAL_MAP); %default map
         
         % YSCALE: either 'normal', or 'log'
         [~, yscale, proplist] = ...
            Tracespectra.getproperty('yscale',proplist,'normal'); %default yscale to 'normal'
         
         logscale = strcmpi(yscale,'log');
         
         % COLORBAR: Dictate the position of the colorbart relative to the plot
         [~,colorbarpref,proplist] = Tracespectra.getproperty('colorbar',proplist,'horiz');
                  
         % SUPRESSINNERLABELS: true, false
         [~, suppressLabels, proplist] = ...
            Tracespectra.getproperty('innerlabels',proplist,false); %only show outside
         
         % SUPRESSXLABELS: true, false
         [~, useXlabel, proplist] = ...
            Tracespectra.getproperty('useXlabel',proplist,true); %show no x, y labels
         % SUPRESSXLABELS: true, false
         [~, useYlabel, proplist] = ...
            Tracespectra.getproperty('useYlabel',proplist,true); %show no x, y labels
         
         
         %% figure out exactly WHERE to plot the spectrogram(s)
         %find out area(axis) in which the spectrograms will be plotted
         clabel= 'Relative Amplitude  (dB)';
         
         if myaxis == 0,
            clf;
            myaxis = gca;
            get(gca,'position');
         else
            get(myaxis,'position');
         end
         
         %% If there are multiple waveforms...
         % subdivide the axis and loop through specgram2 with individual waveforms.
                  
         if numel(ws) > 1
            %create the colorbar if desired
            Tracespectra.createcolorbar(s, colorbarpref, clabel, currFontSize)
            h = Tracespectra.subdivide_axes(myaxis,size(ws));
            remainingproperties = Tracespectra.property2varargin(proplist);
            for n=1:numel(h)
               keepYlabel =  ~suppressLabels || (n <= size(h,1));
               keepXlabel = ~suppressLabels || (mod(n,size(h,2))==0);
               specgram(s,ws(n),...
                  'xunit',xChoice,...
                  'axis',h(n),...
                  'fontsize',currFontSize,...
                  'useXlabel',keepXlabel,...
                  'useYlabel',keepYlabel,...
                  'colorbar','none',...
                  remainingproperties{:});
            end
            return
         end
         
         axes(myaxis);
         
         if any(isnan(double(ws)))
            warning('Spectralobject:specgram:nanValue',...
               ['This waveform has at least one NaN value, which will blank',...
               'the related spectrogram segment. ',...
               'Remove NaN values by either splitting up the ',...
               'waveform into non-NaN sections or by using waveform/fillgaps',...
               ' to replace the NaN values.']);
         end
         
         [xunit, xfactor] = Tracespectra.parse_xunit(xChoice);
         
         switch lower(xunit)
            case 'date'
               % we need the actual times...
               Xvalues = get(ws,'timevector');
               
            case 'day of year'
               startvec = datevec(get(ws,'start'));
               Xvalues = get(ws,'timevector');
               dec31 = datenum(startvec(1)-1,12,31); % 12/31/xxxx of previous year in Matlab format
               Xvalues = Xvalues - dec31;
               xunit = [xunit, ' (', datestr(startvec,'yyyy'),')'];
               
            otherwise,
               dl= 1:numel(ws.data); %dl : DataLength
               Xvalues = dl .* ws.period ./ xfactor;
         end
         
         
         %%  once was function specgram(d, NYQ, nfft, noverlap, freqmax, dBlims)
         
         nx = length(ws.data);
         window = hanning(s.nfft);
         nwind = length(window);
         if nx < nwind    % zero-pad x if it has length less than the window length
            ws.data(nwind) = 0;
            nx = nwind;
         end
         
         ncol = fix( (nx - s.over) / (nwind - s.over) );
         
         %added "floor" below
         colindex = 1 + floor(0:(ncol-1))*(nwind- s.over);
         rowindex = (1:nwind)';
         if length(ws.data)<(nwind+colindex(ncol)-1)
            ws.data(nwind+colindex(ncol)-1) = 0;   % zero-pad x
         end
         
         y = zeros(nwind,ncol);
         
         % put x into columns of y with the proper offset
         % should be able to do this with fancy indexing!
         A_ = colindex(  ones(nwind, 1) ,: )    ;
         B_ = rowindex(:, ones(1, ncol)    )    ;
         y(:) = ws.data(fix(A_ + B_ -1));
         clear A_ B_
         
         for k = 1:ncol;         %  remove the mean from each column of y
            y(:,k) = y(:,k)-mean(y(:,k));
         end
         
         % Apply the window to the array of offset signal segments.
         y = window(:,ones(1,ncol)).*y;
         
         % USE FFT
         % now fft y which does the columns
         y = fft(y,s.nfft);
         if ~any(any(imag(ws.data)))    % x purely real
            if rem(s.nfft,2),    % nfft odd
               select = 1:(s.nfft+1)/2;
            else
               select = 1:s.nfft/2+1;
            end
            y = y(select,:);
         else
            select = 1:s.nfft;
         end
         f = (select - 1)' * ws.samplerate / s.nfft;
                  
         NF = s.nfft/2 + 1;
         nf1=round(f(1) / ws.nyquist * NF);                     %frequency window
         if nf1==0, nf1=1; end
         nf2=NF;
         
         y = 20*log10(abs(y(nf1:nf2,:)));
         
         F = f(f <= s.freqmax);
         
         
         if F(1)==0,
            F(1)=0.001;
         end
         
         if logscale
            t = linspace(Xvalues(1), Xvalues(end),ncol); % Replaced by TCB - 01/18/2012
            try
               h = uimagesc(t, log10(F), y(nf1:length(F),:), s.dBlims);
            catch exception
               if strcmp(exception.identifier, 'MATLAB:UndefinedFunction')
                  warning('Spectralobject:specgram:uimageNotInstalled',...
                     ['Cannot plot with log spacing because uimage, uimagesc ',...
                     ' not installed or not visible in matlab path.']);
                  h = imagesc(Xvalues,F,y(nf1:length(F),:),s.dBlims);
                  logscale = false;
               else
                  rethrow(exception)
               end
            end
         else
            h = imagesc(Xvalues, F, y(nf1:length(F),:), s.dBlims);
         end
         set(gca, 'fontsize', currFontSize);
         if strcmpi(xunit, 'date')
            datetick('x', 'keepticks');
         end
         titlename = [ws.station '-' ws.channel '  from:' ws.start];
         title (titlename);
         axis xy;
         colormap(alternateMap);
         shading flat
         axis tight;
         if useYlabel
            if ~logscale
               ylabel ('Frequency (Hz)')
            else
               ylabel ('Log Frequency (log Hz)')
            end
            
         end
         if useXlabel
            xlabel(['Time - ',xunit]);
         end

         %create the colorbar if desired
         Tracespectra.createcolorbar(s,colorbarpref, clabel, currFontSize);
         
         %% added a series of functions that help with argument parsing.
         % These were ported from my waveform/plot function.
         

      end %specgram
      function h = specgram2(s, ws, varargin)
         %SPECGRAM2 - plots spectrograms of waveforms with waveform along top
         %  h = specgram2(spectralobject, waveforms) generates a spectrogram from
         %  the waveform(s), overwriting the current figure.  The waveform will be
         %  displayed along the top of the spectrogram. The return value is a handle
         %  to the spectrogram, and is optional.
         %
         %  The spectrograms will be created in the same shape as the passed
         %  waveforms.  ie, if W is a 2x3 matrix of waveforms, then
         %  specgram2(spectralobject,W) will generate a 2x3 plot of spectra.
         %
         %  Many additional behaviors can be modified through the passing of
         %  additional parameters, as listed further below.  These parameters are
         %  always passed in pairs, as such:
         %
         %  specgram2(spectralobject, waveforms,'PARAM1',VALUE1,...,'PARAMn',VALUEn)
         %    Any number of these parameters may be passed to specgram2.
         %
         %  specgram2(..., 'axis', AXIS_HANDLE)
         %    Specify the axis AXIS_HANDLE within which the spectrogram will be
         %    generated.  The boundary of the axis becomes the boundary for the
         %    entire spectra plot.  For a matrix of waveforms, this area is
         %    subdivided into NxM subplots, where N and M are the size of the
         %    waveform matrix.
         %
         %  specgram2(..., 'xunit', XUNIT)
         %    Spedifies the x-unit scale to be used with the spectrogram.  The
         %    default unit is 'seconds'.
         %    valid xunits:
         %     'seconds','minutes','hours','days','doy' (day of year),and 'date'
         %
         %  specgram2(..., 'colormap', ALTERNATEMAP)
         %    Instead of using the default colormap, any colormap may be used.  An
         %    alternate way of setting the global map is by using the SETMAP
         %    function.  ALTERNATEMAP will either be a name (eg. grayscale) or an
         %    Nx3 numeric. Type HELP GRAPH3D to see additional useful colormaps.
         %
         %
         %  specgram2(..., 'colorbar', COLORBAR_OPTION)
         %    Generates a spectrogram from the waveform and uses a specific map
         %    valid COLORBAR_OPTION values: 'horiz' (default),'vert','none',
         %      'HORIZ' places a single colorbar below all plots
         %      'VERT' places a single colorbar to the right of all plots
         %      'NONE' supresses the colorbar placement
         %
         %  specgram2(..., 'yscale', YSCALE)
         %    Choosing 'log' Allows the y-axis to be generated on a log-frequency
         %    scale, with uneven vertical cell spacing.  The default value is
         %    'normal', and provides the standard spectrogram view.
         %    valid yscales: 'normal', 'log' (see NOTE below)
         %
         %    NOTE: In order to use the log scale, UIMAGESC needs to be available on
         %    the matlab path.  This routine was created by Frederic Moisy, and may
         %    be downloaded from the maltabcentral fileexchange (File ID: 11368).
         %    If this routine is not found,then the original spectrogram will be
         %    created.
         %
         %  specgram2(..., 'fontsize', FONTSIZE)
         %    Specify the font size for a spectrogram.  The default font size is 8.
         %
         %  specgram2(..., 'innerLabels', SHOWINNERLABELS)
         %    Suppress the labling of the inside graphs by setting SHOWINNERLABELS
         %    to false.  If this is false, then the frequency label only shows on
         %    the leftmost spectrograms, and the X-unit label only shows on the
         %    bottommost spectrograms.
         %
         %  Example 1:
         %    % The following plots a waveform using an alternate mapping, an xunit of
         %    % of 'hours', and with the y-axis plotted using a log scale.
         %    specgram2(spectralobject, waveform,...
         %      'colormap', alternateMap,'xunit','h','yscale','log')
         %
         %
         %  Example 2:
         %    % create an arbitrary subplot, and then plot multiple spectra
         %    a = subplot(3,2,1);
         %    specgram2(spectralobject,waves,'axis',a); % waves is an NxM waveform
         %
         %   See also SPECTRALOBJECT/SPECGRAM
         
         % enforce input arguments.
         if ~isa(ws,'TraceData')
            error('Spectralobject:specgram2:invalidArgument','Second input argument should be a waveform, not a %s',class(ws));
         end
         
         hasExtraArg = mod(numel(varargin),2);
         if hasExtraArg
            error('Spectralobject:DepricatedArgument',...
               ['spectralobject/specgram2 now requires parameter ',...
               'pairs.  Most likely, you tried to call spectrogram with an ',...
               'axis without specifying the property ''axis''',...
               ' See help spectralobject/specgram for new usage instructions.']);
         else
            proplist=  Tracespectra.parseargs(varargin);
         end
         
         %% search for relevent property pairs passed as parameters
         
         % AXIS: a handle to the axis, defining the area to be used
         [~,myaxis,proplist] = Tracespectra.getproperty('axis',proplist,0);
         
         % POSITION: 1x4 vector, specifying area in which to plot
         %          [left, bottom, width, height]
         [~,mypos,proplist] = Tracespectra.getproperty('position',proplist,[]);
         
         % COLORBAR: Dictate the position of the colorbart relative to the plot
         [~,colorbarpref,proplist] = Tracespectra.getproperty('colorbar',proplist,'horiz');
         
         % XUNIT: Specify the time units for the plot.  eg, hours, minutes, doy, etc.
         [~, xChoice, proplist] =...
            Tracespectra.getproperty('xunit',proplist,s.scaling);
         
         % FONTSIZE: specify the font size to be used for all labels within the plot
         [~, currFontSize, proplist] =...
            Tracespectra.getproperty('fontsize',proplist,8); %default font size or override?
         
         % YSCALE: either 'normal', or 'log'
         [~, yscale, proplist] = ...
            Tracespectra.getproperty('yscale',proplist,'normal'); %default yscale to 'normal'
         
         % SUPRESSINNERLABELS: true, false
         [~, suppressLabels, proplist] = ...
            Tracespectra.getproperty('innerlabels',proplist,false); %only show outside
         
         % SUPRESSXLABELS: true, false
         [~, useXlabel, proplist] = ...
            Tracespectra.getproperty('useXlabel',proplist,true); %show no x, y labels
         % SUPRESSXLABELS: true, false
         [~, useYlabel, proplist] = ...
            Tracespectra.getproperty('useYlabel',proplist,true); %show no x, y labels
         
         %% figure out exactly WHERE to plot the spectrogram(s)
         %find out area(axis) in which the spectrograms will be plotted
         clabel= 'Relative Amplitude  (dB)';
         
         if myaxis == 0,
            clf;
            pos = get(gca,'position');
         else
            pos = get(myaxis,'position');
         end
         if ~isempty(mypos) %position
            pos = myaxis;
         end
         
         left = pos(1); bottom=pos(2); width=pos(3); height=pos(4);
         
         %% If there are multiple waveforms...
         % subdivide the axis and loop through specgram2 with individual waveforms.
         
         if numel(ws) > 1
            if myaxis== 0,
               myaxis = gca;
            end
            %create the colorbar if desired
            Tracespectra.createcolorbar(s,colorbarpref, clabel, currFontSize);
            h = Tracespectra.subdivide_axes(myaxis,size(ws));
            remainingproperties = Tracespectra.property2varargin(proplist);
            for n=1:numel(h)
               keepYlabel =  ~suppressLabels || (n <= size(h,1));
               keepXlabel = ~suppressLabels || (mod(n,size(h,2))==0);
               specgram2(s,ws(n),...
                  'xunit',xChoice,...
                  'axis',h(n),...
                  'fontsize',currFontSize,...
                  'useXlabel',keepXlabel,...
                  'useYlabel',keepYlabel,...
                  'colorbar','none',...
                  remainingproperties{:});
               
            end
            return
         end
         
         %% Plot the spectrogram with a wiggle on top and colorbar below
         
         % Define the area for both the wiggle and spectra
         wavepos = [ left, bottom + height * 0.85,  width , height * 0.15] ;
         specpos = [ left, bottom, width, height * 0.85 ];
         
         %plot the wiggle
         subplot('position',wavepos);
         plot(ws,'xunit',xChoice,'autoscale',true,'fontsize',currFontSize);
         
         % make the axis tight, and keep axis info for later use with spectra
         axis tight;
         xAxisLims = get(gca,'xlim');
         ticnos = get(gca,'xtick');
         
         %plot the spectra
         a = subplot('position',specpos);
         specgram(s,ws,...
            'xunit',xChoice,...
            'fontsize',currFontSize,...
            'yscale',yscale,...
            'colorbar','none',...
            'axis',a,...
            'suppressXlabel',useXlabel,...
            'suppressYlabel',useYlabel,...
            varargin{:});
         
         %make the axis match exactly with the waveform above
         set(gca,'xtick',ticnos);
         if ~strcmpi(yscale,'log')
            % axis scaling doesn't work quite right at a log scale
            xlim(xAxisLims);
         end
         
         title(''); %clear the title
         
         %create the colorbar if desired
         Tracespectra.createcolorbar(s,colorbarpref, clabel, currFontSize);
      end
      function [varargout] = fft(s, w)
         %FFT Discrete Fourier transform.  OVERLOADED for waveform & Spectralobject
         %   USAGE
         %       v = fft(s, w);      % get the fft only
         %       [v, f] = fft(s,w);  % get the fft & assoc. frequencies
         %       [v, f, Pyy] = fft(s,w); % get fft, frequencies, and Power Spectrum
         %
         %   See also SPECTRALOBJECT/IFFT, FFT, FFT2, FFTN, FFTSHIFT, FFTW, IFFT2, IFFTN, WAVEFORM/FILLGAPS.
         
         if nargin < 2
            error('Spectralobject:fft:insufficientArguments', 'Not enough input arguments. [out]=fft(spectralobject, waveform)');
         end
         
         if ~isscalar(w)
            error('Spectralobject:fft:nonScalarWaveform', 'waveform must be scalar (1x1)');
         end
         
         if ~isa(w,'waveform')
            error('Spectralobject:fft:invalidArgument',...
               'second argument expected to be WAVEFORM, but was [%s]', class(w));
         end
         
         if any(isnan(double(w)))
            warning('Spectralobject:fft:nanValue',...
               ['This waveform has at least one NaN value, which returns NaN ',...
               'results. Remove NaN values by either splitting up the ',...
               'waveform into non-NaN sections or by using waveform/fillgaps',...
               ' to replace the NaN values.']);
         end
         
         varargout{1} = builtin('fft', double(w));
         varargout{2} = w.samplerate * (0:fix(s.nfft ./ 2)) / [s.nfft];
         varargout{3} = varargout{1}.* conj(varargout{1}) / [s.nfft];
         varargout{3} = varargout{3}(1:length(varargout{2}));
      end
      function [varargout] = ifft(s, w)
         %IFFT Inverse discrete Fourier transform.  OVERLOADED FOR Spectralobject
         %   IFFT(spectralobject, X) is the N-point inverse discrete Fourier
         %   transform of X, using the spectralobject's NFFT value for N.
         %
         %   See also SPECTRALOBJECT/FFT, FFT, FFT2, FFTN, FFTSHIFT, FFTW, IFFT2, IFFTN.
         
         if nargin < 2
            error('Spectralobject:ifft:insufficientArguments',...
               'Not enough input arguments. [out]=ifft(spectralobject, waveform)');
         end
         
         if numel(w) > 1
            error('Spectralobject:ifft:nonScalarWaveform', 'waveform must be scalar (1x1)');
         end
         
         if ~isa(w,'TraceData')
            error('Spectralobject:ifft:invalidArgument',...
               'argument expected to be Trace, but was [%s]', class(w));
         end
         
         if nargout == 0
            builtin('ifft', double(w), get(s,'nfft'));
         else
            [varargout{1:nargout}] = builtin('ifft', double(w), get(s,'nfft'));
         end
      end
      function [varargout] = pwelch(s,w, varargin)
         %PWELCH   overloaded pwelch for spectralobjects
         %   pwelch(spectralobject, waveform) - plots the spectral density
         %       Pxx = pwelch(spectralobject, waveform) - returns the Power Spectral
         %           Density (PSD) estimate, Pxx, of a discrete-time signal
         %           vector X using Welch's averaged,  modified periodogram method.
         %       [Pxx, Freqs] = pwelch(spectralobject, waveform) - returns spectral
         %       density and associated frequency bins.
         %
         %       Options, pwelch(s,w, 'DEFAULT') - plots the spectral density using
         %       pwelch's defaults (8 averaged windows, 50% overlap)
         %   window is length of entire waveform..
         %
         %   NOTE: voltage offsets may cause a large spike for lowest Pxx value.
         %   NOTE: NaN values will result in blank
         %
         % See also pwelch, waveform/fillgaps
         
         if nargin < 2
            error('Spectralobject:pwelch:insufficientArguments',...
               'usage: [out] = pwelch(spectralobject, waveform, [''default'']');
         end
         
         if ~isscalar(w)
            error('Spectralobject:pwelch:nonScalarWaveform',...
               'waveform must be scalar (1x1)');
         end
         
         if ~isa(w,'waveform')
            error('Spectralobject:pwelch:invalidArgument',...
               'second argument expected to be WAVEFORM, but was [%s]', class(w));
         end
         
         if any(isnan(double(w)))
            warning('Spectralobject:pwelch:nanValue',...
               ['This waveform has at least one NaN value. ',...
               'Remove NaN values by either splitting up the',...
               ' waveform into non-NaN sections or by using ',...
               'waveform/fillgaps to replace the NaN values.']);
         end
         if nargin == 3
            if strcmpi(varargin{1}, 'DEFAULT')
               %disp('defaulting')
               window = [];
               over = [];
            end
         end
         [varargout{1:nargout}] =  pwelch(double(w),numel(w.data),s.over,s.nfft,w.samplerate);
      end
      
      function handle = colorbar_axis(s,loc,clabel,rlab1,rlab2, fontsize)
         % COLORBAR - Display color bar (color scale).
         %
         %   This function differs from colorbar(loc,clabel,rlab1,rlab2) in that
         %   only a portion of the colorbar defined by the plot axis "paxis" is shown
         %
         %       s.dBlims is the [2] vector containing the plotting axis limits
         %       paxis   is the [2] vector containing the plotting axis limits
         %               that are used to limit the portion of the colorbar shown
         %
         %	COLORBAR('vert') appends a vertical color scale to
         %	the current axis. COLORBAR('horiz') appends a
         %	horizontal color scale.
         %
         %	COLORBAR(H) places the colorbar in the axes H. The
         %	colorbar will be horizontal if the axes width > height.
         %
         %	COLORBAR without arguments either adds a new vertical
         %	color scale or updates an existing colorbar.
         %
         %	H = COLORBAR(...) returns a handle to the colorbar axis.
         %
         %       clabel  is the string containing the colorbar axis label
         %       rlab1   is the string label for the lower limit plotted
         %       rlab2   is the string label for the upper limit plotted
         %
         %
         
         % AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
         % $Date$
         % $Revision$
         
         %return
         
         %set (gca, 'FontSize', 8)
         if ~exist('fontsize','var')
            fontsize = 8;
         end;
         if nargin<1,
            echo ' Error:  vector of plot-axis limits required'
            echo '         else,  use: '
            echo '    colorbar_axis(spectralobject,loc,clabel,rlab1,rlab2)'
            return
         end
         
         if nargin>1,
            lower=s.dBlims(1);
            upper=s.dBlims(2);
            paxis = s.dBlims;
         end
         
         if nargin<2,
            loc = 'vert';
         end
         
         ax = [];
         if nargin==2,
            if ~ischar(loc),
               ax = loc;
               if ~strcmp(get(ax,'type'),'axes'),
                  error('Requires axes handle.');
               end
               rect = get(ax,'position');
               if rect(3) > rect(4), loc = 'horiz'; else loc = 'vert'; end
            end
         end
         
         % Determine color limits by context.  If any axes child is an image
         % use scale based on size of colormap, otherwise use current CAXIS.
         
         ch = get(gca,'children');
         hasimage = 0; t = [];
         for i=1:length(ch),
            if strcmp(get(ch(i),'type'),'image'),
               hasimage = 1;
               t = get(ch(i),'UserData'); % Info stored by imshow or imagesc
            elseif strcmp(get(ch(i),'Type'),'surface'), % Texturemapped surf?
               if strcmp(get(ch(i),'FaceColor'),'texturemap')
                  hasimage = 2;
                  t = get(ch(i),'UserData'); % Info stored by imshow or imagesc
               end
            end
         end
         if hasimage,
            if isempty(t),
               t = [0.5 size(colormap,1)+0.5];
            end
         else
            t = paxis;
            cmin=t(1);
            cmax=t(2);
         end
         
         h = gca;
         
         if nargin==1,
            % Search for existing colorbar
            ch = get(gcf,'children'); ax = [];
            for i=1:length(ch),
               d = get(ch(i),'userdata');
               if numel(d)==1,
                  if d==h,
                     ax = ch(i);
                     pos = get(ch(i),'Position');
                     if pos(3)<pos(4), loc = 'vert';
                     else loc = 'horiz';
                     end
                     break;
                  end
               end
            end
         end
         
         if strcmp(get(gcf,'NextPlot'),'replace'),
            set(gcf,'NextPlot','add')
         end
         set(gca,'FontSize',fontsize);
         fsize=get(gca,'FontSize');          %get fontsize and shift if>16
         %vshift=0;
         %if fsize>16, vshift=.25; end
         
         %------------------------------------------------------------------------
         
         if loc(1)=='v',        % Append VERTICAL scale to right of current plot
            stripe = 0.075; edge = 0.02;
            
            if isempty(ax),
               pos = get(h,'Position');
               [az,el] = view;
               if all([az,el]==[0 90]), space = 0.05; else space = .1; end
               set(h,'Position',[pos(1) pos(2) pos(3)*(1-stripe-edge-space) pos(4)])
               rect = [pos(1)+(1-stripe-edge)*pos(3) pos(2) stripe*pos(3)*.5 pos(4)];
               
               % Create axes for stripe
               ax = axes('Position', rect);
            else
               axes(ax);
            end
            
            % Create color stripe
            n = size(colormap,1);
            image([0 1],t,[1:n]'); set(ax,'Ydir','normal')
            
            if nargin>2,
               set(ax,'ylabel',text(0,0,clabel, 'FontSize', fontsize));
            end
            
            xpos = get(ax,'Xlim');
            ypos = get(ax,'Ylim');
            if nargin>3,
               xshift=.5*(xpos(2)-xpos(1));
               yshift=.05*(ypos(2)-ypos(1));
               if nargin==4,        %put color range  max label on colorbar
                  text(xpos(2)-xshift,ypos(2)+yshift,0.,rlab1);
               end
               if nargin==5,        %put color range min, max labels on colorbar
                  text(xpos(1)-xshift,ypos(1)-.75*yshift,0.,rlab1);
                  text(xpos(1)-xshift,ypos(2)+yshift,0.,rlab2);
               end
            end
            %d=date;
            yshift=.12*(ypos(2)-ypos(1));
            %  text(xpos(1)+2.0,ypos(1)-yshift,0.,d)
            
            % Create color axis
            ylim = get(ax,'ylim');   % Note: axis ticlabel range will be truncated
            units = get(ax,'Units'); set(ax,'Units','pixels');
            pos = get(ax,'Position');
            set(ax,'Units',units);
            yspace = get(ax,'FontSize')*(ylim(2)-ylim(1))/pos(4)/2;
            xspace = .5*get(ax,'FontSize')/pos(3);
            yticks = get(ax,'ytick');
            ylabels = get(ax,'yticklabel');
            labels = []; width = [];
            
            set (gca, 'FontSize', fontsize)  %This sets the font size
            for i=1:length(yticks),
               labels = [labels;text(1+0*xspace,yticks(i),deblank(ylabels(i,:)), ...
                  'HorizontalAlignment','right', ...
                  'VerticalAlignment','middle', ...
                  'FontName',get(ax,'FontName'), ...
                  'FontSize',get(ax,'FontSize'), ...
                  'FontAngle',get(ax,'FontAngle'), ...
                  'FontWeight',get(ax,'FontWeight'))];
               width = [width;get(labels(i),'Extent')];
            end
            
            % Shift labels over so that they line up
            [dum,k] = max(width(:,3)); width = width(k,3);
            for i=1:length(labels),
               pos = get(labels(i),'Position');
               set(labels(i),'Position',[pos(1)+width pos(2:3)])
            end
            
            % If we need an exponent then draw one
            [ymax,k] = max(abs(yticks));
            if abs(abs(str2num(ylabels(k,:)))-ymax)>sqrt(eps),
               ex = log10(max(abs(yticks)));
               ex = sign(ex)*ceil(abs(ex));
               l = text(0,ylim(2)+2*yspace,'x 10', ...
                  'FontName',get(ax,'FontName'), ...
                  'FontSize',get(ax,'FontSize'), ...
                  'FontAngle',get(ax,'FontAngle'), ...
                  'FontWeight',get(ax,'FontWeight'));
               width = get(l,'Extent');
               text(width(3)-xspace,ylim(2)+3.2*yspace,num2str(ex), ...
                  'FontName',get(ax,'ExpFontName'), ...
                  'FontSize',get(ax,'ExpFontSize'), ...
                  'FontAngle',get(ax,'ExpFontAngle'), ...
                  'FontWeight',get(ax,'ExpFontWeight'));
            end
            
            set(ax,'yticklabelmode','manual','yticklabel','')
            set(ax,'xticklabelmode','manual','xticklabel','')
            
            %set(gca,'ytick',[])
            %------------------------------------------------------------------------
            %------------------------------------------------------------------------
         else            % Append HORIZONTAL scale to bottom of current plot
            
            if isempty(ax),
               pos = get(h,'Position');           %[left,bottom,width,height]
               stripe = 0.05; space = 0.1;       %stripe = 0.075
               ori=get(gcf,'paperorientation');
               if fsize<=16,
                  sfact=1;
               else
                  sfact=2;
               end
               %    if ori=='landscape', stripe = 0.05; end
               %    if fsize<=26,
               %      set(h,'Position',...
               %        [pos(1) pos(2)+(stripe+space)*pos(4) pos(3) (1-stripe-space)*pos(4)])
               %    else
               set(h,'Position',...
                  [pos(1) pos(2)+(sfact*stripe+space)*pos(4) pos(3) (1-stripe-space)*pos(4)])
               %    end
               rect = [pos(1) pos(2) pos(3) stripe*pos(4)*.8];
               
               % Create axes for stripe
               ax = axes('Position', rect);
            else
               axes(ax);
            end
            
            t = paxis;
            cmin=t(1);
            cmax=t(2);
            
            % Create color stripe
            n = size(colormap,1);
            if paxis(1)>cmin,
               diff=paxis(1)-cmin;
               cstep=(cmax-cmin)/n;
               n1=round(diff/cstep);
            else
               n1=1;
            end
            if paxis(2)<cmax,
               diff=cmax-paxis(2);
               cstep=(cmax-cmin)/n;
               n2=n-round(diff/cstep);
            else
               n2=n;
            end
            
            %  image(t,[0 1],[1:n]); set(ax,'Ydir','normal')
            image(t,[0 1],[n1:n2]); set(ax,'Ydir','normal')
            set(ax,'yticklabelmode','manual')
            set(ax,'yticklabel','')
            
            set (gca, 'FontSize', fontsize)  %This sets the font size
            if nargin>2,
               set(ax,'xlabel',text(0,0,clabel, 'FontSize', fontsize));
            end
            
            xpos = get(ax,'Xlim');
            ypos = get(ax,'Ylim');
            if nargin>3,
               xshift=.025*(xpos(2)-xpos(1));
               if nargin==4,        %put color range  max label on colorbar
                  text(xpos(2)-xshift,ypos(1)-1.0,0.,rlab1);
               end
               if nargin==5,        %put color range min, max labels on colorbar
                  text(xpos(1)-xshift,ypos(1)-1.0,0.,rlab1);
                  text(xpos(2)-xshift,ypos(1)-1.0,0.,rlab2);
               end
            end
            d=date;
            xshift=.15*(xpos(2)-xpos(1));
            %  text(xpos(1)-xshift,ypos(1)-3.5,0.,d)
            
            %set(gca,'xtick',[])
         end
         %------------------------------------------------------------------------
         %------------------------------------------------------------------------
         
         set(ax,'userdata',h)
         set(gcf,'CurrentAxes',h)
         set(gcf,'Nextplot','Replace')
         
         if nargout>0, handle = ax; end
      end
   end %methods
   methods(Static, Access=protected)
      function [unitName, secondMultiplier] = parse_xunit(unitName)
         % PARSE_XUNIT returns a labelname and a multiplier for an incoming xunit
         % value.  This routine was removed to centralize this function
         % [unitName, secondMultiplier] = parse_xunit(unitName)
         
         switch lower(unitName)
            case {'m','minutes'}
               unitName = 'Minutes';
               secondMultiplier = 60;
            case {'h','hours'}
               unitName = 'Hours';
               secondMultiplier = 3600;
            case {'d','days'}
               unitName = 'Days';
               secondMultiplier = 86400;
            case {'doy','day_of_year'}
               unitName = 'Day of Year';
               secondMultiplier = 86400;
            case 'date',
               unitName = 'Date';
               secondMultiplier = nan; %inconsequential!
            case {'s','seconds'}
               unitName = 'Seconds';
               secondMultiplier = 1;
            otherwise,
               unitName = 'Seconds';
               secondMultiplier = 1;
         end
      end
      function sub_h = subdivide_axes(h,sizes)
         % returns handles for sub-axes of axis(h).  These axes are createdb y
         % subdividing h into sections according to SIZES, where sizes is a
         % 2-component vector corresponding to [nCol, nRow];
         % example:
         %   subplot(3,3,5); % break figure into 3x3 grid, and select the center
         %   % let w be an NxM object array
         %   h = subdivide_axes(gca, size(w));
         %   for n=1:numel(h)
         %     plot(h,somethingToPlot);
         %   end
         %
         % axis h is cleared, then subaxes are created.  This function returns an
         % NxM array of handles to the subaxes.
         
         rect = get(h,'position');
         nCol = sizes(2);
         nRow = sizes(1);
         left = rect(1);
         bottom = rect(2);
         width = rect(3);
         height = rect(4);
         %top = bottom - height;
         
         if sizes(1) == 1
            newMaxHeight  = height; % unchanged # of rows
         else
            newMaxHeight = height / nRow .* 0.85;
            bottom = linspace(bottom,  (bottom+height)-newMaxHeight,nRow);
         end
         if sizes(2) == 1
            
            newMaxWidth = width; % unchanged # of columns
         else
            newMaxWidth = width / nCol .* 0.93;
            left = linspace(left, (left+width) - newMaxWidth, nCol);
         end
         delete(h);
         sub_h = zeros(nRow,nCol);
         for c = 1:nCol
            for r = 1:nRow
               sub_h(r,c) = subplot('position', [left(c) bottom(r) newMaxWidth newMaxHeight]);
            end
         end
         sub_h = flipud(sub_h);
      end
      function specmap = loadmap()
         
         if exist('spectral.map','file')
            specmap = load('spectral.map','-ascii');
         else
            specmap =[...
               0         0    0.5625
               0         0    0.6250
               0         0    0.6875
               0         0    0.7500
               0         0    0.8125
               0         0    0.8750
               0         0    0.9375
               0         0    1.0000
               0    0.0625    1.0000
               0    0.1250    1.0000
               0    0.1875    1.0000
               0    0.2500    1.0000
               0    0.3125    1.0000
               0    0.3750    1.0000
               0    0.4375    1.0000
               0    0.5000    1.0000
               0    0.5625    1.0000
               0    0.6250    1.0000
               0    0.6875    1.0000
               0    0.7500    1.0000
               0    0.8125    1.0000
               0    0.8750    1.0000
               0    0.9375    1.0000
               0    1.0000    1.0000
               0.0625    1.0000    1.0000
               0.1250    1.0000    0.9375
               0.1875    1.0000    0.8750
               0.2500    1.0000    0.8125
               0.3125    1.0000    0.7500
               0.3750    1.0000    0.6875
               0.4375    1.0000    0.6250
               0.5000    1.0000    0.5625
               0.5625    1.0000    0.5000
               0.6250    1.0000    0.4375
               0.6875    1.0000    0.3750
               0.7500    1.0000    0.3125
               0.8125    1.0000    0.2500
               0.8750    1.0000    0.1875
               0.9375    1.0000    0.1250
               1.0000    1.0000         0
               1.0000    0.9375         0
               1.0000    0.8750         0
               1.0000    0.8125         0
               1.0000    0.7500         0
               1.0000    0.6875         0
               1.0000    0.6250         0
               1.0000    0.5625         0
               1.0000    0.5000         0
               1.0000    0.3750         0
               1.0000    0.2500         0
               1.0000    0.1250         0
               1.0000         0         0
               0.9375         0    0.6375
               0.9375    0.1500    0.9375
               1.0000    0.8000    1.0000];
         end
      end
      function [properties] = parseargs(arglist)
         % parse the incoming arguments, returning a cell with each parameter name
         % as well as a cell for each parameter value pair.  parseargs will also
         % doublecheck to ensure that all pnames are actually strings... otherwise,
         % we're looking at a mis-parse.
         %check to make sure these are name-value pairs
         % from both specgram and specgram2
         argcount = numel(arglist);
         evenArgumentCount = mod(argcount,2) == 0;
         if ~evenArgumentCount
            error('ParseArgs:propertyMismatch',...
               'Odd number of arguments means that these arguments cannot be parameter name-value pairs');
         end
         
         %assign these to output variables
         properties.name = arglist(1:2:argcount);
         properties.val = arglist(2:2:argcount);
         
         %
         for i=1:numel(properties.name)
            if ~ischar(properties.name{i})
               error('ParseArgs:invalidPropertyName',...
                  'All property names must be strings.');
            end
         end
      end
      function [isfound, foundvalue, properties] = getproperty(desiredproperty,properties,defaultvalue)
         %returns a property value (if found) from a property list, removing that
         %property pair from the list.  only removes the first encountered property
         %name.
         % from both specgram and specgram2
         pmask = strcmpi(desiredproperty,properties.name);
         isfound = any(pmask);
         if isfound
            foundlist = find(pmask);
            foundidx = foundlist(1);
            foundvalue = properties.val{foundidx};
            properties.name(foundidx) = [];
            properties.val(foundidx) = [];
         else
            if exist('defaultvalue','var')
               foundvalue = defaultvalue;
            else
               foundvalue = [];
            end
            % do nothing to properties...
         end
      end
      function c = property2varargin(properties)
         %convert the properties structure into something that can be passed as a
         %parameter into a function
         % from both specgram and specgram2
         c = {};
         c(1:2:numel(properties.name)*2) = properties.name;
         c(2:2:numel(properties.name)*2) = properties.val;
      end
      function hbar = createcolorbar(s, colorbarpref, clabel, currFontSize)
         % createcolorbar(spec, colorbarpref, clabel, fontsize)
         % used by specgram and specgram2
         if ~strcmpi(colorbarpref,'none')
            hbar = colorbar_axis(s,colorbarpref,clabel,'','',currFontSize);
            set(hbar,'fontsize',currFontSize)
         end
      end
   end
end

