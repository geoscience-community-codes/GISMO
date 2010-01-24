function [c,t,i,CC,LL] = interferogram(c,varargin)

% C = INTERFEROGRAM(C)
% This function calculates an interferogram from the waveforms in a 
% correlation object against the a single "master" trace.
%
% The routine interatively selects a narrow time window on all traces,
% carries out a cross-correlation, and stores the maximum correlation value
% and the time lag necessary to acheive this best fit for each time window.
% All cross correlations include sub-sample interpolation of lag values
% (see HELP XCORR for details). The results are two matrices of correlation
% value and lag time. These can be plotted with the C-INTERFER and
% L-INTERFER options in correlation plot.
%
% [C,TIME,INDEX,MAXCORR,LAG] = INTERFEROGRAM(C,...) In addition to the
% correlation object, this use returns a vector of window center times
% relative to trigger times (1xM), a vector of trace indices (Nx1), a
% matrix of maximum correlation values (NxM), and a matrix of optimum lag
% times (NxM). These values can be used to generate a custom interferogram
% figure, for example:
%    imagesc(TIME,INDEX,MAXCORR)
%
% [C ...] = INTERFEROGRAM(C,WIDTH) Specify the half width of the time window
% explicitly. Default value is 1/20 of the mean trace length.
%
% [C ...] = INTERFEROGRAM(C,WIDTH,TIMESTEP) Specify the timestep interval
% explicitly. If TIMESTEP is a scalar, it is treated as the interval
% between adjacent time windows. If TIMESTEP is a vector, the values are
% treated as the specific center time times of each window.
%
% [C ...] = INTERFEROGRAM(C,WIDTH,TIMESTEP,TRACENUM) Specify which trace
% should be treated as the master trace against which all correlation
% values will be based.
% 
% ** NOTE ABOUT DATA STORAGE **
% The interferogram routine by default places the four output terms
% (TIME,INDEX,MAXCORR and LAG) into supplimental fields in the waveform
% object which holds the first trace. This is embarassingly clunky. However
% it works and allows the data to be passed directly to the plotting
% routine. These terms can always be accessed by extracting them from the
% first waveform using the field names INTERFEROGRAM_TIME,
% INTERFEROGRAM_INDEX, INTERFEROGRAM_MAXCORR, INTERFEROGRAM_LAG. Because of
% this ad hoc structure though, in many cases it may be better to simply
% save the data straight out of the routine and handle it yourself. It is
% automatically placed in the first waveform however to fascilitate a quick
% plotting option.

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks


% GET INPUT PARAMETERS
if ~isa(c,'correlation')
    disp('First input parameter must be a correlation object');
end


% TEST FOR ALIGNED TRACES
if ~check(c,'OFFSET')
   disp('Data not uniformly aligned around triggers. Consider using CROP function.'); 
end


% SET WINDOW WIDTH
srt_offset = ( get(c,'Start') - get(c,'Trig') ) * 86400;
end_offset = ( get(c,'End') - get(c,'Trig') ) * 86400;
if length(varargin)>=1
    width = varargin{1};
else
    width = ( mean(end_offset)-mean(srt_offset) ) / 20;
end


% SET TIME STEP
if length(varargin)>=2
    if length(varargin{2}) == 1
        tstep = varargin{2};
        t = mean(srt_offset) : tstep : mean(end_offset);
    else
        t = varargin{2};
    end
else
    tstep = ( mean(end_offset)-mean(srt_offset) ) / 50;
    t = mean(srt_offset) : tstep : mean(end_offset);
end


% SET MASTER TRACE
if length(varargin)==3
    trace = varargin{3};
else
    trace = get(c,'TRACES');
end


% CHECK INPUT TERMS
if length(varargin)>3
    error('Wrong number of inputs');
end


disp(['Time step: ' num2str(tstep,'%4.3f') '    Window width: ' num2str(width,'%4.3f') '    Reference trace no.: ' num2str(trace,'%2.0f') ]);


% CALC INTERFEROGRAM VOLUME
% FYI: 3D matrix order is (Y,X,Z)
n = size(get(c,'CORR'),1);
[T,N1,N2] = meshgrid(t,1:n,1:n);
CC = [];
LL = [];
times = [];
for i = 1:length(t);
    times = cat(1,times,t(i));
    if (mod(i,10)==1)
        disp(['Center of time window: ' num2str(t(i),'%4.3f') ' ...']);
    end
    ctmp = crop(c,t(i)-width,t(i)+width);
    ctmp = xcorr(ctmp,'row',trace);
    %CC(:,i,:) = get(ctmp,'CORR');
    %LL(:,i,:) = get(ctmp,'LAG');
    corr = get(ctmp,'CORR');
    lag  = get(ctmp,'LAG');
    CC(:,i) = corr(:,trace);
    LL(:,i) = lag(:,trace);
end;


% PLACE OUTPUT INTO FIRST WAVEFORM FIELD
i = [1:get(c,'TRACES')]';
c.W(1) = addfield(c.W(1),'Interferogram_index',i);
c.W(1) = addfield(c.W(1),'Interferogram_time',t);
c.W(1) = addfield(c.W(1),'Interferogram_maxcorr',CC);
c.W(1) = addfield(c.W(1),'Interferogram_lag',LL);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Original code which correlates and saves all traces against all traces
% Works great, but is computationally unnecessary
%
% 
% % CALC INTERFEROGRAM VOLUME
% % FYI: 3D matrix order is (Y,X,Z)
% n = size(get(c,'CORR'),1);
% [T,N1,N2] = meshgrid(t,1:n,1:n);
% CC = [];
% LL = [];
% times = [];
% for i = 1:length(t);
%     times = cat(1,times,t(i));
%     if (mod(i,10)==1)
%         disp(['Time step: ' num2str(t(i),'%4.3f') ' ...']);
%     end
%     ctmp = crop(c,t(i)-width,t(i)+width);
%     %ctmp = taper(ctmp);
%     ctmp = xcorr(ctmp);
%     CC(:,i,:) = get(ctmp,'CORR');
%     LL(:,i,:) = get(ctmp,'LAG');
% end;
%
% % PREPARE OUTPUT
% I = [];
% i = [1:get(c,'TRACES')]';
% t = times';
% CC = squeeze(CC(:,:,end));
% LL = squeeze(LL(:,:,end));
