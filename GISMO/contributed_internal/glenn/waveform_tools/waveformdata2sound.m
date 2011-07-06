function waveformdata2sound(data, Fs, sounddir, soundfile, format)
% waveformdata2sound(data, Fs, sounddir, soundfile, format)
% Glenn Thompson 2001-2009

disp('> waveformdata2sound')

eval(['!mkdir -p ',sounddir]);
soundpath = catpath(sounddir, soundfile);
if ~exist('format','var')
	format = 'wav';
end
if strcmp(format, 'wav')
	wavwrite(data / max(data), Fs * 60, 32, soundpath );
end
if strcmp(format, 'au')
	auwrite(data / max(data), Fs * 60, 16, 'linear', soundpath );
end
disp('< waveformdata2sound')


