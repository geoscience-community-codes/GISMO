diary('unrest2.log')
diary on
debug.set_debug(0)
mins=60;

%% Sakurajima
if 0
chanmatch = 'chan=~/[BESH]H[ENZ]/  || chan=~/BD[FL123]/';
%%chanmatch = 'chan=~/HH[ZNE]/';
ds = datasource('antelope', ...
       '/raid/data/sakurajima/Seismic_Infrasound/SAK_dbs/GT/dbSAK_GT');
setup('Sakurajima', datenum(2015,5,18), datenum(2015,6,7), 'pf/setup_Sakurajima.pf', chanmatch)
iceweb(ds, 'thissubnet', 'Sakurajima', 'snum', datenum(2015,5,18), 'enum', datenum(2015,6,7), 'delaymins', 0, 'matfile', 'pf/Sakurajima.mat', 'nummins', mins, 'runmode', 'archive');
exit
end
%% Montserrat
%chanmatch = 'chan=~/[BESH]H[ENZ]/  || chan=~/BD[FL123]/';
%chanmatch = 'chan=~/[BESH]H[ENZ]/';
%chanmatch = 'chan=~/[BESH]HZ/';
chanmatch = 'chan=~/[BESH]H[ZNEXYV]/ || chan=~/BD[FL123]/';
%ds = datasource('antelope', ...
%        '/raid/data/MONTSERRAT/antelope/db/db%04d%02d%02d',...
%        'year','month','day');
ds = datasource('antelope', '/raid/data/MONTSERRAT/antelope/dbmaster/allnets_glenn');
setup('Montserrat', datenum(1995,7,1), datenum(2008,9,1), 'pf/setup_Montserrat.pf', chanmatch)
iceweb(ds, 'thissubnet', 'Montserrat', 'snum', datenum(2000,1,1), 'enum', datenum(2007,6,1), 'delaymins', 0, 'matfile', 'pf/Montserrat.mat', 'nummins', mins, 'runmode', 'archive');
iceweb(ds, 'thissubnet', 'Montserrat', 'snum', datenum(1996,10,1), 'enum', datenum(2000,1,1), 'delaymins', 0, 'matfile', 'pf/Montserrat.mat', 'nummins', mins, 'runmode', 'archive');
iceweb(ds, 'thissubnet', 'Montserrat', 'snum', datenum(1995,7,18), 'enum', datenum(1996,10,1), 'delaymins', 0, 'matfile', 'pf/Montserrat.mat', 'nummins', mins, 'runmode', 'archive');
%iceweb(ds, 'thissubnet', 'Montserrat', 'snum', datenum(2007,6,1), 'enum', datenum(2008,9,1), 'delaymins', 0, 'matfile', 'pf/Montserrat.mat', 'nummins', mins, 'runmode', 'archive');

%% Others yet to be converted to iceweb
% NOTE:
%   iceweb is just run in a single matlab session without waveform mat files and no rtexec
%   tremor_loadwaveformdata is for running concurrently with an rtexec system mixed with live data and creates waveform mat files)
%tremor_loadwaveformdata('thissubnet', 'Pavlof', 'snum', datenum(2013, 5, 17), 'enum', datenum(2013, 5, 18), 'delaymins', 0, 'matfile', 'pf/tremor_runtime.mat', 'nummins', mins, 'runmode', 'archive');
%tremor_loadwaveformdata('thissubnet', 'Pavlof', 'snum', datenum(2013, 5, 16), 'enum', datenum(2013, 5, 17), 'delaymins', 0, 'matfile', 'pf/tremor_runtime.mat', 'nummins', mins, 'runmode', 'archive');
%tremor_loadwaveformdata('thissubnet', 'Pavlof', 'snum', datenum(2013, 5, 15), 'enum', datenum(2013, 5, 16), 'delaymins', 0, 'matfile', 'pf/tremor_runtime.mat', 'nummins', mins, 'runmode', 'archive');
%tremor_loadwaveformdata('thissubnet', 'Pavlof', 'snum', datenum(2013, 5, 14), 'enum', datenum(2013, 5, 15), 'delaymins', 0, 'matfile', 'pf/tremor_runtime.mat', 'nummins', mins, 'runmode', 'archive');

%tremor_loadwaveformdata('thisubnet', 'Redoubt', 'snum', datenum(2009, 3, 23, 0, 0, 0), 'enum', datenum(2009, 4, 5), 'nummins', mins, 'runmode', 'archive');
%tremor_loadwaveformdata('thisubnet', 'Redoubt', 'snum', datenum(2009, 3, 19), 'enum', datenum(2009, 3, 23), 'nummins', mins, 'runmode', 'archive');
%tremor_loadwaveformdata('thisubnet', 'Redoubt', 'snum', datenum(2009, 1, 1, 0, 0, 0), 'enum', datenum(2009, 3, 19), 'nummins', mins, 'runmode', 'archive');
%tremor_loadwaveformdata('thisubnet', 'Redoubt', 'snum', datenum(2009, 4, 5), 'enum', datenum(2009, 4, 12), 'nummins', mins, 'runmode', 'archive');
%tremor_loadwaveformdata('thisubnet', 'Redoubt', 'snum', datenum(2009, 4, 12), 'enum', datenum(2009, 6, 1), 'nummins', mins, 'runmode', 'archive');
%tremor_loadwaveformdata('thisubnet', 'Redoubt', 'snum', datenum(2008, 11, 1), 'enum', datenum(2009, 1, 1), 'nummins', mins, 'runmode', 'archive');
%tremor_loadwaveformdata('thisubnet', 'Redoubt', 'snum', datenum(2008, 9, 1), 'enum', datenum(2008, 11, 1), 'nummins', mins, 'runmode', 'archive');
%tremor_loadwaveformdata('thisubnet', 'Okmok', 'snum', datenum(2008, 7, 15), 'enum', datenum(2008, 8, 20), 'nummins', mins, 'runmode', 'archive');
%tremor_loadwaveformdata('thisubnet', 'Pavlof', 'snum', datenum(2007, 8, 11), 'enum', datenum(2007, 9, 15), 'nummins', mins, 'runmode', 'archive');
%tremor_loadwaveformdata('thisubnet', 'Augustine', 'snum', datenum(2005, 12, 1), 'enum', datenum(2006, 3, 15), 'nummins', mins, 'runmode', 'archive');
%tremor_loadwaveformdata('thisubnet', 'Shishaldin', 'snum', datenum(1999, 2, 15), 'enum', datenum(1999, 5, 27), 'nummins', mins, 'runmode', 'archive');
%tremor_loadwaveformdata('thisubnet', 'Pavlof', 'snum', datenum(1996, 9, 10), 'enum', datenum(1997, 1, 1), 'nummins', mins, 'runmode', 'archive');
