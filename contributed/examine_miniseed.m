function stats = examine_miniseed(thisfilename)
%EXAMINE_MINISEED Inspect internal segments of a MiniSEED file using RDMSEED
%
% stats = examine_miniseed(filename)
%
% Returns a struct of sampling statistics and generates diagnostic plots.
%
% Requires rdmseed.m (Beauducel).

assert(isfile(thisfilename), 'File not found.');

s = rdmseed(thisfilename);

nseg = numel(s);
stats.mean_fs   = nan(1,nseg);
stats.median_fs = nan(1,nseg);
stats.max_fs    = nan(1,nseg);
stats.min_fs    = nan(1,nseg);
stats.std_fs    = nan(1,nseg);
stats.given_fs  = nan(1,nseg);
stats.segment_time = nan(1,nseg);

figure

for c = 1:nseg
    subplot(3,1,1)
    plot(s(c).t, s(c).d, '.'); hold on
    datetick('x')

    tdiff = diff(s(c).t * 86400);
    real_fs = 1./tdiff;

    stats.mean_fs(c)   = nanmean(real_fs);
    stats.median_fs(c) = nanmedian(real_fs);
    stats.max_fs(c)    = nanmax(real_fs);
    stats.min_fs(c)    = nanmin(real_fs);
    stats.std_fs(c)    = nanstd(real_fs);
    stats.given_fs(c)  = s(c).SampleRate;
    stats.segment_time(c) = s(c).t(1);

    if c > 1
        stats.tjump(c-1) = s(c).t(1) - s(c-1).t(end);
    end
end

xlabel('Time')
ylabel('Amplitude')
title(sprintf('%d segments in MiniSEED file %s', nseg, thisfilename))

subplot(3,1,2)
plot(stats.segment_time, stats.given_fs,'o'); hold on
errorbar(stats.segment_time, stats.mean_fs, stats.std_fs)
plot(stats.segment_time, stats.median_fs,'.')
plot(stats.segment_time, stats.max_fs,'.')
plot(stats.segment_time, stats.min_fs,'.')
datetick('x')
ylabel('Sampling rate (Hz)')
title('Sampling Rate Statistics Per Segment')

subplot(3,1,3)
plot(stats.segment_time(2:end), 1./(stats.tjump*86400),'.')
datetick('x')
xlabel('Time')
ylabel('Effective Fs (Hz)')
title('Inter-segment Sample Rate')

end
