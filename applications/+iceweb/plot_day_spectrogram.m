function plot_day_spectrogram(s, filepattern, ctags, startTime, endTime, varargin)
% PLOT_DAY_SPECTROGRAM produce an multi-channel day spectrogram plot in the style of
% AVO web (IceWeb) spectrograms, by wrapping the default MATLAB spectrogram
% function
%
% Usage:
% 	plot_day_spectrogram(s, w, 'colormap', mycolormap, 'plot_metrics', 0)
%
% Inputs:
%   s - a spectralobject (default, if left empty becomes that used for
%                         iceweb)
%   filepattern - can include substitute strings 'SSSS', 'CCC', 'SCN',
%                   'NSLC'
%	ctag - a vector of ChannelTags objects
%   startTime - start time
%   endTime - end time
%	
%   Name/Value pairs:
%       'spectrogramFraction' - fraction of a panel height the spectrogram should take up (default: 0.75). 
%			The waveform trace takes up the remaining fraction.
%       'mycolormap' - A user-defined colormap. (Default: iceweb colormap)
%       'plot_metrics' - superimpose a plot of mean & dominant frequency
%                        (default: false)
%
% AUTHOR: Glenn Thompson, University of Alaska Fairbanks

    debug.printfunctionstack('>');

    if isempty(s)
        nfft = 1024;
        overlap = 924;
        fmax = 10;
        dbLims = [60 120];
        s = spectralobject(nfft, overlap, fmax, dbLims);
    end


    p = inputParser;
    p.addParameter('spectrogramFraction', 1, @isnumeric);
    p.addParameter('colormap', iceweb.extended_spectralobject_colormap, @isnumeric);
    p.addParameter('plot_metrics', false, @islogical);
    p.parse(varargin{:});
    spectrogramFraction = p.Results.spectrogramFraction;

    debug.print_debug(2, sprintf('%d ChannelTag objects',numel(ctags)));

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
    fsamp = 200;
    
    wt.start = startTime;
    wt.stop = endTime;
    [Xtickmarks,XTickLabel]=findMinuteMarks(wt);

    for c=1:numel(ctags)
        [T,Y,F] = iceweb.read_spectraldata_file(filepattern,startTime,endTime, ctags(c));
        % test plot the loaded spectral data
%         if debug.get_debug()>10
%             iceweb.spdatatestplot(T,F,Y);
%         end
                        
        if numel(F)==0
            warning(sprintf('No data found for %s',ctags(c).string()));
            continue;
        end
        
        if all(isnan(Y))
            warning(sprintf('All data are zeros for %s',ctags(c).string()));
            continue;
        end
        
        if F(1)==0,
            F(1)=0.001;
        end

    %     index = find(F <= fmax);
    %     T = wt.start + T/86400;
    %     Y = Y(1:max(index),:);


        [spectrogramPosition, tracePosition] = iceweb.calculatePanelPositions(numel(ctags), c, spectrogramFraction, 0.12, 0.05, 0.80, 0.9);
        axes('position', spectrogramPosition);
        if isempty(dBlims)
        % plot spectrogram
            %imagesc(T,F,abs(S));
            imagesc(T,F,Y);
        else
            imagesc(T,F,Y,dBlims);
        end
        axis xy;
        colormap(p.Results.colormap);

    %     %% superimpose graphs of frequency metrics?
    %     if p.Results.plot_metrics
    %         hold on; plot(T,smooth(meanF{c}),'k','LineWidth',.5);
    %         hold on; plot(T,smooth(peakF{c}),'w','LineWidth',.5);
    %     end        

        % Change Y-Labels to 'sta.chan'
        thissta = ctags(c).station();
        thischan = ctags(c).channel();
        ylabel( sprintf('%s\n%s',thissta, thischan(1:3) ), 'FontSize', 8);
        xlabel('')
        title('')
        set(gca,'XLim', [startTime endTime]);
        if c==numel(ctags)
            set(gca, 'XTick', Xtickmarks, 'XTickLabel', XTickLabel,  'FontSize', 8); % time labels only on bottom spectrogram
        else
            set(gca, 'XTick', Xtickmarks, 'XTickLabel', {});
        end

    %     if spectrogramFraction < 1
    %         plotTrace(tracePosition, get(w(c),'data'), get(w(c),'freq'), Xtickmarks, wt, p.Results.colormap, s, thissta, thischan);
    %         set(gca,'XLim', [wt.start wt.stop]); % added 20111214 to align trace with spectrogram when data missing (prevent trace being stretched out)
    % 
    %         % change the trace background color if we want to identify
    %         % broadband stations
    % % 		if (regexp(thischan, '[BH]H.'))
    % % 			set(gca, 'Color', [.8 .8 .8]);
    % %         end[30 100
    % 
    %     end


    end

debug.printfunctionstack('<');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plotTrace(tracePosition, data, freqSamp, Xtickmarks, timewindow, mycolormap, s, thissta, thischan);
debug.printfunctionstack('>');
startTime =timewindow.start;

% set axes position
axes('position',tracePosition);

% trace time vector - bins are ~0.01 s apart (not 5 s as for spectrogram time)
% not really worthwhile plotting more than 1000 points on the screen
dnum = ((1:length(data))./freqSamp)/86400 + startTime;

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
end
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
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [Xtickmarks,Xticklabels]=findMinuteMarks(timewindow);
debug.printfunctionstack('>');

% calculate where minute marks should be, and labels
startTime = ceilminute(timewindow.start);
endTime = floorminute(timewindow.stop);

% Number of minute marks should be no greater than 20
numMins = (endTime - startTime) * 1440;
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

Xtickmarks = startTime:stepMins/1440:endTime;
Xticklabels = datestr(Xtickmarks,15); 
debug.printfunctionstack('<');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%