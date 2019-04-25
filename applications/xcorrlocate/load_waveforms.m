function [waveform_object] = load_waveforms(LIST, CONDITION)
    % Function for loading waveforms from a file that contains a list of
    % waveforms or from an already existing list/cell array of waveforms.
    % Returns a waveform object that holds all waveforms in the file.


    if CONDITION == 1 % open file and load waveforms 
         fid = fopen(LIST, 'r');
         count = 1;
         while 1
             tline = fgetl(fid);
             if ~ischar(tline), break, end;
             fname = tline;
             %d = fname(1:4); 
             full = fullfile('/media/shared/mitch/telica/data/M_201205',fname);
             waveform_object(count) = waveform(full, 'sac');
             count = count + 1;
         end
    elseif CONDITION == 0 % list/array of waveforms
        count = 1;
        count5 = 1;

        for count = 1:numel(LIST)
            if exist(LIST{count}, 'file')
                waveform_object(count5) = waveform(LIST{count}, 'sac');
                count5 = count5 +1;
            else
                continue
            end
            count = count + 1;
        end
    else
        error('CONDITION must be 0 or 1, 0 for a fullfile list and 1 to generate the fullfile list')

    end

end