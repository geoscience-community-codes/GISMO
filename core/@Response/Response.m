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

        % Preserve length explicitly
        y = filtfilt(z, p, y(:));
        y = y(1:N);   % HARD guarantee: no growth/shrink


        % --- Output waveform ---
        wOut = set(wIn,'DATA',y(:));
        wOut = addhistory(wOut,'Instrument response removed (FFT)');
        wOut = addhistory(wOut,'Post-filter applied');

        % --- Store metadata ---
        %zresp.scnl = get(wIn,'SCNL');
        resp.scnl = get(wIn,'channelinfo');

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

        function cookbook()
            %% Response Class Cookbook
            % RESPONSE / SACPZ MODERN INSTRUMENT RESPONSE WORKFLOW
            %
            % This cookbook demonstrates how to:
            %
            %   1) Load an instrument response from a SAC PZ file via the sacpz class
            %   2) Wrap it in a Response object and plot amplitude/phase
            %   3) Generate a synthetic waveform in counts
            %   4) Remove the instrument response with Response.apply
            %   5) (Optionally) show how you *would* load from an Antelope database
            %
            % This file is intended as an executable, minimal example of the
            % modern GISMO response system:
            %
            %   • sacpz.m        → canonical pole-zero representation
            %   • Response.m     → high-level façade around sacpz / Antelope / structs
            %
            % No legacy helpers like response_apply.m, response_get_from_db.m,
            % or response_plot.m are required anymore.

            disp('------------------------------------------------------------');
            disp('Response class cookbook starting...');
            disp('------------------------------------------------------------');

            %% ------------------------------------------------------------------------
            % 1. Locate or construct a SAC PZ definition
            %
            % We first try to find a SAC PZ file on the MATLAB path.
            % If none is found, we fall back to a small synthetic demo response.

            % Try a few common demo filenames (edit these for your own setup)
            cand = {
                'SACPZ.IU.ANMO.BHZ'   % classic IRIS-style name
                'SACPZ.DEMO.BHZ'
                'demo.SACPZ'
                };

            pzfile = '';
            for k = 1:numel(cand)
                f = which(cand{k});
                if ~isempty(f)
                    pzfile = f;
                    break
                end
            end

            if ~isempty(pzfile)
                fprintf('Found SAC PZ file: %s\n', pzfile);
                pz = sacpz(pzfile);

            else
                % ---------------------------------------------------------------------
                % Synthetic fallback: simple 1 Hz-ish broad-band instrument
                % ---------------------------------------------------------------------
                warning('No SAC PZ file found on path. Using synthetic demo PZ.');

                pz           = sacpz();  % empty, then populate by hand
                pz.station   = 'DEMO';
                pz.channel   = 'BHZ';
                pz.network   = 'XX';
                pz.location  = '--';
                pz.samplerate = 100;

                % Simple 1-pole/1-zero style system (not a real instrument)
                pz.z = [0; 0];
                pz.p = [-0.037 + 0.037i; -0.037 - 0.037i];
                pz.k = 1.0;

                pz.inputunit  = 'M/S';
                pz.outputunit = 'COUNTS';
            end

            disp('SACPZ object:');
            disp(pz);

            %% ------------------------------------------------------------------------
            % 2. Wrap SAC PZ in a Response object and plot amplitude/phase
            %
            % Response is a lightweight façade that:
            %   • Knows how to evaluate H(f)
            %   • Knows how to apply instrument correction to waveform objects

            R = Response.from_sacpz(pz);

            fprintf('\nCreated Response from sacpz:\n');
            disp(R);

            % Plot frequency response over a useful band
            figure('Name','Response amplitude/phase','Color','w');
            R.plot();
            sgtitle('Instrument response (from SACPZ)','FontSize',14);

            %% ------------------------------------------------------------------------
            % 3. Create a synthetic waveform in counts
            %
            % Here we make a 10-s, 2 Hz sine wave in "counts", then wrap it in
            % a GISMO waveform object using ChannelTag.

            fs   = 100;                        % Hz
            t    = (0:fs*10-1)'/fs;           % 10 s
            f0   = 2;                          % Hz
            data = sin(2*pi*f0*t) + 0.1*randn(size(t));   % simple noisy signal

            % Build a ChannelTag and waveform (this matches typical GISMO usage)
            try
                ctag      = ChannelTag(pz.network, pz.station, pz.location, pz.channel);
            catch
                % Fallback if ChannelTag is not available – adjust as needed
                error(['ChannelTag class not found. ' ...
                    'Edit this section to match your local waveform constructor.']);
            end

            starttime = datenum(2020,1,1,0,0,0);
            units     = 'counts';

            wraw = waveform(ctag, fs, starttime, data, units);

            figure('Name','Raw waveform','Color','w');
            plot(wraw);
            title('Raw synthetic waveform (counts)');

            %% ------------------------------------------------------------------------
            % 4. Define a post-correction filter and apply the response
            %
            % Response.apply performs:
            %   • FFT-domain inverse filtering using the sacpz transfer function
            %   • Spectral floor to avoid division by tiny values
            %   • Zero-phase Butterworth bandpass via filtfilt
            %   • Bookkeeping in the waveform HISTORY / RESPONSE / FILTER fields

            % Define a reasonable analysis band (edit to taste)
            filterObj = filterobject('b',[0.5 10],3);

            % Apply response removal
            wcorr = R.apply(wraw, filterObj);

            figure('Name','Waveform before/after correction','Color','w');
            subplot(2,1,1);
            plot(wraw);
            title('Raw waveform (counts)');
            grid on;

            subplot(2,1,2);
            plot(wcorr);
            title('Instrument-corrected waveform');
            grid on;

            %% ------------------------------------------------------------------------
            % 5. Quick sanity checks
            %
            % These are simple checks you can adapt into unit tests.

            % Check same length
            assert(get(wraw,'DATA_LENGTH') == get(wcorr,'DATA_LENGTH'), ...
                'Corrected waveform has different length than input.');

            % Check that FILTER and RESPONSE fields were attached
            miscFields = get(wcorr,'MISC_FIELDS');
            hasFilter   = any(strcmpi(miscFields,'FILTER'));
            hasResponse = any(strcmpi(miscFields,'RESPONSE'));

            assert(hasFilter,   'Corrected waveform missing FILTER field.');
            assert(hasResponse, 'Corrected waveform missing RESPONSE field.');

            disp('Basic sanity checks passed: length + FILTER/RESPONSE attached.');

            %% ------------------------------------------------------------------------
            % 6. OPTIONAL: How you would use Antelope (NOT run by default)
            %
            % The modern pattern is:
            %
            %   pz = sacpz.from_antelope(sta, chan, time, dbName);
            %   R  = Response.from_sacpz(pz);
            %   wcorr = R.apply(wraw, filterObj);
            %
            % This section is left as a commented template because:
            %   • Antelope is an optional, contributed dependency
            %   • Paths, station codes, and times are site-specific
            %
            % Uncomment and edit if you have Antelope installed.

            %{
            if exist('dbopen','file') && exist('dbresponse','file')
                fprintf('\nAntelope detected – example usage template:\n');

                dbName = '/path/to/your/antelope/database';  % EDIT ME
                sta    = 'OKSO';                             % EDIT ME
                chan   = 'BHZ';                              % EDIT ME
                t_ant  = datenum(2011,3,21,0,0,0);          % EDIT ME

                % Load response from Antelope and wrap in Response
                pz_db  = sacpz.from_antelope(sta, chan, t_ant, dbName);
                R_db   = Response.from_sacpz(pz_db);

                % Evaluate and plot
                figure('Name','Antelope-based response','Color','w');
                R_db.plot();
                sgtitle(sprintf('Response from Antelope: %s.%s', sta, chan));

                % Apply to an existing waveform wraw (must match same station/channel)
                wcorr_db = R_db.apply(wraw, filterObj);   % assuming wraw matches station
            else
                disp('Antelope MATLAB toolbox not found – skipping Antelope example.');
            end
            %}

            %% ------------------------------------------------------------------------
            % 7. Summary
            %
            %  • sacpz is now the canonical pole-zero representation in GISMO.
            %  • Response is a light façade that:
            %       – Evaluates H(f)
            %       – Applies instrument correction to waveform objects
            %  • No external response_*.m helpers are required in normal usage.
            %
            % Typical observatory pattern:
            %
            %   % 1. For each waveform w:
            %   pz = sacpz('SACPZ.XXX...');           % or sacpz.from_antelope(...)
            %   R  = Response.from_sacpz(pz);
            %   w_corrected = R.apply(w, filterObj);
            %
            %   % 2. Use w_corrected for RSAM, spectra, magnitudes, energy, etc.
            %
            disp('------------------------------------------------------------');
            disp('Response class cookbook complete.');
            disp('------------------------------------------------------------');
        end
    end
end