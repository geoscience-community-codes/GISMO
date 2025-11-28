function w = gcf2waveform(filepath, channelinfo, units)
%GCF2WAVEFORM Read a single Guralp GCF file and convert to a GISMO waveform
%
%   w = gcf2waveform(filepath, channelinfo, units)
%
%   filepath    : full path to GCF file
%   channelinfo : ChannelTag object (optional)
%   units       : physical units (default: 'Counts')
%
%   Requires: readgcffile (Guralp)

    narginchk(1,3);

    if ~exist(filepath,'file')
        error('GCF2WAVEFORM:FileNotFound', ...
              'GCF file does not exist: %s', filepath);
    end

    if nargin < 2 || isempty(channelinfo)
        channelinfo = ChannelTag('...');
    end

    if nargin < 3 || isempty(units)
        units = 'Counts';
    end

    [SAMPLES, STREAMID, SPS, tStart] = readgcffile(filepath); %#ok<ASGLU>

    % Ensure column vector
    SAMPLES = double(SAMPLES(:));

    w = waveform(channelinfo, SPS, tStart, SAMPLES, units);
end
