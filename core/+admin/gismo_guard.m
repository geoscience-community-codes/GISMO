function G = gismo_guard()
%GISMO_GUARD  Detect optional dependencies and environment status

G = struct();

%% ------------------------------------------------------------------------
% MATLAB version
% ------------------------------------------------------------------------
v = ver('MATLAB');
G.MATLAB.Release = v.Release;
G.MATLAB.Year = str2double(regexp(v.Release,'\d{4}','match','once'));

%% ------------------------------------------------------------------------
% Toolboxes
% ------------------------------------------------------------------------
G.Toolboxes.SignalProcessing = license('test','Signal_Toolbox');
G.Toolboxes.Statistics       = license('test','Statistics_Toolbox');
G.Toolboxes.Mapping          = license('test','Map_Toolbox');

%% ------------------------------------------------------------------------
% Antelope (MATLAB toolbox)
% ------------------------------------------------------------------------
G.Antelope.exists = admin.antelope_exists();

%% ------------------------------------------------------------------------
% IRIS / irisFetch
% ------------------------------------------------------------------------
G.IRIS.irisFetchAvailable = (exist('irisFetch','file') == 2);
G.IRIS.javaAvailable = ...
    exist('edu.iris.dmc.extensions.fetch.TraceData','class') == 8;

G.IRIS.usable = G.IRIS.irisFetchAvailable && G.IRIS.javaAvailable;

%% ------------------------------------------------------------------------
% Internet (lightweight check)
% ------------------------------------------------------------------------
try
    webread('https://service.iris.edu');
    G.Internet.available = true;
catch
    G.Internet.available = false;
end

%% ------------------------------------------------------------------------
% TESTDATA (authoritative test data)
% ------------------------------------------------------------------------
G.TESTDATA.configured = admin.is_testdata_setup(false);

%% ------------------------------------------------------------------------
% Human-readable summary
% ------------------------------------------------------------------------
G.summary = sprintf([ ...
    'MATLAB Release: %s\n' ...
    'Signal Processing Toolbox: %s\n' ...
    'Statistics Toolbox: %s\n' ...
    'Mapping Toolbox: %s\n' ...
    'Antelope Toolbox: %s\n' ...
    'irisFetch usable: %s\n' ...
    'TESTDATA installed: %s\n'], ...
    G.MATLAB.Release, ...
    yesno(G.Toolboxes.SignalProcessing), ...
    yesno(G.Toolboxes.Statistics), ...
    yesno(G.Toolboxes.Mapping), ...
    yesno(G.Antelope.exists), ...
    yesno(G.IRIS.usable), ...
    yesno(G.TESTDATA.configured) ...
    );
end
%% ========================================================================
function s = yesno(tf)
if tf
    s = 'yes';
else
    s = 'no';
end
end
