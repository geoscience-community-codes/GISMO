function d = xcorr1x1(d);

% This function is the same as xcwfm1xr except that it uses matlab's xcorr
% function and cycles through cross correlations individually instead by
% row. It appears to run somewhat slower.
% 

% AUTHOR: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks


% CREATE EMPTY CORRELATION AND LAG MATRICES
d.C = eye(length(d.trig),'single');
d.L = zeros(length(d.trig),'single');


% TIME THE PROCESS
tic;
t0 = cputime;
numcorr = ((length(d.trig))^2-length(d.trig))/2;
count = 0;


% GET XCORR FUNCTION HANDLE
Hxcorr = @xcorr;


% LOOP THROUGH FIRST WAVEFORM
for i = 1:length(d.trig)	
    d1 = d.w(:,i);
    st1 = d.start(i);

	% LOOP THROUGH SECOND WAVEFORM
	for j = (i+1):length(d.trig)
		count = count + 1;	
		d2 = d.w(:,j);
        st2 = d.start(j);
        
        % "shift" allows flexibility in when the waveforms actually start
		shift = 86400*((d.trig(j)-st2)-(d.trig(i)-st1));
		
		% DO CORRELATION		
		%[corr,l]=xcorr(d1,d2,'coeff');
		[corr,l]=feval(Hxcorr,d1,d2,'coeff');

		[maxval,index] = max(corr);
		d.C(i,j)=corr(index);
		d.L(i,j)=l(index)/d.Fs + shift; % lag in seconds
	
		% SHOW PROGRESS
 		if (mod(count,round(numcorr/4))==0)
			disp([num2str(count) ' of ' num2str(numcorr,'%2.0f') ' complete (' num2str(100*count/numcorr,'%2.0f') '%)']);
		end;

	end;

end;


% FILL LOWER TRIANGULAR PART OF MATRICES
d.C = d.C + d.C' - eye(size(d.C));
d.L = d.L - d.L';


% DISPLAY RUN TIMES
tclock = toc;
tcpu = cputime-t0;
disp(['Clock time to complete correlations: ' num2str(tclock,'%5.1f') ' s']);
disp(['CPU time to complete correlations:   ' num2str(tcpu,'%5.1f') ' s']);
