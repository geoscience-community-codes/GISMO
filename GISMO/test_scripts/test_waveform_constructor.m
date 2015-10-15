% test waveform creation
%deprecated by testWaveform.m

data = 1:(10*60*60*2.5);
st_mat = now-1;
st_txt = '5/5/2014';
et_mat = now-0.98;
et_txt = '5/5/2004 01:00:00';
sta = 'XXXX';
net = 'NW';
cha = 'BHZ';
loc = '00';
nslctxt = [net, '.', sta, '.', loc, '.', cha];
hz = 20;
unit = 'CNT';
scnl = scnlobject(sta,cha,net,loc);
tag = channeltag(net,sta,loc,cha);
ds = datasource;

disp('************* starting test  **********');
disp('CREATE: default')
w = waveform()
disp('CREATE: copy')
w2 = w
disp('CREATE: sta cha hz st data')
w = waveform(sta,       cha,  hz,      st_mat,  data)
disp('CREATE: scnl hz st data unit')
w = waveform(scnl,      hz,   st_mat,  data,    unit)
disp('CREATE: nscltxt hz st data unit')
w = waveform(nslctxt,   hz,   st_mat,  data,    unit)
disp('CREATE: tag hz st data unit')
w = waveform(tag,       hz,   st_mat,  data,    unit)
disp('CREATE: scnl hz st data')
w = waveform(scnl,      hz,   st_mat,  data)
disp('CREATE: nscltxt hz st data')
w = waveform(nslctxt,   hz,   st_mat,  data)
disp('CREATE: tag hz st data')
w = waveform(tag,       hz,   st_mat,  data)


disp('CREATE: tag hz st data unit nocombine')
w = waveform(tag,       hz,   st_mat,  data,    unit, 'nocombine')

disp('** done **');


