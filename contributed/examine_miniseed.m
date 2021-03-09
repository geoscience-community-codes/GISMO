function examine_miniseed(thisfilename)
%EXAMINE_MINISEED Analyze all segments within a MiniSEED file
%   MiniSEED files can continue multiple segments, separated by changes in
%   sampling interval. EXAMINE_MINISEED uses RDMSEED to load the file and
%   then EXAMINE_MINISEED plots various statistics.

s = rdmseed(thisfilename); % written by Francois Beuducel

figure
for c=1:numel(s)
    subplot(3,1,1), plot(s(c).t, s(c).d,'.')
    hold on
    datetick('x')
    
    %             w(c) = waveform(ChannelTag(s(c).network, s(c).station, s(c).location, s(c).channel), ...
    %                 s(c).sampleRate, epoch2datenum(s(c).startTime), s(c).data);
    %             w(c) = waveform(ChannelTag(s(c).NetworkCode, s(c).StationIdentifierCode, s(c).LocationIdentifier, s(c).ChannelIdentifier), ...
    %                 s(c).SampleRate, s(c).RecordStartTimeMATLAB, s(c).d);
    %                 debug.print_debug(1, sprintf('Segment %d of %d\n', c, numel(s)) )
    tdiff = diff(s(c).t*86400);
    real_fs = 1./tdiff;
    mean_fs(c) = nanmean(real_fs);
    median_fs(c) = nanmedian(real_fs);
    max_fs(c) = nanmax(real_fs);
    min_fs(c) = nanmin(real_fs);
    std_fs(c) = nanstd(real_fs);
    given_fs(c) = s(c).SampleRate;
    segment_time(c) = s(c).t(1);
    
    if c>1
        tjump(c-1) = s(c).t(1) - s(c-1).t(end);
    end
end
xlabel('Time')
ylabel('Amplitude')
title(sprintf('%d segments in MiniSEED file %s', numel(s), thisfilename) )

subplot(3,1,2)
plot(segment_time, given_fs, 'o');
hold on
errorbar(segment_time, mean_fs, std_fs);
plot(segment_time, median_fs, '.');
plot(segment_time, max_fs, '.');
plot(segment_time, min_fs, '.');
datetick('x')
legend({'given';'mean';'median';'max';'min'});
ylabel('Sampling rate')
xlabel('Time')
title('Statistics of sampling rate within each segment')


subplot(3,1,3)
plot(segment_time(2:end), 1./(tjump*86400), '.');
datetick('x')
xlabel('Time')
ylabel('Sampling rate')
title('Instantaneous sample rate between segments (Hz)')

end
