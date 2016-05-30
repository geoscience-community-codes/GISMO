function isSuccessful = waveform2sound(w, speedup, outfile)
%WAVEFORM2SOUND generate an audio file from a waveform object.
%   success = waveform2sound(waveform, speedup)
%
%   Input Arguments
%       WAVEFORM - a single waveform produces a mono output.  Two waveforms
%                produce stereo, with waveform(1)=Left, waveform(2)=Right
%       SPEEDUP - speed factor (typically 60 or 100 to get into human hearing range)
%       OUTFILE - complete path and filename for output audio file.
%               Extension determines sound file type (.wav, .flac, .ogg)
%
%       If OUTFILE is omitted, sound is played instead of saved to audio
%       file.
%
%   Output Argument
%       SUCCESS - a logical value (true/false) indicating on whether this
%               worked or not
%
%   See also AUDIOWRITE

% AUTHOR: Glenn Thompson
% Previous version by Celso Reyes no longer worked (wavwrite discontinued) 
% and seemed overly complex (requiring files from Celso's GI account. It has
% been moved to the deprecated folder.
    isSuccessful = false;
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

    % ensure that both waveforms have same sampling rate
    samprate = get(w,'freq');
    if round(samprate(1))~=round(samprate(2))
        minsamprate = round(min(samprate));
        [maxsamprate,index] = round(max(samprate));
        crunchfactor = maxsamprate / minsamprate;
        w(index) = resample(w(index), 'mean', crunchfactor);
    end

    % normalize the waveforms
    for n = 1 : numel(w)
        loudestSample = max(abs(double(w(n))));
        w(n) = w(n) / loudestSample;     
        clear loudestSample
    end
    w = fix_data_length(w);     %make our waveforms the same length

    % new sampling rate
    samprate = round(get(w(1),'freq')) * round(speedup);
    
    if exist('outfile','var')
        % write sound file
        try

            titlestr = sprintf('waveform object');
            [snum, enum] = gettimerange(w(1));
            nslc = get(w,'ChannelTag');
            commentstr = sprintf('%s to %s. %s and %s',datestr(snum),datestr(enum),nslc(1).string(),nslc(2).string());
            audiowrite(outfile, [double(w(LEFT)), double(w(RIGHT))], samprate, 'title', titlestr, 'comment', commentstr)
            isSuccessful = true;
        end
    else
        a=audioplayer([double(w(LEFT)), double(w(RIGHT))], samprate);
        a=audioplayer(double(w(LEFT)), samprate)
        a.play()
        isSuccessful = true;
    end

end
