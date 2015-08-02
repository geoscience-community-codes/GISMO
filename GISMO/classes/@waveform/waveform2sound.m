function isSuccessful = waveform2sound(w, outfile, speedup)
%WAVEFORM2SOUND generate a wav file from the existing waveform
%   Success = waveform2sound(waveform, outfile, speedup)
%
%   Input Arguments
%       WAVEFORM - a single waveform produces a mono output.  Two waveforms
%                produce stereo, with waveform(1)=Left, waveform(2)=Right
%       OUTFILE - complete path and filename for output (*.wav) file
%       SPEEDUP - speed factor.  Typically, 100.  this brings 
%               Other speedup factors might produce funny sounding intros
%
%   Output Argument
%       SUCCESS - a logical value (true/false) indicating on whether this
%               worked or not
%
%   See also WAVREAD, WAVWRITE

%references to filter object was removed: waveform is independent of filter
%and need no nothing about it.  Prefilter instead!

% VERSION: 1.0 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 4/6/2009

%our conventions
LEFT = 1;
RIGHT = 2;

if numel(w) > 2 %too many waveforms, we'll use first two for stereo
    warning('Waveform:waveform2sound:tooManyWaveforms','Only using first two waveforms!');
    w = [w(1) w(2)];
elseif isscalar(w)
    w = [w(1) w(1)];
end

w = demean(w); %make sure we're centered about zero...

for n = 1 : numel(w)
    loudestSample = max(abs(double(w(n))));
    w(n) = w(n) ./ loudestSample; % normalize.
    
    % adjust sound level
    h = hilbert(w(n)); %grab the hilbert envelope
    peakmask = getpeaks(h); %get the location of the envelope's peaks
    h = double(h); %grab the actual data
    avgAmp = mean(h(peakmask));%average of the peaks of the envelope (whew!)
    w(n) = w(n) ./ (avgAmp .* 2); %set the average peak amplitude to 1/2 max    
    clear h loudestSample peakmask avgAmp
end
w = fix_data_length(w);     %make our waveforms the same length

%grab the headers (the "voice" that announces station and time)
whL = waveheader(w(LEFT));
whR = waveheader(w(RIGHT));

%grab longest file and make both same size. (or data will be out of synch)
maxheader = max(length(whL),length(whR));
whL(maxheader,1) = 0;
whR(maxheader,1) = 0;

%calculate frequency of the new wavefile
newspeed = speedup .* get(w(1),'fs');  % for 100x speedup, 100 Hz sampling -- 100Hz * 100 = 10000

LeftChannel = [whL; double(w(LEFT))];
RightChannel = [whR; double(w(RIGHT))];
clear w whL whR

try
    wavwrite([LeftChannel, RightChannel], newspeed, outfile)
catch
    isSuccessful = false;
    return 
end
isSuccessful = true;
return

function wh = waveheader(w)
% create a soundheader from this info

blankbit =zeros(3000,1);

mydate = datestr(get(w,'start'),30); %yyyymmddTHHMMSS
[yy,mo,dd,hh,mi,ss] = strread( mydate,'%4c%2c%2cT%2c%2c%2c');
sdirect = '/home/celso/CRON/soundbits/';

%assemble the new waveform
try
    sta = wavread([sdirect,'station', get(w,'station'), '.wav']);
catch
    sta = 0;
end;


%for debug purposes
disp([sdirect, 'number' dd '.wav']);           % date
disp([sdirect, 'month' mo '.wav']);              % month
disp([sdirect, 'number2000.wav']);               % 2000
disp([sdirect , 'number', yy(3:4), '.wav']);     % year
disp([sdirect,'number', hh, '.wav']);            % Hour
disp([sdirect,'number', mi, '.wav']);            % Minute
disp([sdirect,'UTC.wav']);                       % UTC
%end debug purposes
try
wh = [...
    wavread([sdirect, 'number' dd '.wav']);             % date
    wavread([sdirect, 'month' mo '.wav']);              % month
    wavread([sdirect, 'number2000.wav']);               % 2000
    wavread([sdirect , 'number', yy(3:4), '.wav']);     % year
    blankbit;
    wavread([sdirect,'number', hh, '.wav']);            % Hour
    wavread([sdirect,'number', mi, '.wav']);            % Minute
    wavread([sdirect,'UTC.wav']);                       % UTC
    blankbit;
    sta;                                                % Station Code
    blankbit;
    ];
catch
    wh = [0];
end