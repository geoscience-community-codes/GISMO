% function to read a list of waveforms and make a directory with the sac
% files

LIST='M-2012-05-11-edit2.dat';

cd('~/Desktop/Multiplets')
copy_waveforms(LIST)

function [test_data] = copy_waveforms(LIST)
% Function for loading waveforms from a file that contains a list of
% waveforms or from an already existing list/cell array of waveforms.
% Returns a waveform object that holds all waveforms in the file.

fid = fopen(LIST, 'r');
mkdir ~/Desktop/test_data
count = 1;
while 1
    tline = fgetl(fid);
    if ~ischar(tline), break, end;
    fname = tline;
    d = fname(1:4);
    wfile = fullfile(d,fname); % variable part of the file path
    full = fullfile('~/Desktop/Multiplets', wfile) % fullfile path to wfile
    copyfile(full,'~/Desktop/test_data')
    count = count + 1;
    %waveform_object(count) = waveform(full, 'sac');
    %count = count + 1;
end
end