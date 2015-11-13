function w=antelope2waveform_test()
    dbpath = '/aerun/sum/db/archive/archive_2011/archive_2011_11_16';
    sta = '.*';
    sta = 'AKT';
    sta = '.*';
    %sta = 'AKT|CRAP|VIB';
    chan = 'HHZ.*';
    chan = 'HH.*';
    starttime = datenum2epoch(datenum('16-Nov-2011 16:29:00'));
    endtime = datenum2epoch(datenum('16-Nov-2011 16:43:24'));
%     dbexample_get_demodb_path;
%     dbpath = demodb_path;
%     sta = '.*';
%     chan = '.*';
%     starttime = [];
%     endtime = [];
     w=antelope.antelope2waveform(dbpath, sta, chan, starttime, endtime);
end

