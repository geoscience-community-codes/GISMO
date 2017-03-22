function arrivalobj = addwaveforms(arrivalobj, datasourceobj, pretrigsecs, posttrigsecs);
%addwaveforms Add waveform objects corresponding to arrivals
%   addwaveforms will attempt to add a waveform object corresponding to
%   each arrival row in an Arrival object. It is added as a field to the
%   structure misc_fields.
%   
%   Usage:
%       arrivalobj = arrivalobj.addwaveforms(datasourceobj, pretrigsecs, posttrigsecs)
%
%   Example:
%       dbpath = '/raid/data/sakurajima/db';
%       ds = datasource('antelope', dbpath);
%       arrivalobj = Arrival.retrieve('antelope', dbpath);
%       pretrigsecs = 5;
%       posttrigsecs = 5;
%       arrivalobj = arrivalobj.addwaveforms(ds, pretrigsecs, posttrigsecs)
%
    disp('Adding waveforms to arrival object');
    w = [];
    numsuccess=0;
    for c=1:numel(arrivalobj.time)
        ctag = ChannelTag(arrivalobj.channelinfo(c));
        snum = arrivalobj.time(c) - pretrigsecs/86400;
        enum = arrivalobj.time(c) + posttrigsecs/86400;
        try
            w = [w waveform(datasourceobj, ctag, snum, enum)];
            fprintf('.');
            numsuccess = numsuccess + 1;
        catch
            w = [w waveform()];
            fprintf('x');
        end
    end
    arrivalobj.waveforms = w';
    fprintf('\n(added %d of %d waveforms successfully)\n', numsuccess,  numel(arrivalobj.time));   

end

