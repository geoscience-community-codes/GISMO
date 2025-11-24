function irisfetch_test()
% IRISFETCH_TEST
% Tests whether GISMO's waveform() and irisFetch.Traces() can
% retrieve data from IRIS DMC webservices.
%
% This version:
%   • avoids stray continuation markers
#   • handles network failures cleanly
%   • provides structured test results
%   • plots only when successful
%
% Glenn Thompson + ChatGPT, 2025

clc; close all;

%% -----------------------------
%  1. Test parameters
% ------------------------------
params.net  = 'AV';
params.sta  = 'REF';
params.loc  = '*';
params.chan = 'EHZ';
params.t1   = '2009-03-22 06:30:00';
params.t2   = '2009-03-22 10:30:00';

fprintf('\nRunning irisfetch_test.m …\n');

results = struct();
results.gismo_success = false;
results.iris_success  = false;
results.error_gismo   = '';
results.error_iris    = '';

%% -----------------------------
%  2. Test GISMO waveform()
% ------------------------------
try
    ds = datasource('irisdmcws');
    CT = ChannelTag(params.net, params.sta, params.loc, params.chan);
    w  = waveform(ds, CT, params.t1, params.t2);

    % Optionally apply calibration
    if hasfield(get(w,'calib')), w = w * get(w,'calib'); end

    figure; plot(w); title('GISMO waveform()');

    fprintf('✔ GISMO waveform() succeeded.\n');
    results.gismo_success = true;

catch ME
    fprintf('✖ GISMO waveform() failed.\n    %s\n', ME.message);
    results.error_gismo = ME.message;
end

%% -----------------------------
%  3. Test irisFetch.Traces()
% ------------------------------
try
    traces = irisFetch.Traces(params.net, params.sta, params.loc, ...
                              params.chan, params.t1, params.t2);

    if ~isempty(traces) && isfield(traces, 'data')
        figure; plot(traces.data); title('irisFetch.Traces');
        fprintf('✔ irisFetch.Traces() succeeded.\n');
        results.iris_success = true;
    else
        error('irisFetch returned empty data');
    end

catch ME
    fprintf('✖ irisFetch.Traces() failed.\n    %s\n', ME.message);
    results.error_iris = ME.message;
end

%% -----------------------------
%  4. Summary
% ------------------------------
disp('--------------------------------------');
disp('IRISFETCH_TEST RESULTS:');
disp(results);
disp('--------------------------------------');

end

