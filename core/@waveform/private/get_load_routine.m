function myLoadRoutine = get_load_routine(ds, use_wkaround)
      % determine the load function based upon the datasource's type
   switch lower(get(ds,'type'))
      case 'sac'
         myLoadRoutine = @load_sac;
      case 'matfile'
         myLoadRoutine = @load_matfile;
      case 'obspy'
         myLoadRoutine = @load_obspy;
      case 'file'
         myLoadRoutine = @load_matfile; %same as type 'matfile'
      case 'antelope' 
         if use_wkaround
            myLoadRoutine = @load_antelope_workaround;
         else
            myLoadRoutine = @load_antelope;
         end
      case 'irisdmcws'
         myLoadRoutine = @load_irisdmcws;
      case 'winston'
         myLoadRoutine = @load_winston;
      case 'seisan'
         myLoadRoutine = @load_seisan;
      case 'ah'
         myLoadRoutine = @load_ah;
       case 'miniseed' % added by Glenn 2016/05/25
           myLoadRoutine = @load_miniseed;
       case 'seed' % added by Glenn 2016/05/25
           myLoadRoutine = @rdmseed2waveform;           
      otherwise
            error('Waveform:waveform:noDatasourceInterpreter',...
               'user defined datasources should be associated with an interpreter');
   end
   disp(myLoadRoutine)
end
