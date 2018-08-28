function [w,scnl]=stream_matfile2waveform(matfilepath)
%OBSPY.STREAM2WAVEFORM Use ObsPy to read a stream object and then convert
% into a waveform object. Also return a scnlobject.
% Example:
%  [w,scnl]=obspy.stream_matfile2waveform(matfilepath)
    tr=load(matfilepath)
    scnl=scnlobject(tr.station, tr.channel, tr.network, tr.location);
    %snum=(tr.starttime.timestamp/86400)+datenum(1970,1,1);
    snum=datenum('2007-08-28T00:00:00','yyyy-mm-ddTHH:MM:SS');
    w=waveform(scnl, tr.sampling_rate, snum, tr.data);
end
