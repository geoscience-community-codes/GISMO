function disp(w)
   %DISP Waveform disp overloaded operator
   
   
   % AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
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
      nets = cellstr(unique(get(ctobj,'network')));
      fprintf('    network: ');
      for count=1:numel(nets)
          fprintf('''%s''',nets{count});
          if count<numel(nets)
              fprintf('|')
          end
      end
      fprintf('\n');
      clear nets

      stas = cellstr(unique(get(ctobj,'station')));
      fprintf('    station: ');
      for count=1:numel(stas)
          fprintf('''%s''',stas{count});
          if count<numel(stas)
              fprintf('|')
          end
      end
      fprintf('\n');
      clear stas   
      
      locs = cellstr(unique(get(ctobj,'location')));
      fprintf('   location: ');
      for count=1:numel(locs)
          fprintf('''%s''',locs{count});
          if count<numel(locs)
              fprintf('|')
          end
      end
      fprintf('\n');
      clear locs   

      chans = cellstr(unique(get(ctobj,'channel')));
      fprintf('    channel: ');
      for count=1:numel(chans)
          fprintf('''%s''',chans{count});
          if count<numel(chans)
              fprintf('|')
          end
      end
      fprintf('\n');
      clear chans 
      
      clear ctobj
      
      
      [wstart,wend] = gettimerange(w);
      mintime = min(wstart);
      maxtime = max(wend);
      fprintf('      start: %s\n',datestr(mintime,'yyyy-mm-dd HH:MM:SS.FFF'));
      fprintf('        end: %s\n',datestr(maxtime,'yyyy-mm-dd HH:MM:SS.FFF'));
      fprintf(' difference: %d days %s\n',floor(maxtime-mintime),datestr(maxtime-mintime,'HH:MM:SS.FFF'));
      clear mintime maxtime wstart wend
      
      nsamps = [get(w,'data_length')];
      fprintf('    samples: %d ',min(nsamps))
      if max(nsamps)>min(nsamps)
          fprintf('to %d', max(nsamps));
      end
      fprintf('\n');
      clear nsamps
      
      samprates = [get(w,'freq')];
      fprintf('   samprate: %-10.4f Hz ',min(samprates));
      if max(samprates)>min(samprates)
          fprintf('to %-10.4f Hz', max(samprates));
      end
      fprintf('\n');      
      clear samprates
      
      sunits = cellstr(unique(get(w,'units')));
      fprintf('      units: ');
      for count=1:numel(sunits)
          fprintf('''%s''',sunits{count});
          if count<numel(sunits)
              fprintf('|')
          end
      end
      fprintf('\n\n');
      clear sunits
      
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
      fprintf('      start: %s\n',get(w,'start_str'));
      fprintf('        end: %s\n',get(w,'end_str'));
      fprintf('   duration: %s\n',get(w,'duration_str'));
      fprintf('    samples: %d\n', get(w, 'data_length'));
      fprintf('   samprate: %-10.4f Hz\n',get(w,'freq'));
      fprintf('      units: ''%s''\n',get(w,'units'));
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
