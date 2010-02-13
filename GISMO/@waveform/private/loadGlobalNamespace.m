function isloaded = loadGlobalNamespace()
% loadGlobalNamespace handles the global variables and routines used within
% wavefrom.
%

%global mep2dep dep2mep

global WAVEFORM_HISTORY
WAVEFORM_HISTORY = true; %keep track of waveform modifications

%time converter functions
% matlab date (# days since 0 JAN 0000)
%mep2dep = inline ('(matepoch - 719529) * 24 * 3600','matepoch');
% antelope epoch( # secs since 1 JAN 1970 )
%dep2mep = inline ('(dep / 86400 + 719529)', 'dep');

%default period for envelopes
global DEFAULT_PERIOD
DEFAULT_PERIOD = 10; %seconds

global SECONDS_IN_DAY
SECONDS_IN_DAY = 24 * 60 * 60;


isloaded = true;