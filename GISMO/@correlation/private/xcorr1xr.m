function d = xcorr1xr(d,style)

% This function performs cross correlations in sets by correlating one
% trace against a row of traces at once. Generally it is faster than the
% one at a time implimentation. All steps are included in this function.
% That is, no calls to the Matlab built-in xcorr are used.

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks


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
    
    
    if style == 1       % WITH POLYNOMIAL INTERPOLATION
        [maxtest,indx1] = max(corr(2:end-1,:));
        [mm,nn] = size(corr);
        indx2 = (indx1+1) + mm*[0:nn-1];                 % convert to matrix index
        lag = repmat( l , 1 , size(corr,2) );
        lagM   = lag([ indx2-1 ; indx2 ; indx2+1 ]) + repmat(pretrig(cols)'-pretrig(n)',3,1);
        corrM  = corr([ indx2-1 ; indx2 ; indx2+1 ]);
        for z = 1:numel(cols)
            p = polyfit( lagM(:,z) , corrM(:,z) , 2 );
            d.L(n,cols(z))  = -0.5*p(2)/p(1);
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


