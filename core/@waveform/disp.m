function disp(w)
   %DISP Waveform disp overloaded operator
   
   
   % AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   % Numerous modifications by Glenn Thompson
   
   if numel(w) > 1
      disp(' ');
      fprintf('[%s] %s object with fields:\n', size2str(size(w)), class(w));
%       disp('     ChannelTag');
%       disp('     start');
%       disp('     freq');
%       disp('     data');
%       disp('     units');
%       disp('     history');

%       fprintf(' ChannelTag: %-15s\n', w.cha_tag.string);
      ctobj = get(w,'ChannelTag');
      fprintf('ChannelTag : ');
      for i=1:numel(w)
          fprintf('%s ',ctobj(i).string());
      end
      fprintf('\n');
      
%       % networks
%       nets = cellstr(unique(get(ctobj,'network')));
%       fprintf('    network: ');
%       for count=1:numel(nets)
%           fprintf('''%s''',nets{count});
%           if count<numel(nets)
%               fprintf('|')
%           end
%       end
%       fprintf('\n');
%       clear nets
% 
%       % stations
%       stas = cellstr(unique(get(ctobj,'station')));
%       fprintf('    station: ');
%       for count=1:numel(stas)
%           fprintf('''%s''',stas{count});
%           if count<numel(stas)
%               fprintf('|')
%           end
%       end
%       fprintf('\n');
%       clear stas   
%       
%       % locations
%       locs = cellstr(unique(get(ctobj,'location')));
%       fprintf('   location: ');
%       for count=1:numel(locs)
%           fprintf('''%s''',locs{count});
%           if count<numel(locs)
%               fprintf('|')
%           end
%       end
%       fprintf('\n');
%       clear locs   
% 
%       % channels
%       chans = cellstr(unique(get(ctobj,'channel')));
%       fprintf('    channel: ');
%       for count=1:numel(chans)
%           fprintf('''%s''',chans{count});
%           if count<numel(chans)
%               fprintf('|')
%           end
%       end
%       fprintf('\n');
%       clear chans 
      
      clear ctobj
      
      % display start/end times
      [wstart,wend] = gettimerange(w);
      mintime = nanmin(wstart);
      maxtime = nanmax(wend);
      if ~isnan(mintime) 
        fprintf('      start: %s\n',datestr(mintime,'yyyy-mm-dd HH:MM:SS.FFF'));
      else
        fprintf('      start: NaN\n');
      end
      if ~isnan(maxtime)
        fprintf('        end: %s\n',datestr(maxtime,'yyyy-mm-dd HH:MM:SS.FFF'));
      else
        fprintf('        end: NaN\n'); 
      end
      if ~isnan(mintime) & ~isnan(maxtime)
        fprintf('   duration: up to %d days %s\n',floor(maxtime-mintime),datestr(maxtime-mintime,'HH:MM:SS.FFF'));
      else
        fprintf('   duration: unknown\n');          
      end
      clear mintime maxtime wstart wend
      
      % number of samples
      nsamps = [get(w,'data_length')];
%      fprintf('    samples: %d ',min(nsamps))
      fprintf('    samples: ')
      for wavnum=1:numel(w)
          fprintf('%d ',nsamps(wavnum));
      end      
%       if max(nsamps)>min(nsamps)
%           fprintf('to %d', max(nsamps));
%       end
      fprintf('\n');
      clear nsamps
      
      % sampling rate
      samprates = [get(w,'freq')];
      fprintf('   samprate: ');
      for wavnum=1:numel(w)
          fprintf('%f ',samprates(wavnum));
      end
      fprintf('\n');      
      
