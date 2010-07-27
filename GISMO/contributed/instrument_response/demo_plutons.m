%

dbName = '/home/field/databases/PLUTONS/wf/plutons';
ds = datasource('antelope',dbName);


%t1 = datenum('2010/2/27 6:35');
%t2 = datenum('2010/2/27 6:55');
%filterObj = filterobject('b',[0.033 0.2],3);
%stachan = {
% 'UTLO'   'BHZ'     
% 'UTKH'   'BHZ'     
% 'UTSA'   'BHZ'     
% 'UTQU'   'BHZ'     
% 'UTLV'   'BHZ' 
% 'UTSM'   'BHZ'     
% 'UTLL'   'SHZ'         
% 'UTSS'   'SHZ'     
% 'UTLA2'  'SHZ'     
% 'UTSW'   'SHZ'         
% 'UTMK'   'SHZ'     
% 'UTCM'   'SHZ'     
% 'UTCA'   'SHZ'          
% 'UTZN'   'SHZ'     
% 'UTTM'   'SHZ'}  

%t1 = datenum('2009/9/22 22:47:10');
%t2 = datenum('2009/9/22 22:47:30');
t1 = datenum('2010/02/27 22:47:10');
t2 = datenum('2010/02/27 22:47:30');

filterObj = filterobject('b',[0.5 10],2);
stachan = {
'UTSM'   'BHZ'     
'UTQU'   'BHZ'    
'UTTM'   'SHZ' 
'UTLA2'  'SHZ'     
'UTCA'   'SHZ'          
'UTLV'   'BHZ' 
'UTCM'   'SHZ'     
'UTSW'   'SHZ'         
'UTSA'   'BHZ'     
'UTZN'   'SHZ'     
'UTSS'   'SHZ'     
'UTMK'   'SHZ'     
'UTLO'   'BHZ'     
'UTLL'   'SHZ'         
'UTKH'   'BHZ'
}  

for n = 1:size(stachan,1)
    scnl = scnlobject(stachan(n,1),stachan(n,2),'','');
    try
        w(n) = waveform(ds,scnl,t1,t2);
    catch
        w(n) = waveform;
    end
end
f = find(get(w,'DATA_LENGTH')~=0);
w = w(f);


% APPLY RESPONSES TO ORIGINAL WAVEFORMS (SHORT PERIOD)

wFilt = filtfilt(filterObj,w);
wNew = response_apply(wFilt,filterObj,'antelope',dbName);

% for n =1:numel(w)
%     n
%     wFilt(n) = filtfilt(filterObj,w(n));
%     wNew(n) = response_apply(wFilt(n),filterObj,dbName);
% end
save

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check one channel
n = 3;
figure
plot(wFilt(n),'r');
hold on;
plot(wNew(n),'b');
response_plot(get(wNew(n),'RESPONSE'),[0.01 50])


load
% compare all channels
cNew = correlation(wNew);
%cNew = xcorr(cNew);
%cNew = adjusttrig(cNew);
plot(cNew,'wig',0.6)
title('Filtered and corrected for instrument response','FontSize',16);
%print(gcf,'-dpsc2','demo_corrected.ps');

cFilt = correlation(wFilt);
plot(cFilt,'wig',.6)
title('Filtered only (30.5 - 10 Hz)','FontSize',16);
%print(gcf,'-dpsc2','demo_filtered.ps');

c = correlation(w);
plot(c,'wig',.6)
title('Raw','FontSize',16);
%print(gcf,'-dpsc2','demo_raw.ps');

% 
% % compare all channels
% cNew = correlation(wNew);
% cNew = crop(cNew,[0 600]);
% cNew = xcorr(cNew,[100 300]);
% cNew = adjusttrig(cNew);
% plot(cNew,'wig',0.6)
% title('Filtered and corrected for instrument response','FontSize',16);
% print(gcf,'-dpsc2','demo_corrected.ps');
% 
% cFilt = correlation(wFilt);
% cNew = crop(cFilt,[0 600]);
% plot(cFilt,'wig',.6)
% title('Filtered only (30-5 s)','FontSize',16);
% print(gcf,'-dpsc2','demo_filtered.ps');
% 
% c = correlation(w);
% cNew = crop(c,[0 600]);
% plot(c,'wig',.6)
% title('Raw','FontSize',16);
% print(gcf,'-dpsc2','demo_raw.ps');
% 
% 
