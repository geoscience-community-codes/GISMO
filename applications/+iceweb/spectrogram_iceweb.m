function [result,Tcell,Fcell,Ycell,meanF,peakF] = spectrogram_iceweb(s, w, varargin)
% SPECTROGRAM_ICEWEB produce an multi-channel spectrogram plot in the style of
% AVO web (IceWeb) spectrograms, by wrapping the default MATLAB spectrogram
% function
%
% Usage:
% 	[result, Tcell, Fcell, Ycell] =spectrogram_iceweb(s, w, 'spectrogramFraction', 0.75, 'colormap', mycolormap, 'plot_metrics', 0)
%
% Inputs:
%   s - a spectralobject (default, if left empty becomes that used for
%                         iceweb)
%	w - a vector of waveform objects
%	
%   Name/Value pairs:
%       'spectrogramFraction' - fraction of a panel height the spectrogram should take up (default: 0.75). 
%			The waveform trace takes up the remaining fraction.
%       'mycolormap' - A user-defined colormap. (Default: iceweb colormap)
%       'plot_metrics' - superimpose a plot of mean & dominant frequency
%                        (default: false)
%       'makeplot' - plot the spectrograms (default: true). But sometimes
%                    we only want to compute the spectrogram.
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


if isempty(s)
    nfft = 1024;
    overlap = 924;
    freqmax = 10;
    dbLims = [60 120];
    s = spectralobject(nfft, overlap, freqmax, dbLims);
end


p = inputParser;
p.addParameter('spectrogramFraction', 0.75, @isnumeric);
p.addParameter('colormap', iceweb.extended_spectralobject_colormap, @isnumeric);
p.addParameter('plot_metrics', false, @islogical);
p.addParameter('makeplot', true, @islogical);
p.addParameter('relative_time',false, @islogical);
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
if p.Results.relative_time
    % RELATIVE TIME
    [wsnum, wenum]=gettimerange(w);
    wt.start = 0; 
    wt.stop = (max(wenum) - min(wsnum)) * 86400;
    Xtickmarks = []; XTickLabel={};
else % ABSOLUTE TIME, plot minute marks
    [wsnum, wenum]=gettimerange(w);
    wt.start = min(wsnum);
    wt.stop = max(wenum);
    [Xtickmarks,XTickLabel]=findMinuteMarks(wt);
end

Ycell = {}; Fcell = {}; Tcell = {};
for c=1:numw
    fsamp = get(w(c), 'freq');
    data = get(w(c), 'data');
    
    if length(data) > nfft
        %fprintf('Computing spectrogram %d\n',c)
        %[S,F,T] = spectrogram(data, nfft, nfft/2, nfft, fsamp);
        [S,F,T] = spectrogram(data, nfft, overlap, nfft, fsamp); % 20181210 check this
        % looks like could also try multitaper method by making 2nd and 3rd
        % arguments smaller
        Y = 20*log10(abs(S)+eps);
        index = find(F <= fmax);
        if F(1)==0,
            F(1)=0.001;
        end
        if ~p.Results.relative_time
            T = wt.start + T/86400;
        end
        Fplot = F(1:max(index));
        Yplot = Y(1:max(index),:);
        Splot = S(1:max(index),:);
        
        % mean frequency
        %minS = min(min(abs(S)+eps));
        minS = prctile(reshape(S,numel(S),1),40);
        S2 = abs(S)-minS;
        S2(S2<eps)=eps;
        numerator = abs(S2)' * F;
        denominator = sum(S2,1);
        thismeanf = numerator./denominator';
        
        % peak frequency
        [maxvalue,maxindex] = max(S2);
        thispeakf = F(maxindex);
        
%         % remove very small signals
%         Ymin_all = min(min(Y));
%         Ymax_all = max(max(Y));
%         Ymax_time = max(Y);
%         Ythreshold = Ymin_all + (Ymax_all - Ymin_all) * 50/70;
%         Ythreshold = prctile(reshape(Y, numel(Y),1),80);
%         thismeanf(Ymax_time < Ythreshold) = NaN;
%         thispeakf(Ymax_time < Ythreshold) = NaN;
        meanF{c} = thismeanf;
        peakF{c} = thispeakf;
        
        result = result + 1;
        Ycell{c} = Y; Fcell{c} = F; Tcell{c} = T;     
        
        %% PLOT THE SPECTROGRAMS?
        if p.Results.makeplot
            [spectrogramPosition, tracePosition] = iceweb.calculatePanelPositions(numw, c, spectrogramFraction, 0.12, 0.05, 0.80, 0.9);
            axes('position', spectrogramPosition);
            % T2 = linspace(wt.start, wt.stop, length(T)); % I noticed the
            % start and end of spectrograms are missing. Is this because of
            % tapering? Anyway, tried to create a new time vector for
            % spectrogram, but not very helpful
            if isempty(dBlims)
                % plot spectrogram
                %imagesc(T,F,abs(S));
                imagesc(T,Fplot,Yplot);
            else
                imagesc(T,Fplot,Yplot,dBlims); 
            end
            axis xy;
            colormap(p.Results.colormap);
        
            %% superimpose graphs of frequency metrics?
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
                if ~p.Results.relative_time
                    set(gca, 'XTick', Xtickmarks, 'XTickLabel', XTickLabel,  'FontSize', 8); % time labels only on bottom spectrogram
                end

            else
                if ~p.Results.relative_time
                    set(gca, 'XTick', Xtickmarks, 'XTickLabel', {});
                else
                    set(gca, 'XTickLabel', {});
                end
            end
            

            if spectrogramFraction < 1
                plotTrace(tracePosition, get(w(c),'data'), get(w(c),'freq'), Xtickmarks, wt, p.Results.colormap, s, thissta, thischan);
                set(gca,'XLim', [wt.start wt.stop]); % added 20111214 to align trace with spectrogram when data missing (prevent trace being stretched out)

                % change the trace background color if we want to identify
                % broadband stations
        % 		if (regexp(thischan, '[BH]H.'))
        % 			set(gca, 'Color', [.8 .8 .8]);
        %         end[30 100

            end
        end

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

if ~isempty(Xtickmarks)
    % trace time vector - bins are ~0.01 s apart (not 5 s as for spectrogram time)
    % not really worthwhile plotting more than 1000 points on the screen
    dnum = ((1:length(data))./freqSamp)/86400 + snum;
else
    dnum = (1:length(data))./freqSamp;
end

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
set(traceHandle,'LineWidth',[0.01],'Color',[0 0 0])

if ~isempty(Xtickmarks)
    set(gca, 'XTick', Xtickmarks, 'XTickLabel', '', 'XLim', [timewindow.start timewindow.stop], 'Ytick',[],'YTickLabel',['']);
end

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

