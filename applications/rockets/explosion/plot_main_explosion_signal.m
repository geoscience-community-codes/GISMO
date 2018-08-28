close all

dbpath = '/raid/data/rockets/rocketmaster2';
%dbpath = '/raid/data/rockets/rocketmaster';
ds = datasource('antelope', dbpath);
snum=datenum(2016,9,1,13,7,0);
enum = snum + 1/1440;
scnl = scnlobject('BCHH', '*', 'FL');
wf = clean(waveform(ds, scnl, snum, enum));
%%
plot_panels(wf)
suptitle('1st stage explosion infrasound')
%%
wf2=extract(wf,'time',snum+10/86400,snum+19.4/86400);
plot_panels(wf2);
suptitle('2nd stage explosion infrasound')
%%
wf3=extract(wf,'time',snum+10/86400,snum+15.8/86400);
plot_panels(wf3);
suptitle(sprintf('before 2nd stage explosion infrasound. \nseismic? infrasound precursor?'))
%%
wf4=extract(wf,'time',snum+15.8/86400,snum+16.3/86400);
plot_panels(wf4);
suptitle('2nd stage explosion infrasound zoom')

%%
load_all_rocket_events2