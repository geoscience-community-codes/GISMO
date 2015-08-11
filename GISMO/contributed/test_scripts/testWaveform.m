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
         
         %manual constructor
         w = waveform(STATIONVALUE,CHANNELVALUE,rfreq, stt,Ad);
         assert(strcmp(get(w,'station'), STATIONVALUE));
         assert(strcmp(get(w,'channel'), CHANNELVALUE)) ;
         assert(all(get(w,'freq') == rfreq));
         assert(all(get(w,'start') == stt));
         assert(all(get(w,'data') == Ad(:)));
         
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
                  % fprintf('field <%s> of type <%s> uncompared\n',fn{n},class(s1.(fn{n})));
            end
         end
         
      end
      
      function testSetGets(obj)
         %% test SET routines
         mep2dep = inline('(n - 719529) * 86400','n');
         set_test = {'station','freq','channel','data','units',...
            'start','start_epoch','data_length'};
         
         set_VALID_vals = {'Bob',293,'JIM',(1:10000)','MyUNIT',now,mep2dep(now),3};
         
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
      end
      
      function testBasicMath(obj)
         % basic math functions
         %   'uminus','plus','minus'
         %   'times','mtimes','rdivide','mrdivide','power'
         w = obj.wf;
         D = obj.Dt(:);
         % identities
         assert(w + 0 == w);
         assert(w ./ 1 == w);
         assert(w - 0 == w);
         assert(w * 1 == w);
         assert(w .* 1 == w);
         assert(w .^ 1 == w);
         
         % comparing operations
         assert(w + w == w * 2);    % plus, times, vector addition
         assert(w - w == w .* 0);    % minus, mtimes, vector subtraction
         assert(w ./ 2 == w .* 0.5); % rdivide, times
         assert(w .^ 2 == w .* w);  % power, vector multiplication
         assert(all(D .* D == double(w .* D)));
         assert(w .* 5 == w * 5);   % mtimes, times
         assert(w + -w == w .* 0);  % uminus
         
         % communicative
         assert(w + 100 == 100 + w);
         assert(w .* 5 == 5 .* w);
         
         assert(all(double(w + 5 .* w) == D + 5 .* D));
         assert(all(double((7 .* w) + (w ./ 5) - w.^3) == (D .* 7)+(D ./ 5) - D.^3));
         
         assert(all(double(w / 2) == (D / 2)));
      end
      
      function testAdvancedMath(obj)
         % sign, abs, diff, integrate
         D = obj.Dt(:);
         w = obj.wf;
         
         assert(all(double(sign(w)) == sign(D)));  % signum
         assert(abs(w) == sign(w) .* w);           % abs vs signum
         assert(all(double(abs(w)) == abs(D)));
         assert(all(double(diff(w)) == diff(D)),'diff(waveform) == diff(data)');
         assert(get(diff(w),'units') == [get(diff(w),'units'), ' / sec']);
         assert(all(double(integrate(w)) == integrate(D)));
         assert(all(cumtrapz(D) ./ get(w,'freq') == double(integrate(w,'trapz'))));
         assert(get(integrate(w),'units') == 'm');
         % to do: diff & integrate with extra options
         %{
         results.integrate = ...
            all(cumsum(Bd) ./ get(B,'freq') == double(integrate(B))) &&...
            strcmp(get(integrate(B),'units'), 'Counts * sec');
         results.integrate = results.integrate &&...
            all(cumtrapz(Bd) ./ get(B,'freq') == double(integrate(B,'trapz')));
         %}
      end
      
      function testStatisticalMath(obj)
         % 'min','max','mean', 'median','std','var'
         D = obj.Dt(:);
         w = obj.wf;
         
         assert(min(D) == min(w));
         assert(max(D) == max(w));
         assert(mean(D) == mean(w));
         assert(median(D) == median(w));
         assert(std(D) == std(w));
         assert(var(D) == var(w));
      end
      
      function testTransforms(obj)
         % transform functions
         % 'rms','hilbert','detrend','demean','taper','stack','fix_data_length'
         
         % todo: rms
         % WAVEFORM/RMS
         w = obj.wf;
         D = obj.Dt(:);
         
         
         assert(all(rms(w)  == sqrt((sum(D .^2) / (numel(D)-1)))));
         % WAVEFORM/DETREND
         assert(all(double(detrend(w)) == detrend(D)));
         
         % WAVEFORM/DEMEAN
         assert(all(double(demean(w)) == (D - mean(D))));
         
         % WAVEFORM/HILBERT
         assert(all(double(hilbert(w)) == abs(hilbert(D))));
         
         % WAVEFORM/STACK
         %TODO:waveform/stack ***** NOT IMPLEMENTED ****
         
         % WAVEFORM/FIX_DATA_LENGTH
         assert(get(fix_data_length(w, 5001),'data_length') == 5001 &&...
            get(fix_data_length(w, 301),'data_length') == 301 &&...
            all(get(fix_data_length([w,set(w,'data',2:100)]),'data_length')...
            == get(w,'data_length')));
      end
      
      function testSacLoad(obj)
         % station: BYR, chan: BHZ_01, 2000/7/14 13:40 ~10 seconds
         fileName = fullfile(obj.dataPath,'test_data','example_sacfile.sac');
         dsac = datasource('sac',fileName);
         scnlSac(1) = scnlobject('*','*','*','*');
         scnlSac(2) = scnlobject('BYR','BHZ_01','*','*');
         sacwave = loadsac(waveform,fileName);
         assert(get(sacwave,'data_length')==500 &&...
            get(sacwave,'NZYEAR') == 2000 &&...
            get(sacwave,'start') == datenum('2000-07-14 13:40:00.006'));
         sacwave = waveform(dsac,scnlSac(1),'7/14/2000','7/15/2000');
         assert( get(sacwave,'data_length')==500 &&...
            get(sacwave,'NZYEAR') == 2000 &&...
            get(sacwave,'start') == datenum('2000-07-14 13:40:00.006'));
      end
      
      function testPlot(obj)
         A = obj.wf;
         B = waveform('SY.SIN..BHZ',20,fix(now),sin(1:.001:100),'Counts');
         figure;
         plot(A);
         plot([A B]);
         plot([A B]','g.');
         plot([A B B.*2 B.*7 set(B,'start',get(B,'start')+datenum(0,0,0,0,0,1))],...
            'xunit','date','markersize',3);
         legend([A, B]);
         
      end
      
      function testUserDefinedFields(obj)
         %% User Defined Fields
         w = obj.wf;
         w = addfield(w,'ABCD','hello');
         test1 = strcmp(get(w,'abCD'),'hello');
         w = set(w,'ABcD',5);
         test2 = get(w,'AbCD') == 5;
         results.addfield = test1 && test2;
         lastwarn('') ;
         w = delfield(w,'abcd');
         disp('There SHOULD be a warning following this ...');
         get(w,'ABCD'); %should fail because it was deleted.
         if ~isempty(lastwarn)
            results.delfield = true;
         else
            results.delfield = false;
         end
      end
      
      function testHistory(obj)
         %addhistory, clearhistory, clearhistory
         % test ADDHISTORY
         w = obj.wf;
         w = addhistory(w,'StringTest');
         w = addhistory(w,'[%s]<%02d>','ABCDEFG',3);
         w = addhistory(w,{3});
         fullhist = get(w,'history');
         
         assert( ...
            numel(fullhist(:,1)) == 4 && numel(fullhist(1,:)) == 2 && ...
            strcmp(fullhist{1,1}, 'created') && ...
            strcmp(fullhist{2,1},'StringTest') && ...
            strcmp(fullhist{3,1}, '[ABCDEFG]<03>') && ...
            (fullhist{4,1}{1} == 3));
         
         [~, dates] = history(w);
         
         %test HISTORY
         assert(all(datenum(datestr([fullhist{:,2}])) == datenum(dates)));
         
         %test CLEARHISTORY
         Z = get(clearhistory(w),'History');
         n = now;
         onesecond = datenum(0,0,0,0,0,1);
         assert((abs(Z{2} - n) < onesecond)  &&... % last event less than a second ago?
            all(size(Z) == [1 2]) &&...
            isa(Z{1},'char') && isa(Z{2},'double') &&...
            strcmp(Z{1},'Cleared History'));
         
         %results.clearhistory = isempty(Z);
         
      end
      
     
      function testIsEmpty(obj)
         
         % isEMPTY, double
         assert(isempty(waveform) && ~isempty(set(waveform,'data',1)));
      end
      function testDouble(obj)
         A = obj.wf;
         Ad = obj.Dt(:);
         assert(all(double(A) == Ad) && ...
            all(all(double([A A]) == [Ad Ad]))); %ADDITIONAL CHECKS REQUIRED
      end
      
      function testLoadobj(obj)
         load_v0()
         load_v1_0()
         load_v1_1()
         load_v1_2()
         
         function load_v0()
            fileName = fullfile(obj.dataPath,'test_data','v0_example_waveforms.mat');
            dummy = load(fileName);
            assert(isa(dummy.w,'waveform'), 'converting single v0 waveform failed');
            assert(isa(dummy.ww,'waveform'), 'converting multiple v0 waveforms failed');
         end
         function load_v1_0()
            % test file has two variables w & ww
            fileName = fullfile(obj.dataPath,'test_data','v1.0_example_waveforms.mat');
            dummy = load(fileName);
            assert(isa(dummy.w,'waveform'), 'converting single v1.0 waveform failed');
            assert(isa(dummy.ww,'waveform'), 'converting multiple v1.0 waveforms failed');
         end
         function load_v1_1()
            w = waveform;
            fileName = fullfile(obj.dataPath,'test_data','v1.1_example_waveforms.mat');
            dummy = load(fileName);
            assert(isa(dummy.w,'waveform'), 'converting multiple v1.1 waveform failed');
         end
         function load_v1_2()
            fileName = fullfile(obj.dataPath,'test_data','v1.2_example_waveforms.mat');
            dummy = load(fileName);
            assert(isa(dummy,'waveform'));
         end
      end
      
      function testSave(obj)
         %% try saving and loading current version
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
         %% Test Functions: ensure they don't error & output size is correct
         results.taper = all(double(taper(A)) == double(taper(A,.2))) &&...
            all(double(taper(A,.2)) == double(taper(A,.2,'cosinE')));
         
         assert(results.taper && any(double(taper(A)) ~= double(taper(A,.5))));
      end
      
      function testClip(obj)
         A = obj.wf;
         Ad = obj.Dt;
         
         clippedAd = Ad(:);
         clippedAd(Ad>.3) = .3;
         clippedAd(Ad<-.2) = -.2;
         assert(all(double(clip(A,[-.2,.3])) == clippedAd));
      end
      
      function testStack(obj)
         A = obj.wf;
         Ad = obj.Dt;
         results.stack = all(double(stack([A, A, A, A])) == Ad(:) .* 4);
      end
      
      function testDisp(obj)
         
         A = obj.wf;
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
      end
      
   end
   methods(Static)
       function testCorrelationCookbook()
         % probably doesn't belong in this class
         %% try the correlation cookbook
         % assumes we are in GISMO/contributed/test_scripts/waveform and that
         % correlation_cookbook is in GISMO/contributed/correlation_cookbook/
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
