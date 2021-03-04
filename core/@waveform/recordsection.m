function recordsection(wv, distances)
%RECORDSECTION Plot a record section from waveform objects
%   A record section consists of seismograms plotted against distance from
%   the source.
% RECORDSECTION(wv, distances, units) where wv is a vector of waveform objects and
% distances are the distances of each station from the source. Units are
% the units of distance, which could be m, km, miles, degrees or even
% seconds.
    disp('GOT HERE')

    if numel(wv)~=numel(distances)
        error('Inputs must have the same number of elements: 1 distance for each waveform.')
    end
    
    figure
%     if min(min(wv)) < 0 % do not detrend if this is RSAM data
%         wv = detrend(wv);
%     end
    maxamp = max(max(wv));
    maxdist = max(distances);
    maxtrace = maxdist/numel(wv);
    scalingfactor = maxtrace/maxamp;
    for c = 1:numel(wv)
        wv(c)
        y = get(wv(c),'data');
        t = get(wv(c), 'timevector');
        offset = distances(c);
        plot(86400*(t-t(1)),y*scalingfactor + offset);
        hold on
    end
    set(gca, 'YLim', [-maxtrace maxdist*1.2])
    hold off
    xlabel('Time (s)')
    ylabel('Distance')
    set(gca,'YDir','reverse')
%     yticklabels = [0:200:maxdist];
%     yticks = yticklabels/maxdist-1
%     set(gca,'YTick',yticks,'YTickLabels',yticklabels)

end