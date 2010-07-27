function w = response_demo_waveforms

%RESPONSE_DEMO_WAVEFORMS returns the absolute path to the demo database
%  W = RESPONSE_DEMO_WAVEFORMS



file = which('response_cookbook');
path = fileparts(file);

if ~exist([path '/demo'])
	error('response_demo_waveforms: demo waveforms not found');
else
	load([path '/demo/plutons_waveforms.mat']);
end
