function response_structure_description

%RESPONSE_STRUCTURE_DESCRIPTION Describe response structure fields
%   The fields of a response structure are as follows:
%       scnl: scnlobject associated with the response
%       time: time at which the response is valid
%frequencies: Nx1 vector of frequencies (Hz)
%     values: Nx1 vector of complex responses at each frequency.
%               Values should be normalized such that the maximum amplitude 
%               of the response (max(abs(values))) is near 1.
%      calib: Scaler alibration value used to scale the normalized responses
%               to their real value. NOTE that many waveform objects already
%               have this value applied.
%      units: Character string describing the units
% sampleRate: Sample rate in Hz
%   respFile: Character string of name (and path) of response file.
%     status: Open-ended character string describing any issues with file
%
%  NOTE ABOUT CALIBRATION VALUES AND ANTELOPE DATABASES: In many cases the
%  calib value and units will already have been applied to a waveform if it
%  was loaded with WAVEFORM from an Antelope database. WAVEFORM attempts to
%  read the CALIB from the wfdisc table. DB_GET_RESPONSE retrieves the
%  calib value from the calibration table. Its inclusion here allows the
%  user to verify that the two values are the same. If they are not, it may
%  be necessary to reconcile the two. The units variable (translated from
%  the segtype field) should match as well.

