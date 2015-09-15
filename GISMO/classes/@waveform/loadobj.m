function b = loadobj(a)
   %LOADOBJ updates older versions of waveform class upon loading
   % This handles the updated versions and gives a warning if you're trying to
   % load a newer version of a waveform object
   %
   % The newest version of waveform can be found in the GISMOTOOLS repository:
   %  OBSOLETE: http://code.google.com/p/gismotools
   %
   % See also WAVEFORM/WAVEFORM
   
   % AUTHOR: Celso Reyes, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   
   %get the current version of waveform for this system.
   THIS_VERSION = get(waveform,'waveform_object_version');
   
   if isa(a,'waveform')
      b = a;
   else %a is an old version
      %b = waveform;
      % fprintf('Upgrading waveform to new version... v%4.2f\n',THIS_VERSION);
      fn = fieldnames(a);
      if ~ismember('version',fn)
         %this waveform exists prior to using version numbers, and is a
         %simple waveform
         b = repmat(waveform,size(a)); %create a default waveform array
         for n = 1: numel(b)
            b(n) = set(b(n),'station', a(n).station,...
               'channel', a(n).channel,...
               'freq', a(n).Fs,...
               'start', a(n).start,...
               'data', a(n).data,...
               'units','unknown');
            addfield(b(n),'calib',1);
         end
         
         b = reshape(b,size(a));
         return
      end % ~ismember
      
      %If we've reached this portion of code, then we're dealing with a
      %modernish waveform, and upgrades can be based upon the version
      
      switch a(1).version
         case 1
            
            b = repmat(waveform,size(a)); %create a default waveform array
            for n=1: numel(b)
               % waveform contains "station" and "channel" fields.
               b(n) = set(b(n),'station', a(n).station);
               b(n) = set(b(n),'channel', a(n).channel);
               b(n) = set(b(n),'network', a(n).misc_values{strcmpi(a(n).misc_fields,'network')});
               b(n) = set(b(n),'location', a(n).misc_values{strcmpi(a(n).misc_fields,'location')});
               b(n) = set(b(n),'start',a(n).start);
               b(n) = set(b(n),'freq',a(n).Fs);
               b(n) = set(b(n),'data',a(n).data);
               b(n) = set(b(n),'units',a(n).units);
               for myfieldnum = numel(a(n).misc_fields)
                  if strcmp(a(n).misc_fields{myfieldnum},'HISTORY')
                     b(n).history = a(n).misc_values{myfieldnum};
                  else
                     b(n) = addfield(b(n),a(n).misc_fields{myfieldnum},...
                        a(n).misc_values{myfieldnum});
                  end
               end
            end
            
         case 1.1
            % Change to 1.1 means that SCNLOBJECTs are used.
            %invoked, because station and channel fields exist?
            
            b = repmat(waveform,size(a));
            for n=1:numel(b)
               if isstruct(a(n).scnl)
                  scnl = a(n).scnl;
                  b(n).cha_tag = channeltag(scnl.network,scnl.station,scnl.location,scnl.channel);
               else
                  b(n).cha_tag = channeltag(a(n).scnl);
               end
               b(n).Fs = a(n).Fs;
               b(n).start = a(n).start;
               b(n).data = a(n).data;
               b(n).units = a(n).units;
               for m=1:numel(a(n).misc_fields)
                  if strcmp(a(n).misc_fields{m},'HISTORY')
                     b(n).history = a(n).misc_values{m};
                  else
                     b(n) = addfield(b(n),a(n).misc_fields{m},a(n).misc_values{m});
                  end
               end
               %add history here
               %remove history here
            end
            
         case 1.2
            % prior to channeltags.
            
            b = repmat(waveform,size(a));
            for n=1:numel(b)
               b(n).cha_tag = channeltag(a(n).scnl);
               b(n).Fs = a(n).Fs;
               b(n).start = a(n).start;
               b(n).data = a(n).data;
               b(n).units = a(n).units;
               for m=1:numel(a(n).misc_fields)
                  if strcmp(a(n).misc_fields{m},'HISTORY')
                     b(n).history = a(n).misc_values{m};
                  else
                     b(n) = addfield(b(n),a(n).misc_fields{m},a(n).misc_values{m});
                  end
               end
               %add history here
               %remove history here
            end
            
         case 2.0
            %current itteration
            
         otherwise
            error('Waveform:loadobj:unknownWaveformVersion',...
               'Unknown version of waveform object (%1.2f).  Current version is %1.2f',  a(1).version, THIS_VERSION);
      end
   end
   b = addhistory(b,['Updated to version ' num2str(THIS_VERSION)]);
end
