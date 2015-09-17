function w = load_from_file(myLoadFunc, fname, allowMultiple, ErrorOnEmpty)
   % load waveforms from a file using myLoadfunc
   % w = load_from_file(myLoadFunc, singleFileName);
   %     singleFileName may have wildcards.
   
   
   possiblefiles = dir(fname); % this handles wildcards
   
   if isempty(possiblefiles)
      error('Waveform:waveform:FileNotFound','No file matches: %s', fname);
   end
   
   mydir = fileparts(fname); %fileparts returns [path, name, ext]
   myfiles = fullfile(mydir, {possiblefiles(:).name});
   w(numel(myfiles)) = waveform; %best-guess preinitialization (candidate for trouble!)
   startindex = 0;
   while ~isempty(myfiles)
      [f, myfiles] = peel(myfiles);
      tmp = myLoadFunc(f);
      nFound = numel(tmp);
      switch nFound
         case 0
            if ErrorOnEmpty
               error('Waveform:waveform:noData','no data retrieved: %s', f);
            end
         case 1
            w(startindex+1) = tmp;
         otherwise
            if allowMultiple
               w(startindex+1:startindex+nFound) = tmp(:);
            else
               error('Waveform:waveform:MultipleWaveformsInFile',...
                  'Expected a single waveform, but several exist: %s', f)
            end
      end %switch
      startindex = startindex + nFound;
   end %while
end %load_from_file

function [v, cell_array] = peel(cell_array)
   % remove first item from a cell array, return remaining items
   v = cell_array{1};
   cell_array(1) = [];
end %peel
