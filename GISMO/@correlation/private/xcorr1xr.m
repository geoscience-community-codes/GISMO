function d = xcorr1xr(d,style)

%XCORR1XR Cross correlate 1 trace against all other traces at once.
% D = XCORR1XR(D,STYLE) This private function performs cross correlations
% in sets by correlating one trace against a row of traces at once.
% Generally it is faster than the one at a time implimentation. All steps
% are included in this function. That is, no calls to the Matlab built-in
% xcorr are used. This structure is grandfathered in from early versions of
% correlation which did use waveform objects. This structure is used only
% within cross correlation routines where trace data needs to be pulled out
% of waveform objects anyway. STYLE denotes whether or not polynomial
% interpolation should be used to refine cross correlations to subsample
% precision.

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


% PREP NECESSARY TERMS
[M,N] = size(d.w);
pretrig = 86400*(d.trig-d.start);   % time between trace start and trigger
l = (1./d.Fs)*[-M+1:M-1]';        % lag vector
% next two lines are equivalent ways to get normalization coefficients
wcoeff = 1./sqrt(sum(d.w.*d.w));
%for i = 1:size(d.w,2), wcoeff(i) = 1./norm(d.w(:,i)); end;
d.C = eye(length(d.trig),'single');
d.L = zeros(length(d.trig),'single');


% GET FFT OF TRACES
X = fft(d.w,2^nextpow2(2*M-1));
Xc = conj(X);
[MX,NX] = size(X);


% TIME THE PROCESS
starttime = now;
tic;
t0 = cputime;
numcorr = ((length(d.trig))^2-length(d.trig))/2;
count = 0;


% LOOP THROUGH ROWS OF SIMILARITY MATRIX
for n =1:N
    cols = n:N;
    % multiply fourier series and transform back to time domain
    CC = repmat(X(:,n),1,length(cols)) .* Xc(:,cols);
    corr = ifft(CC);
    corr = corr([end-M+2:end,1:M],:);
    
    
    if style == 1       % USE POLYNOMIAL INTERPOLATION
        [maxtest,indx1] = max(corr(2:end-1,:));
        [mm,nn] = size(corr);
        indx2 = (indx1+1) + mm*[0:nn-1];                 % convert to matrix index
        lag = repmat( l , 1 , size(corr,2) );
        lagM   = lag([ indx2-1 ; indx2 ; indx2+1 ]) + repmat(pretrig(cols)'-pretrig(n)',3,1);
        corrM  = corr([ indx2-1 ; indx2 ; indx2+1 ]);
        for z = 1:numel(cols)
            p = polyfit( lagM(:,z) , corrM(:,z) , 2 );
            Ltmp = -0.5*p(2)/p(1);
            if abs(Ltmp)<eps('single')
                Ltmp = 0;
            end
            d.L(n,cols(z))  = Ltmp;
            d.C(n,cols(z)) = polyval( p , d.L(n,cols(z)) ) .* wcoeff(n) .* wcoeff(cols(z));
        end
    elseif style == 0     % NO POLYNOMIAL INTERPOLATION
        [maxval,indx1] = max(corr);
        d.C(n,cols) = maxval .* wcoeff(n) .* wcoeff(cols);   % normalized maximum correlation
        d.L(n,cols) = l(indx1) + (pretrig(cols) - pretrig(n)); % lag in seconds
    end

    if (n==100) | (n==1000)
        tclock = toc/86400;
        completed = sum(N-n:N-1)/((N*N-N)/2);
        fin = datestr(starttime + tclock/completed,16);
        if completed<0.5
            disp([num2str(100*completed,'%2.0f') '% completed. Estimated completion at ' fin '...']);
        end;
    end;
end


% REPLACE NaNs WITH ZEROS
f = find(isnan(d.C));
d.C(f) = 0;



% FILL LOWER TRIANGULAR PART OF MATRICES
d.C = d.C + d.C' - eye(size(d.C));
d.L = d.L - d.L';


% DISPLAY RUN TIMES
tclock = toc;
tcpu = cputime-t0;
if tclock>20
    disp(['Clock time to complete correlations: ' num2str(tclock,'%5.1f') ' s']);
    disp(['CPU time to complete correlations:   ' num2str(tcpu,'%5.1f') ' s']);
end;


