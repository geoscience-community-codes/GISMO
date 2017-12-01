function [result,Tcell,Fcell,Ycell,meanF,peakF] = spectrogram_iceweb(s, w, varargin)
% SPECTROGRAM_ICEWEB produce an multi-channel spectrogram plot in the style of
% AVO web (IceWeb) spectrograms, by wrapping the default MATLAB spectrogram
% function
%
% Usage:
% 	[result, Tcell, Fcell, Ycell] =spectrogram_iceweb(s, w, 'spectrogramFraction', 0.75, 'colormap', mycolormap, 'plot_metrics', 0)
%
% Inputs:
%	w - a vector of waveform objects
%	s - a spectralobject
%	spectrogramFraction - fraction of a panel height the spectrogram should take up (default: 0.8). 
%			The waveform trace takes up the remaining fraction.
%
%   Name/Value pairs:
%       'mycolormap' - (Optional) a user-defined colormap 
%       'plot_metrics' - superimpose a plot of mean & dominant frequency.
%                                                        0 or 1 (default 0)
%
% Outputs:
%	(other than a figure on the screen)
%	result = true if successful, false if there was an error
%   T - cell array of date/time for each spectrogram/waveform
%   F - cell array of frequency vector from fmin to fmax for each spectrogram/waveform
%   Y - cell array of spectrogram absolute amplitudes from fmin to fmax for each spectrogram/waveform

% waveform should already have had zero-length waveform objects replaced by zero vectors 

% AUTHOR: Glenn Thompson, University of Alaska Fairbanks

debug.printfunctionstack('>');

% varargin
% mycolormap

result = 0;

% % reverse the order of the waveforms so they plot top to bottom in same
% % order as in mulplt and as in waveform vector
% w = fliplr(w); don't need this with calculatePanelPositions2

numw = numel(w);
if numw==0
	return;
end
% if ~exist('s','var')
% 	s = spectralobject(1024, 924, 10, [60 120]);
% end
% if ~exist('spectrogramFraction','var')
% 	spectrogramFraction = 1;
% end
nfft = 1024;
overlap = 924;
fmax = 10;
dbLims = [60 120];

p = inputParser;
p.addParameter('spectrogramFraction', 0.75, @isnumeric);
p.addParameter('colormap', jet, @isnumeric);
p.addParameter('plot_metrics', 0, @isnumeric);
p.parse(varargin{:});
spectrogramFraction = p.Results.spectrogramFraction;