%       fprintf('   samprate: %-10.4f Hz ',min(samprates));
%       if max(samprates)>min(samprates)
%           fprintf('to %-10.4f Hz', max(samprates));
%       end
%       fprintf('\n');      
      clear samprates
      
      % units
      sunits = cellstr(unique(get(w,'units')));
      fprintf('      units: ');
      for count=1:numel(sunits)
          fprintf('''%s''',sunits{count});
          if count<numel(sunits)
              fprintf('|')
          end
      end
      fprintf('\n');
      clear sunits
      
      fprintf('        max: ');
      for wavnum=1:numel(w)
          fprintf('%e ',max(w(wavnum)));
      end
      fprintf('\n');
      fprintf('        min: ');
      for wavnum=1:numel(w)
          fprintf('%e ',min(w(wavnum)));
      end
      fprintf('\n');
      
      fprintf('     # NaNs: ');
      for wavnum=1:numel(w)
          nanindexes = isnan(get(w(wavnum),'data'));
          fprintf('%d ', sum(  nanindexes));
      end
      fprintf('\n');
      
      % handle miscelleneous fields
      a = get(w(1),'misc_fields');
      for n=2:length(w);
         a = intersect(a,get(w(n),'misc_fields'));
      end
      if isempty(a) %no fields in common
         if ~isempty(get(w,'misc_fields'))
            % no fields in common, but fields exist
            disp('    With dissimilar misc fields');
         end
      else
         disp('   with common misc fields...')
         %disp(a')
         for count=1:numel(a)
             fprintf('''%s''',a{count});
             if count<numel(a)
                 fprintf(',')
             end
         end
         fprintf('\n')
      end
      
   elseif numel(w) == 0
      disp('  no waveform');
      
   else %single waveform
      if isempty(get(w,'station')) | ...
            isempty(get(w,'channel')) | ...
            isnan(get(w,'Fs')) | ...
            get(w,'data_length')==0;
         disp('  (incomplete or empty waveform)');
      end
      fprintf(' ChannelTag: %-15s\n', w.cha_tag.string);
      ctobj = get(w,'ChannelTag');
      fprintf('    network: ''%s''\n   station: ''%s''\n  location: ''%s''\n   channel: ''%s''\n',...
               ctobj.network,ctobj.station,ctobj.location, ctobj.channel);
      clear ctobj
      if ~isnan(get(w,'start'))
          fprintf('      start: %s\n',get(w,'start_str'));
          if ~isnan(get(w,'end'))
            fprintf('        end: %s\n',get(w,'end_str'));
            fprintf('   duration: %s\n',get(w,'duration_str'));
          end
      else
          fprintf('      start: NaN\n');
          if ~isnan(get(w,'end'))
              fprintf('        end: %s\n',get(w,'end_str'));
              if get(w,'data_length')==0
                  fprintf('   duration: 0 days 00:00:00.000\n');
              else
                  fprintf('   duration: %s\n',get(w,'duration_str'));
              end
          else
              fprintf('        end: NaN\n');
              fprintf('   duration: unknown\n');
          end
      end
      fprintf('    samples: %d\n', get(w, 'data_length'));
      fprintf('   samprate: %-10.4f Hz\n',get(w,'freq'));
      fprintf('      units: ''%s''\n',get(w,'units'));
      fprintf('        max: %e\n', max(w));
      fprintf('        min: %e\n', min(w));
      nanindexes = isnan(get(w,'data'));
      fprintf('     # NaNs: %d\n', sum(  nanindexes));
      historycount =  size(get(w,'history'));
      if historycount == 1
         plural='';
      else
         plural = 's';
      end
      fprintf('    history: [%d item%s], last modification: %s\n',...
         historycount(1), plural, datestr(max([w.history{:,2}])));
      if numel(get(w,'misc_fields')) > 0,
         disp('    With misc fields...');
      end;
      for n= get(w,'misc_fields')
         val = get(w,n{1}); %grab value associated with this misc_field
         displayIF = (isnumeric(val) || islogical(val)) && (numel(val)<=6);
         displayIF = displayIF || ischar(val);
         
         if strcmp(n{1},'HISTORY'), %special case!
            historycount =  size(val,1);
            if historycount == 1, plural=''; else, plural = 's'; end
            fprintf('    * HISTORY: [%d item%s], last modification: %s\n',...
               historycount, plural, datestr(max([val{:,2}])));
         else
            if ~displayIF
               %must be some sort of object or multiple-value field
               fprintf('    * %s: ',n{1});
               fprintf('[%s] %s object\n',...
                  size2str(size(val)), class(val) );
            else
               fprintf('    * %s: ',n{1});
               if ischar(val)
                  fprintf('%s',val);
               else
                  fprintf('%s',num2str(val));
               end
               fprintf('\n');
            end
         end
         
      end
   end
end

function DispStr = size2str(sizeval)
   % helper function that changes the way we view the size
   %   from : [1 43 2 6] (numeric)  to  '1x43x2x6' (char)
   
   DispStr = sprintf('x%d', sizeval);
   DispStr = DispStr(2:end);
end
