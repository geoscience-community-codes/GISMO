function disp(ds)
%DISP Datasource disp overloaded operator


% VERSION: 1.0 of waveform objects
% AUTHOR: Celso Reyes (celso@gi.alaska.edu)
% LASTUPDATE: 11/29/2008

if numel(ds) > 1;
  disp(' ');
  disp(sprintf('[%s] %s object with Types:',...
    size2str(size(ds)), class(ds)));
  for j=1:numel(ds)
    alltypes(j) = {get(ds(j),'type')};
  end
  alltypes = unique(alltypes);
  for i=1:numel(alltypes)
    disp(sprintf('     %s',alltypes{i}));
  end



elseif isunassigned(ds)
  disp('  unassigned datasource');
else
  mytype = get(ds,'type');
  disp(['      type: ' upper(mytype)]);
  switch lower(mytype)
    case 'winston'
      disp(['    server: ' get(ds,'server')]);
      disp(['      port: ' num2str(get(ds,'port'))]);

    case {'file','sac','antelope','seisan'}
      filelist = getfilename(ds,[],[]);
      for n=1:numel(filelist)
        disp(sprintf('  location: %s',filelist{n}));
      end
      
    case {'user_defined'}
      filelist = getfilename(ds,[],[]);
      for n=1:numel(filelist)
        disp(sprintf('  location: %s',filelist{n}));
      end
      disp(sprintf(' Interpreting Function: %s',func2str(get(ds,'interpreter'))));
    otherwise
      warning('Datasource:unanticipatedType',...
        'unanticipated datasource type');
  end
end;

function DispStr = size2str(sizeval)
% helper function that changes the way we view the size
%   from : [1 43 2 6] (numeric)  to  '1x43x2x6' (char)

DispStr = sprintf('x%d', sizeval);
DispStr = DispStr(2:end);
