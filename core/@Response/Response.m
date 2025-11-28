classdef Response
    % RESPONSE  High-level instrument response facade
    %
    % Wraps one of:
    %   - sacpz object
    %   - Antelope database reference (lazy)
    %   - Legacy response struct (compatibility)
    %
    % Numerical physics ALWAYS handled by sacpz or legacy struct.
    % Deconvolution ALWAYS handled by response_apply (external).
    %

    properties (Access=private)
        mode   % 'sacpz' | 'antelope' | 'structure'
        source % sacpz object | dbName | response struct
        tag    % ChannelTag (for Antelope)
        time   % datenum     (for Antelope)
    end

    methods
        function obj = Response()
        end

        function H = evaluate(obj, frequencies)
            switch obj.mode
                case 'sacpz'
                    resp = obj.source.to_response_structure(frequencies);
                    H = resp.values;

                case 'antelope'
                    pz = sacpz.from_antelope( ...
                        obj.tag.station, ...
                        obj.tag.channel, ...
                        obj.time, ...
                        obj.source);
                    resp = pz.to_response_structure(frequencies);
                    H = resp.values;

                case 'structure'
                    H = interp1( ...
                        obj.source.frequencies, ...
                        obj.source.values, ...
                        frequencies, ...
                        #'linear','extrap');
                        'spline','extrap');

                otherwise
                    error('Invalid response mode');
            end
        end

        function wOut = apply(obj, wIn, filterObj)
        % APPLY  Remove instrument response using FFT deconvolution

            wOut = repmat(wIn, size(wIn));

            for n = 1:numel(wIn)
                wOut(n) = obj.apply_one(wIn(n), filterObj);
            end
        end

        function plot(obj, xLimits)

            if nargin < 2
                xLimits = [];
            end

            f = logspace(-3,2,600);
            H = obj.evaluate(f);

            figure('Color','w');
            set(gcf,'DefaultAxesFontSize',14);
            set(gcf,'DefaultLineLineWidth',2);

            subplot(2,1,1);
            semilogx(f, angle(H)*180/pi, 'k');
            grid on; box on;
            ylabel('Phase (degrees)');
            ylim([-180 180]);
            set(gca,'YTick',[-180 -135 -90 -45 0 45 90 135 180]);
            if ~isempty(xLimits), xlim(xLimits); end

            subplot(2,1,2);
            semilogx(f, abs(H), 'k');
            set(gca,'YScale','log');
            grid on; box on;
            ylabel('Amplitude');
            xlabel('Frequency (Hz)');
            if ~isempty(xLimits), xlim(xLimits); end

        end
    end

    methods (Access=private)

    function wOut = apply_one(obj, wIn, filt)

        raw = double(wIn);
        fs  = get(wIn,'FREQ');
        N   = numel(raw);
        nyq = fs/2;

        raw = raw(:)';
        X   = fft(raw);
        f   = (0:N-1) * fs / N;

        % --- Evaluate response ---
        H = obj.evaluate(f);

        H(abs(H) < 1e-12) = 1e-12;
        Hinv = 1 ./ H;

        % --- Deconvolution ---
        Y = X .* Hinv;
        y = real(ifft(Y));

        % --- Post-filter ---
        fc = get(filt,'CUTOFF') ./ nyq;
        [z,p] = butter(get(filt,'POLES'), fc);
        y = filtfilt(z,p,y);

        % --- Output waveform ---
        wOut = set(wIn,'DATA',y(:));
        wOut = addhistory(wOut,'Instrument response removed (FFT)');
        wOut = addhistory(wOut,'Post-filter applied');

        % --- Store metadata ---
        resp.scnl = get(wIn,'SCNL');
        resp.frequencies = f(:);
        resp.values = H(:);

        wOut = addfield(wOut,'RESPONSE',resp);
        wOut = addfield(wOut,'FILTER',filt);

    end
    end    

    %% --- Static constructors ---
    methods (Static)
        function R = from_sacpz(pz)
            R = Response;
            R.mode = 'sacpz';
            R.source = pz;
        end

        function R = from_antelope(sta, chan, time, db)
            R = Response;
            R.mode   = 'antelope';
            R.source = db;
            R.tag    = scnlobject(sta,chan,'','');
            R.time   = time;
        end

        function R = from_struct(S)
            R = Response;
            R.mode = 'structure';
            R.source = S;
        end

        function R = fromSacpzFile(filename)
            %FROMSACPZFILE Create Response from a SACPZ file or URL
            %
            %   R = Response.fromSacpzFile(filename)
            %
            %   filename may be:
            %       - Local SACPZ file path
            %       - Raw SACPZ text
            %       - IRIS SACPZ URL
            %
            %   Internally constructs a sacpz object and wraps it
            %   inside a Response facade.
            %

            pz = sacpz(filename);
            R  = Response.from_sacpz(pz);
        end
    end
end