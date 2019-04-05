function w = gcf2waveform(filepath, channelinfo, units)
%GCF2WAVEFORM Read a single Guralp GCF file and convert to a GISMO waveform
%object
%   w = GCF2WAVEFORM(filepath, channelinfo, units) Guralp digitizers record format
%   in "Guralp compressed format" or GCF files. These are normally streamed
%   using the Guralp "Scream!" application. But for seismic analysis, we
%   generally want to read these in as waveform objects, or convert them to
%   miniseed or sac format, which are more widely supported.
%
%   Inputs:
%       filepath    = the full file path to the GCF file
%       channelinfo = a ChannelTag object describing the NET.STA.LOC.CHAN
%                     for this GCF file (default: empty ChannelTag)
%       units       = physical units of the GCF data, e.g. "nm / sec". 
%                     Default is "Counts".
% 
%   Uses the function READGCFFILE provided by Guralp.
%
%
%   Examples:
%     gcffile = '/raid/data/NICARAGUA/MBMG/6776n2/20160220_2300.gcf';
%     channelinfo = ChannelTag('NU.MBMG..HHN');
%     w = GCF2WAVEFORM(gcffile, channelinfo);
%     figure;
%     plot(w,'xunit','date')
%
%   See also: READGCFFILE, CHANNELTAG, WAVEFORM

% Glenn Thompson 2019/04/05


    if exist('filepath','var')
        if exist(filepath, 'file')
            [SAMPLES,STREAMID,SPS,tStart] = readgcffile(filepath);
            if ~exist('channelinfo','var')
                channelinfo = ChannelTag('...');
            end
            if ~exist('units','var')
                units = 'Counts';
            end            
            w = waveform(channelinfo, SPS, tStart, SAMPLES, units);
        else
            error(sprintf('GCF file %s does not exist',filepath));
        end
    else
        error(sprintf('Usage: %s(''/path/to/gcffile'')',mfilename));
    end
end
