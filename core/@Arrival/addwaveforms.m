function arrivalobj = addwaveforms(arrivalobj, datasourceobj, pretrigsecs, posttrigsecs);
%addwaveforms Add waveform objects corresponding to arrivals
%   addwaveforms will attempt to add a waveform object corresponding to
%   each arrival row in an Arrival object. It is added as a field to the
%   structure misc_fields.
%   
%   Usage:
%       arrivalobj = arrivalobj.addwaveforms(datasourceobj, pretrigsecs, posttrigsecs)
%   or:
%       arrivalobj = arrivalobj.addwaveforms(waveformobj, pretrigsecs, posttrigsecs)
%
%   Example:
%       dbpath = '/raid/data/sakurajima/db';
%       ds = datasource('antelope', dbpath);
%       arrivalobj = Arrival.retrieve('antelope', dbpath);
%       pretrigsecs = 5;
%       posttrigsecs = 5;
%       arrivalobj = arrivalobj.addwaveforms(ds, pretrigsecs, posttrigsecs)
%
    Na = numel(arrivalobj.time);
    disp(sprintf('Adding waveforms to all %d arrivals in Arrival object',Na));
    w = [];
    numsuccess=0;

    for c=1:Na
        ctag = ChannelTag(arrivalobj.channelinfo(c));
        snum = arrivalobj.time(c) - pretrigsecs/86400;
        enum = arrivalobj.time(c) + posttrigsecs/86400;
        if strcmp(class(datasourceobj),'waveform')
            index = match_channel(ctag, get(datasourceobj,'channelinfo') );
            neww = extract(datasourceobj(index),'time',snum,enum);
        else
%         try
            neww = waveform(datasourceobj, ctag, snum, enum);
        end
        
        if isempty(neww)
            error('Blank waveform')
        end
        w = [w neww];
        fprintf('.');
        numsuccess = numsuccess + 1;
%         catch
%             w = [w waveform()];
%             fprintf('x');
%         end
        if mod(c,30) == 0
            fprintf('\nDone %d out of %d\n',c, Na);
        end

    end
    arrivalobj.waveforms = clean(w');
    fprintf('\n(added %d of %d waveforms successfully)\n', numsuccess,  numel(arrivalobj.time));   

end

function index=match_channel(chaninfo, chaninfo_list)
    index=0;
    for c=1:numel(chaninfo_list)
        pattern = chaninfo.string();
        if strcmp(pattern(end-2),'_') % take care of when the location has changed between waveform and arrival
            pattern = pattern(1:end-3);
        end
        result=strfind(chaninfo_list{c},pattern);
        if ~isempty(result)
            index=result;
            break;
        end
    end
end

