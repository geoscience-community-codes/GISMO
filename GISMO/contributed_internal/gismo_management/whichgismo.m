function whichgismo(sourceLocation)

%WHICHGISMO   Select from multiple GISMO archives.
% 
% WHICHGISMO displays the path to the current GISMO archive and lists all
% the other optional paths that currently defined paths.
% 
% WHICHGISMO(NAME) removes all existing paths containing the phrase
% 'GISMO'. New GISMO paths are then added based on predefined locations specified by NAME.
% Example names and paths are listed below. 
%
%    name          path
%   LinuxNet     /home/admin/share/matlab/PACKAGES/GISMO_OP/GISMO
%   LinuxNetWest /home/west/mlcode/GISMO
%   WestPC       C:\Users\Michael West\Documents\mlcode\GISMO_OP\GISMO
%
% A suitable WHICHGISMO_PATH script should look like this: 
%
% paths = {
%     'LinuxNet'       '/home/admin/share/matlab/PACKAGES/GISMO_OP/GISMO'
%     'LinuxNetWest'    '/home/west/mlcode/GISMO'
%     'WestPC'         'C:\Users\Michael West\Documents\mlcode\GISMO_OP\GISMO'
% };
%
% See also WHICHGISMO_PATHS, RMGISMO

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


% LOAD PATH LIST
whichgismo_paths;


% LIST OPTIONS, IF NONE USED
if ~exist('sourceLocation')
    displaypaths(paths);
    return;
end


% FIND DESIRED GISMO PATH
f = find(strcmpi(sourceLocation,paths(:,1)));
if numel(f)>1
    warning('Argument matches more than one path.');
    displaypaths(paths);
    return;
end

if numel(f)==0
    warning('GISMO Source not recognized');
    displaypaths(paths);
    return;
end

NewSource = paths{f,2};
disp(['Adding GISMO components from ' NewSource ' ...']);
if exist('rmgismo')==2
   rmgismo;
else
    error('Program not found: RMGISMO. Path not changed.');
end
addpath(NewSource);
startup_GISMO;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PRINT PATH OPTIONS TO SCREEN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function displaypaths(paths)

% DISPLAY CURRENT GISMO
gismoPath = which('startup_GISMO');
disp(' ');
disp('CURRENT GISMO PATH: ');
disp(gismoPath(1:end-16));
disp(' ');
disp('OTHER GISMO PATHS: ');

% SHOW PATH OPTIONS
disp(' name          path');
for n = 1:size(paths,1)
    txt = sprintf('%-12s %s', paths{n,1} , paths{n,2} );
    disp(txt);
end


