function [waveform_object] = load_waveforms(LIST, TYPE)
%LOAD_WAVEFORMS reads either a file or a cellarray of waveform filenames
%and loads them into one waveform object. 
%       Input Arguments:
%           LIST: either 1) a filename containing the names of the files to
%           loaded into a waveform object or 2) a cellarray containing the
%           names of the waveform files. Note: for 1) use the fullfile path
%           to the file. It can read relative paths but using the fullfile
%           path is recommended.
%           TYPE: either 1) 'file' for the file option or 2) 'cellarray'
%           for the cell array option.
%       Output/Examples:
%           waveform_object: a waveform object containing the waveforms
%           from the sac files that exist within the list provided.
%               Ex from a file:
%                   LIST = '/media/mitch/telica/data/2012-05-11.dat'
%                   TYPE = 'file'
%                   wobj = load_waveforms(LIST,TYPE);
%               Ex from a cell array:
%                   NOTE: this is the option to use after station_replace
%                   to load the output of station replace to a waveform
%                   object.
%                   LIST = station_replace(wobj, new_station, new_channel)
%                   TYPE = 'cellarray'
%                   wobj = load_waveforms(LIST, TYPE)

    
    % directory containing the data subfolders.
    wrkdir = '/media/shared/mitch/telica/data';
    
    switch TYPE
        case 'file'
            fid = fopen(LIST, 'r');
            count = 1;
            while 1
                tline = fgetl(fid);
                if ~ischar(tline), break, end;
                fname = tline;
                d = fname(1:4); 
                full = fullfile(wrkdir,d,fname);
                waveform_object(count) = waveform(full, 'sac');
                count = count + 1;
            end
        case 'cellarray'
            count = 1;
            count2 = 1;
            for c = 1:numel(LIST)
                if exist(LIST{count},'file')
                    waveform_object(count2) = waveform(LIST{count},'sac');
                    count2 = count2 + 1;
                else
                    sprintf('%s does not exist, maybe incorrect path?',LIST{count})
                end
                count = count + 1;
            end
        otherwise
            error('%s is not an option, use file or cellarray',TYPE)
    end
    
end