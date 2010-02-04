function d = xcorrrow(d,c,index)

% This function performs cross correlations one trace against a full row of
% traces at once. Generally this routine will take twice as long as the 1xr
% for the full matrix. However it has the advantage of filling the entire
% correlation matrix instead of just the upper triangle. This is useful
% when the correlation and lag values of just a few traces need to be
% calculated within a much larger correlation object.

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


% CREATE MATRICES IF NEEDED
nn = get(c,'traces');
if (size(c.C,1) == 0)
    c.C = nan(nn);
end
if (size(c.L,1) == 0)
    c.L = nan(nn);
end


% do not overwrite matrices if they are only being added to
if size(c.C,1)==0
    d.C = eye(length(d.trig),'single');
    eraseC = 1;
else
    d.C = c.C;
    eraseC = 0;
end

if size(c.L,1)==0
    d.L = zeros(length(d.trig),'single');
    eraseL = 1;
else
    d.L = c.L;
    eraseL = 0;
end


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
for n = index
    cols = 1:N;
    % multiply fourier series and transform back to time domain
    CC = (X(:,n) * ones(1,length(cols))) .* Xc(:,cols);
    corr = ifft(CC);
    corr = [corr(end-M+2:end,:);corr(1:M,:)];

     % USE POLYNOMIAL INTERPOLATION
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
    % DON'T USE POLYNOMIAL INTERPOLATION
%    [maxval,indx1] = max(corr);
%    d.C(n,cols) = maxval .* wcoeff(n) .* wcoeff(cols);   % normalized maximum correlation
%    d.L(n,cols) = l(indx1) + (pretrig(cols) - pretrig(n)); % lag in seconds
end

% FILL IN OTHER HALF OF MATRIX
d.C(:,index) = d.C(index,:)';

if eraseL
    d.L = [];
else 
    d.L(:,index) = -1* d.L(index,:)';
end


if eraseC
    d.C = [];
else 
    d.C(:,index) = d.C(index,:)';
end



