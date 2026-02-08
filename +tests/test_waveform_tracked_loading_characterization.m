function tests = test_waveform_tracked_loading_characterization()
% Characterisation test for "tracked waveform loading" behaviour.
% This test does NOT enforce N-in/N-out. It simply documents current
% behaviour and checks basic invariants.
tests = functiontests(localfunctions);
end

function testWaveformRequestCardinality_Characterize(testCase)

    % --- Choose a datasource that may or may not be available ---
    % We use IRIS here because it’s widely available, but this is an
    % integration test. If IRIS is unreachable, we skip.
    try
        ds = datasource('irisdmcws');
    catch ME
        testCase.assumeFail(['Skipping: could not create irisdmcws datasource: ' ME.message]);
        return
    end

    % --- Request 2 channels, one valid and one intentionally invalid ---
    % Keep the time window small.
    t1 = '2010-02-27 06:30:00';
    t2 = '2010-02-27 06:35:00';

    % Known-good channel (commonly available)
    good = ChannelTag('IU.ANMO.00.BHZ');

    % Intentionally bad channel (should not exist)
    bad  = ChannelTag('IU.ANMO.00.NOPE');

    req = ChannelTag.array([string(good), string(bad)]);

    % --- Attempt load ---
    try
        w = waveform(ds, req, t1, t2);
    catch ME
        testCase.assumeFail(['Skipping: waveform load failed (network/service?): ' ME.message]);
        return
    end

    % --- Characterise result ---
    nRequested = numel(req);
    nReturned  = numel(w);

    fprintf('\nTracked-loading characterisation:\n');
    fprintf('  Requested: %d\n', nRequested);
    fprintf('  Returned : %d\n', nReturned);

    % If GISMO returns fewer than requested, this is the “issue”.
    % If it returns exactly requested, then maybe it was fixed years ago.
    %
    % Either way, enforce invariants that should always hold.

    % Returned set should not exceed requested
    testCase.verifyLessThanOrEqual(nReturned, nRequested);

    % Returned channels should be unique
    if nReturned > 0
        retTags = get(w,'ChannelTag');   % returns ChannelTag array for waveform
        testCase.verifyEqual(numel(unique(string(retTags))), numel(retTags), ...
            'Returned waveforms contain duplicate ChannelTags (unexpected).');

        % Returned channels should be a subset of requested channels
        reqStr = string(req);
        retStr = string(retTags);
        isMember = ismember(retStr, reqStr);
        testCase.verifyTrue(all(isMember), ...
            'Returned waveforms include ChannelTags not present in the request.');
    end

end