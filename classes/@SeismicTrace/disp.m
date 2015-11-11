function disp(T)
   %disp   Display information about SeismicTrace(s)
   %
   % See also disp
   
   if numel(T) > 1;
      disp(' ');
      fprintf('[%s] <a href="matlab: help %s">%s</a> containing:\n', size2str(size(T)), class(T), class(T));
      % could present fields that it has in common
      %could provide a bulkdataselect style output...
      fprintf('net.sta.lo.cha\tfirstsample\t\t  nsamples\tsamprate\t duration\n');
      for n=1:numel(T)
         secs = mod(T(n).duration,60);
         mins = mod(fix(T(n).duration / 60),60);
         hrs = fix(T(n).duration / 3600);
         fprintf('%-10s\t%s\t%9d\t%9.3f\t',...
            T(n).name, T(n).start, numel(T(n).data), T(n).samplerate);
         fprintf('%02d:%02d:%05.3f\n' , hrs,mins,secs);
      end;
      return
   elseif numel(T) == 0
      disp('  No Traces');
      
   else %single SeismicTrace
      fprintf('<a href="matlab:help SeismicTrace">SeismicTrace</a> containing:\n');
      fprintf(' ChannelTag: %-15s   [network.station.location.channel]\n', T.name);
      fprintf('      start: %s\n',T.start);
      secs = mod(T.duration,60);
      mins = mod(fix(T.duration / 60),60);
      hrs = fix(T.duration / 3600);
      fprintf('             duration %02d:%02d:%06.3f\n' , hrs,mins,secs);
      fprintf('       data: %d samples\n', numel(T.data));
      fprintf('             range(%f, %f),  mean (%f)\n',min(T), max(T), mean(T));
      fprintf('sample rate: %-10.4f samples per sec\n',T.samplerate);
      fprintf('      units: %s\n',T.units);
      historycount =  numel(T.history);
      if historycount == 1
         plural='';
      else
         plural = 's';
      end
      fprintf('    history: [%d item%s], last modification: %s\n',...
         historycount, plural, datestr(max([T.history.when])));
      ud_fields = fieldnames(T.userdata);
      if isempty(ud_fields)
         disp('<No user defined fields>');
      else
         fprintf('User Defined fields:\n');
         format compact
         for n=1:numel(ud_fields);
            if isstruct(T.UserDataRules) && isfield(T.UserDataRules, ud_fields{n})
               fprintf('   *%15s: ',ud_fields{n}); disp(T.userdata.(ud_fields{n}));
            else
               fprintf('    %15s: ',ud_fields{n}); disp(T.userdata.(ud_fields{n}));
            end
         end
         format short
         disp(' <(*) before fieldname means that rules have been set up governing data input for this field>');
      end
   end
   
   function DispStr = size2str(sizeval)
      % helper function that changes the way we view the size
      %   from : [1 43 2 6] (numeric)  to  '1x43x2x6' (char)
      
      DispStr = sprintf('x%d', sizeval);
      DispStr = DispStr(2:end);
   end
end