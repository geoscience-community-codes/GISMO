function h = specgram(s, ws, varargin)
%SPECGRAM - plots spectrogram of waveforms
%   specgram(spectralobject, waveforms)
%   Generates a spectragram from the waveform
%
%   h = specgram(spectralobject, waveforms)
%   Generates a spectragram from the waveform and returns a handle to it
%
%   h = specgram(spectralobject, waveforms, 'colormap', alternateMap);
%   Generates a spectragram from the waveform and uses a specific map
%
%   The colormap I use is "SPECTRAL_MAP", but can be changed by passing
%   your preferred map as a parameter.  An alternate way of setting the
%   global map is by using the SETMAP function.
%
%   Notice, that changes to the colormap are now done through parameter
%   pairs:  'colormap',alternatemap)
%
%   New parameters include: 'xunit', 'yscale', 'colormap','colorbar'
%     valid xunits:'seconds'(default),'minutes','hours','days','doy','date'
%     valid yscales: 'normal' (default), 'log' (see NOTE below)
%     valid colorbar values: 'horiz','vert','none'
%
%
% The following plots a waveform using an alternate mapping, an xunit of
% 'hours', and with the y-axis plotted using a log scale.
%  ex. specgram(spectralobject, waveform,...
%      'colormap', alternateMap,'xunit','h','yscale','log')
%
% NOTE: In order to use the log scale, UIMAGESC needs to be available on
% the matlab path.  This routine was created by Frederic Moisy, and may be
% downloaded from the maltabcentral fileexchange (File ID: 11368)
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

[isfound, xChoice, proplist] =...
    getproperty('xunit',proplist,s.scaling); %'s' is default value for xChoice

[isfound, currFontSize, proplist] =...
    getproperty('fontsize',proplist,currFontSize);%default font size or override?

%%take care of additional parsing that affects all waveforms

[useAlternateMap, alternateMap, proplist] = ...
    getproperty('colormap',proplist, SPECTRAL_MAP); %default map

[isfound, yscale, proplist] = ...
    getproperty('yscale',proplist,'normal'); %default yscale to 'normal'

logscale = strcmp(yscale,'log');

% colorbar isn't used here...
%[isfound,colorbarpref,proplist] = getproperty('colorbar',proplist,'horiz');

%%
if numel(ws) > 1
    allh = subdivide_axes(gca,size(ws));
else
    allh=gca;
end

for j = 1:numel(ws) %added to handle arrays and vectors of waveforms
    axes(allh(j));
    
    if any(isnan(double(ws(j))))
        warning('Spectralobject:specgram:nanValue',...
            ['This waveform has at least one NaN value, which will blank',...
            'the related spectrogram segment. ',...
            'Remove NaN values by either splitting up the ',...
            'waveform into non-NaN sections or by using waveform/fillgaps',...
            ' to replace the NaN values.']);
    end
    
    w = ws(j);
    
    [xunit, xfactor] = parse_xunit(xChoice);
    
    switch lower(xunit)
        case 'date'
            % we need the actual times...
            Xvalues = get(w,'timevector');
            
        case 'day of year'
            startvec = datevec(get(w,'start'));
            Xvalues = get(w,'timevector');
            dec31 = datenum(startvec(1)-1,12,31); % 12/31/xxxx of previous year in Matlab format
            Xvalues = Xvalues - dec31;
            xunit = [xunit, ' (', datestr(startvec,'yyyy'),')'];
            
        otherwise,
            dl= 1:get(w,'data_length'); %dl : DataLength
            Xvalues = dl./ get(w,'freq') ./ xfactor;
    end
    
    
    %%  once was function specgram(d, NYQ, nfft, noverlap, freqmax, dBlims)
    
    d = get(w,'data')'; %should be column data already!
    nx = length(d);
    %logscale = 0; %% supplanted by parameter value
    %clabel= 'Relative Amplitude  (dB)'; %%not used outside of specgram2
    
    window = hanning(s.nfft);
    NYQ = get(w,'NYQ');
    Fs = get(w,'Fs');
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
            else
                rethrow(exception)
            end
        end
    else
        h = imagesc(Xvalues,F,y(nf1:length(F),:),s.dBlims);
    end
    set(gca,'fontsize',currFontSize);
    if strcmpi(xunit,'date')
        datetick('x','keepticks');
    end
    %       colorbar_axis(dBlims,'horiz',clabel)
    titlename = [get(w,'Station') '-' get(w,'component') '  from:' get(w,'start_Str')];
    %th = 
    title (titlename);
    %set(th,'fontsize',currFontSize)
    axis xy;
    
    colormap(alternateMap);
    
    shading flat
    
    axis tight;
    [thisr, thisc] = ind2sub(size(ws),j);
    isFirstCol = thisc == 1;
    if isFirstCol
    ylabel ('Frequency (Hz)')
    end
    isBottomrow = thisr==size(ws,1);
    if isBottomrow
        xlabel(['Time - ',xunit]);
    end
    
    % colorbar_axis(s.dBlims,colorbarpref,clabel)
end;
%% local parameter stuff
% function [xfactor, xunit] = xscaling(xChoice, freq)
% 
% secs = 1;
% mins = 60;
% hrs = 3600;
% days = 3600*24;
% 
% switch lower(xChoice)
%     case {'m','minutes'},
%         xunit = 'Minutes';      xfactor = mins;
%     case {'h','hours'},
%         xunit = 'Hours';        xfactor = hrs;
%     case {'d','days'},
%         xunit = 'Days';         xfactor = days;
%     case {'doy','day_of_year'},
%         xunit = 'Day of Year';  xfactor = days;
%     case 'date',
%         xunit = 'Date';         xfactor = 1 / freq;
%     otherwise,
%         xunit = 'Seconds';      xfactor = secs;
% end

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
c = {};
c(1:2:numel(properties.name)*2) = properties.name;
c(2:2:numel(properties.name)*2) = properties.val;