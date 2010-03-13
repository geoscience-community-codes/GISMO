function specgram2(s, ws, varargin)
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

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

%% enforce input arguments.
if ~isa(ws,'waveform')
    error('Spectralobject:specgram2:invalidArgument',...
        'Second input argument should be a waveform, not a %s',class(ws));
end

hasExtraArg = mod(numel(varargin),2);
if hasExtraArg
    error('Spectralobject:DepricatedArgument',...
        ['spectralobject/specgram2 now requires parameter ',...
        'pairs.  Most likely, you tried to call spectrogram with an ',...
        'axis without specifying the property ''axis''',...
        ' See help spectralobject/specgram for new usage instructions.']);
else
    proplist=  parseargs(varargin);
end

%% search for relevent property pairs passed as parameters

% AXIS: a handle to the axis, defining the area to be used
[isfound,myaxis,proplist] = getproperty('axis',proplist,0);

% POSITION: 1x4 vector, specifying area in which to plot
%          [left, bottom, width, height]
[isfound,mypos,proplist] = getproperty('position',proplist,[]);

% COLORBAR: Dictate the position of the colorbart relative to the plot
[isfound,colorbarpref,proplist] = getproperty('colorbar',proplist,'horiz');

% XUNIT: Specify the time units for the plot.  eg, hours, minutes, doy, etc.
[isfound, xChoice, proplist] =...
    getproperty('xunit',proplist,s.scaling);

% FONTSIZE: specify the font size to be used for all labels within the plot
[isfound, currFontSize, proplist] =...
    getproperty('fontsize',proplist,8); %default font size or override?

% YSCALE: either 'normal', or 'log'
[isfound, yscale, proplist] = ...
    getproperty('yscale',proplist,'normal'); %default yscale to 'normal'

% SUPRESSINNERLABELS: true, false
[isfound, suppressLabels, proplist] = ...
    getproperty('innerlabels',proplist,false); %only show outside

% SUPRESSXLABELS: true, false
[isfound, useXlabel, proplist] = ...
    getproperty('useXlabel',proplist,true); %show no x, y labels
% SUPRESSXLABELS: true, false
[isfound, useYlabel, proplist] = ...
    getproperty('useYlabel',proplist,true); %show no x, y labels

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
if ~strcmpi(colorbarpref,'none')
    hbar = colorbar_axis(s,colorbarpref,clabel,'','',currFontSize);
    set(hbar,'fontsize',currFontSize)
end

    h = subdivide_axes(myaxis,size(ws));
    remainingproperties = property2varargin(proplist);
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
if ~strcmpi(colorbarpref,'none')
    hbar = colorbar_axis(s,colorbarpref,clabel,'','',currFontSize);
    set(hbar,'fontsize',currFontSize)
end


function [properties] = parseargs(arglist)
% parse the incoming arguments, returning a cell with each parameter name
% as well as a cell for each parameter value pair.  parseargs will also
% doublecheck to ensure that all pnames are actually strings... otherwise,
% we're looking at a mis-parse.
%check to make sure these are name-value pairs
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
    if ~isa(properties.name{i},'char')
        error('ParseArgs:invalidPropertyName',...
            'All property names must be strings.');
    end
end

function [isfound, foundvalue, properties] = getproperty(desiredproperty,properties,defaultvalue)
%returns a property value (if found) from a property list, removing that
%property pair from the list.  only removes the first encountered property
%name.

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

function c = property2varargin(properties)
c = {};
c(1:2:numel(properties.name)*2) = properties.name;
c(2:2:numel(properties.name)*2) = properties.val;