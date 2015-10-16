function reducedisp_wfmeas(varargin);

% REDUCEDISP_WFMEAS(STARTTIME,ENDTIME,SCNL,DIST,DS,DBOUT,FILT,TIMESTEP,ALGORITHM)
% This function reads calibrated waveforms and write out a wfmeas
% database table containing reduced displacement values. The reduced displacment 
% functionality requres the Antelope toolbox, the waveform object toolbox and the 
% filterobject toolbox.
% 
% Example:
%    starttime = '12/01/2006 19:40:00';	% formatted start time (string)
%    endtime = '12/31/2006 24:00:00';	% formatted end data (string)
%    scnl = scnlobject('BEZB','HHZ')
%    dist = 5.224;			% distance to assumed source (km)
%    ds = datasource('antelope','/home/admin/databases/PIRE/wf/pire_2006');
%    dbout = 'databases/BEZB_p5-10Hz';   	% output db (string)
%    filt = filterobject('B',[0.5 10],4);	% filter to apply to traces
%    Tstep = 600;				% time step and window wdith
%    algorithm = 'BODY';    % algorithm (BODY or SURF)
%    reducedisp_wfmeas(starttime,endtime,scnl,dist,ds,dbout,filt,Tstep,algorithm);

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$


if numel(varargin) ~= 9
    error('Incorrect number of input arguments');
else
    T1 = varargin{1};
    T2 = varargin{2};
    scnl = varargin{3};
    distkm = varargin{4};
    ds = varargin{5};
    dbout = varargin{6};
    flt = varargin{7};
    Tstep = varargin{8};
    algorithm = varargin{9};
end


% PREP TIME PARAMETERS
Tstep = Tstep/86400;	% time step between measurements in seconds
Twin = Tstep;           % could be used later to have different time steps and windows.
TWstep = 6*3600/86400;	% load 6 hr. waveforms at a time
gapThresh = 0.5;        % [<1.0] maximum allowable gap size (ratio to data length)


% GET WAVEFORM TIMES (LARGE CHUCKS OF TIME)
% round *up* the waveform start times the nearest Tstep
tmod = mod(datenum(T1),Tstep);
if tmod == 0
	tmod = Tstep;
end;
t1 = datenum(T1) + ( Tstep -  tmod); 
Nwf = floor( (datenum(T2)-t1(1)) / TWstep );
t1 = t1(1) + TWstep*[0:Nwf-1];
t2 = t1 + TWstep;



for i = 1:Nwf    

	% LOAD WAVEFORM AND TEST FOR GOOD DATA
    	PROCESS = 1;
	try
		W = waveform(ds,scnl,t1(i),t2(i));
		if isempty(W)  
        		disp(['Skipping ' datestr(t1(i),31) ' to ' datestr(t2(i),31) ' . Empty waveform.']);
			PROCESS = 0;
    		end
	catch
		disp(['Skipping ' datestr(t1(i),31) ' to ' datestr(t2(i),31) ' . Problem loading waveform.']);
    		PROCESS = 0;
	end
    	if PROCESS
		if (get(W,'DURATION_EPOCH') < gapThresh*Tstep)
        		disp(['Skipping ' datestr(t1(i),31) ' to ' datestr(t2(i),31) '. Data is more than ' num2str(100*gapThresh) '% gaps.']);
    			PROCESS = 0;
		end
	end


if PROCESS

        % FILTER DATA
        % TODO: should be changed to be gap aware        
        W = fillgaps(W,'meanAll'); 
        W = demean(detrend(W));
		W = filtfilt(flt,W);
        
        % CREATE SUBSETS OF DATA
        Nwin = get(W,'DURATION') / Twin;
        To = get(W,'START_MATLAB');
        for ii = 1:Nwin
            Tbegin(ii) = To+(ii-1)*Tstep;
            Tend(ii) = To+(ii-1)*Tstep+Twin;
        end;
        w = extract(W,'TIME',Tbegin,Tend);

        % GET REDUCED DISPLACEMENT
        disp(['Calculating reduced displacements on ' datestr(t1(i),31) ' to ' datestr(t2(i),31) ' ...']);
        w = reducedisp_calc(w,distkm,algorithm);

        % WRITE DB TABLE
        disp(['Writing reduced displacements to ' dbout ' ...']);
        reducedisp_write_wfmeas(dbout,w,flt,algorithm);

    end;

end;




