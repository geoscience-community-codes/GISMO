function d = xcorrrow(d,c,index)

%XCORRROW Cross correlation for one or more traces.
% D = XCORR1XR(D,C,STYLE) This private function performs cross correlations
% for a subset of traces. It differs from the XCORR1XR algorithm in that it
% fills both halves of the correlation matrix. While this is unnecessary
% when correlating all waveforms, it is necessary when doing just a subset
% of traces. This should be of little concern to most users. All steps are
% included in this function. That is, no calls to the Matlab built-in xcorr
% are used. This code is a little kludgy since it mixes both the original d
% structure (predates the internal use of waveform objects) with the later
% wave-based correlation objects. This is the reason it reads in both D and
% C arguments. STYLE denotes whether or not polynomial interpolation should
% be used to refine cross correlations to subsample precision.

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


% LOOP THROUGH ROWS OF SIMILARITY MATRIX
for n = index
    cols = 1:N;
    % multiply fourier series and transform back to time domain
    %CC = (X(:,n) * ones(1,length(cols))) .* Xc(:,cols);
    CC = repmat(X(:,n),1,length(cols)) .* Xc(:,cols);
    corr = ifft(CC);
    corr = corr([end-M+2:end,1:M],:);
        
    % USE POLYNOMIAL INTERPOLATION
    [maxtest,indx1] = max(corr(2:end-1,:));
    [mm,nn] = size(corr);
    indx2 = (indx1+1) + mm*[0:nn-1];     % convert to matrix index
    lag = repmat( l , 1 , size(corr,2) );  % replace size statement with nn
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



