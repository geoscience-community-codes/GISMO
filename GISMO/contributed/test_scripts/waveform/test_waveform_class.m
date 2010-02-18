% function results = test_waveform_class
% $Date$
% $Revision$
%script that will test the waveform class FOR 1-D CASES!!!!
lasterror('reset')
totest = {... constructor methods
    'constructor_default','constructor_manual','constructor_copy'...
    'read_antelope','read_antelope_altDB',...
    'read_winston_avopub','read_winston_avofbx',...
    ... get functions
    'get', 'getm',...
    ... set functions
    'set',...
    ... alternate load methods
    'load_sac', 'loadobj','load_file', ...
    ... alternate save methods
    'save_sac',...
    ... basic math functions
    'uminus','plus','minus',...
    'times','mtimes','rdivide','mrdivide','power',...
    ... derrived math functions
    'abs','diff','integrate', 'rms',...
    ... statistical functions
    'min','max','mean', 'median','std','var',...
    ... transform functions
    'hilbert','detrend','demean','taper','stack','fix_data_length',...
    ... conversion functions
    'double',...
    ... complicated functions
    'clip','getpeaks','stack','extract','align','resample',...
    'subtime','waveform2sound',...
    ... History functions
    'addhistory','clearhistory','history',...
    ... User Field related functions
    'addfield','delfield',...
    ... state functions
    'isempty',...
    ... display functions
    'disp','display', 'plot',...
    ... loadobj function
    'loadobj_v0', 'loadobj_v1_0', 'loadobj_v1_1', 'loadobj_current' ...
    ... test w/ correlation
    'correlation_cookbook'
    };
clear results
for n=1:numel(totest)
    results.(totest{n}) = 'unchecked';
end

% Set up sample data
rand5000 = inline('rand(1,5000) .* A','A'); %length 5000, amplitude A
sindata = sin((1:5000) / (2*pi *10));


%% first, try the different methods of loading up waveforms
%default constructor
w = waveform; %create an empty waveform
results.constructor_default =  strcmp(class(w),'waveform');

rfreq = rand(1) * 200;
Ad = rand5000(1000);
stt = now - rand(1) * 1500;
clear w
STATIONVALUE = 'STAtION';
CHANNELVALUE = 'CHAnNEL';

%manual constructor
w = waveform(STATIONVALUE,CHANNELVALUE,rfreq, stt,Ad);
test.manconstruct.bStamatch = strcmp(get(w,'station'), STATIONVALUE);
test.manconstruct.bChanmatch = strcmp(get(w,'channel'), CHANNELVALUE) ;
test.manconstruct.bFreqmatch = all(get(w,'freq') == rfreq);
test.manconstruct.bTimematch = all(get(w,'start') == stt);
test.manconstruct.bDatamatch = all(get(w,'data') == Ad(:));

results.constructor_manual =  ...
    test.manconstruct.bStamatch && test.manconstruct.bChanmatch && ...
    test.manconstruct.bTimematch && test.manconstruct.bDatamatch;

% copy constructor
w2 = w;
s1 = struct(w); s2 = struct(w2);
fn = fieldnames(s1);
valid = true;
for n=1:numel(fn)
    switch (class(s1.(fn{n})))
        case 'char'
            valid = valid && strcmp(s1.(fn{n}), s2.(fn{n}));
        case {'double', 'logical'}
            valid = valid && all(s1.(fn{n}) == s2.(fn{n}));
        otherwise
            fprintf('field <%s> of type <%s> uncompared\n',fn{n},class(s1.(fn{n})));
    end
end
results.constructor_copy = valid;


%% test SET routines
mep2dep = inline('(n - 719529) * 86400','n');
set_test = {'station','freq','channel','data','units',...
    'start','start_epoch','data_length'};

