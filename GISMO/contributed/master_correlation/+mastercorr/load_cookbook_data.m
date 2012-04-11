function W = load_cookbook_data

%LOAD_COOKBOOK_DATA Load sample data used in MASTERCORR.COOKBOOK 
% W = LOAD_COOKBOOK_DATA loads a sample dataset for use with the
% MASTERCOR.COOKBOOK function. The output W is a waveform object.
%
% See also mastercorr.cookbook

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$




pathName = which('mastercorr.cookbook');
[pathStr,~,~] = fileparts(pathName);
load(fullfile(pathStr,'cookbook_data.mat'));



