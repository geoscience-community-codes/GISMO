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

% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

% Thanks to Jason Amundson for providing the way to do log scales

global SPECTRAL_MAP

currFontSize = 8;
%enforce input arguments.
if ~isa(ws,'waveform')
    error('Second input argument should be a waveform, not a %s',class(ws));
end

%% The following xunit styling is swiped from waveform/plot


hasExtraArg = mod(numel(varargin),2);
if hasExtraArg
    error('Spectralobject:specgram:DepricatedArgument',...
        ['%s/n%s/n%s','spectralobject/specgram now requires parameter pairs.',...
        'See help spectralobject/specgram for new usage instructions',...
        'most likely you tried to call specgram with an alternate ',...
        'color map without specifying the property ''colormap''']);
else
    proplist=  parseargs(varargin);
end

%% search for relevent property pairs passed as parameters

% AXIS: a handle to the axis, defining the area to be used
[isfound,myaxis,proplist] = getproperty('axis',proplist,0);

% POSITION: 1x4 vector, specifying area in which to plot
%          [left, bottom, width, height]
[isfound,mypos,proplist] = getproperty('position',proplist,[]);

% XUNIT: Specify the time units for the plot. eg, hours, minutes, doy, etc.
[isfound, xChoice, proplist] =...
    getproperty('xunit',proplist,s.scaling); %'s' is default value for xChoice

% FONTSIZE: specify the font size to be used for all labels within the plot
[isfound, currFontSize, proplist] =...
    getproperty('fontsize',proplist,currFontSize);%default font size or override?

%%take care of additional parsing that affects all waveforms

[useAlternateMap, alternateMap, proplist] = ...
    getproperty('colormap',proplist, SPECTRAL_MAP); %default map

% YSCALE: either 'normal', or 'log'
[isfound, yscale, proplist] = ...
    getproperty('yscale',proplist,'normal'); %default yscale to 'normal'

logscale = strcmpi(yscale,'log');

% COLORBAR: Dictate the position of the colorbart relative to the plot
[isfound,colorbarpref,proplist] = getproperty('colorbar',proplist,'horiz');



% SUPRESSINNERLABELS: true, false
[isfound, suppressLabels, proplist] = ...
    getproperty('innerlabels',proplist,false); %only show outside

% SUPRESSXLABELS: true, false
[isfound, useXlabel, proplist] = ...
    getproperty('useXlabel',proplist,true); %show no x, y labels
% SUPRESSXLABELS: true, false
[isfound, useYlabel, proplist] = ...
    getproperty('useYlabel',proplist,true); %show no x, y labels

% %%
% if numel(ws) > 1
%     %allh = subdivide_axes(gca,size(ws));
%     %create the colorbar if desired BEFORE subdividing, so that a single
%     %one covers all.
%     if myaxis == 0, myaxis = gca; end
%     if ~strcmpi(colorbarpref,'none')
%         clabel= 'Relative Amplitude  (dB)';
%         hbar = colorbar_axis(s,colorbarpref,clabel,'','',currFontSize)
%         set(hbar,'fontsize',currFontSize)
%     end
%     allh = subdivide_axes(myaxis,size(ws));
% else
%     allh=myaxis;
% end

%% figure out exactly WHERE to plot the spectrogram(s)
%find out area(axis) in which the spectrograms will be plotted
clabel= 'Relative Amplitude  (dB)';

if myaxis == 0,
    clf;
    pos = get(gca,'position');
else
    pos = get(myaxis,'position');
end
% if ~isempty(mypos) %position
%     pos = myaxis;
% end

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
        set(hbar,'fontsize',currFontSize);
    end
    
    h = subdivide_axes(myaxis,size(ws));
    remainingproperties = property2varargin(proplist);
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
%%
%for j = 1:numel(ws) %added to handle arrays and vectors of waveforms
axes(myaxis);

