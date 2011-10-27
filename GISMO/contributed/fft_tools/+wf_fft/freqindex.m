function W = freqindex(W,varargin)

% WAVEFORM = FREQINDEX(WAVEFORM) calculates the frequency index of a waveform.
% The FI is stored as a new field called FFT_FI. This function must be run after 
% WF_FFT.COMPUTE so that the necessary spectral fields exist in advance
%
% WAVEFORM = FREQINDEX(WAVEFORM,1) includes a plot of the waveform, and the 
% frequency spectrum with the FI frequency bins shaded by their appropriate
% heights. If WAVEFORM is a vector, plots will only be included for the
% first five waveforms. This is a bit ad hoc, but it prevents accidental
% plotting of thousands of waveforms. To plot specific waveforms one can
% always use freqindex(w(n)) where n is the index of the nth waveform.
%
% See also wf_fft.compute wf_fft.plot

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date: 2010-02-04 11:51:43 -0900 (Thu, 04 Feb 2010) $
% $Revision: 178 $


DOPLOT = 0;
if length(varargin) == 1
    DOPLOT = varargin{1};
end


% LOOP THROUGH WAVEFORMS (INEFFICIENT CODE!)
for i = 1:length(W)
    w = W(i);


    % GET FFT
    %W(i) = demean(W(i));
    %W(i) = wf_fft(W(i));
    F = get(W(i),'FFT_FREQ');
    A  = get(W(i),'FFT_AMP');
    if isempty(F) || isempty(A)
    	%W(i) = wf_fft.compute(W(i));
        error(['Trace ' num2str(i) ' does not have FFT_FREQ or FFT_AMP fields. Run WF_FFT.COMPUTE before WF_FFT.FREQINDEX' ]);
    end
    %A = A .* A;
    j = find(F >= 1 & F <= 2);
    Al = mean(A(j));
    j = find(F >= 10 & F <= 20);
    Ah = mean(A(j));
    fi = log10(Ah/Al);
    W(i) = addfield(W(i),'FFT_FI',fi);
    
    % PLOT IT
    if DOPLOT && i<=5

        figure('Color','w');
        set(gcf,'DefaultAxesFontSize',14);

        subplot(2,1,1);
        plot(w);
        title(datestr(get(w,'START'),31));

        subplot(2,1,2);
        hold on;
        fill( [1 1 2 2] , [0 Al Al 0] , [.7 .7 .7]);
        fill( [10 10 20 20] , [0 Ah Ah 0] , [.7 .7 .7]);
        plot( F , A , 'r-' );
        xlabel('Frequency (Hz)');
        ylabel('Power');
        set(gca,'XScale','Log');
        grid on; box on;
        xlim([0.1 50]);
        title(['Frequency index: ' num2str(fi,'%5.2f')]);

    end

end
