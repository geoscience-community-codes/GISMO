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
% Examples:
%
%     t = [0:60:1440]/1440;
%     y = randn(size(t)) + rand(size(t));
%     s = rsam(t, y);
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
        reduced = struct('Q', Inf, 'sourcelat', NaN, 'sourcelon', NaN, 'distance', NaN, 'waveType', '', 'isReduced', false, 'f', NaN, 'waveSpeed', NaN, 'stationlat', NaN, 'stationlon', NaN); 
        units = 'counts';
        use = true;
        files = '';
        sta = '';
        chan = '';
        snum = -Inf;
        enum = Inf;
        spikes = []; % a vector of rsam objects that describe large spikes
        % in the data. Populated after running 'despike' method. These are
        % removed simultaneously from the data vector.
        transientEvents = []; % a vector of rsam objects that describe
        % transient events in the data that might correspond to vt, rf, lp
        % etc. Populated after running 'despike' method with the
        % 'transientEvents' argument. These are not removed from the data
        % vector, but are instead returned in the continuousData vector.
        continuousData = []; % 
        continuousEvents = []; % a vector of rsam objects that describe tremor

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
                          
                    [self.sta, self.chan, self.measure, self.seismogram_type, self.units, self.snum, self.enum] = ...
                        matlab_extensions.process_options(varargin, 'sta', self.sta, ...
                        'chan', self.chan, 'measure', self.measure, 'seismogram_type', self.seismogram_type, 'units', self.units, 'snum', self.snum, 'enum', self.enum);
            
                end
            end
        end
        
        % Prototypes
        save(self);
        plot(self, varagin);
        resample(self, varargin);
        despike(self, spiketype, maxRatio);
        [lambda, r2] = duration_amplitude(self, law, min_amplitude, mag_zone);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
        function fs = Fs(self)
            for c=1:length(self)
                l = length(self(c).dnum);
                s = self(c).dnum(2:l) - self(c).dnum(1:l-1);
                fs(c) = 1.0/(median(s)*86400);
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function s=subset(self, snum, enum)
            for c=1:numel(self)
                s(c) = self(c);
                i = find(self(c).dnum>=snum & self(c).dnum <= enum);
                s(c).dnum = self(c).dnum(i);
                s(c).data = self(c).data(i);
            end
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
        function toTextFile(self, filepath)
           % toTextFile(filepath);
            if numel(self)>1
                warning('Cannot write multiple RSAM objects to the same file');
                return
            end
            
            fout=fopen(filepath, 'w');
            for c=1:length(self.dnum)
                fprintf(fout, '%15.8f\t%s\t%5.3e\n',self.dnum(c),datestr(self.dnum(c),'yyyy-mm-dd HH:MM:SS.FFF'),self.data(c));
            end
            fclose(fout);
        end
    end % end of dynamic methods
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    methods(Access = public, Static)
        self = loadwfmeastable(sta, chan, snum, enum, measure, dbname);
        makebobfile(outfile, days);
        rsamobj = detectTremorEvents(stationName, chan, DP, snum, enum, spikeRatio, transientEventRatio, STA_minutes, LTA_minutes, stepsize, ratio_on, ratio_off, plotResults);
        rsamobj = load(varargin);
        test();
    end

end % classdef

