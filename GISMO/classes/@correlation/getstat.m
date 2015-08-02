function c=getstat(c)

% c = GETSTAT(c)
% This routine distills the results of a cross correlation into statistics
% by trace. These statistics are stored in an Mx? matrix in the STAT field
% of the correlation object, where M is the number of traces. See help
% correlation for description of individual statisitics columns within the
% STAT field. See Vandecar and Crosson (BSSA 1990) for details of how these
% statistics are calculated.
% 
% Note that statistics determined from the maximum cross correlation values
% are transformed to z space to determine the mean and rms error and then
% transformed back for presentation, where 
% 
%   z = 1/2 * log ( (1+r) / (1-r) ) r = (exp(2*Z)-1)./(exp(2*Z)+1)
%
% This is done because the cross correlation value is bounded by 1 on the
% high side and not normally distributed. Fisher's transform (z) translates
% the correlation values into a space where they have a roughly normal
% distribution. The implimentation here is a slight approximation because
% the matrix of maximum correlations contains the diagonal values of one
% where each trace is compared against itself. GETSTAT makes an
% approximation to remove this bias. For very small numbers of traces, this
% approach may break down. But then, for small numbers of the traces, the
% statistics aren't terribly valid anyway.
%
% The least squares inversion in this routine bogs down quickly when
% operating on more than a few hundred traces.


% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$
% TODO: needs better handling of xcorr=1 values (MEW - 11/20/06)
%


if nargin <= 0
    error('Wrong number of inputs');
end

if ~strcmpi(class(c),'correlation')
    error('First input must be a correlation object');
end

if isempty(get(c,'CORR'))
    error('CORR and LAG fields must be filled in input object');
    error('See xcorr function');
end

   
% GET MEAN AND STD OF MAX. CROSS CORRELATION (EQ. 4)
Ztmp = c.C - 0.3*eye(size(c.C));
Z = 0.5 * log((1+Ztmp)./(1-Ztmp));
Zmean = mean(Z);
Zrmshi = mean(Z) + std(Z);
Zrmslo = mean(Z) - std(Z);
Rmean = (exp(2*Zmean)-1)./(exp(2*Zmean)+1);
Rrmshi = (exp(2*Zrmshi)-1)./(exp(2*Zrmshi)+1);
Rrmslo = (exp(2*Zrmslo)-1)./(exp(2*Zrmslo)+1);



% BUILD A AND dT
n = size(c.C,1);
m = n*(n-1)/2+1;
A = sparse(m,n);
A(m,:) = 1;
dT = zeros(m,1);
W = speye(m);
I = zeros(m,1);
J = zeros(m,1);
count = 0;
for i = 1:n-1
	for j = (i+1):n
		count = count + 1;
		A(count,i) = 1;	
		A(count,j) = -1;
		dT(count) = c.L(i,j);
		W(count,count) = c.C(i,j);
	end;
end;



% INVERT FOR Test
T = inv( A' * A ) * A' * dT;			% unweighted
%Tw = inv( A' * W * A ) * A' * W * dT;		% weighted



% ESTIMATE RESIDUALS, STD
for i = 1:n
	for j = 1:n
		res(i,j) = c.L(i,j) - ( T(i) - T(j) );	%eq. 7
	end;
end;
Trms = std(res)';		% ~eq. 8


c.stat(:,1) = Rmean;
c.stat(:,2) = Rrmshi;
c.stat(:,3) = Rrmslo;
c.stat(:,4) = -1*T;
c.stat(:,5) = Trms;





