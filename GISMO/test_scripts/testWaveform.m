classdef testWaveform < TestCase
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
   
   methods
      function self = testWaveform(name)
         self = self@TestCase(name);
         
         self.Dt = rand(1,1001) .* 1000 - 500;
         self.chanTag = channeltag('IU.ANMO.00.BHZ');
         self.wf = waveform(self.chanTag, 20, fix(now), self.Dt, 'm / sec');
      end
      
      function SetUp(self)
         % not sure this is working in any way.
         self.Dt = rand(1,1001) .* 1000 - 500;
         self.chanTag = channeltag('IU.ANMO.00.BHZ');
         self.wf = waveform(self.chanTag, 20, fix(now), D, 'm / sec');
      end
      
      function testConstructors(obj)
         %% first, try the different methods of loading up waveforms
         %default constructor
         w = waveform; %create an empty waveform
         assert(isa(w,'waveform'));
         
         rfreq = rand(1) * 200;
         Ad = obj.Dt;
         stt = now - rand(1) * 1500;
         clear w
         STATIONVALUE = 'STAtION';
         CHANNELVALUE = 'CHAnNEL';
         
         %manual constructor now gives error
         assertExceptionThrown(@() waveform(STATIONVALUE,CHANNELVALUE,rfreq, stt,Ad),...
            'Waveform:waveform:oldUsage');
         w = waveform(obj.chanTag, rfreq, stt, obj.Dt);
         
         % copy constructor
         w2 = w;
         s1 = struct(w); s2 = struct(w2);
         fn = fieldnames(s1);
         for n=1:numel(fn)
            switch (class(s1.(fn{n})))
               case {'char', 'double', 'logical'}
                  assertEqual(s1.(fn{n}), s2.(fn{n}));
               otherwise
                  % fprintf('field <%s> of type <%s> uncompared\n',fn{n},class(s1.(fn{n})));
            end
         end
         
      end
      
      function testSetGets(obj)
         %% test SET routines
         %TODO: Update to use TestCase syntax
         mep2dep = inline('(n - 719529) * 86400','n');
         set_test = {'station','freq','channel','data','units',...
            'start','start_epoch','data_length'};
         
         set_VALID_vals = {'Bob',293,'JIM',(1:10000)','MyUNIT',now,mep2dep(now),3};
         
         set_INVALID_vals = {5,'a',5,ones(5,5),3,'a','a',-1};
         
         w =  obj.wf;
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
            assertTrue(setresult.(set_test{N}), set_test{N})
         end
      end
      
      function testBasicMath(obj)
         % basic math functions
         %   'uminus','plus','minus'
         %   'times','mtimes','rdivide','mrdivide','power'
         w = obj.wf;
         D = obj.Dt(:);
         % identities
         assertEqual(w + 0, w);
         assertEqual(w ./ 1, w);
         assertEqual(w - 0, w);
         assertEqual(w * 1, w);
         assertEqual(w .* 1, w);
         assertEqual(w .^ 1, w);
         
         % comparing operations
         assertEqual(w + w, w * 2);    % plus, times, vector addition
         assertEqual(w - w, w .* 0);    % minus, mtimes, vector subtraction
         assertEqual(w ./ 2, w .* 0.5); % rdivide, times
         assertEqual(w .^ 2, w .* w);  % power, vector multiplication
         assertEqual(D .* D, double(w .* D));
         assertEqual(w .* 5, w * 5);   % mtimes, times
         assertEqual(w + -w, w .* 0);  % uminus
         
         % communicative
         assertEqual(w + 100, 100 + w);
         assertEqual(w .* 5, 5 .* w);
         
         assertEqual(double(w + 5 .* w), D + 5 .* D);
         assertEqual(double((7 .* w) + (w ./ 5) - w.^3), (D .* 7)+(D ./ 5) - D.^3);
         
         assertEqual(double(w / 2), (D / 2));
      end
      
      function testAdvancedMath(obj)
         % sign, abs, diff, integrate
         D = obj.Dt(:);
         w = obj.wf;
         
         assertEqual(double(sign(w)),  sign(D));
         assertEqual(abs(w),           sign(w) .* w);
         assertEqual(double(abs(w)),   abs(D));
      end
      
      function testDiff(obj)
         dW = diff(obj.wf);
         dd = diff(obj.Dt(:)) * get(obj.wf,'freq'); %scaled!
         assertEqual(double(dW), dd,  'differentiation values');
         
         expectedUnits = [get(obj.wf,'units'), ' / sec'];
         assertEqual(get(dW,'units'), expectedUnits, 'unit check');
      end
      
      function testIntegrate(obj)
         d = sin(1:0.01:1000) .* 100;
         d = d(:) + randn(size(d(:)));
         w = waveform('NW.STA.LO.CHA',20,fix(now),d,'Counts');
         assertEqual(cumsum(d) ./ get(w,'freq'), double(integrate(w)), 'default (CUMSUM) integration');
         assertEqual(get(integrate(w),'units'), 'Counts * sec');
         assertEqual(cumsum(d) ./ get(w,'freq'), double(integrate(w, 'cumsum')), 'CUMSUM integration');
         assertEqual(cumtrapz(d) ./ get(w,'freq'), double(integrate(w,'trapz')), 'TRAPZ integration');
         %}
      end
      
      function testStatisticalMath(obj)
         % 'min','max','mean', 'median','std','var'
         D = obj.Dt(:);
         w = obj.wf;
         
         assertEqual(min(D), min(w));
         assertEqual(max(D), max(w));
         assertEqual(mean(D), mean(w));
         assertEqual(median(D), median(w));
         assertEqual(std(D), std(w));
         assertEqual(var(D), var(w));
      end
      
      function testTransforms(obj)
         % transform functions
         % 'rms','hilbert','detrend','demean','taper','stack','fix_data_length'
         
         % todo: rms
         % WAVEFORM/RMS
         w = obj.wf;
         D = obj.Dt(:);
         
         
         assertEqual(rms(w), sqrt((sum(D .^2) / (numel(D)-1))));
         % WAVEFORM/DETREND
         assertEqual(double(detrend(w)), detrend(D));
         
         % WAVEFORM/DEMEAN
         assertEqual(double(demean(w)), (D - mean(D)));
         
         % WAVEFORM/HILBERT
         assertEqual(double(hilbert(w)), abs(hilbert(D)));
         
         % WAVEFORM/STACK
         %TODO:waveform/stack ***** NOT IMPLEMENTED ****
         
         % WAVEFORM/FIX_DATA_LENGTH
         % TOO: doublecheck the replacement values
         assertEqual(get(fix_data_length(w, 5001),'data_length'), 5001);
         assertEqual(get(fix_data_length(w, 301),'data_length'), 301);
         twoWs = fix_data_length([w,set(w,'data',2:100)]);
         assertEqual(get(twoWs,'data_length'), get([w w],'data_length'));
      end
      
      function testSacLoad(obj)
         % station: BYR, chan: BHZ_01, 2000/7/14 13:40 ~10 seconds
         fileName = fullfile(obj.dataPath,'test_data','example_sacfile.sac');
         dsac = datasource('sac',fileName);
         scnlSac(1) = scnlobject('*','*','*','*');
         scnlSac(2) = scnlobject('BYR','BHZ_01','*','*');
         
         sacwave = loadsac(waveform,fileName);
         assertEqual(get(sacwave,'data_length'), 500);
         assertEqual(get(sacwave,'NZYEAR'), 2000);
         assertEqual(get(sacwave,'start'), datenum('2000-07-14 13:40:00.006'));
         
         sacwave = waveform(dsac,scnlSac(1),'7/14/2000','7/15/2000');
         assertEqual(get(sacwave,'data_length'), 500);
         assertEqual(get(sacwave,'NZYEAR'), 2000);
         assertEqual(get(sacwave,'start'), datenum('2000-07-14 13:40:00.006'));
      end
      
      function testPlot(obj)
         A = obj.wf;
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
      
      function testUserDefinedFields(obj)
         % User Defined Fields
         w = obj.wf;
         w = addfield(w,'ABCD','hello');
         assertEqual(get(w,'abCD'),'hello');
         w = set(w,'ABcD',5);
         assertEqual(get(w,'AbCD'), 5);
         
         %make sure field was deleted
         w = delfield(w,'abcd');
         assertFalse(ismember('ABCD',get(w,'misc_fields')));
         assertExceptionThrown(@() get(w,'ABCD'),'Waveform:get:unrecognizedProperty');
      end
      
      function testHistory(obj)
         %addhistory, clearhistory, clearhistory
         % test ADDHISTORY
         w = obj.wf;
         w = addhistory(w,'StringTest');
         w = addhistory(w,'[%s]<%02d>','ABCDEFG',3);
         w = addhistory(w,{3});
         fullhist = get(w,'history');
         
         assertEqual(numel(fullhist(:,1)), 4);
         assertEqual(numel(fullhist(1,:)), 2);
         assertEqual(fullhist{1,1}, 'created');
         assertEqual(fullhist{2,1},'StringTest');
         assertEqual(fullhist{3,1}, '[ABCDEFG]<03>');
         assertEqual(fullhist{4,1}{1}, 3);
         
         [~, dates] = history(w);
         
         %test HISTORY
         assertEqual(datenum(datestr([fullhist{:,2}])), datenum(dates));
         
         %test CLEARHISTORY
         Z = get(clearhistory(w),'History');
         n = now;
         onesecond = datenum(0,0,0,0,0,1);
         assertTrue(abs(Z{2} - n) < onesecond, 'last event expected within past second');
         assertEqual(size(Z), [1 2])
         assertTrue(ischar(Z{1}));
         assertTrue(isa(Z{2},'double'));
         assertEqual(Z{1},'Cleared History');
         
         %results.clearhistory = isempty(Z);
         
      end
      
      function testIsEmpty(obj)
         w = waveform;
         assertTrue(isempty(w), 'generic waveform should be empty');
         w = set(w,'data',1);
         assertFalse(isempty(w),'waveform with one byte should not be empty');
         w = set(w,'data',[]);
         assertTrue(isempty(w), 'data set to [] should be empty');
      end
      
      function testDouble(obj)
         A = obj.wf;
         Ad = obj.Dt(:);
         assertEqual(double(A), Ad);
         assertEqual(double([A A]), [Ad Ad]);
      end
      
      function testLoadobj(obj)
         load_v0()
         load_v1_0()
         load_v1_1()
         load_v1_2()
         
         function load_v0()
            fileName = fullfile(obj.dataPath,'test_data','v0_example_waveforms.mat');
            assertEqual(exist(fileName,'file'), 2, 'test data for v0 does not exist');
            dummy = load(fileName);
            assertTrue(isa(dummy.w,'waveform'), 'converting single v0 waveform failed');
            assertTrue(isa(dummy.ww,'waveform'), 'converting multiple v0 waveforms failed');
            assertEqual(numel(dummy.ww),10);
         end
         function load_v1_0()
            % test file has two variables w & ww
            fileName = fullfile(obj.dataPath,'test_data','v1.0_example_waveforms.mat');
            assertEqual(exist(fileName,'file'), 2, 'test data for v1.0 does not exist');
            dummy = load(fileName);
            assertTrue(isa(dummy.w,'waveform'), 'converting single v1.0 waveform failed');
            assertTrue(isa(dummy.ww,'waveform'), 'converting multiple v1.0 waveforms failed');
            assertEqual(numel(dummy.ww),10);
         end
         function load_v1_1()
            fileName = fullfile(obj.dataPath,'test_data','v1.1_example_waveforms.mat');
            assertEqual(exist(fileName,'file'),2,'test data for v1.1 does not exist');
            dummy = load(fileName);
            assertTrue(isa(dummy.w,'waveform'), 'converting multiple v1.1 waveform failed');
            assertEqual(numel(dummy.w),100);
         end
         function load_v1_2()
            fileName = fullfile(obj.dataPath,'test_data','v1.2_example_waveforms.mat');
            assertEqual(exist(fileName,'file'),2,'test data for v1.2 does not exist');
            dummy = load(fileName);
            assertTrue(isa(dummy.w,'waveform'), 'converting single v1.2 waveform failed');
            assertTrue(isa(dummy.ww,'waveform'), 'converting multiple v1.2 waveforms failed');
            assertEqual(numel(dummy.ww),2);
         end
      end
      
      function testSave(obj)
         % try saving and loading current version
         tmp_name = [tempname , '.mat'];
         
         wtesttemp = obj.wf;
         save(tmp_name,'wtesttemp')
         
         clear wtesttemp
         dummy = load(tmp_name);
         results.loadobj_current = true;
         delete(tmp_name); %clean up
      end
      
      function testTaper(obj)
         A = obj.wf;
         % Test Functions: ensure they don't error & output size is correct
         assertEqual(double(taper(A)), double(taper(A,.2)));
         assertEqual(double(taper(A,.2)), double(taper(A,.2,'cosine')));
         assert(any(double(taper(A)) ~= double(taper(A,.5))));
      end
      
      function testClip(obj)
         A = obj.wf;
         Ad = obj.Dt;
         
         clippedAd = Ad(:);
         clippedAd(Ad>.3) = .3;
         clippedAd(Ad<-.2) = -.2;
         assertEqual(double(clip(A,[-.2,.3])), clippedAd);
      end
      
      function testStack(obj)
         A = obj.wf;
         Ad = obj.Dt;
         assertEqual(double(stack([A, A, A, A])), Ad(:) .* 4);
      end
      
      %{
function testDisp(obj)
         
         A = obj.wf;
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
      
      function testCorrelationCookbook(obj)
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