% if nargin>=4
%     if strcmp(
%     if ~exist('mycolormap', 'var')
%     mycolormap = jet; % should be using SPECTRAL_MAP here?
% end

%save lastspecgramcall.mat s w spectrogramFraction mycolormap
debug.print_debug(2, sprintf('%d waveform objects',numel(w)));

% % Default colormap is JET. Override that here.
% if exist('mycolormap', 'var')
%         setmap(s, mycolormap);      
% end

setmap(s, p.Results.colormap);

% To get a colorbar, stop the function here and set colorbar option to vert

% Reset axes position & squeeze in the trace panels

nfft = round(get(s,'nfft'));
overlap = floor(get(s, 'over'));
dBlims = get(s, 'dBlims');
fmax = get(s, 'freqmax');

% Set appropriate date ticks
[wsnum, wenum]=gettimerange(w);
wt.start = min(wsnum);
wt.stop = max(wenum);
[Xtickmarks,XTickLabel]=findMinuteMarks(wt);

Ycell = {}; Fcell = {}; Tcell = {};
for c=1:numw
    fsamp = get(w(c), 'freq');
    data = get(w(c), 'data');
    
    if length(data) > nfft
        [S,F,T] = spectrogram(data, nfft, nfft/2, nfft, fsamp);

        Y = 20*log10(abs(S)+eps);
        index = find(F <= fmax);
        if F(1)==0,
            F(1)=0.001;
        end

        [spectrogramPosition, tracePosition] = iceweb.calculatePanelPositions(numw, c, spectrogramFraction, 0.12, 0.05, 0.80, 0.9);
        axes('position', spectrogramPosition);
        T = wt.start + T/86400;
        F = F(1:max(index));
        Y = Y(1:max(index),:);
        S = S(1:max(index),:);
        
        % mean frequency
        numerator = abs(S)' * F;
        denominator = sum(abs(S),1);
        meanF{c} = numerator./denominator';
        
        % peak frequency
        [maxvalue,maxindex] = max(abs(S));
        peakF{c} = F(maxindex);
            
        if isempty(dBlims)
            % plot spectrogram
            imagesc(T,F,abs(S));
        else
            imagesc(T,F,Y,dBlims); 
        end
        axis xy;
        colormap(p.Results.colormap);
        
        % add plot of frequency metrics?
        if p.Results.plot_metrics
            hold on; plot(T,smooth(meanF{c}),'k','LineWidth',.5);
            hold on; plot(T,smooth(peakF{c}),'w','LineWidth',.5);
        end        

        % Change Y-Labels to 'sta.chan'
        thissta = get(w(c), 'station');
        thischan = get(w(c), 'channel');
        ylabel( sprintf('%s\n%s',thissta, thischan(1:3) ), 'FontSize', 8);
        xlabel('')
        title('')
        set(gca,'XLim', [wt.start wt.stop]);
        if c==numw
            set(gca, 'XTick', Xtickmarks, 'XTickLabel', XTickLabel,  'FontSize', 8); % time labels only on bottom spectrogram
        else
            set(gca, 'XTick', Xtickmarks, 'XTickLabel', {});
        end

        if spectrogramFraction < 1
            plotTrace(tracePosition, get(w(c),'data'), get(w(c),'freq'), Xtickmarks, wt, p.Results.colormap, s, thissta, thischan);
            set(gca,'XLim', [wt.start wt.stop]); % added 20111214 to align trace with spectrogram when data missing (prevent trace being stretched out)

            % change the trace background color if we want to identify
            % broadband stations
    % 		if (regexp(thischan, '[BH]H.'))
    % 			set(gca, 'Color', [.8 .8 .8]);
    %         end

        end
        result = result + 1;
        Ycell{c} = Y; Fcell{c} = F; Tcell{c} = T;
    else
        Ycell{c} = []; Fcell{c} = []; Tcell{c} = [];
    end
    
end

debug.printfunctionstack('<');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plotTrace(tracePosition, data, freqSamp, Xtickmarks, timewindow, mycolormap, s, thissta, thischan);
debug.printfunctionstack('>');
snum =timewindow.start;

% set axes position
axes('position',tracePosition);

% trace time vector - bins are ~0.01 s apart (not 5 s as for spectrogram time)
% not really worthwhile plotting more than 1000 points on the screen
dnum = ((1:length(data))./freqSamp)/86400 + snum;

% plot seismogram - assuming data cleaned already with
% w=detrend(fillgaps(w,'interp'))
traceHandle = plot(dnum, data);

% blow up trace detail so it almost fills frame
maxAmpl = max(abs(data));
if (maxAmpl == 0) % make sure that max_ampl is not zero
	maxAmpl = 1;
end

% set properties - here we set trace color according to amplitude
%rgb = amplitude2tracecolor(maxAmpl, mycolormap, s);
%set (traceHandle,'LineWidth',[0.01],'Color',rgb)
% or we can use this...
set (traceHandle,'LineWidth',[0.01],'Color',[0 0 0])

set(gca, 'XTick', Xtickmarks, 'XTickLabel', '', 'XLim', [timewindow.start timewindow.stop], 'Ytick',[],'YTickLabel',['']);

if ~isnan(maxAmpl) % make sure it is not NaN else will crash
	traceRange = [dnum(1) dnum(end) -maxAmpl*1.1 maxAmpl*1.1];
	decibels = 20 * log10(maxAmpl) + eps;
	%fprintf('%s: %s.%s: Max amplitude %.1e (%d dB)\n',mfilename, thissta, thischan, maxAmpl,round(decibels)); 
	axis(traceRange);
end
debug.printfunctionstack('<');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function rgb = amplitude2tracecolor(maxAmpl, mycolormap, s);
debug.printfunctionstack('>');
a = 20 * log10(maxAmpl) + eps;
dBlims = get(s, 'dBlims');
index = round( ( (a - dBlims(1)) / (dBlims(2) - dBlims(1)) ) * (length(mycolormap)-1) ) + 1;
index=max([index 1]);
index=min([index length(mycolormap)]);
rgb = mycolormap(index, :);
debug.printfunctionstack('<');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [Xtickmarks,Xticklabels]=findMinuteMarks(timewindow);
debug.printfunctionstack('>');

% calculate where minute marks should be, and labels
snum = ceilminute(timewindow.start);
enum = floorminute(timewindow.stop);

% Number of minute marks should be no greater than 20
numMins = (enum - snum) * 1440;
stepMinOptions = [1 2 3 5 10 15 20 30 60 120 180 240 360 480 720 1440];
c = 1;
while (numMins / stepMinOptions(c) > 12)
	c = c + 1;
    if c >= numel(stepMinOptions)
        c = numel(stepMinOptions);
        break;
    end
end
stepMins = stepMinOptions(c);

Xtickmarks = snum:stepMins/1440:enum;
Xticklabels = datestr(Xtickmarks,15); 
debug.printfunctionstack('<');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

