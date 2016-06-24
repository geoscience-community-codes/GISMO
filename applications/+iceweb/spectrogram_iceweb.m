function [result,Tcell,Fcell,Ycell] = spectrogram_iceweb(s, w, spectrogramFraction, mycolormap)
% SPECTROGRAM_ICEWEB produce an multi-channel spectrogram plot in the style of
% AVO web (IceWeb) spectrograms, by wrapping the default MATLAB spectrogram
% function
%
% Usage:
% 	[result, Tcell, Fcell, Ycell] =spectrogram_iceweb(s, w, spectrogramFraction, mycolormap)
%
% Inputs:
%	w - a vector of waveform objects
%	s - a spectralobject
%	spectrogramFraction - fraction of a panel height the spectrogram should take up (default: 0.8). 
%			The waveform trace takes up the remaining fraction.
%	mycolormap - (Optional) a user-defined colormap
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



result = 0;


% % reverse the order of the waveforms so they plot top to bottom in same
% % order as in mulplt and as in waveform vector
% w = fliplr(w); don't need this with calculatePanelPositions2

numw = numel(w);
if numw==0
	return;
end
if ~exist('s','var')
	s = spectralobject(1024, 924, 10, [60 120]);
end
if ~exist('spectrogramFraction','var')
	spectrogramFraction = 1;
end
if ~exist('mycolormap', 'var')
    mycolormap = jet; % should be using SPECTRAL_MAP here?
end

%save lastspecgramcall.mat s w spectrogramFraction mycolormap
debug.print_debug(2, sprintf('%d waveform objects',numel(w)));

% Default colormap is JET. Override that here.
if exist('mycolormap', 'var')
        setmap(s, mycolormap);      
end

% To get a colorbar, stop the function here and set colorbar option to vert

% Reset axes position & squeeze in the trace panels

nfft = round(get(s,'nfft'));
overlap = floor(get(s, 'over'));
dBlims = get(s, 'dBlims')
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
        fmax
        max(F)
        index = find(F <= fmax)
        if F(1)==0,
            F(1)=0.001;
        end

        [spectrogramPosition, tracePosition] = iceweb.calculatePanelPositions(numw, c, spectrogramFraction, 0.08, 0.05, 0.88, 0.95);
        axes('position', spectrogramPosition);
        T = wt.start + T/86400;
        F = F(1:max(index));
        Y = Y(1:max(index),:);
        S = S(1:max(index),:);
        if isempty(dBlims)
            imagesc(T,F,abs(S));
            % mean frequency
            numerator = abs(S)' * F;
            denominator = sum(abs(S),1);
            meanF = numerator./denominator';
            hold on; plot(T,meanF,'k','LineWidth',3);
            % peak frequency
            [maxvalue,maxindex] = max(abs(S));
            size(maxindex)
            fmax = F(maxindex);
            size(fmax)
            hold on; plot(T,fmax,'r','LineWidth',3);
            
        else
            imagesc(T,F,Y,dBlims); 
        end
        axis xy;
        colormap(mycolormap);

        % Change Y-Labels to 'sta.chan'
        ylabel( sprintf('%s\n%s',get(w(c), 'station'), get(w(c), 'channel')), 'FontSize', 10);
        xlabel('')
        title('')
        set(gca,'XLim', [wt.start wt.stop]);
        if c==numw
            set(gca, 'XTick', Xtickmarks, 'XTickLabel', XTickLabel,  'FontSize', 10); % time labels only on bottom spectrogram
        else
            set(gca, 'XTick', Xtickmarks, 'XTickLabel', {});
        end

        if spectrogramFraction < 1
            thissta = get(w(c), 'station');
            thischan = get(w(c), 'channel');
            plotTrace(tracePosition, get(w(c),'data'), get(w(c),'freq'), Xtickmarks, wt, mycolormap, s, thissta, thischan);
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
	fprintf('%s: %s.%s: Max amplitude %.1e nm/s (%d dB)\n',mfilename, thissta, thischan, maxAmpl,round(decibels)); 
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
end
stepMins = stepMinOptions(c);

Xtickmarks = snum:stepMins/1440:enum;
Xticklabels = datestr(Xtickmarks,15); 
debug.printfunctionstack('<');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

