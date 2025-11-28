function varargout = amplitude_spectrum(w)
%AMPLITUDE_SPECTRUM Compute amplitude spectrum of waveform(s)
%
%   s = amplitude_spectrum(w)
%   [A, phi, f] = amplitude_spectrum(w)   % single waveform only
%
%   Outputs:
%       s(count).f
%       s(count).amp
%       s(count).phi
%       s(count).peakf
%       s(count).meanf
%       s(count).freqindex
%       s(count).freqratio
%
%   Glenn Thompson refactor 2025

    % ----------------------------
    % Input validation
    % ----------------------------
    if ~isa(w,'waveform')
        error('amplitude_spectrum:InvalidInput','Input must be waveform');
    end

    nW = numel(w);

    % ----------------------------
    % Loop over waveforms
    % ----------------------------
    for count = 1:nW

        Fsamp  = get(w(count),'freq');
        signal = get(w(count),'data');
        Nsignal = numel(signal);

        %NFFT = 2^nextpow2(Nsignal);
        NFFT = Nsignal;

        Y = fft(signal, NFFT);
        NumUniquePts = NFFT/2 + 1;
        NumUniquePts = floor(NFFT/2) + 1;

        A   = 2*abs(Y(1:NumUniquePts)) / Nsignal;
        phi = angle(Y(1:NumUniquePts));
        f   = Fsamp/2 * linspace(0,1,NumUniquePts);

        % ---- Structure output ----
        s(count).f   = f(:);
        s(count).amp = A(:);
        s(count).phi = phi(:);

        % ---- Peak frequency ----
        [~,idx] = max(A);
        s(count).peakf = f(idx);

        % ---- Mean frequency ----
        s(count).meanf = sum(s(count).f .* s(count).amp) / sum(s(count).amp);

        % ---- Frequency index (Buurman & West) ----
        Al = mean(A(f >= 1 & f <= 2));
        Ah = mean(A(f >= 10 & f <= 20));
        s(count).freqindex = log10(Ah/Al);

        % ---- Frequency ratio (Rodgers) ----
        Al = mean(A(f >= 1 & f <= 5));
        Ah = mean(A(f >= 5 & f <= 15));
        s(count).freqratio = log2(Ah/Al);
    end

    % ----------------------------
    % Output dispatch
    % ----------------------------
    if nargout == 1
        % Struct output (vectorized)
        varargout{1} = s;

    elseif nargout == 3
        % Numeric output (single waveform only)
        if nW > 1
            error('amplitude_spectrum:TooManyWaveforms', ...
                  'Three-output form only supported for scalar waveform');
        end
        varargout{1} = s(1).amp;
        varargout{2} = s(1).phi;
        varargout{3} = s(1).f;

    else
        error('amplitude_spectrum:InvalidOutputs', ...
              'Use either s = amplitude_spectrum(w) or [A,phi,f] = amplitude_spectrum(w)');
    end
end
