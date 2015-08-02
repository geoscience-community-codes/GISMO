function d = xcorr1xr(d)

% This function performs cross correlations of one correlation object
% against another. Traces from the second object are added and correlated
% one by one with the first in sets by correlating one trace against a row
% of traces at once. Generally it is faster than the one at a time
% implimentation. All steps are included in this function.
% That is, no calls to the Matlab built-in xcorr are used.

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
    CC = (X(:,n) * ones(1,length(cols))) .* Xc(:,cols);
    corr = ifft(CC);
    corr = [corr(end-M+2:end,:);corr(1:M,:)];
    
    % save only max correlation value
    [maxval,index] = max(corr);
    d.C(n,cols)=maxval .* wcoeff(n) .* wcoeff(cols);   % normalized maximum correlation
    d.L(n,cols)=l(index) + (pretrig(cols) - pretrig(n)); % lag in seconds
    
    if (n==100) | (n==1000)
        tclock = toc/86400;
        completed = sum(N-n:N-1)/((N*N-N)/2);
        fin = datestr(starttime + tclock/completed,16);
        disp([num2str(100*completed,'%2.0f') '% completed. Estimated completion at ' fin '...']);
    end;
end


% FILL LOWER TRIANGULAR PART OF MATRICES
d.C = d.C + d.C' - eye(size(d.C));
d.L = d.L - d.L';


% DISPLAY RUN TIMES
tclock = toc;
tcpu = cputime-t0;
disp(['Clock time to complete correlations: ' num2str(tclock,'%5.1f') ' s']);
disp(['CPU time to complete correlations:   ' num2str(tcpu,'%5.1f') ' s']);




