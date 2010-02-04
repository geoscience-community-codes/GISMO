function plot(c,varargin)

% PLOT(C) plots waveforms stored in a correlation object. Traces are
% aligned by their trigger times. For optimum correlation use ADJUSTTRIG
% first. Trace amplitudes are normalized before plotting.
%
% PLOT(C,'wiggle') plots a wiggle trace (default for < 100 traces)
%
% PLOT(C,'wiggle',SCALE) plots wiggle traces with relative amplitudes
% of SCALE (default SCALE is 1.0 - no overlap for adjacent traces)
%
% PLOT(C,'wiggle',SCALE,PERM) plots the wiggle traces as specified and 
% ordered by the PERM vector. PERM may be a subset of the full list of
% trace, a reordering of the traces, or both. The default behavior is to
% plot traces as they appear in the TRIG field. One common use is to use
% the PERM vector to plot traces in the same order they appear in a
% dendrogram plot. For example:
%       [H,tmp,perm] = dendrogram(c, ...);
%       plot(c,'wig',1,perm);
%
% PLOT(C,'raw',...) same as 'wig' option except that traces are not
% normalized to an equal amplitude before plotting. They are scaled to the
% mean of the maximum trace amplitude. Scaling can be further refined 
% with the SCALE factor and/or by using the NORM function prior to plotting.
%
% PLOT(C,'shaded',...) plots shaded waveforms. (default for >= 100 traces) 
% The 'wiggle' option is not conducive to displays of more than about 100
% traces. The 'shaded' option is recommended for large datasets.  Plot
% colors can be modified with the COLORMAP command. Same options are 
% available as for the wiggle plots.
%
% PLOT(C,'overlay',...) overlays the aligned traces on one another. The
% stack of the traces is plotted in bold on top. If traces have not been
% cropped prior to plotting, beware of odd effects toward the ends of the
% stacked traces. Trace amplitudes are not normalized prior to plotting 
% (like 'raw'). Use NORM if normalization is necessary prior to plotting.
% 
% PLOT(C,'interfer') plot shaded images of the correlation values and/or
% lag times from behind the traces. See HELP INTERFEROGRAM for more
% information on where this data comes from and how it is stored (a bit ad
% hoc). Note that no trace normalization is applied to interferograms. In
% many cases the user will choose to run the NORM command before plotting.
% By default PLOT(C,'interfer') is the same as PLOT(C,'interfer',1,'LAG').
% 
% PLOT(C,'interfer',SCALE,'CORR') plots a shaded image of the correlation
% values from the interferogram routine behind the traces. Lag times are
% ignored in this style of plot.
%
% PLOT(C,'interfer',SCALE,'LAG',RANGE) plots traces on a shaded image that
% is a function of both the lag time and the correlation value. The color
% scale ranges from -RANGE to +RANGE seconds. If RANGE is not included, then
% it is set to 0.03 seconds. As the correlation value drops, the colors are
% increasingly faded. Regions of the waveforms that correlate at less than
% 0.6 are considered unreliable and are not colored at all. For example,
% bright red indicates a waveform segment that correlates very well but is
% delayed relative to the reference trace. Faded blue indicates moderate
% correlation and advanced arrival. Yellow is no time shift. White
% signifies poor correlation (in which case the lag time is meaningless).
%
% PLOT(C,'sample',...) same as wiggle plot except that individual sample
% points are plotted. Really this is only useful for debugging.
%
% PLOT(C,'corr') plots an image of the correlation matrix. Requires 
% CORR field to be filed. 
%
% PLOT(C,'lag') plots an image of the lag matrix. Requires LAG field to be
% filled.
%
% PLOT(C,'stat') plots the delay time statistics for each trace. Requires STAT
% field to be filled. If STAT field is not filled, PLOT(C,'STAT') will call
% GETSTAT. The resulting values will be used for plotting but will *not* be
% saved into C. 
%
% PLOT(D,'den') plots a dendrogram image. Requires the LINK field to be
% filled (see correlation/linkage).
%
% PLOT(C,'event') This routine has been depricated and will be removed in a
% future release. Use the occurence plot routine instead. The event routine
% plots the time evolution of each event cluster together with a stack of
% all of the traces in that cluster. No normalization is applied to the
% traces before stacking. Requires the CLUST property be filled.
%
% PLOT(C,'event',SCALE)
% PLOT(C,'event',SCALE,CLUSTERS)
% Same as above except relative trace amplitudes are scaled by SCALE.
% Default is 1. If specified, CLUSTERS states how many clusters to include 
% in the analysis. That is, if CLUSTERS is 5, then the 5 largest clusters
% are included in the plots. The default value of CLUSTERS is 4.
% Example - plot the 3 largest clusters at half the default amplitude.
%       ...
%       c = linkage(c,'average');
%       c = cluster(c,'CUTOFF',.5,'Criterion','distance');
%       plot(c,'event',.5,3);
%
% PLOT(C,'occurrence',SCALE,CLUSTERS) similar to EVENT plot above. Plots a time
% historgram for each event cluster together with a stack of all of the
% traces in that cluster. CLUSTERS specifies the number of each cluster to
% be included. Due to space constraints, no more than 10 clusters can be
% plotted on a single figure. Requires the CLUST property be filled. SCALE
% term is required for consistency but has little impact on the plots.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$



% SET VAR5 (USED ARBITRARILY BY SOME SUBFUNCTIONS)
if length(varargin)>=4
    var5 = varargin{4};
else
    var5 = [];
end;


% SET ORDER AND NUMBER OF TRACES
if length(varargin)>=3
    ord = reshape(varargin{3},1,length(varargin{3}));
else
    ord = 1:length(c.trig);
end;


% SET TRACE SCALE
if length(varargin)>=2
    scale = varargin{2};
else
    scale = 1;
end;

% PLOT SHADED TRACES, NOT WIGGLES
if length(varargin)>=1
    %disp(varargin{1});
    plottype = varargin{1};
else
    if length(ord)>=100
        plottype = 'sha';
    else
        plottype = 'wig';
    end
    
end;


% MAKE PLOT
if strncmpi(plottype,'SHA',3)
    shadedplot(c,scale,ord);
elseif strncmpi(plottype,'WIG',3)
    wiggleplot(c,scale,ord,1);
elseif strncmpi(plottype,'RAW',3)
    wiggleplot(c,scale,ord,0);
elseif strncmpi(plottype,'OVE',3)
    overlayplot(c,scale,ord);
elseif strncmpi(plottype,'SAM',3)
    sampleplot(c,scale,ord);
elseif strncmpi(plottype,'COR',3)
    corrplot(c);
elseif strncmpi(plottype,'LAG',3)
    lagplot(c);
elseif strncmpi(plottype,'STA',3)
    statplot(c);
elseif strncmpi(plottype,'DEN',3)
    dendrogramplot(c);
elseif strncmpi(plottype,'EVE',3)       % ord field has been co-opted 
    warning('The event plot has been depricated. Use the "occurence" plot instead');
    if length(ord) > 1
        ord = 4;
    end
    eventplot(c,scale,ord);
elseif strncmpi(plottype,'OCC',3)       % ord field has been co-opted 
    occurrenceplot(c,scale,ord);
elseif strncmpi(plottype,'INT',3)   % ord is used as flag for "corr" vs. "lag"
    ord = ord(1);
    if isnumeric(ord)
       ord = 'c'; 
    end
    if isempty(var5)                % var5 only used for lag plot
        var5 = 0.03;
    end
    wiggleinterferogram(c,scale,ord,0,var5);
else
    disp('Plot type not recognized');
end;





