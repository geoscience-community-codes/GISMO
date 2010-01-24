function startup_GISMO
% STARTUP_GISMO recursively adds paths for contributed codes that build on
% the GISMO suite. If the Antelope toolbox is already in the Matlab path,
% then the codes with Antelope dependencies are added as well.
%
% To add new paths to the contributed archives please
% read 'contributed_style_guide.txt' in the GISMO directory.

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks


% GET PATHS TO DIRECTORIES IN GISMO
gismofile = which('GISMO/startup_GISMO');
gismopath = fileparts(gismofile); % first argout is the path

% ADD A PATH TO EACH DIRCTORY IN CONTRIBUTED
addContributed(gismopath,'contributed');

% ADD A PATH TO EACH DIRECTORY IN CONTRIBUTED_ANTELOPE
if exist('dbopen','file') && exist('trload_css','file'); %  test for antelope
  addContributed(gismopath,'contributed_antelope');
end

% ADD A PATH TO EACH DIRCTORY IN CONTRIBUTED_INTERNAL
addContributed(gismopath,'contributed_internal');


%%
function addContributed(gismopath, contribDir)
% add each subdirectory within gismopath/contribDir/ to the matlab path
dirlist = dir(fullfile(gismopath,contribDir,''));
dirlist = removeHiddenFiles(dirlist);

for n = 1:numel(dirlist)
  newpath = fullfile(gismopath,contribDir, dirlist(n).name,'');
  if ~isdir(newpath), continue, end  %don't add loose files to the path
  addpath(newpath);
  %disp(['Adding path:  ' newpath]);
end


function directoryList = removeHiddenFiles(directoryList)
%removes files that start with '.', which also includes '.', and '..'
startsWithPeriod = strncmp('.',{directoryList.name},1);
directoryList = directoryList(~startsWithPeriod);

