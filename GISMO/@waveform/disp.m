function disp(w)
%DISP Waveform disp overloaded operator


% AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$

if numel(w) > 1;
  disp(' ');
  fprintf('[%s] %s object with fields:\n', size2str(size(w)), class(w));
  disp('     station');
  disp('     channel');
  disp('     start');
  disp('     freq');
  disp('     data');
  disp('     units');
  
  % handle miscelleneous fields
  a = get(w(1),'misc_fields');
  for n=2:length(w);
    a = intersect(a,get(w(n),'misc_fields'));
  end
  if isempty(a) %no fields in common
    if ~isempty(get(w,'misc_fields'))
      % no fields in common, but fields exist
      disp('    With dissimilar fields');
    end
  else
    disp('   with common fields...')
    disp(a')
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
  fprintf('   station: %6s\t\t network: %2s\n',...
    get(w,'station'),get(w,'network'));
  fprintf('   channel: %6s\t\tlocation: %2s\n',...
    get(w,'channel'),get(w,'location'));
  fprintf('     start: %s\n',get(w,'start_str'));
  fprintf('            duration(%s)\n' , get(w,'duration_str'));
  fprintf('      data: %d samples\n', get(w,'data_length'));
  fprintf('      freq: %10.4f Hz\n',get(w,'Fs'));
  fprintf('     units: %s\n',get(w,'units'));
            historycount =  size(get(w,'history'));
          if historycount == 1, plural=''; else, plural = 's'; end
  fprintf('   history: [%d item%s], last modification: %s\n',...
              historycount, plural, datestr(max([w.history{:,2}])));
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
end;

function DispStr = size2str(sizeval)
% helper function that changes the way we view the size
%   from : [1 43 2 6] (numeric)  to  '1x43x2x6' (char)

DispStr = sprintf('x%d', sizeval);
DispStr = DispStr(2:end);
