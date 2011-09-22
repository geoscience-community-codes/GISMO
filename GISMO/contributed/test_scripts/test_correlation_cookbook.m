function test_correlation_cookbook
%% try the correlation cookbook
% assumes we are in GISMO/contributed/test_scripts/waveform and that
% correlation_cookbook is in GISMO/contributed/correlation_cookbook/
ppp = pwd;
cd ..
cd ..
cd correlation_cookbook
pathname = '';
pathname = '../../correlation_cookbook/';
 fileName = 'correlation_cookbook.m';
% [fileName, pathName] = uigetfile('*.m',...
%     'locate the correlation_cookbook',...
%     '../../correlation_cookbook/correlation_cookbook.m');
if strcmpi(fileName,'correlation_cookbook.m')
    results.correlation_cookbook = true;
    oldchildren = get(0,'children');
    try
        correlation_cookbook;
    catch
        results.correlation_cookbook = false;
    end
    newchildren = get(0,'children');
    todelete = newchildren(~ismember(newchildren,oldchildren));
    delete(todelete); %clean up after it.
end
cd(ppp);