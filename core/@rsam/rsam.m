classdef rsam 
% RSAM Seismic Amplitude Measurement class constructor, version 1.0.
%
% RSAM is a generic term used here to represent any continuous data
% sampled at a regular time interval (usually 1 minute). This is a 
% format widely used within the USGS Volcano Hazards Programme which
% originally stems from the RSAM system (Endo & Murray, 1989)
%
% Written for loading and plotting RSAM data at the Montserrat Volcano 
% Observatory (MVO), and then similar measurements derived from the VME 
% "ltamon" program and ampengfft and rbuffer2bsam which took Seisan 
% waveform files as input. 
%
% RSAM data are historically stored in "BOB" format, which consists
% of a 4 byte floating number for each minute of the year, for a 
% single station-channel.
%
% s = rsam() creates an empty RSAM object.
%
% s = rsam(dnum, data, 'sta', sta, 'chan', chan, 'measure', measure, 'seismogram_type', seismogram_type, 'units', units)
%
%     dnum        % the dates/times (as datenum) corresponding to the start
%                   of each time window
%     data        % the value at each dnum
%     ctag        % ChannelTag
%     measure     % statistical measure, default is 'mean'
%     seismogram_type % e.g. 'velocity' or 'displacement', default is 'raw'
%     units       % units to label y-axis, e.g. 'nm/s' or 'nm' or 'cm2', default is 'counts'
%
% Example 1:
%
%     t = [0:60:1440]/1440;
%     y = randn(size(t)) + rand(size(t));
%     s = rsam(t, y);
%
% Example 2:
%     dp = 'INETER_DATA/RSAM/MOMN2015.DAT';
%     s = rsam.read_bob_file('file', dp, 'snum', datenum(2015,1,1), ...
%           'enum', datenum(2015,2,1), 'sta', 'MOMN', 'units', 'Counts')
%
% Example 3:
%     dp = 'INETER_DATA/RSAM/SSSSYYYY.DAT';
%     s = rsam.read_bob_file('file', dp, 'snum', datenum(2015,1,1), ...
%           'enum', datenum(2015,2,1), 'sta', 'MOMN', 'units', 'Counts')
%

% See also: read_bob_file, oneMinuteData, waveform>rsam
%
% % ------- DESCRIPTION OF FIELDS IN RSAM OBJECT ------------------
%   DNUM:   a vector of MATLAB datenum's
%   DATA:   a vector of data (same size as DNUM)
%   MEASURE:    a string describing the statistic used to compute the
%               data, e.g. "mean", "max", "std", "rms", "meanf", "peakf",
%               "energy"
%   SEISMOGRAM_TYPE: a string describing whether the RSAM data were computed
%                    from "raw" seismogram, "velocity", "displacement"
%   UNITS:  the units of the data, e.g. nm / sec.
%   FILES: structure of files data is loaded from

% AUTHOR: Glenn Thompson, Montserrat Volcano Observatory
% $Date: $
% $Revision: $

    properties(Access = public)
        dnum = [];
        data = []; 
        measure = 'mean';
        seismogram_type = '';
        units = 'counts';
        files = '';
        ChannelTag = ChannelTag();
        request = struct();
    end
    
    properties(Dependent)
        snum
        enum
        sta
        chan
        sampling_interval
        stats
    end
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %methods(Access = public)
    methods
        function self=rsam(dnum, data, varargin)
            if nargin==0
                return;
            end
            
            if nargin>1
                self.dnum = dnum;
                self.data = data;
                if nargin>2
                   classFields = {'ChannelTag','measure','seismogram_type','units'};
                   p = inputParser;
                   for n=1:numel(classFields)
                      p.addParameter(classFields{n}, self.(classFields{n}));
                   end
                   p.parse(varargin{:});
                   
                   % modify class values based on user-provided values
                   for n = 1:numel(classFields)
                      self.(classFields{n}) = p.Results.(classFields{n});
                   end
                end
            end
            
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function r = get.snum(self)
            r = [];
            for c=1:numel(self)
                r(c) = nanmin(self(c).dnum);
            end
        end
        
        function r = get.enum(self)
            r = [];
            for c=1:numel(self)
                r(c) = nanmax(self(c).dnum);
            end
        end   
        
        function r = get.sta(self)
            r = {};
            for c=1:numel(self)
                r{c} = self(c).ChannelTag.station;
            end     
        end        

        function r = get.chan(self)
            r = {};
            for c=1:numel(self)
                r{c} = self(c).ChannelTag.channel;
            end     
        end       
        
        function r = get.sampling_interval(self)
            r = [];
            for c = 1:length(self)
                l = numel(self(c).dnum);
                s = self(c).dnum(2:l) - self(c).dnum(1:l-1);
                r(c) = (median(s)*86400);
            end
        end     
        
        function stats = get.stats(self)
            for c=1:numel(self)
                stats(c) = struct;
                stats(c).min = nanmin(self(c).data);
                stats(c).max = nanmax(self(c).data);
                stats(c).mean = nanmean(self(c).data);
                stats(c).median = nanmedian(self(c).data);
                stats(c).rms = rms(self(c).data);
                stats(c).std = nanstd(self(c).data);
            end
        end
               
        
        % Prototypes
        self = findfiles(self, filepattern)
        self = load(self, file)
        s=extract(self, snum, enum)
        self = medfilt1(self, nsamples_to_average_over)
        handlePlot = plot(rsam_vector, varargin)
        plot_panels(self);
        w = rsam2waveform(self);
        save_to_bob_file(self, filepattern)
        save_to_text_file(self, filepath)       

    end % end of dynamic methods
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    methods(Access = public, Static)
        self = read_bob_file(varargin)
        make_bob_file(outfile, days)
    end

end % classdef

