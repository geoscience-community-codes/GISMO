function wave = filt(wave,f_type,f_rng)

%FILT: Quick function for 2-pole filtering waveforms and avoiding the 
%      hassle of generating a filterobject
%
%USAGE: wave = filt(wave,f_type,f_rng)
%
%INPUTS:  wave - input waveform
%         f_type - 'lp', 'hp', 'bp' (all 2 pole filters)
%OUTPUT: wave - filtered waveform

wave = fillgaps(wave,0);

if any(strcmpi(f_type,{'b','bp','band','bandpass'}))
    wave = filtfilt(filterobject('B',f_rng,2),wave);
elseif any(strcmpi(f_type,{'h','hp','high','highpass'}))
    wave = filtfilt(filterobject('H',f_rng,2),wave);
elseif any(strcmpi(f_type,{'l','lp','low','lowpass'}))
    wave = filtfilt(filterobject('L',f_rng,2),wave);
end
