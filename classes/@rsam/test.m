%TEST Test the RSAM class
close all
file = '/Users/thompsong/Dropbox/MVOnetwork/SEISMICDATA/RSAM_1/%station%year.DAT';
sta = {'MLGT';'MRYT'};
chan = 'SHZ';
snum = datenum(1995,7,1);
enum = datenum(2004,12,31,23,59,59);
s = rsam.load('file', file, 'snum', snum, 'enum', enum, 'sta', sta, 'chan', chan);
s.plot();