set_VALID_vals = {'Bob',293,'JIM',[1:10000]','MyUNIT',now,mep2dep(now),3};

set_INVALID_vals = {5,'a',5,ones(5,5),3,'a','a',-1};

w =  waveform;
results.set = true;
for N=1:numel(set_test)
    %Make sure that INVALID cases don't slip thorugh
    try
        set (w,set_test{N},set_INVALID_vals);
        setresult.(set_test{N}) = false;
    catch
        setresult.(set_test{N}) = true;
    end
    
    %Make sure that corresponding VALID cases work
    setresult.(set_test{N}) = setresult.(set_test{N}) && ...
        all(get(set(w,set_test{N},set_VALID_vals{N}),set_test{N})...
        == set_VALID_vals{N});
    
    results.set = results.set && setresult.(set_test{N});
end

%% test math methods
Ad = rand5000(1000); Bd = sindata;
Ad = Ad(:); Bd = Bd(:);
A = set(waveform,'data',Ad,'freq',100); B = set(waveform,'data',Bd,'freq',100);

results.uminus = all(-Ad == double(-Ad));

results.plus = ...
    all(double(A + B) == (Ad + Bd)) && ... test vector addition
    all(double(A + 1) == (Ad + 1)) && ...  test scalar addition
    all(all(double([A, B]) + 1 == [Ad + 1, Bd + 1]));  %test 2x1 addition

results.minus = all(double(A - B) == (Ad - Bd));
results.mtimes = ...
    all(double(A .* B) == (Ad .* Bd)) && ...
    all(double(A .* 2) == (Ad .* 2)) && ...
    all(double(A .* Bd) == (Ad .* Bd)) ;

results.times = ...   all(double(Ad' * B) == (Ad' * Bd));
    all(double(A * 2) == (Ad * 2));

results.mrdivide = ...
    all(double(A ./ B) == (Ad ./ Bd)) && ...    all(double(A ./ 2) == (Ad ./ 2)) && ...
    all(double(A ./ Bd) == (Ad ./ Bd)) ;

results.rdivide = ...
    all(double(A / 2) == (Ad / 2));

results.power = ...
    all(double(A .^ B) == (Ad .^ Bd)) && ...
    all(double(A .^ 2) == (Ad .^ 2)) && ...
    all(double(A .^ Bd) == (Ad .^ Bd)) ;

%% Test derrived math functions

%'abs','diff','integrate', 'rms',...

results.abs = ...
    all(double(abs(B)) == abs(Bd));

results.diff = ...
    all(diff(Ad).* get(A,'freq') == double(diff(A))) &&...
    strcmp(get(diff(A),'units'), 'Counts / sec');

results.integrate = ...
    all(cumsum(Bd) ./ get(B,'freq') == double(integrate(B))) &&...
    strcmp(get(integrate(B),'units'), 'Counts * sec');
results.integrate = results.integrate &&...
    all(cumtrapz(Bd) ./ get(B,'freq') == double(integrate(B,'trapz')));

results.rms = ...
    all(rms(A)  == sqrt((sum(Ad .^2) / (numel(Ad)-1))));


%% Test STATISTICAL functions

results.min = min(A) == min(double(A));
results.max = max(A) == max(double(A));
results.mean  = mean(A) == mean(double(A));
results.median = median(A) == median(double(A));
results.std = std(A) == std(Ad);
results.var = var(A) == var(Ad);

%% Test TRANSFORM functions

%    'hilbert','detrend','demean','taper','stack','fix_data_length'

results.detrend=  all(double(detrend(A)) == detrend(Ad));
results.demean = all(double(demean(A)) == (Ad - mean(Ad)));
results.hilbert = all(double(hilbert(A)) == abs(hilbert(Ad)));

%% Test Functions: ensure they don't error & output size is correct
results.taper = all(double(taper(A)) == double(taper(A,.2))) &&...
    all(double(taper(A,.2)) == double(taper(A,.2,'cosinE')));
results.taper = results.taper && any(double(taper(A)) ~= double(taper(A,.5)));

clippedAd = Ad; clippedAd(Ad>.3) = .3; clippedAD(Ad<-.2) = .2;
results.clip = all(double(clip(A,[-.2,.3])) == clippedAd);

results.stack = all(double(stack([A, A, A, A])) == Ad .* 4);
%% Test HISTORY functions
%   'addHistory','clearHistory','history'

% test ADDHISTORY
w = waveform;
w = addhistory(w,'StringTest');
w = addhistory(w,'[%s]<%02d>','ABCDEFG',3);
w = addhistory(w,{3});
fullhist = get(w,'history');

results.addhistory = ...
    numel(fullhist(:,1)) == 4 && numel(fullhist(1,:)) == 2 && ...
    strcmp(fullhist{1,1}, 'CREATED') && ...
    strcmp(fullhist{2,1},'StringTest') && ...
    strcmp(fullhist{3,1}, '[ABCDEFG]<03>') && ...
    (fullhist{4,1}{1} == 3);

[histStr dates] = history(w);

%test HISTORY
results.history = all(datenum(datestr([fullhist{:,2}])) == datenum(dates));

%test CLEARHISTORY
Z = get(clearhistory(w),'History');
n = now;
onesecond = datenum(0,0,0,0,0,1);
results.clearhistory = ...
    (abs(Z{2} - n) < onesecond)  &&... % last event less than a second ago?
    all(size(Z) == [1 2]) &&...
    isa(Z{1},'char') && isa(Z{2},'double') &&...
    strcmp(Z{1},'Cleared History');


%% User Defined Fields
try
    w = waveform;
    w = addfield(w,'ABCD','hello');
    test1 = strcmp(get(w,'abCD'),'hello');
    w = set(w,'ABcD',5);
    test2 = get(w,'AbCD') == 5;
    results.addfield = test1 && test2;
catch
    error('error in user defined fields');
end
lastwarn('') ;
w = delfield(w,'abcd');
get(w,'ABCD'); %should fail because it was deleted.
if ~isempty(lastwarn)
    results.delfield = true;
else
    results.delfield = false;
end

%% try display functions
disp('testing display functions ---------------------------------------');
try
    disp(A); disp([A A]); disp([A A; A A; A A]);
    results.disp = true;
catch exception
    results.disp = false;
    disp(exception);
end
try
    display(A); display([A A]); display([A A; A A; A A]);
    results.display = true;
catch exception
    results.display = false;
    disp(exception)
end
disp('end testing display functions -----------------------------------');

%% try plot functions
try
    f = figure;
    plot(A); plot([A B]); plot([A B]','g.');
    plot([A B B.*2 B.*7 set(B,'start',get(B,'start')+datenum(0,0,0,0,0,1))],'xunit','date','markersize',3);
    results.plot = true;
    title('test plot...');
catch exception
    results.plot = false;
    rethrow(exception);
end
delete(f)

%% isEMPTY, double
results.isempty = isempty(waveform) && ~isempty(set(waveform,'data',1));

results.double = all(double(A) == Ad) && ...
    all(all(double([A A]) == [Ad Ad])); %ADDITIONAL CHECKS REQUIRED


%% try load functions
results.loadobj_v0 = true;
try
    dummy = load('v0_example_waveforms.mat');
catch exception
    disp(exception)
    results.loadobj_v0 = false;
end
results.loadobj_v1_0 = true;
try
    dummy = load('v1.0_example_waveforms.mat');
catch exception
    disp(exception)
    results.loadobj_v1_0 = false;
end
results.loadobj_v1_1 = true;
try
    dummy = load('v1.1_example_waveforms.mat');
catch exception
    disp(exception)
    results.loadobj_v1_1 = false;
end

%% try saving and loading current version
tmp_name = [tempname , '.mat'];

wtesttemp = waveform;
save(tmp_name,'wtesttemp')

clear wtesttemp
try
    dummy = load(tmp_name);
    results.loadobj_current = true;
catch exception
    disp(exception);
    results.loadobj_current = false;
end
delete(tmp_name); %clean up
clear dummy

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

%% DISPLAY RESULTS
%clear A Ad B Bd w w2
disp('');
disp(' * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *');
disp('');
for n=1:numel(totest)
    switch (results.(totest{n}))
        case true
            results.(totest{n}) = 'OK';
        case false
            results.(totest{n}) = '--error--';
        otherwise
            %do nothing
    end
end
disp('RESULTS for 1D waveform tests:');
disp(results);
