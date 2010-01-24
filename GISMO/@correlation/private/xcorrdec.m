function d = xcorrdec(d)

% Same algorithm as xcorr1xr, except this function decomposes the complex
% numbers into their real and imaginary parts before doing the math.

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks

% PREP NECESSARY TERMS
[M,N] = size(d.w);
pretrig = 86400*(d.trig-d.start);   % time between trace start and trigger
l = (1./d.Fs)*[-M+1:M-1]';        % lag vector
wcoeff = 1./sqrt(sum(d.w.*d.w));
d.C = eye(length(d.trig),'single');
d.L = zeros(length(d.trig),'single');


% GET FFT OF TRACES
X = fft(d.w,2^nextpow2(2*M-1));
[MX,NX] = size(X);


% DECOMPOSE COMPLEX INTO REAL AND IMAG PARTS
Xr = real(X);
Xi = imag(X);


% TIME THE PROCESS
starttime = now;
tic;
t0 = cputime;
numcorr = ((length(d.trig))^2-length(d.trig))/2;
count = 0;

% LOOP THROUGH ROWS OF SIMILARITY MATRIX
i = sqrt(-1);
for n =1:N
    cols = n:N;
    % multiply fourier series and transform back to time domain
    
    % APPROACH NUMBER 1 (test time: 11.3, 11.2, 11.3 sec)
    %a = (Xr(:,n)*ones(1,length(cols))).*Xr(:,cols);
    %b = (Xr(:,n)*ones(1,length(cols))).*Xi(:,cols); 
    %c = (Xi(:,n)*ones(1,length(cols))).*Xr(:,cols);
    %d = (Xi(:,n)*ones(1,length(cols))).*Xi(:,cols);
    %CC = a - i*b + i*c - i*i*d;
    
    % APPROACH NUMBER 2 (test time: 11.4, 11.8, 11.6 sec)
    %ad = (Xr(:,n)*ones(1,length(cols))).*Xr(:,cols) + (Xi(:,n)*ones(1,length(cols))).*Xi(:,cols);
    %cb = (Xi(:,n)*ones(1,length(cols))).*Xr(:,cols) - (Xr(:,n)*ones(1,length(cols))).*Xi(:,cols);
    %CC = ad + i*cb;
    
    % APPROACH NUMBER 3 (test time: 16.2, 16.0, 15.8 sec)
    CC = (Xr(:,n)*ones(1,length(cols))).*Xr(:,cols) - i*(Xr(:,n)*ones(1,length(cols))).*Xi(:,cols) + i*(Xi(:,n)*ones(1,length(cols))).*Xr(:,cols) + (Xi(:,n)*ones(1,length(cols))).*Xi(:,cols);
    
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

