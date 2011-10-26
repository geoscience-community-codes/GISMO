function which(sourceLocation)

%WHICH manage and switch between multiple GISMO archives
% WHICH displays the path to the current GISMO archive and lists all
% the other optional paths that currently defined paths.
% 
% WHICH(NAME) removes all existing paths containing the phrase
% 'GISMO'. New GISMO paths are then added based on predefined locations 
% specified by NAME.
% Example names and paths are listed below. 
%
%    name          path
%    r306          /home/admin/share/matlab/PACKAGES/GISMO_r306/GISMO
%    MyLaptop      ~/Repositories/GISMOTOOLS/GISMO
%    Work          ~/src/gismotools/GISMO
%
% A suitable WHICHGISMO_PATH script should look like this: 
%
% paths = {
%    'r306'          '/home/admin/share/matlab/PACKAGES/GISMO_r306/GISMO'
%    'MyLaptop'      '~/Repositories/GISMOTOOLS/GISMO'
%    'Work'          '~/src/gismotools/GISMO'
% };
%
% See also admin.remove admin.getpath admin.refresh

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date: 2010-02-04 11:51:43 -0900 (Thu, 04 Feb 2010) $
% $Revision: 178 $



% LOAD PREDEFIEND PATHS
whichgismo_paths;


% LIST OPTIONS, IF NONE USED
if ~exist('sourceLocation')
    displaypaths(paths);
    return;
end


% CHECK IF SOURCELOCATION IS A VALID GISMO PATH
fullStartUp = fullfile(sourceLocation,'startup_GISMO.m');
if exist(sourceLocation,'dir') &&  exist(fullStartUp,'file')
    newSource = sourceLocation;
else
    
    % CHECK IF SOURCELOCATION IS PREDIFINED
    f = find(strcmpi(sourceLocation,paths(:,1)));
    if numel(f)>1
        displaypaths(paths);
        error('Argument matches more than one path.');
    end
    
    if numel(f)==0
        displaypaths(paths);
        error('GISMO Source not recognized');
    end
    
end




% ADD NEW GISMO PATH
disp(['Removing all references to GISMO ...']);
disp(['Adding GISMO components from ' newSource ' ...']);
try
    import admin.remove
catch
   error('Could not find program admin.remove'); 
end
addpath(newSource);
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


