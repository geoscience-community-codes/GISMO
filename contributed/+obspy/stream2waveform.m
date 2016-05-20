function [w,scnl]=obspy.stream2waveform(path_to_python, path_to_converter, path_to_data)
%OBSPY.STREAM2WAVEFORM Use ObsPy to read a stream object and then convert
% into a waveform object. Also return a scnlobject.
% Example:
%  [w,scnl]=obspy.stream2waveform('/Users/glennthompson/anaconda/bin/python', ...
%       '/Users/glennthompson/obspy_stream2matfile.py', ...
%       'https://examples.obspy.org/BW.BGLD..EH.D.2010.037')
%  plot(w)
    commandstr=sprintf('%s %s "%s"',path_to_python, path_to_converter, path_to_data);
    system(commandstr);
    clear commandstr fname
    d=dir('obspy.stream.*.mat');
    disp(sprintf('%d trace matfiles found\n',length(d))) 
    for c=1:length(d)
        tr=load(d(c).name);
        disp(sprintf('Loaded trace %d',c))
        scnl(c)=scnlobject(tr.station, tr.channel, tr.network, tr.location);
        snum=(tr.starttime.timestamp/86400)+datenum(1970,1,1);
        w(c)=waveform(scnl, tr.sampling_rate, snum, tr.data);
        delete(d(c).name);
    end
end
