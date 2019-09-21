clear all, clc, close all
dbpath='gdrive/data/AUGUSTINE_2005/db';
augcatobj = Catalog.retrieve('antelope', 'dbpath', dbpath,'startTime',datenum(2005,1,1),'endTime',datenum(2007,1,1));
augerobj = augcatobj.eventrate()
augerobj.plot('metric', {'counts';'energy'})
save AUGUSTINE2005.mat 

%% 
% That's great, but how do we load event waveforms too?
subcatobj = augcatobj.subset('start_time',datenum(2005,7,17),'end_time', datenum(2005,7,25));
%%
ds = datasource('antelope', dbpath);
ctag(1) = ChannelTag('.AUE..SHZ');
ctag(2) = ChannelTag('.AUH..SHZ');
ctag(3) = ChannelTag('.AUI..SHZ');
ctag(4) = ChannelTag('.AUL..BHZ');
ctag(5) = ChannelTag('.AUL..SHZ');
ctag(6) = ChannelTag('.AUP..SHZ');
ctag(7) = ChannelTag('.AUR..SHZ');
ctag(8) = ChannelTag('.AUS..SHZ');
ctag(9) = ChannelTag('.AUW..SHZ');
pretriggerSecs=10;
posttriggerSecs=60;
subcatobj.addwaveforms(ds, ctag, pretriggerSecs, posttriggerSecs);
