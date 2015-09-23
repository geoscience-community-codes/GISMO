function spectrogramFilename = get_spectrogram_filename(paths, subnet, enum)
debug.printfunctionstack('>');
timestamp = datestr(enum, 30);
spdir = fullfile(paths.spectrogram_plots, subnet, timestamp(1:4), timestamp(5:6), timestamp(7:8));
spectrogramFilename = fullfile(spdir, [timestamp, '.png']);
debug.printfunctionstack('<');
