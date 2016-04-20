function h = specgram2(s, T, varargin)
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
   
   if ~isa(T,'TraceData')
            try
               T = SeismicTrace(T);
               disp('successfully converted to a SeismicTrace');
            catch er
      error('Spectralobject:specgram2:invalidArgument','Should work on a trace (ex. TraceData, SeismicTrace), not a %s',class(T));
            end
   end
   
   %% search for relevent property pairs passed as parameters
   p = parseSpecgramInputs(s, varargin);
   
   %% figure out exactly WHERE to plot the spectrogram(s)
   %find out area(axis) in which the spectrograms will be plotted
   clabel= 'Relative Amplitude  (dB)';
   
   if p.Results.axis == 0,
      clf;
      pos = get(gca,'position');
   else
      pos = get(p.Results.axis,'position');
   end
   if ~isempty(p.Results.position)
      pos = p.Results.position;
   end
      
   %% If there are multiple waveforms...
   % subdivide the axis and loop through specgram2 with individual waveforms.
   if numel(T) > 1
      if p.Results.axis== 0,
         myaxis = gca;
      end
      %create the colorbar if desired
      TraceSpectra.createcolorbar(s,p.Results.colorbar, clabel, p.Results.fontsize);
      h = TraceSpectra.subdivide_axes(myaxis, size(T));
      % remainingproperties = TraceSpectra.property2varargin(proplist);
      remainingproperties = TraceSpectra.buildParameterList( p.Unmatched);
      for n=1:numel(h)
         keepYlabel =  ~p.Results.innerlabels || (n <= size(h,1));
         keepXlabel = ~p.Results.innerlabels || (mod(n,size(h,2))==0);
         specgram2(s,T(n),...
            'xunit',p.Results.xunit,...
            'axis',h(n),...
            'fontsize',p.Results.fontsize,...
            'useXlabel',keepXlabel,...
            'useYlabel',keepYlabel,...
            'colorbar','none',...
            remainingproperties{:});
      end
      return
   end
   
   %% Plot the spectrogram with a wiggle on top and colorbar below
   
   %plot the wiggle
   ax_wiggle = subplot('position',wigglePosition(pos));
   plot(T,'xunit',p.Results.xunit,'autoscale',true,'fontsize',p.Results.fontsize);
   
   % make the axis tight, and keep axis info for later use with spectra
   axis(ax_wiggle,'tight');
   xAxisLims = get(ax_wiggle,'xlim');
   ticnos = get(ax_wiggle,'xtick');
   
   %plot the spectra
   ax_spectra = subplot('position',spectraPosition(pos));
   additionalParams = TraceSpectra.buildParameterList( p.Unmatched);
   specgram(s,T,...
      'xunit',p.Results.xunit,...
      'fontsize',p.Results.fontsize,...
      'yscale',p.Results.yscale,...
      'colorbar','none',...
      'axis',ax_spectra,...
      'suppressXlabel',p.Results.useXlabel,...
      'suppressYlabel',p.Results.useYlabel,...
      additionalParams{:});
   
   %make the axis match exactly with the waveform above
   set(ax_spectra,'xtick',ticnos);
   if ~strcmpi(p.Results.yscale,'log')
      % axis scaling doesn't work quite right at a log scale
      xlim(ax_spectra, xAxisLims);
   end
   
   title(''); %clear the title
   
   %create the colorbar if desired
   TraceSpectra.createcolorbar(s,p.Results.colorbar, clabel, p.Results.fontsize);
end

function wigPos = wigglePosition(pos)
   % wigglePosition   wiggle occupies the top 15% of the axis
   % pos = [ left, bottom, width, height ]   
   % wavepos = [ left, bottom + height * 0.85,  width , height * 0.15] ;
   wigPos = pos .* [1, 1, 1, 0.15] + [0,  pos(4) * 0.85, 0, 0] ;
end

function specPos = spectraPosition(pos)
   %spectraPosition   spectra occupies the bottom 85% of the axis
   specPos = pos .* [1, 1, 1, 0.85 ];
end
