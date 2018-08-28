function name=subclass2longname(subclass)
switch(subclass)
case 'r', name='rockfall';
case 'e', name='lp-rockfall';
case 'l', name='long period';
case 'h', name='hybrid';
case 't', name='volcano-tectonic';
case 'R', name='regional';
case 'D', name='teleseismic';
case 'u', name='unknown';
case '*', name='seismic';
otherwise, name='?';
end
end
