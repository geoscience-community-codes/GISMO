function scroll(w, timeStepSeconds)
%SCROLL scroll through the data in a waveform vector

% fh = plot_panels(w);
% % hScrollLeft = uicontrol('Parent', fh, 'Style', 'pushbutton','String','<-','Position',[0 0 40 20]);
% % p = get(fh, 'Position');
% % hScrollRight = uicontrol('Parent', fh, 'Style', 'pushbutton','String','->','Position',[p(3)-40 0 40 20]);
% 
% 
% hScrollLeft = uicontrol('Parent', fh, 'Style', 'pushbutton','String','<-','Position',[0 0 0.05 0.01],'units','normalized');
% p = get(fh, 'Position');
% hScrollRight = uicontrol('Parent', fh, 'Style', 'pushbutton','String','->','Position',[0.95 0 0.05 0.01],'units','normalized');
% 
% get(hScrollRight)
% set(hScrollRight,'units')


[snum enum]=gettimerange(w);
close all
h = scrollplot();
data = guidata(h);
data.w = w;
data.snum = min(snum);
data.enum = max(enum);
data.timeStep = timeStepSeconds/86400;
data.winstart = data.snum;
data.winend = data.snum + data.timeStep * 2;
data.zoomstart = data.winstart;
data.zoomend = data.winend;
data.we = extract(w,'time', data.winstart, data.winend);
data.autoscale = true;
guidata(h,data);
plot(data.we,'axeshandle',data.axes1,'autoscale',data.autoscale)
ylabel(data.axes1,'');
end

