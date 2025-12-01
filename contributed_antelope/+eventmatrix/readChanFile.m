function stations = readChanFile(chanfile)
%EVENTMATRIX.READCHANFILE Read station/channel list file

fp = fopen(chanfile, 'r');
if fp < 0
    error('Could not open file %s', chanfile);
end

raw = textscan(fp,'%s %s %s %s', ...
    'Delimiter',',', ...
    'ReturnOnError',false, ...
    'CommentStyle','%');

fclose(fp);

C = cat(2, raw{:});
stations = C(:,1);

if numel(unique(stations)) ~= numel(stations)
    error('Duplicate station entries detected in channel file.');
end
end