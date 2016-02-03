% Cookbook for rsam class

%% Load RSAM data for 2 stations from the Montserrat network
file = '/Users/thompsong/Dropbox/MVOnetwork/SEISMICDATA/RSAM_1/%station%year.DAT';
sta = {'MLGT';'MRYT'};
chan = 'SHZ';
snum = datenum(1995,8,1);
enum = datenum(1999,12,31);
s = rsam.read_bob_file('file', file, 'snum', snum, 'enum', enum, 'sta', sta, 'chan', chan);

%% Plot the RSAM data
s.plot()
