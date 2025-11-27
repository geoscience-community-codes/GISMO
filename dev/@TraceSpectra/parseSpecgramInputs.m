function p = parseSpecgramInputs(me, cellOfArgs)
   %parseSpecgramInputs   handles inputs for specgram functions
   %   p = parseSpecgramInputs(obj, cell_of_arguments) will parse the
   %   cell of arguments into an inputParser.  specgram-specific
   %   arguments will be returned in p.Results, while any additional
   %   arguments will be returned in p.Unmatched.
   %
   %   specifically looks for:
   %      'axis' - a handle to the axis, defining the area to be used
   %      'position' - 1x4 vector, specifying area in which to plot [left, bottom, width, height]
   %      'colorbar' - Position of the colorbar relative to the plot
   %      'colormap' - alternate colormap
   %      'xunit' - Specify the time units for the plot.  eg, hours, minutes, doy, etc.
   %      'fontsize' -  specify the font size to be used for all labels within the plot
   %      'yscale' - either 'normal', or 'log'
   %      'innerlabels' -  true/false
   %      'useXlabel' - true/false
   %      'useYlabel' - true/false
   p = inputParser;
   p.StructExpand = true;
   p.KeepUnmatched = true;
   p.CaseSensitive = false;
   if verLessThan('matlab','8.2') %2013b
      addParameter = @addParamValue; % usage is the same as of 2015b
   end
   %NOTE: older version of matlab requires addParamValue instead of addParamter
   addParameter(p,'axis', 0); %myaxis
   addParameter(p,'position', []);
   addParameter(p,'colorbar', 'horiz');
   addParameter(p,'colormap', me.SPECTRAL_MAP);
   addParameter(p,'xunit', me.scaling);
   addParameter(p,'fontsize', 10);
   addParameter(p,'yscale', 'normal');
   addParameter(p,'innerlabels', false);
   addParameter(p,'useXlabel', true);
   addParameter(p,'useYlabel', true);
   p.parse(cellOfArgs{:});
end
