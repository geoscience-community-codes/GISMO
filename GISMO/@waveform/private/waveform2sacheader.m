function header = waveform2sacheader(w)
% WAVEFORM2SACHEADER generates a SAC header from a waveform object
%
%    See also: waveform/private/readsacfile, waveform/private/sac2waveform,
%    waveform/private/writesac, waveform/private/set_sacheader

% VERSION: 1.1 of waveform objects
% AUTHOR: Celso Reyes
%    modified from Michael Thorne (4/2004)
% LASTUPDATE: 9/2/2009 


% currently a roundabout way to do things.  This will change. -CR

if numel(w) > 1,
    error('Waveform:waveform2sacheader:tooManyWaveforms',...
      'can only run waveform2sacheader on a single waveform');
end

%set real header variables
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
h(1:70) = -12345;
header(1:70) = h(1:70)';

%set required header variables
%head = header(2,1) - header(1,1);
w = addfield(w,'DELTA',get(w,'period'));
% header=set_sacheader(header,'DELTA',deltaTime);
%head = header(1,1);
w = addfield(w,'B',0);
w = addfield(w,'E',get(w,'end_epoch') - get(w,'start_epoch'));
w = addfield(w,'NPTS',get(w,'data_length'));
%header=set_sacheader(header,'B',beginTime);
 %head = header(numel(header(:,1)),1);
%header=set_sacheader(header,'E',endTime);
header=set_sacheader(header,'DEPMIN',min(get(w,'data')));
header=set_sacheader(header,'DEPMAX',max(get(w,'data')));
header=set_sacheader(header,'DEPMEN',mean(get(w,'data')));

%set logical and integer header variables:
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
h(71:110) = -12345;
header(71:110) = h(71:110)';

%set required header variables
header=set_sacheader(header,'IFTYPE',true);
header=set_sacheader(header,'LEVEN',true);
header=set_sacheader(header,'LCALDA',true);
header=set_sacheader(header,'LOVROK',true);
version = 6;
header=set_sacheader(header,'NVHDR',version);
head = 0;
header=set_sacheader(header,'LPSPOL',head);

%set character header variables:
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
h8 = '-12345  ';
% h8 = [45 49 50 51 52 53 32 32];
h16 = [45 49 50 51 52 53 32 32 32 32 32 32 32 32 32 32];
header(111:118)=h8';
header(119:134)=h16';
header(135:142)=h8';
header(143:150)=h8';
header(151:158)=h8';
header(159:166)=h8';
header(167:174)=h8';
header(175:182)=h8';
header(183:190)=h8';
header(191:198)=h8';
header(199:206)=h8';
header(207:214)=h8';
header(215:222)=h8';
header(223:230)=h8';
header(231:238)=h8';
header(239:246)=h8';
header(247:254)=h8';
header(255:262)=h8';
header(263:270)=h8';
header(271:278)=h8';
header(279:286)=h8';
header(287:294)=h8';
header(295:302)=h8';

%% go through all fields and change 'em (if they'll change...)

% check units
switch lower(get(w,'units'))
    case 'nm' %idisp
        IDEP_ref = 6;
    case 'nm / sec' %ivel
        IDEP_ref = 7;
    case 'nm / sec / sec' %iacc
        IDEP_ref = 8;
    case 'volts' %ivolts
        IDEP_ref = 50;
    otherwise %case 5 = iunkn
        IDEP_ref = 5;
end        
w = addfield(w,'IDEP',IDEP_ref);

% update fields based on the actual station data...
w = addfield(w,'KSTNM',get(w,'station'));
w = addfield(w,'KCMPNM', get(w,'channel'));
w = addfield(w,'KNETWK', get(w,'network'));

[Y,M,D,h,m,s] = datevec( get(w,'start') );
JD = datenum(Y,M,D,h,m,s) - datenum(Y-1,12,31,0,0,0);
w = addfield(w,'NZYEAR',Y);
w = addfield(w,'NZJDAY',JD);
w = addfield(w,'NZHOUR',h);
w = addfield(w,'NZMIN',m);
w = addfield(w,'NZSEC',fix(s));
w = addfield(w,'NZMSEC',(s - fix(s)) * 1000);


fieldsToChange = get(w,'misc_fields');

%now, actually generate the header values
for n=1: numel(fieldsToChange)
    header = set_sacheader(header,fieldsToChange{n}, get(w,fieldsToChange{n}));    
end
