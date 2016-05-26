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
%     sta         % station
%     chan        % channel
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
%   REDUCED:    a structure that is set is data are "reduced", i.e. corrected
%               for geometric spreading (and possibly attenuation)
%               Has 4 fields:
%                   REDUCED.Q = the value of Q used to reduce the data
%                   (Inf by default, which indicates no attenuation)
%                   REDUCED.SOURCELAT = the latitude used for reducing the data
%                   REDUCED.SOURCELON = the longitude used for reducing the data
%                   REDUCED.STATIONLAT = the station latitude
%                   REDUCED.STATIONLON = the station longitude
%                   REDUCED.DISTANCE = the distance between source and
%                   station in km
%                   REDUCED.WAVETYPE = the wave type (body or surface)
%                   assumed
%                   REDUCED.F = the frequency used for surface waves
%                   REDUCED.WAVESPEED = the S wave speed
%                   REDUCED.ISREDUCED = True if the data are reduced
%   UNITS:  the units of the data, e.g. nm / sec.
%   USE: use this rsam object in plots?
%   FILES: structure of files data is loaded from

% AUTHOR: Glenn Thompson, Montserrat Volcano Observatory
% $Date: $
% $Revision: $

    properties(Access = public)
        dnum = [];
        data = []; % 
        measure = 'mean';
        seismogram_type = 'raw';
        %reduced = struct('Q', Inf, 'sourcelat', NaN, 'sourcelon', NaN, 'distance', NaN, 'waveType', '', 'isReduced', false, 'f', NaN, 'waveSpeed', NaN, 'stationlat', NaN, 'stationlon', NaN); 
        units = 'counts';
        %use = true;
        files = '';
        sta = '';
        chan = '';
        snum = -Inf;
        enum = Inf;
        %spikes = []; % a vector of rsam objects that describe large spikes
        % in the data. Populated after running 'despike' method. These are
        % removed simultaneously from the data vector.
        %transientEvents = []; % a vector of rsam objects that describe
        % transient events in the data that might correspond to vt, rf, lp
        % etc. Populated after running 'despike' method with the
        % 'transientEvents' argument. These are not removed from the data
        % vector, but are instead returned in the continuousData vector.
        %continuousData = []; % 
        %continuousEvents = []; % a vector of rsam objects that describe tremor

    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = public)

        function self=rsam(dnum, data, varargin)
            if nargin==0
                return;
            end
            
            if nargin>1
                self.dnum = dnum;
                self.data = data;
                if nargin>2
                   classFields = {'sta','chan','measure','seismogram_type','units','snum','enum'};
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
% % %         function result=snum(self)
% % %             result = nanmin(self.dnum);
% % %         end
% % %         function result=enum(self)
% % %             result = nanmax(self.dnum);
% % %         end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Prototypes
        self = findfiles(self, file)
        self = load(self)
        handlePlot = plot(rsam_vector, varargin)
        save(self, filepattern)
        toTextFile(self, filepath)
        [aw,tt1, tt2, tmc, mag_zone]=bvalue(this, mcType, method)
        [lambda, r2] = duration_amplitude(self, law, min_amplitude, mag_zone)
        s=extract(self, snum, enum)
        fs = Fs(self)
        self = medfilt1(self, nsamples_to_average_over)
        w=getwaveform(self, datapath)
        %scrollplot(s)
        %plotyy(obj1, obj2, varargin)
        %self = reduce(self, waveType, sourcelat, sourcelon, stationlat, stationlon, varargin)
        %[self, timeWindow] = tremorstalta(self, varargin)
        %self = resample(self, varargin)
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%         function save2wfmeastable(self, dbname)
%             datascopegt.save2wfmeas(self.scnl, self.dnum, self.data, self.measure, self.units, dbname);
%         end    
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         function self = remove_calibs(self)    
%              for c=1:numel(self)
%             % run twice since there may be two pulses per day
%                     self(c).data = remove_calibration_pulses(self(c).dnum, self(c).data);
%                     self(c).data = remove_calibration_pulses(self(c).dnum, self(c).data);
%              end
%         end
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         function self = correct(self)    
%              ref = 0.707; % note that median, rms and std all give same value on x=sin(0:pi/1000:2*pi)
%              for c=1:numel(self)
%                 if strcmp(self(c).measure, 'max')
%                     self(c).data = self(c).data * ref;
%                 end
%                 if strcmp(self(c).measure, '68')
%                     self(c).data = self(c).data/0.8761 * ref;
%                 end
%                 if strcmp(self(c).measure, 'mean')
%                     self(c).data = self(c).data/0.6363 * ref;
%                 end 
%              end
%         end
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%         function self=rsam2energy(self, r)
%             % should i detrend first?
%             e = energy(self.data, r, get(self.scnl, 'channel'), self.Fs(), self.units);
%                 self = set(self, 'energy', e);
%         end
%         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
%         function w=rsam2waveform(self)
%             w = waveform;
%             w = set(w, 'station', self.sta);
%             w = set(w, 'channel', self.chan);
%             w = set(w, 'units', self.units);
%             w = set(w, 'data', self.data);
%             w = set(w, 'start', self.snum);
%             %w = set(w, 'end', self.enum);
%             w = set(w, 'freq', 1/ (86400 * (self.dnum(2) - self.dnum(1))));
%             w = addfield(w, 'reduced', self.reduced);
%             w = addfield(w, 'measure', self.measure);
%         end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 

    end % end of dynamic methods
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    methods(Access = public, Static)
        self = read_bob_file(varargin)
        makebobfile(outfile, days)
        self = loadbobfile(infile, snum, enum)
        %self = loadwfmeastable(sta, chan, snum, enum, measure, dbname)
        %[data]=remove_calibration_pulses(dnum, data)
        %[rsamobjects, ah]=plotrsam(sta, chan, snum, enum, DATAPATH)
        %rsamobj = detectTremorEvents(stationName, chan, DP, snum, enum, ...
        % spikeRatio, transientEventRatio, STA_minutes, LTA_minutes, ...
        % stepsize, ratio_on, ratio_off, plotResults)
    end

end % classdef

