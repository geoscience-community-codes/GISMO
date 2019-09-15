classdef Seisan_Catalog < Catalog
    properties
        aef = {}
        sfilepath = {}
        reldir = {}
        topdir = {}
        wavfilepath = {}
    end
    methods
        
        
        function self = Seisan_Catalog(varargin)
            % Blank constructor
            if nargin==0
                %return
            end
            % Call Catalog constructor
            self@Catalog(varargin{:});
        end
        
        
        function regress_energy_vs_amplitude(self, eventnum)
            % regress_energy_vs_amplitude(self, eventnum)
            figure;
            logamp=log10(self.aef{eventnum}.amp);
            logeng=log10(self.aef{eventnum}.eng);
            plot(logamp, logeng,'*');
            xlabel('log(Amplitude) (m/s)')
            ylabel('log(Energy) (J/kg)')
            p=polyfit(logamp, logeng,1)
            xlims=get(gca,'XLim');
            px=linspace(xlims(1),xlims(2));
            f=polyval(p,px)
            hold on
            plot(px,f)
            text(px(3),f(3),sprintf('log_{10}(E) = %.2f log_{10}(A) + %.2f',p(1),p(2)));
        end
        
        
        
        function regress_energy_vs_amplitude_all(self)
            % regress_energy_vs_amplitude_all(self)
            % A way to see how amplitude and energy of a signal computed
            % by ampengfft.c scale against each other for different event
            % types
            figure
            for eventnum=1:self.numberOfEvents
                k=findstr('rehlt',self.etype{eventnum});
                if k>0 & isfield(self.aef{eventnum},'amp')
                    logamp=log10(self.aef{eventnum}.amp);
                    logeng=log10(self.aef{eventnum}.eng);
                    p=polyfit(logamp, logeng,1);
                    hold on
                    warning off
                    switch k
                        case 1
                            plot(log10(median(logamp)),p(1),'r.');
                            continue
                        case 2
                            plot(log10(median(logamp)),p(1),'m.');
                            continue
                        case 3
                            plot(log10(median(logamp)),p(1),'b.');
                            continue
                        case 4
                            plot(log10(median(logamp)),p(1),'c.');
                            continue
                        case 5
                            plot(log10(median(logamp)),p(1),'g.');
                    end
                end

                
            end
            xlabel('log_{10}(median amplitude of event) (m/s)')
            ylabel('exponent of power law between amplitude and energy');
            warning on
        end        
        
        
        
        function self=addwaveforms(self)
            w=[];
            for eventnum=1:self.numberOfEvents
                thesewavfiles = cellstr(self.wavfilepath{eventnum});
                w0 = [];
                for wfnum=1:numel(thesewavfiles)
                    thiswavfile = [self.topdir{eventnum},thesewavfiles{wfnum}];
                    if exist(thiswavfile,'file')
                        w0 = [w0 waveform(thiswavfile,'seisan')];
                    else
                        disp(sprintf('%s not found',thiswavfile));
                    end
                end
                if numel(w0)>1
                    %disp('combining & appending')
                    w1=combine(w0);
                    w{eventnum} = w1;
                else
                    %disp('appending')
                    w{eventnum} = w0;
                end
            end
            self.waveforms = w; 
            % SCAFFOLD: self.waveforms here is populated. But on return to
            % the external function, it is not unless you do
            % cobj=cobj.addwaveforms().
        end
    end
    
end
        % SCAFFOLD also use durations (bbdur) and ampengfft info
        % Compute a magnitude from amp & eng, but need to know where
        % stations are. I can save these as MA and ME, to distinguish from
        % Ml, Ms, Mb, Mw if those exist
    