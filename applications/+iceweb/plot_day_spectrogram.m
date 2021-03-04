function plot_day_spectrogram(s, filepattern, ctags, startTime, endTime, varargin)
% PLOT_DAY_SPECTROGRAM produce an multi-channel day spectrogram plot in the style of
% AVO web (IceWeb) spectrograms, by wrapping the default MATLAB spectrogram
% function
%
% Usage:
%   plot_day_spectrogram(s, filepattern, ctags, startTime, endTime)
% 	
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

% plot_day_spectrogram(s, w, 'colormap', mycolormap, 'plot_metrics', 0)

    debug.printfunctionstack('>');

    if isempty(s)
        nfft = 1024;
        overlap = 924;
        fmax = 15;
        dBlims = [60 120]; % 60 dB, not 80 dB as I say in WI report. 
        s = spectralobject(nfft, overlap, fmax, dBlims);
    else
        nfft = round(get(s,'nfft'));
        overlap = floor(get(s, 'over'));
        dBlims = get(s, 'dBlims');
        fmax = get(s, 'freqmax');
    end

    p = inputParser;
    p.addParameter('spectrogramFraction', 0.75, @isnumeric);
    p.addParameter('colormap', iceweb.extended_spectralobject_colormap, @isnumeric);
    p.addParameter('plot_metrics', false, @islogical);
    p.addParameter('plot_spectrum', false, @islogical);
    p.addParameter('plot_SSAM', false, @islogical);
    p.parse(varargin{:});
    spectrogramFraction = p.Results.spectrogramFraction;

    debug.print_debug(2, sprintf('%d ChannelTag objects',numel(ctags)));

    setmap(s, p.Results.colormap);
    

    % To get a colorbar, stop the function here and set colorbar option to vert

    % Reset axes position & squeeze in the trace panels
    DAYS = round(endTime-startTime);
    wt.start = startTime;
    wt.stop = endTime;
    [Xtickmarks,XTickLabel]=findMinuteMarks(wt);
    
    for c=1:numel(ctags)
        debug.print_debug(10,ctags(c).string())
        debug.print_debug(sprintf('%s\n',datestr(startTime)))
        T_all = [];
        Y_all = [];
        F = [];

        for dnum=startTime:floor(endTime)

            [T,Y,F0] = iceweb.read_spectraldata_file(filepattern,floor(dnum), floor(dnum)+1-1/86400, ctags(c));
            size(T)
            size(Y)
            size(F0)
            if ~isempty(F0)
                F=F0;
            end
            
            T_all = [T_all T];

            if numel(F)==0
                warning(sprintf('No data found for %s',ctags(c).string()));
                continue;
            end

            if all(isnan(Y))
                warning(sprintf('All data are zeros for %s',ctags(c).string()));
                continue;
            end
            
            if isempty(Y)
                Y_all = Y';
            else
                Y_all = [Y_all; Y'];
            end

            if F(1)==0,
                F(1)=0.001;
            end

        end

        [spectrogramPosition, tracePosition] = iceweb.calculatePanelPositions(numel(ctags), c, spectrogramFraction, 0.12, 0.05, 0.80, 0.9);
        axes('position', spectrogramPosition);

        index = find(F <= fmax);
        Fplot = F(1:max(index));
        Yplot = Y_all(:,1:max(index));
        thisS = power(10,Yplot/20);
        Splot{c} = power(10,Yplot/20);
        
        % white island
        gainWIZ = 5.04365e8; % counts per m/s % only for 2016/09/13 and thereafter
        gainWSRZ = 8.38861e8; % counts per m/s
        if strcmp(ctags(c).station, 'WIZ')
            disp('Correcting WIZ data')
            ind = find(T_all < datenum(2016,5,8)); % we think same as WSRZ gain here
            ind2 = find(T_all >= datenum(2016,5,8)); % modern WIZ gain
            thisS(ind) = thisS(ind) / gainWSRZ * 1e9; % nm/s
            thisS(ind2) = thisS(ind2) / gainWIZ * 1e9; % nm/s
            Splot{c} = thisS;
            Yplot = 20 * log10(thisS);
        elseif strcmp(ctags(c).station, 'WSRZ')
            disp('Correcting WSRZ data')
            thisS = thisS / gainWSRZ * 1e9; % nm/s
            Splot{c} = thisS;
            Yplot = 20 * log10(thisS);            
        end


        % if we are plotting energy rather than amplitude
        if strfind(filepattern, 'energy')
            Yplot = sqrt(Yplot/60);
        end

        if isempty(dBlims)
            % plot spectrogram
            imagesc(T_all,Fplot,Yplot');
        else
            imagesc(T_all,Fplot,Yplot',dBlims);
        end
        axis xy;
        colormap(p.Results.colormap);

        % Change Y-Labels to 'sta.chan'
        thissta = ctags(c).station();
        thischan = ctags(c).channel();
        ylabel( sprintf('%s\n%s',thissta, thischan(1:3) ), 'FontSize', 8);
        xlabel('')
        title('')
        set(gca,'XLim', [startTime endTime]);
        
        % loop over XTickLabel and replace '00:00' with day
        XTickLabel=cellstr(XTickLabel);
        for xtlnum=1:numel(XTickLabel)
            if strcmp(XTickLabel{xtlnum},'00:00')
                XTickLabel{xtlnum} = datestr(Xtickmarks(xtlnum),'mm/dd');
            end
        end
        
        if c==numel(ctags)
            set(gca, 'XTick', Xtickmarks, 'XTickLabel', XTickLabel,  'FontSize', 8); % time labels only on bottom spectrogram
            xtickangle(45);
        else
            set(gca, 'XTick', Xtickmarks, 'XTickLabel', {});
        end
    end

    % add RSAM panels
%     if spectrogramFraction < 1
%         rsamfilepattern = fullfile(fileparts(fileparts(filepattern)),'SSSS.CCC.YYYY.MMMM.060.bob');
%         for c=1:numel(ctags)
%             [spectrogramPosition, tracePosition] = iceweb.calculatePanelPositions(numel(ctags), c, spectrogramFraction, 0.12, 0.05, 0.80, 0.9);
%             r = rsam.read_bob_file(rsamfilepattern, 'snum', startTime, 'enum', endTime, 'sta', ctags(c).station, 'chan', ctags(c).channel, 'measure', 'median');
%             r = r.medfilt1(DAYS);
%             plotTrace(tracePosition, r, Xtickmarks, wt, p.Results.colormap, s, ctags(c).station, ctags(c).channel);
%             set(gca,'XLim', [wt.start wt.stop]); % added 20111214 to align trace with spectrogram when data missing (prevent trace being stretched out)
%         end
%     end
    
%     if spectrogramFraction < 1
%         fLow = [2];
%         fHigh = [5];
%         ymin=0;
%         ymax=0;
%         for c=1:numel(ctags)
%             [spectrogramPosition, tracePosition] = iceweb.calculatePanelPositions(numel(ctags), c, spectrogramFraction, 0.12, 0.05, 0.80, 0.9);
%             index = find(F <= fHigh & F >= fLow);
%             S = Splot{c};
%             S2 = S(:,1:max(index));
%             S3 = nanmean(S2,2);
%             S3 = medfilt1(S3,DAYS)/numel(T_all);
%             r.dnum = T_all;
%             r.data = S3;
%             plotTrace(tracePosition, r, Xtickmarks, wt, p.Results.colormap, s, ctags(c).station, ctags(c).channel);
%             set(gca,'XLim', [wt.start wt.stop]); % added 20111214 to align trace with spectrogram when data missing (prevent trace being stretched out)
%         end
%     end
    if spectrogramFraction < 1

        load ~/Dropbox/WhiteIsland2019Project/data/seismic/rsam/GNSrsam.mat
        gainWIZ = 5.04365e8; % counts per m/s % only for 2016/09/13 and thereafter
        gainWSRZ = 8.38861e8; % counts per m/s
        r = rsamvector.extract(startTime, endTime);
        for cc=1:numel(r)
            if strcmp(r(cc).sta, 'WIZ')
                disp('Correcting WIZ data')
                ind = find(r(cc).dnum < datenum(2016,5,8)); % we think same as WSRZ gain here
                ind2 = find(r(cc).dnum >= datenum(2016,5,8)); % modern WIZ gain
                r(cc).data(ind) = r(cc).data(ind) / gainWSRZ;
                r(cc).data(ind2) = r(cc).data(ind2) / gainWIZ;
            elseif strcmp(r(cc).sta, 'WSRZ')
                disp('Correcting WSRZ data')
                r(cc).data = r(cc).data / gainWSRZ;
            end
            [spectrogramPosition, tracePosition] = iceweb.calculatePanelPositions(numel(ctags), cc, spectrogramFraction, 0.12, 0.05, 0.80, 0.9);
            plotTrace(tracePosition, r(cc), Xtickmarks, wt, p.Results.colormap, s, ctags(cc).station, ctags(cc).channel);
            set(gca,'XLim', [wt.start wt.stop]); % added 20111214 to align trace with spectrogram when data missing (prevent trace being stretched out)
             set(gca,'YLim', [0 1.5e-5])
        end
    end
    
    % plot daily spectra
    if p.Results.plot_spectrum
        figure();
        for c=1:numel(ctags)
            subplot(numel(ctags),1,c)
            try
                disp(datestr(startTime))
                disp(datestr(endTime))
                plot(Fplot, nansum(Splot{c})/numel(T_all));
                xlabel('Frequency (Hz)')
                ylabel('Spectral amplitude')
                title(ctags(c).string());
                set(gca,'XTick',[0:1:15]);
                grid on
            catch
                size(Fplot)
                size(Splot{c})
                size(T_all)
                size(nansum(Splot{c}))
            end
        end
    end
    
    % plot SSAM in different frequency bands
    if p.Results.plot_SSAM
        figure();
        fLow = [0 2 6];
        fHigh = [1 5 fmax];
        ymin=0;
        ymax=0;
        for c=1:numel(ctags)
            for fband = 1:numel(fLow)
                index = find(F <= fHigh(fband) & F >= fLow(fband));
                S = Splot{c};
                S2 = S(:,1:max(index));
                S3 = nanmean(S2,2);
                S3 = medfilt1(S3,DAYS)/numel(T_all);
                subplot(numel(ctags),1,c)
                hold on
                plot(T_all, S3);
                ymax = nanmax([prctile(S3, 99.9) ymax]);
                ymin = nanmin([prctile(S3, 0.01) ymin]);    
            end
            if ~isempty(ymax) & ~isnan(ymax(1))
                set(gca,'YLim',[ymin ymax]);
            end  
            datetick('x');
            xlabel('Date')
            ylabel('SSAM')
            title(ctags(c).string());
            legend({'0-1 Hz';'2-5 Hz';'6-15 Hz'},'Location','best')
        end
    end


debug.printfunctionstack('<');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plotTrace(tracePosition, r, Xtickmarks, timewindow, mycolormap, s, thissta, thischan);
debug.printfunctionstack('>');
startTime =timewindow.start;

% set axes position
axes('position',tracePosition);

% plot seismogram - assuming data cleaned already with
t=r.dnum;
y=r.data;
area(t,y,'FaceColor',[0.5 0.5 0.5],'LineStyle','none')
set(gca,'XTick',[], 'YAxisLocation', 'right')

set(gca, 'XTick', Xtickmarks, 'XTickLabel', '', 'XLim', [timewindow.start timewindow.stop]); %, 'Ytick',[],'YTickLabel',['']);

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
stepMinOptions = [1 2 3 5 10 15 20 30 60 120 180 240 360 480 720 1440 1440*2 1440*3 1440*7 1440*30];
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