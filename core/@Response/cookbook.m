%% Response Class Cookbook
% This tutorial demonstrates how to:
%
%  • Load instrument responses from different sources
%  • Visualize amplitude and phase responses
%  • Apply causal instrument correction to waveform data
%  • Work safely with or without Antelope installed
%
% The Response class is a modern object-oriented wrapper around the
% legacy GISMO instrument response functions:
%
%   - response_get_from_db
%   - response_get_from_polezero
%   - response_apply
%   - response_plot
%
% The numerical algorithms remain unchanged for scientific stability.

%% ------------------------------------------------------------------------
% 1. What is a Response Object?
%
% A Response object encapsulates all metadata necessary to describe an
% instrument transfer function:
%
%   - Poles
%   - Zeros
%   - Gain / normalization
%   - Units
%   - Sensor + digitizer metadata
%
% Internally, a Response can be converted to/from the legacy struct format.

disp('Response class cookbook starting...');

%% ------------------------------------------------------------------------
% 2. Load a Response from a Pole-Zero File
%
% This is the safest standalone usage and does NOT require Antelope.

pzfile = which('example.pz');   % replace with your own file if needed

if ~isempty(pzfile)
    R = Response.fromPoleZero(pzfile);

    disp('Loaded Response from pole-zero file:');
    disp(R);

    %% Plot frequency response
    figure;
    R.plot();
    title('Instrument Response from Pole-Zero File');

else
    warning('No example pole-zero file found. Skipping pole-zero demo.');
end

%% ------------------------------------------------------------------------
% 3. Loading a Response from an Antelope Database (Optional)
%
% This section only executes if Antelope is available.

if exist('admin', 'class') && admin.antelope_exists()

    disp('Antelope detected. Demonstrating database response loading.');

    % NOTE: Replace these with your actual database and channel
    dbpath = fullfile(getenv('HOME'), 'databases', 'exampledb');

    try
        ds  = datasource('antelope', dbpath);
        tag = ChannelTag('AV.OKWR..EHZ');
        t0  = datenum(2009,3,20);

        Rdb = Response.fromDatabase(ds, tag, t0);

        disp('Response loaded from Antelope:');
        disp(Rdb);

        figure;
        Rdb.plot();
        title('Instrument Response from Antelope');

    catch ME
        warning('Antelope response retrieval failed: %s', ME.message);
    end

else
    disp('Antelope not available. Skipping database response demo.');
end

%% ------------------------------------------------------------------------
% 4. Applying an Instrument Response (Causal Correction)
%
% We now demonstrate how to remove an instrument response from raw data.
%
% Input:
%   x  = raw counts
%   fs = sampling rate (Hz)

fs = 100;
t  = (0:fs*10-1)'/fs;
x  = sin(2*pi*2*t) + 0.2*randn(size(t));   % synthetic signal

if exist('R', 'var')
    y = R.apply(x, fs);

    figure;
    subplot(2,1,1);
    plot(t, x);
    title('Raw Signal (Counts)');

    subplot(2,1,2);
    plot(t, y);
    title('Corrected Signal (Physical Units)');

else
    warning('No Response object available for apply() demo.');
end

%% ------------------------------------------------------------------------
% 5. Verifying Numerical Stability
%
% The Response.apply method delegates directly to the legacy
% response_apply() function. No numerical changes are introduced.
%
% For regression verification:
%
%   y1 = response_apply(x, fs, R.toStruct())
%   y2 = R.apply(x, fs)
%   max(abs(y1 - y2)) should be < 1e-10

%% ------------------------------------------------------------------------
% 6. Converting Between Struct and Object Representations

if exist('R', 'var')
    S = R.toStruct();
    R2 = Response(S);

    disp('Converted Response to/from struct successfully.');
end

%% ------------------------------------------------------------------------
% 7. Typical Volcano Observatory Workflow Example
%
% 1. Load waveform (counts)
% 2. Retrieve correct response for station + time
% 3. Apply correction
% 4. Use corrected data for RSAM, spectra, energy, etc.

% Pseudocode:
%
%   w  = waveform(...)
%   fs = get(w, 'freq')
%   R  = Response.fromDatabase(ds, tag, get(w,'start'))
%   y  = R.apply(double(w), fs)
%   w_corrected = set(w, 'data', y)

%% ------------------------------------------------------------------------
% 8. Summary
%
% The Response class provides:
%
%   ✓ A clean OOP interface
%   ✓ Full backward compatibility with legacy GISMO code
%   ✓ A future path toward fully embedded numerical kernels
%   ✓ Safe, testable instrument correction workflows
%
% This cookbook intentionally replaces:
%
%   - response_structure.m
%   - response_demo_waveforms.m
%   - response_demo_database.m
%   - response_polezero_demo.m
%   - legacy response cookbooks
%
% without breaking any underlying code.

disp('Response cookbook complete.');