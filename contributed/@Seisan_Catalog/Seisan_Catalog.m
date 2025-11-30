classdef Seisan_Catalog < Catalog
%SEISAN_CATALOG  GISMO Catalog subclass backed by SEISAN S-files
%
%   This class provides a high-level container for multiple SEISAN
%   S-file events as parsed by the Sfile class. It is designed primarily
%   for use with the Montserrat Volcano Observatory (MVO) SEISAN archives,
%   which include several non-standard extensions:
%
%     • Amplitude–Energy–Frequency (AEF) lines written by ampengfft
%       (sometimes embedded in S-files, sometimes in parallel *.aef files)
%     • Trigger-window duration lines:
%         - Broadband trigger window (bbdur)
%         - Short-period trigger window (spdur)
%
%   Architectural design:
%   ---------------------
%   • Sfile      = atomic, single-event SEISAN parser
%   • Seisan_Catalog = multi-event container + analysis + waveform access
%
%   Seisan_Catalog OWNS an array of Sfile objects and synchronizes essential
%   event metadata into the parent GISMO Catalog fields for compatibility
%   with existing GISMO workflows.
%
%   This class is SEISAN-specific and therefore belongs in:
%       contributed_seisan/
%
%   ---------------------------------------------------------------------
%   EXAMPLE:
%
%     dbpath = '/raid/data/MONTSERRAT/seisan/REA/MVOE_';
%     files  = Sfile.list_sfiles(dbpath, datenum(2002,2,27), datenum(2002,3,1));
%
%     sfiles = cell(numel(files),1);
%     for i = 1:numel(files)
%         sfiles{i} = fullfile(files(i).dir, files(i).name);
%     end
%
%     C = Seisan_Catalog(sfiles);
%     C = C.addwaveforms();
%     C.regress_energy_vs_amplitude_all();
%
%   Author: Glenn Thompson
%   ---------------------------------------------------------------------

    properties
        % Array of Sfile objects (one per event)
        sfiles = Sfile.empty
    end

    properties (Dependent)
        % Backward-compatible proxies (optional legacy API support)
        aef
        wavfiles
        sfilepath
    end

    methods
        %------------------------------------------------------------------
        function self = Seisan_Catalog(sfilePaths)
        %SEISAN_CATALOG  Construct catalog from S-file paths
        %
        %   C = Seisan_Catalog()              -> empty catalog
        %   C = Seisan_Catalog(sfilePaths)   -> load from cellstr of paths
        %
        %   sfilePaths must be a cell array of full S-file paths.

            self@Catalog();  % initialize empty GISMO catalog

            if nargin == 0 || isempty(sfilePaths)
                return;
            end

            assert(iscellstr(sfilePaths), ...
                'Argument must be a cellstr of S-file paths.');

            n = numel(sfilePaths);
            self.sfiles = Sfile.empty(n,0);

            for i = 1:n
                self.sfiles(i) = Sfile(sfilePaths{i});
            end

            % Synchronize core GISMO Catalog fields
            self = self.syncFromSfiles();
        end

        %------------------------------------------------------------------
        function self = syncFromSfiles(self)
        %SYNCFROMSFILES  Populate Catalog fields from Sfile array
        %
        %   Transfers origin times, event classes, arrivals, etc. from
        %   the SEISAN domain (Sfile) into GISMO Catalog fields.

            n = numel(self.sfiles);

            if n == 0
                return;
            end

            self.otime    = nan(n,1);
            self.etype    = cell(n,1);
            self.arrivals = Arrival.empty;

            for i = 1:n
                s = self.sfiles(i);

                self.otime(i)   = s.otime;      % origin time
                self.etype{i}  = s.subclass;   % MVO volcanic subclass

                if ~isempty(s.arrivals)
                    self.arrivals(i) = s.arrivals;
                else
                    self.arrivals(i) = Arrival();
                end
            end
        end

        %------------------------------------------------------------------
        function self = addwaveforms(self)
        %ADDWAVEFORMS  Load SEISAN waveform files for all events
        %
        %   self = self.addwaveforms()
        %
        %   Uses wavfiles + topdir stored in each Sfile to locate waveform
        %   files and load them via:
        %       waveform(filename,'seisan')
        %
        %   If multiple traces exist, they are combined automatically.

            n = numel(self.sfiles);
            w = cell(n,1);

            for i = 1:n
                s = self.sfiles(i);

                if isempty(s.wavfiles)
                    w{i} = waveform.empty;
                    continue;
                end

                w0 = waveform.empty;

                for k = 1:numel(s.wavfiles)
                    wavfile = fullfile(s.topdir, s.wavfiles{k});

                    if exist(wavfile,'file') == 2
                        try
                            w0(end+1) = waveform(wavfile,'seisan'); %#ok<AGROW>
                        catch ME
                            fprintf('Failed to read %s:\n%s\n', ...
                                wavfile, ME.message);
                        end
                    else
                        fprintf('Missing WAV: %s\n', wavfile);
                    end
                end

                if numel(w0) > 1
                    try
                        w{i} = combine(w0);
                    catch
                        w{i} = w0;
                    end
                else
                    w{i} = w0;
                end
            end

            self.waveforms = w;
        end

        %------------------------------------------------------------------
        function regress_energy_vs_amplitude(self, eventnum)
        %REGRESS_ENERGY_VS_AMPLITUDE  Fit log10(E) vs log10(A) for one event
        %
        %   self.regress_energy_vs_amplitude(eventnum)
        %
        %   Uses AEF data stored in the corresponding Sfile object.

            validateattributes(eventnum, {'numeric'}, ...
                {'scalar','integer','>=',1,'<=',numel(self.sfiles)});

            s = self.sfiles(eventnum);

            if isempty(s.aef) || ~isfield(s.aef,'amp') || ~isfield(s.aef,'eng')
                error('No AEF data for event %d.', eventnum);
            end

            amp = s.aef.amp(:);
            eng = s.aef.eng(:);

            mask = (amp > 0) & (eng > 0) & isfinite(amp) & isfinite(eng);
            amp  = amp(mask);
            eng  = eng(mask);

            logamp = log10(amp);
            logeng = log10(eng);

            p = polyfit(logamp, logeng, 1);

            figure;
            plot(logamp, logeng, '*');
            hold on;
            xlabel('log_{10}(Amplitude)');
            ylabel('log_{10}(Energy)');
            xlims = xlim;
            px = linspace(xlims(1), xlims(2));
            plot(px, polyval(p,px));

            txt = sprintf('log_{10}(E) = %.2f log_{10}(A) + %.2f', ...
                p(1), p(2));
            text(px(round(end/3)), polyval(p,px(round(end/3))), txt);
            grid on;
        end

        %------------------------------------------------------------------
        function regress_energy_vs_amplitude_all(self)
        %REGRESS_ENERGY_VS_AMPLITUDE_ALL  Network-wide scaling analysis
        %
        %   Produces a scatter plot of power-law exponent vs median
        %   log-amplitude for all events with valid AEF data.
        %
        %   Points are color-coded by MVO subclass:
        %       r e h l t

            figure; hold on;

            for i = 1:numel(self.sfiles)

                s = self.sfiles(i);

                if isempty(s.aef) || ...
                   ~isfield(s.aef,'amp') || ...
                   ~isfield(s.aef,'eng')
                    continue;
                end

                amp = s.aef.amp(:);
                eng = s.aef.eng(:);

                mask = (amp > 0) & (eng > 0);
                if ~any(mask)
                    continue;
                end

                logamp = log10(amp(mask));
                logeng = log10(eng(mask));

                p = polyfit(logamp, logeng, 1);
                medLogAmp = median(logamp);

                colorChar = local_map_etype(s.subclass);
                plot(medLogAmp, p(1), [colorChar '.']);
            end

            xlabel('log_{10}(median amplitude)');
            ylabel('Energy–Amplitude power-law exponent');
            grid on;
            title('MVO Energy–Amplitude Scaling');
        end

        %========================
        % Dependent properties
        %========================

        function val = get.aef(self)
            val = cell(numel(self.sfiles),1);
            for i = 1:numel(self.sfiles)
                val{i} = self.sfiles(i).aef;
            end
        end

        function val = get.wavfiles(self)
            val = cell(numel(self.sfiles),1);
            for i = 1:numel(self.sfiles)
                val{i} = self.sfiles(i).wavfiles;
            end
        end

        function val = get.sfilepath(self)
            val = cell(numel(self.sfiles),1);
            for i = 1:numel(self.sfiles)
                val{i} = self.sfiles(i).sfilepath;
            end
        end
    end
end


%----------------------------------------------------------------------
% Local utility: map MVO subclass to plot color
%----------------------------------------------------------------------
function c = local_map_etype(subclass)

    switch lower(subclass)
        case 'r', c = 'r';
        case 'e', c = 'm';
        case 'h', c = 'b';
        case 'l', c = 'c';
        case 't', c = 'g';
        otherwise
            c = 'k';
    end
end
