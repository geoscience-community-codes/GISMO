function [w,scnl]=obspy.stream2waveform(path_to_python, path_to_converter, path_to_data)
%OBSPY.STREAM2WAVEFORM Use ObsPy to read a stream object and then convert
% into a waveform object. Also return a scnlobject.
% Example:
%  [w,scnl]=obspy.stream2waveform('/Users/glennthompson/anaconda/bin/python', ...
%       '/Users/glennthompson/obspy_stream2matfile.py', ...
%       'https://examples.obspy.org/BW.BGLD..EH.D.2010.037')
%st=py.obspy.core.read('http://examples.obspy.org/RJOB_061005_072159.ehz.new')
%  plot(w)
%pyversion /Users/glennthompson/anaconda/bin/python
% Problem is here. Can call obspy directly to read stream, but cannot then write or manipulate it.
    st = py.obspy.core.read(python_to_data)
% And there is no way to call this Python code directly. Needs to be in separate .py file and called with system().
    for i, tr in enumerate(st):
        mdict = {k: str(v) for k, v in tr.stats.iteritems()}
        mdict['data'] = tr.data
        savemat("obspy.stream.%s.%s.%s.%s.mat" % (tr.stats.network, tr.stats.station, tr.stats.location, tr.stats.channel), mdict)
% this is the matfile code to convert the files created by https://www.geophysik.uni-muenchen.de/~megies/obspy-docs-colormap-change_3/tutorial/code_snippets/export_seismograms_to_matlab.html into waveform objects
% Celso tried to build something like this here: https://code.google.com/p/gismotools/source/diff?spec=svn350&r=350&format=side&path=/trunk/GISMO/%40waveform/private/load_obspy.m&old_path=/trunk/GISMO/%40waveform/private/load_obspy.m&old=
    for c=1:length(d)
        tr=load(d(c).name);
        disp(sprintf('Loaded trace %d',c))
        scnl(c)=scnlobject(tr.station, tr.channel, tr.network, tr.location);
        snum=(tr.starttime.timestamp/86400)+datenum(1970,1,1);
        w(c)=waveform(scnl, tr.sampling_rate, snum, tr.data);
        delete(d(c).name);
    end
end
