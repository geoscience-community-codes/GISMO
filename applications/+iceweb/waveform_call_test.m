clear w
w = waveform(datasourceObject, ChannelTagList, startTime, ...
    min([startTime+1/24 endTime]) );
if isempty(w)
    disp('No data')
else
    w=iceweb.apply_calib(w, calibObjects);
    w=clean(w);
    plot_panels(w)
end