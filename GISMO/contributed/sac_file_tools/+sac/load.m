function w = load(fileList)

%LOAD Load SAC files into MATLAB as waveform objects
% W = LOAD(FILELIST) Read the contents of one or more SAC files into
% a waveform matrix W. FILELIST is a cell containing the complete path and
% file names of individual SAC files. Wildcards are not recognized. W is a
% waveform object of the same size as FILELIST. If a particular file is not 
% found, the corresponding output element is an empty waveform.
%
% Example:
% >> fileList = {'file1.sac' 'file2.sac' 'file3.sac'};
% >> w=loadsac2(fileList)
% w =
% [1x3] waveform object with fields:
%     station
%     channel
%     ...
%
% NOTE: more sophisticated reads from sac files are possible using the
% datasource and waveform routines. Users are advised to consider accessing
% data through this approach, in lieu of LOADSACFILE, as it may offer
% greater functionality.
%
% see also waveform datasource datasource/setfile

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date: 2010-02-04 11:51:43 -0900 (Thu, 04 Feb 2010) $
% $Revision: 178 $


if ~isa(fileList,'cell')
    error('File names must be cells');
end


w = waveform;
scnl = scnlobject('*','*','*','*');
    
[N,M] = size(fileList);
for n = 1:N
    for m = 1:M
        ds = datasource('sac',fileList{n,m});
        wTmp = waveform(ds,scnl,'1/1/1000','1/1/3000');
        if numel(wTmp)==0
            w(n,m) = waveform;
        elseif numel(wTmp)==1
            w(n,m) = wTmp;
        else
            error('What the f#%@?!  This should not happen.');
        end
    end
end