if any(isnan(double(ws)))
    warning('Spectralobject:specgram:nanValue',...
        ['This waveform has at least one NaN value, which will blank',...
        'the related spectrogram segment. ',...
        'Remove NaN values by either splitting up the ',...
        'waveform into non-NaN sections or by using waveform/fillgaps',...
        ' to replace the NaN values.']);
end

[xunit, xfactor] = parse_xunit(xChoice);

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
        dl= 1:get(ws,'data_length'); %dl : DataLength
        Xvalues = dl./ get(ws,'freq') ./ xfactor;
end


%%  once was function specgram(d, NYQ, nfft, noverlap, freqmax, dBlims)

d = get(ws,'data')'; %should be column data already!
nx = length(d);
%logscale = 0; %% supplanted by parameter value
%clabel= 'Relative Amplitude  (dB)'; %%not used outside of specgram2

window = hanning(s.nfft);
NYQ = get(ws,'NYQ');
Fs = get(ws,'Fs');
nwind = length(window);

if nx < nwind    % zero-pad x if it has length less than the window length
    d(nwind) = 0;
    nx=nwind;
end
d = d(:); % make a column vector for ease later

ncol = fix( (nx - s.over)/(nwind - s.over) );

%added "floor" below
colindex = 1 + floor(0:(ncol-1))*(nwind- s.over);
rowindex = (1:nwind)';
if length(d)<(nwind+colindex(ncol)-1)
    d(nwind+colindex(ncol)-1) = 0;   % zero-pad x
end

y = zeros(nwind,ncol);

% put x into columns of y with the proper offset
% should be able to do this with fancy indexing!
A_ = colindex(  ones(nwind, 1) ,: )    ;
B_ = rowindex(:, ones(1, ncol)    )    ;
y(:) = d(fix(A_ + B_ -1));
clear A_ B_

for k = 1:ncol;		%  remove the mean from each column of y
    y(:,k) = y(:,k)-mean(y(:,k));
end


% Apply the window to the array of offset signal segments.
y = window(:,ones(1,ncol)).*y;

% USE FFT
% now fft y which does the columns
y = fft(y,s.nfft);
if ~any(any(imag(d)))    % x purely real
    if rem(s.nfft,2),    % nfft odd
        select = 1:(s.nfft+1)/2;
    else
        select = 1:s.nfft/2+1;
    end
    y = y(select,:);
else
    select = 1:s.nfft;
end
f = (select - 1)'*Fs/s.nfft;

% t = (colindex-1)'/Fs;
%  't' is supplanted by 'Xvalues';

NF = s.nfft/2+1;
nf1=round(f(1)/NYQ*NF);                     %frequency window
if nf1==0, nf1=1; end
nf2=NF;

y = 20*log10(abs(y(nf1:nf2,:)));

F = f(f <= s.freqmax);


if F(1)==0,
    F(1)=0.001;
end

%h = imagesc(t,F,y(nf1:length(F),:),s.dBlims);

if logscale
    t = (colindex-1)'/Fs;
    try
        h = uimagesc(t,log10(F),y(nf1:length(F),:),s.dBlims);
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
    %axis(myaxis)
    h = imagesc(Xvalues,F,y(nf1:length(F),:),s.dBlims);
end
set(gca,'fontsize',currFontSize);
if strcmpi(xunit,'date')
    datetick('x','keepticks');
end
%       colorbar_axis(dBlims,'horiz',clabel)
titlename = [get(ws,'Station') '-' get(ws,'component') '  from:' get(ws,'start_Str')];
%th =
title (titlename);
%set(th,'fontsize',currFontSize)
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
if ~strcmpi(colorbarpref,'none')
    hbar = colorbar_axis(s,colorbarpref,clabel,'','',currFontSize);
    set(hbar,'fontsize',currFontSize)
end

%% added a series of functions that help with argument parsing.
% These were ported from my waveform/plot function.

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
%convert the properties structure into something that can be passed as a
%parameter into a function
c = {};
c(1:2:numel(properties.name)*2) = properties.name;
c(2:2:numel(properties.name)*2) = properties.val;