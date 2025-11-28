function w = stream2waveform(pythonExe, pyScript, dataSource)
%STREAM2WAVEFORM Bridge ObsPy → GISMO via MAT files
%
%   w = stream2waveform(PYTHON, SCRIPT, DATASOURCE)
%
%   This function:
%     1. Calls ObsPy externally to convert data → MAT files
%     2. Loads the MAT files using GISMO's OBSPY datasource
%
%   Requires:
%       core/@waveform/private/load_obspy.m

    if ~exist(pythonExe,'file')
        error('Python executable not found.')
    end

    if ~exist(pyScript,'file')
        error('ObsPy conversion script not found.')
    end

    tmpdir = tempname;
    mkdir(tmpdir);

    cmd = sprintf('"%s" "%s" "%s" "%s"', ...
        pythonExe, pyScript, dataSource, tmpdir);

    [status,msg] = system(cmd);

    if status ~= 0
        rmdir(tmpdir,'s');
        error('ObsPy conversion failed:\n%s',msg);
    end

    % Now load using the standard GISMO datasource framework
    ds = datasource('obspy', tmpdir);

    w = waveform(ds, '*', now-1, now+1); % time window ignored by loader

    if isempty(w)
        warning('No waveforms returned from ObsPy conversion.')
    end
end
