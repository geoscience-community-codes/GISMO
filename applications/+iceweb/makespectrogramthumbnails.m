function makespectrogramthumbnails(spectrogramFilename, spectrogramFraction)
debug.printfunctionstack('>');

% figure 1 should be a large spectrogram with traces, cropped nicely. Now remove labels and maximise panels.

ax=get(gcf, 'Children');

% Work out number of channels
pos1 = get(ax(1),'position'); % top trace
pos2 = get(ax(2),'position'); % top sgram
height_per_channel = pos1(4) + pos2(4);
numchannels = 0.95 / height_per_channel;
numpanels = numchannels * 2;

new_height_per_channel = 1 / numchannels;

% Remove all axes, tickmarks, labels, and axis boxes and title from view
for c=1:numpanels
    set(ax(c), 'Visible', 'off')
end

% Move panels
for channelNum = 1:numchannels
    [spectrogramPosition, tracePosition] = iceweb.calculatePanelPositions(numchannels, numchannels - channelNum + 1, spectrogramFraction, 0.0, 0.0, 1, 1);
    set(ax(channelNum*2 - 1), 'position', tracePosition);
    set(ax(channelNum*2), 'position', spectrogramPosition);
end

% we need a name for the labelless large spectrogram
[tmppath, tmpbase, tmpext] = fileparts(spectrogramFilename);
tmpfile = sprintf('%s/%s_labelless%s',tmppath,tmpbase,tmpext);

% print large labelless PNG
iceweb.saveImageFile(tmpfile, 72);

% load then delete temporary file 
I = imread(tmpfile);
delete(tmpfile)

% Resize the image (aspect ratio 16:21 same as 576:756) and convert it to an indexed image with 256 colors
% (Note: we were originally creating 150x96, which is far off the aspect ratio of large spectrograms)
%[X,map] = rgb2ind(imresize(I, [126 96]), 256);
%thumbnailfile = sprintf('%s/smallest_%s%s',tmppath, tmpbase, tmpext);
%imwrite(X,map,thumbnailfile,'PNG'); 
%[X,map] = rgb2ind(imresize(I, [147 112]), 256);
%thumbnailfile = sprintf('%s/smaller_%s%s',tmppath, tmpbase, tmpext);
%imwrite(X,map,thumbnailfile,'PNG'); 
[X,map] = rgb2ind(imresize(I, [198 151]), 256);
thumbnailfile = sprintf('%s/small_%s%s',tmppath, tmpbase, tmpext);
imwrite(X,map,thumbnailfile,'PNG'); 
close;

debug.printfunctionstack('<');
