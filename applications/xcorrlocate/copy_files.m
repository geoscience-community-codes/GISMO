% function to read a list of waveforms and make a directory with the sac
% files
function copy_files()
LIST='/media/shared/mitch/telica/2011-09-22.dat';
WRKDIR='/media/shared/mitch/telica/data';

cd(WRKDIR)
copy_waveforms(LIST, WRKDIR)

end

function [] = copy_waveforms(LIST,WRKDIR)
% Function for loading waveforms from a file that contains a list of
% waveforms or from an already existing list/cell array of waveforms.
% Returns a waveform object that holds all waveforms in the file.

sta = {'TBTN'; 'TBMR'; 'TBHY'; 'TBHS'};
chan = {'BHZ'; 'BHN'; 'BHE'};


fid = fopen(LIST, 'r');
count = 1;
while 1
    tline = fgetl(fid);
    if ~ischar(tline), break, end
    fname = tline;
    d = fname(1:4);
    wfile = fullfile(d,fname); % variable part of the file path
    full = fullfile(WRKDIR, wfile); % fullfile path to wfile
    for station = 1:numel(sta)
        nextstation = strrep(full, 'TBTN', sta{station});
        if exist(nextstation, 'file')
            copyfile(nextstation,'/media/shared/mitch/telica/data/M_201109')
        else
            continue
        end
        for channel = 1:numel(chan)
            nextchannel = strrep(nextstation, 'BHZ', chan{channel});
            if exist(nextchannel, 'file')
                copyfile(nextchannel, '/media/shared/mitch/telica/data/M_201109');
            else
                continue
            end
        end
    end
    count = count + 1;
    %waveform_object(count) = waveform(full, 'sac');
    
end
end