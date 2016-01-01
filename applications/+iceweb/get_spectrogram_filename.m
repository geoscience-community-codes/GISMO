function spectrogramFilename = get_spectrogram_filename(paths, subnet, dnum)
   % get_spectrogram_filename    return filename based on path, subnet, and date
debug.printfunctionstack('>');
timestamp = datestr(dnum, 30);
spdir = fullfile(paths.spectrogram_plots, subnet, timestamp(1:4), timestamp(5:6), timestamp(7:8));
spectrogramFilename = fullfile(spdir, [timestamp, '.png']);
debug.printfunctionstack('<');
end
