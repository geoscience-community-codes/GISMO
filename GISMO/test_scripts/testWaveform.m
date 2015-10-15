classdef testWaveform < matlab.unittest.TestCase
   % TESTWAVEFORM validates the funcionality of Waveform
   %
   % requires xUnit
   % see also xUnit, channeltag
   
   properties
      Dt% = rand(1,1001) .* 1000 - 500;
      chanTag% = channeltag('IU.ANMO.00.BHZ');
      dataPath = fileparts(which('test_waveform_class'))
      wf% = waveform(testWaveform.chanTag, 20, fix(now), D, 'm / sec');
   end
   
   methods(TestMethodSetup)
      function SetUp(testCase)
         % not sure this is working in any way.
         testCase.Dt = rand(1,1001) .* 1000 - 500;
         testCase.chanTag = channeltag('IU.ANMO.00.BHZ');
         testCase.wf = waveform(testCase.chanTag, 20, fix(now), testCase.Dt, 'm / sec');
      end
   end
   
   methods(Test)      
      
      function testConstructors(testCase)
         %% first, try the different methods of loading up waveforms
         %default constructor
         w = waveform; %create an empty waveform
         assert(isa(w,'waveform'));
         
         rfreq = rand(1) * 200;
         Ad = testCase.Dt;
         stt = now - rand(1) * 1500;
         clear w
         STATIONVALUE = 'STAtION';
         CHANNELVALUE = 'CHAnNEL';
         
         %manual constructor now gives error
         verifyWarning(testCase, @() waveform(STATIONVALUE,CHANNELVALUE,rfreq, stt,Ad),...
            'Waveform:waveform:oldUsage');
         w = waveform(testCase.chanTag, rfreq, stt, testCase.Dt);
         
         % copy constructor
         w2 = w;
         s1 = struct(w); s2 = struct(w2);
         fn = fieldnames(s1);
         for n=1:numel(fn)
            switch (class(s1.(fn{n})))
               case {'char', 'double', 'logical'}
                  testCase.verifyEqual(s1.(fn{n}), s2.(fn{n}));
               otherwise
                  % fprintf('field <%s> of type <%s> uncompared\n',fn{n},class(s1.(fn{n})));
            end
         end
      end
      
      function testWinstonCall(testCase)
         ds = datasource('winston','pubavo1.wr.usgs.gov',16022);
         chanInfo = channeltag.array('AV.ACH.--.EHE');
         w = waveform(ds,chanInfo,now-1,now-0.995);
         testCase.verifyNumElements(w,1);
         testCase.verifyInstanceOf(w,'waveform');
      end
      
      function testWaveformCalls(testCase)
         data = 1:(10*60*60*2.5);
         st_mat = now-1;
         st_txt = '5/5/2014';
         et_mat = now-0.98;
         et_txt = '5/5/2004 01:00:00';
         sta = 'XXXX';
         net = 'NW';
         cha = 'BHZ';
         loc = '00';
         nslctxt = [net, '.', sta, '.', loc, '.', cha];
         hz = 20;
         unit = 'CNT';
         scnl = scnlobject(sta,cha,net,loc);
         tag = channeltag(net,sta,loc,cha);
         ds = datasource;
         disp('CREATE: default')
         w = waveform()
         disp('CREATE: copy')
         w2 = w
         disp('CREATE: sta cha hz st data')
         w = waveform(sta,       cha,  hz,      st_mat,  data);
         disp('CREATE: scnl hz st data unit')
         w(2) = waveform(scnl,      hz,   st_mat,  data,    unit);
         disp('CREATE: nscltxt hz st data unit')
         w(3) = waveform(nslctxt,   hz,   st_mat,  data,    unit);
         disp('CREATE: tag hz st data unit')
         w(4) = waveform(tag,       hz,   st_mat,  data,    unit);
         disp('CREATE: scnl hz st data')
         w(5) = waveform(scnl,      hz,   st_mat,  data);
         disp('CREATE: nscltxt hz st data')
         w(6) = waveform(nslctxt,   hz,   st_mat,  data);
         disp('CREATE: tag hz st data')
         w(7) = waveform(tag,       hz,   st_mat,  data);
         disp('CREATE: tag hz st data unit nocombine')
         w = waveform(tag,       hz,   st_mat,  data,    unit, 'nocombine');
      end
      function testSetGets(testCase)
         %% test SET routines
         %TODO: Update to use TestCase syntax
         mep2dep = inline('(n - 719529) * 86400','n');
         set_test = {'station','freq','channel','data','units',...
            'start','start_epoch','data_length'};
         
         set_VALID_vals = {'Bob',293,'JIM',(1:10000)','MyUNIT',now,mep2dep(now),3};
         
         set_INVALID_vals = {5,'a',5,ones(5,5),3,'a','a',-1};
         
         w =  testCase.wf;
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
            testCase.verifyTrue(setresult.(set_test{N}), set_test{N})
         end
      end
      
      function testBasicMath(testCase)
         % basic math functions
         %   'uminus','plus','minus'
         %   'times','mtimes','rdivide','mrdivide','power'
         w = testCase.wf;
         D = testCase.Dt(:);
         % identities
         testCase.verifyEqual(w + 0, w);
         testCase.verifyEqual(w ./ 1, w);
         testCase.verifyEqual(w - 0, w);
         testCase.verifyEqual(w * 1, w);
         testCase.verifyEqual(w .* 1, w);
         testCase.verifyEqual(w .^ 1, w);
         
         % comparing operations
         testCase.verifyEqual(w + w, w * 2);    % plus, times, vector addition
         testCase.verifyEqual(w - w, w .* 0);    % minus, mtimes, vector subtraction
         testCase.verifyEqual(w ./ 2, w .* 0.5); % rdivide, times
         testCase.verifyEqual(w .^ 2, w .* w);  % power, vector multiplication
         testCase.verifyEqual(D .* D, double(w .* D));
         testCase.verifyEqual(w .* 5, w * 5);   % mtimes, times
         testCase.verifyEqual(w + -w, w .* 0);  % uminus
         
         % communicative
         testCase.verifyEqual(w + 100, 100 + w);
         testCase.verifyEqual(w .* 5, 5 .* w);
         
         testCase.verifyEqual(double(w + 5 .* w), D + 5 .* D);
         testCase.verifyEqual(double((7 .* w) + (w ./ 5) - w.^3), (D .* 7)+(D ./ 5) - D.^3);
         
         testCase.verifyEqual(double(w / 2), (D / 2));
      end
      
      function testAdvancedMath(testCase)
         % sign, abs, diff, integrate
         D = testCase.Dt(:);
         w = testCase.wf;
         
         testCase.verifyEqual(double(sign(w)),  sign(D));
         testCase.verifyEqual(abs(w),           sign(w) .* w);
         testCase.verifyEqual(double(abs(w)),   abs(D));
      end
      
      function testDiff(testCase)
         dW = diff(testCase.wf);
         dd = diff(testCase.Dt(:)) * get(testCase.wf,'freq'); %scaled!
         testCase.verifyEqual(double(dW), dd,  'differentiation values');
         
         expectedUnits = [get(testCase.wf,'units'), ' / sec'];
         testCase.verifyEqual(get(dW,'units'), expectedUnits, 'unit check');
      end
      
      function testIntegrate(testCase)
         d = sin(1:0.01:1000) .* 100;
         d = d(:) + randn(size(d(:)));
         w = waveform('NW.STA.LO.CHA',20,fix(now),d,'Counts');
         testCase.verifyEqual(cumsum(d) ./ get(w,'freq'), double(integrate(w)), 'default (CUMSUM) integration');
         testCase.verifyEqual(get(integrate(w),'units'), 'Counts * sec');
         testCase.verifyEqual(cumsum(d) ./ get(w,'freq'), double(integrate(w, 'cumsum')), 'CUMSUM integration');
         testCase.verifyEqual(cumtrapz(d) ./ get(w,'freq'), double(integrate(w,'trapz')), 'TRAPZ integration');
         %}
      end
      
      function testStatisticalMath(testCase)
         % 'min','max','mean', 'median','std','var'
         D = testCase.Dt(:);
         w = testCase.wf;
         
         testCase.verifyEqual(min(D), min(w));
         testCase.verifyEqual(max(D), max(w));
         testCase.verifyEqual(mean(D), mean(w));
         testCase.verifyEqual(median(D), median(w));
         testCase.verifyEqual(std(D), std(w));
         testCase.verifyEqual(var(D), var(w));
      end
      
      function testTransforms(testCase)
         % transform functions
         % 'rms','hilbert','detrend','demean','taper','stack','fix_data_length'
         
         % todo: rms
         % WAVEFORM/RMS
         w = testCase.wf;
         D = testCase.Dt(:);
         
         % define tolerance
         tol = 1e-10;
         testCase.verifyEqual(rms(w), sqrt((sum(D .^2) / (numel(D)-1))));
         % WAVEFORM/DETREND
         
         testCase.verifyEqual(double(detrend(w)), detrend(D));
         
         % WAVEFORM/DEMEAN
         testCase.verifyEqual(double(demean(w)), (D - mean(D)));
         
         % WAVEFORM/HILBERT
         testCase.verifyEqual(double(hilbert(w)), abs(hilbert(D)));
         
         % WAVEFORM/STACK
         %TODO:waveform/stack ***** NOT IMPLEMENTED ****
         
         % WAVEFORM/FIX_DATA_LENGTH
         % TOO: doublecheck the replacement values
         testCase.verifyEqual(get(fix_data_length(w, 5001),'data_length'), 5001);
         testCase.verifyEqual(get(fix_data_length(w, 301),'data_length'), 301);
         twoWs = fix_data_length([w,set(w,'data',2:100)]);
         testCase.verifyEqual(get(twoWs,'data_length'), get([w w],'data_length'));
      end
      
      function testSacLoad(testCase)
         % station: BYR, chan: BHZ_01, 2000/7/14 13:40 ~10 seconds
         fileName = fullfile(testCase.dataPath,'test_data','example_sacfile.sac');
         dsac = datasource('sac',fileName);
         chanTag(1) = channeltag('...');
         chanTag(2) = channeltag('.BYR..BHZ_01')
         %scnlSac(1) = scnlobject('*','*','*','*');
         %scnlSac(2) = scnlobject('BYR','BHZ_01','*','*');
         
         sacwave = loadsac(waveform,fileName);
         testCase.verifyEqual(get(sacwave,'data_length'), 500);
         testCase.verifyEqual(get(sacwave,'NZYEAR'), 2000);
         testCase.verifyEqual(get(sacwave,'start'), datenum('2000-07-14 13:40:00.006'));
         
         %sacwave = waveform(dsac,scnlSac(1),'7/14/2000','7/15/2000');
         sacwave = waveform(dsac,chanTag(1),'7/14/2000','7/15/2000');
         testCase.verifyEqual(get(sacwave,'data_length'), 500);
         testCase.verifyEqual(get(sacwave,'NZYEAR'), 2000);
         testCase.verifyEqual(get(sacwave,'start'), datenum('2000-07-14 13:40:00.006'));
      end
      
      function testPlot(testCase)
         A = testCase.wf;
         B = waveform('SY.SIN..BHZ',20,fix(now),sin(1:.001:100),'Counts');
         F = figure;
         plot(A);
         plot([A B]);
         plot([A B]','g.');
         plot([A B B.*2 B.*7 set(B,'start',get(B,'start')+datenum(0,0,0,0,0,1))],...
            'xunit','date','markersize',3);
         legend([A, B]);
         plotdetails = get(gca);
         delete(F)
      end
      
      function testUserDefinedFields(testCase)
         % User Defined Fields
         w = testCase.wf;
         w = addfield(w,'ABCD','hello');
         testCase.verifyEqual(get(w,'abCD'),'hello');
         w = set(w,'ABcD',5);
         testCase.verifyEqual(get(w,'AbCD'), 5);
         
         %make sure field was deleted
         w = delfield(w,'abcd');
         testCase.verifyFalse(ismember('ABCD',get(w,'misc_fields')));
         testCase.verifyError(@() get(w,'ABCD'),'Waveform:get:unrecognizedProperty');
      end
      
      function testHistory(testCase)
         %addhistory, clearhistory, clearhistory
         % test ADDHISTORY
         w = testCase.wf;
         w = addhistory(w,'StringTest');
         w = addhistory(w,'[%s]<%02d>','ABCDEFG',3);
         w = addhistory(w,{3});
         fullhist = get(w,'history');
         
         testCase.verifyEqual(numel(fullhist(:,1)), 4);
         testCase.verifyEqual(numel(fullhist(1,:)), 2);
         testCase.verifyEqual(fullhist{1,1}, 'created');
         testCase.verifyEqual(fullhist{2,1},'StringTest');
         testCase.verifyEqual(fullhist{3,1}, '[ABCDEFG]<03>');
         testCase.verifyEqual(fullhist{4,1}{1}, 3);
         
         [~, dates] = history(w);
         
         %test HISTORY
         testCase.verifyEqual(datenum(datestr([fullhist{:,2}])), datenum(dates));
         
         %test CLEARHISTORY
         Z = get(clearhistory(w),'History');
         n = now;
         onesecond = datenum(0,0,0,0,0,1);
         testCase.verifyTrue(abs(Z{2} - n) < onesecond, 'last event expected within past second');
         testCase.verifyEqual(size(Z), [1 2])
         testCase.verifyTrue(ischar(Z{1}));
         testCase.verifyTrue(isa(Z{2},'double'));
         testCase.verifyEqual(Z{1},'Cleared History');
         
         %results.clearhistory = isempty(Z);
         
      end
      
      function testIsEmpty(testCase)
         w = waveform;
         testCase.verifyTrue(isempty(w), 'generic waveform should be empty');
         w = set(w,'data',1);
         testCase.verifyFalse(isempty(w),'waveform with one byte should not be empty');
         w = set(w,'data',[]);
         testCase.verifyTrue(isempty(w), 'data set to [] should be empty');
      end
      
      function testDouble(testCase)
         A = testCase.wf;
         Ad = testCase.Dt(:);
         testCase.verifyEqual(double(A), Ad);
         testCase.verifyEqual(double([A A]), [Ad Ad]);
      end
      
      function testLoadWinston(testCase)
         import matlab.unittest.constraints.HasSize;
         import matlab.unittest.constraints.IsEqualTo;
         import matlab.unittest.constraints.IsGreaterThan;
         
         testCase.assumeThat(...
            exist('gov.usgs.winston.server.WWSClient', 'class'),IsEqualTo(8), ...
            'Winston does not seem to be installed');
         ds = datasource('winston','pubavo1.wr.usgs.gov',16022);
         ch = channeltag('AV.ACH.--.EHZ');
         st = now -2;
         ed = st - datenum(0,0,0,0,1,0); % one minute later
         w = waveform(ds, ch, st, ed);
         testCase.verifyThat(w, HasSize([1 1]));
         testCase.verifyThat(~isempty(double(w)));
         n = get(w(1),'data_length');
         testCase.verifyThat(double(w(1)), HasSize([n, 1])); %data is in cols
      end
      
      function testLoadIRIS(testCase)
         chanInfo = channeltag('IU.ANMO.00.BHZ');
         ds = datasource('irisdmcws');
         st = now - [5 1 -3]; %5 days ago, 1 day ago, 3 days in the future
         et = st + datenum(0,0,0,0,1,0);
         w = waveform(ds,chanInfo,st,et);
         testCase.verifyThat(w, HasSize([1 2]));
         testCase.verifyThat(~isempty(double(w)));
         n = get(w(1),'data_length');
         testCase.verifyThat(double(w(1)), HasSize([n, 1])); %data is in cols
      end
      
      function testLoadobj(testCase)
         load_v0()
         load_v1_0()
         load_v1_1()
         load_v1_2()
         
         function load_v0()
            fileName = fullfile(testCase.dataPath,'test_data','v0_example_waveforms.mat');
            testCase.verifyEqual(exist(fileName,'file'), 2, 'test data for v0 does not exist');
            dummy = load(fileName);
            testCase.verifyTrue(isa(dummy.w,'waveform'), 'converting single v0 waveform failed');
            testCase.verifyTrue(isa(dummy.ww,'waveform'), 'converting multiple v0 waveforms failed');
            testCase.verifyEqual(numel(dummy.ww),10);
         end
         function load_v1_0()
            % test file has two variables w & ww
            fileName = fullfile(testCase.dataPath,'test_data','v1.0_example_waveforms.mat');
            testCase.verifyEqual(exist(fileName,'file'), 2, 'test data for v1.0 does not exist');
            dummy = load(fileName);
            testCase.verifyTrue(isa(dummy.w,'waveform'), 'converting single v1.0 waveform failed');
            testCase.verifyTrue(isa(dummy.ww,'waveform'), 'converting multiple v1.0 waveforms failed');
            testCase.verifyEqual(numel(dummy.ww),10);
         end
         function load_v1_1()
            fileName = fullfile(testCase.dataPath,'test_data','v1.1_example_waveforms.mat');
            testCase.verifyEqual(exist(fileName,'file'),2,'test data for v1.1 does not exist');
            dummy = load(fileName);
            testCase.verifyTrue(isa(dummy.w,'waveform'), 'converting multiple v1.1 waveform failed');
            testCase.verifyEqual(numel(dummy.w),100);
         end
         function load_v1_2()
            fileName = fullfile(testCase.dataPath,'test_data','v1.2_example_waveforms.mat');
            testCase.verifyEqual(exist(fileName,'file'),2,'test data for v1.2 does not exist');
            dummy = load(fileName);
            testCase.verifyTrue(isa(dummy.w,'waveform'), 'converting single v1.2 waveform failed');
            testCase.verifyTrue(isa(dummy.ww,'waveform'), 'converting multiple v1.2 waveforms failed');
            testCase.verifyEqual(numel(dummy.ww),2);
         end
      end
      
      function testSave(testCase)
         % try saving and loading current version
         tmp_name = [tempname , '.mat'];
         
         wtesttemp = testCase.wf;
         save(tmp_name,'wtesttemp')
         
         clear wtesttemp
         dummy = load(tmp_name);
         results.loadobj_current = true;
         delete(tmp_name); %clean up
      end
      
      function testTaper(testCase)
         A = testCase.wf;
         % Test Functions: ensure they don't error & output size is correct
         testCase.verifyEqual(double(taper(A)), double(taper(A,.2)));
         testCase.verifyEqual(double(taper(A,.2)), double(taper(A,.2,'cosine')));
         assert(any(double(taper(A)) ~= double(taper(A,.5))));
      end
      
      function testClip(testCase)
         A = testCase.wf;
         Ad = testCase.Dt;
         
         clippedAd = Ad(:);
         clippedAd(Ad>.3) = .3;
         clippedAd(Ad<-.2) = -.2;
         testCase.verifyEqual(double(clip(A,[-.2,.3])), clippedAd);
      end
      
      function testStack(testCase)
         A = testCase.wf;
         Ad = testCase.Dt;
         testCase.verifyEqual(double(stack([A, A, A, A])), Ad(:) .* 4);
      end
      
      %{
function testDisp(testCase)
         
         A = testCase.wf;
         % try display functions
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
      end
      %}
      
      function testCorrelationCookbook(testCase)
         % probably doesn't belong in this class
         %% try the correlation cookbook
         % assumes we are in GISMO/contributed/test_scripts/waveform and that
         % correlation_cookbook is in GISMO/contributed/correlation_cookbook/
         disp('skipping testCorrelationCookbook')
         return
         ppp = pwd;
         [dataPathCorrelation,~,~] = fileparts(which('correlation'));
         cd(dataPathCorrelation)
         if exist('correlation_cookbook.m','file')
            results.correlation_cookbook = true;
            oldchildren = get(0,'children');
            correlation_cookbook;
            newchildren = get(0,'children');
            todelete = newchildren(~ismember(newchildren,oldchildren));
            delete(todelete); %clean up after it.
         end
         cd(ppp);
         
         % stress test
         w = get(c,'waveform'); %c is from the correlation_cookbook.
         w = repmat(w,20,2);
         dummy = w .* 3;
         todiv = rand(size(w));
         try
            w ./ todiv;
         catch
            for z=1:numel(w);
               dummy(z) = w(z) ./ todiv(z);
            end
         end
         w + 2;
         hilbert(w);
      end
   end
end
