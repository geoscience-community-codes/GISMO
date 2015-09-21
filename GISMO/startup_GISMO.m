function startup_GISMO(gismopath)
% STARTUP_GISMO recursively adds paths for contributed codes that build on
% the GISMO suite. If the Antelope toolbox is already in the Matlab path,
% then the codes with Antelope dependencies are added as well.
%
% To add new paths to the contributed archives please
% read 'contributed_style_guide.txt' in the GISMO directory.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


% CHECK COMPATIBILITY
% Should consider added a compatibility checkign mechanism at some point. 
% Not clear how best to do this. But given that GISMO uses features from
% recent releases and add-on toolboxes, it would be great to give users a
% heads up about such.


% GET PATHS TO DIRECTORIES IN GISMO
if ~exist('gismopath', 'var')
	gismofile = which('GISMO/startup_GISMO');
	gismopath = fileparts(gismofile); % first argout is the path
end

% ADD A PATH TO EACH DIRCTORY IN CONTRIBUTED
addContributed(gismopath,'contributed');

% ADD A PATH TO EACH DIRECTORY IN CONTRIBUTED_ANTELOPE
if exist('dbopen','file') && exist('trload_css','file'); %  test for antelope
  addContributed(gismopath,'contributed_antelope');
end

% ADD A PATH TO EACH DIRCTORY IN CONTRIBUTED_INTERNAL
addContributed(gismopath,'contributed_internal');

% ADD A PATH TO CLASSES (Added by Glenn Thompson)
addpath(fullfile(gismopath,'classes'));
addpath(fullfile(gismopath,'classes','catalog'));
addpath(fullfile(gismopath,'classes','rsam'));
%addpath(fullfile(gismopath,'classes','channeltag'));
%addpath(fullfile(gismopath,'classes','measurementunit'));

% ADD A PATH TO APPLICATIONS e.g. IceWeb
addpath(genpath(fullfile(gismopath,'applications')));

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

