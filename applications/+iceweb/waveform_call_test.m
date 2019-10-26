clear w
w = waveform(datasourceObject, ChannelTagList, startTime, ...
    min([startTime+1/86400 min([endTime startTime+1/24]) ]) );
if isempty(w)
    disp('No data')
else
    w=iceweb.apply_calib(w, calibObjects);
    w=clean(w);
    plot_panels(w)

end