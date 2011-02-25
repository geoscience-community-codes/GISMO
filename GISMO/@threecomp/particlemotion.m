function TC = particlemotion(TC, varargin)
%PARTICLEMOTION calculates particle motion vectors for threecomp object
% TC = PARTICLEMOTION(TC) calculates particle motion parameters for
% threecomp object TC. The results are stored as threecomp properties:
%     TC.rectilinearity
%     TC.planarity
%     TC.energy
%     TC.azimuth
%     TC.inclination
%
% TC = PARTICLEMOTION(TC, DT, WIDTH) calculates particle motions where DT
% is the time step through the traces. WIDTH is the width of the time
% window. If these parameters are not included, the function estimates
% appropriate values for the data.
%
% PARTICLEMOTION can accept traces that have been rotated in the horizontal
% plane (i.e. type ZRT and Z21) so long as the orientation field is filled
% in. This is accomplished internally by first rotating these traces to
% type ZNE and then carrying out the particle motion analysis. In other
% words, the particle motion coefficients are relative to a fixed
% geographic reference frame and are independent of the orientation of the
% input traces. See THREECOMP(DESCRIBE) for a complete description of the
% particle motion fields.
%
% see also threecomp/describe

% Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
% $Date$
% $Revision$



if isa(TC,'threecomp')
    originalTraces = TC.traces;
else
    error('Threecomp:particlemotion:mustBeThreecompObject','First argument must be a threecomp object');
end
    
    
% SET UP INPUTS
if length(varargin) >= 1
    dt = varargin{1};
else
    dt = 86400 * get(TC(1).traces(1),'DURATION' ) / 100;
end

if length(varargin) >= 2
    width = varargin{2};
else
    width = 86400 * get(TC(1).traces(1),'DURATION' ) / 10;
end

disp(['Time step: ' num2str(dt,'%4.3f') '    Window width: ' num2str(width,'%4.3f') ]);


% CHECK ORIENTATIONS
orientation = get(TC,'ORIENTATION');
if isempty(orientation) || any(any(isnan(orientation)))
    error('Threecomp:particlemotion:requiresOrientation','Orientations must be provided for all channels');
end
if any(orientation(:,2)~=0)
    error('Threecomp:particlemotion:verticalCompMustPointUp','vertical component must have a vertical orientation of 0.');
end



% TODO: ROTATE TEMPORARY THREECOMP TO ZNE, IF NEEDED


% STEP THROUGH EACH OBJECT
disp('calculating particle motions ->      ');
nMax = numel(TC);
for n = 1:nMax;
    fprintf('\b\b\b\b\b%4.0f%%',n/nMax*100);
    [TC(n).rectilinearity,TC(n).planarity,TC(n).energy,TC(n).azimuth,TC(n).inclination] = do_one(TC(n),dt,width); 
end
fprintf('\n');




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Process a single object

function [rec, plan, energy, az, incl] = do_one(TC,dt,width)

% TEMPORARILY ADJUST ORIENTATION IF NEEDED
if any(TC.orientation~=[0 0 0 90 90 90]) 
    %disp('temporarily rotating trace to Z-N-E for particle motion calculation ...');
    TC = rotate(TC,0);
end
w = TC.traces;
freq = get(w(1), 'Freq');
alldata = double(w);
%ellipsoidMatrix = cov(alldata);
Tstart = get(w(1), 'Start_Matlab');
Tend = get(w(1), 'End_Matlab');
Tc = Tstart : dt/86400 : Tend;
T1 = Tc - 0.5*width/86400;
T2 = Tc + 0.5*width/86400;
f = find(T1<Tstart);
T1(f) = Tstart;
f = find(T2>Tend);
T2(f) = Tend;
T1i = round((T1-Tstart)*86400*freq + 1);
T2i = round((T2-Tstart)*86400*freq);
test = [(T2'-T1')*86400 T2i' T1i'];
% Tc is the center of the time ranges bounded by T1 and T2
% T1i and T2i are the sample indexes corresponding to these time ranges
% Is this formulation correct to the sample?



steps = numel(T1)-1;
pm.Rec = zeros(1,steps); pm.Plan = pm.Rec; pm.Ener = pm.Rec; X = pm.Rec; pm.Az = pm.Rec; pm.Inc = pm.Rec;
% fprintf('Calculating covariance matrix : %05d of %05d',0, steps);
% backspacing = repmat('\b',1,15);
% formstr = [backspacing,' %05d of %05d'];
 
for n=1:steps
    %fprintf(formstr,n, totcount);
    snippet = alldata( T1i(n) : T2i(n) ,:); %grab a chunk
    %snippet = snippet .* repmat(hanning(size(snippet,1)),1,3);
    covmatrix = cov(snippet); %covariance matrix
    [V, D] = eig(covmatrix); %columns of V are eigenvectors, D are eigenvalues
    [lambda,I] = sort(diag(D),1,'descend'); %lambda are sorted eigenvlues, I is index
    if numel(lambda) < 3,
        warning('less than three eigenvalues!');
    end

  
    % ADJUST SO THAT PRIMARY VECTOR POINTS ABOVE HORIZON
    X = V(:,I(1));  % X is the largest eigenvector
    FLIP = 0;       % track whether vector has been flipped (affects azimuth) 
    if X(1)<0       % if eigenvector points toward Z-
       X = -1*X;
       FLIP = 1;
    end

    
    % RECTILINEARITY
    pm.Rec(n) = 1 - lambda(2) / lambda(1);   
    %pm.Rec(n) = 1 - (lambda(2)+lambda(3))/(2*lambda(1)); % alternate definition

    % PLANARITY
    pm.Plan(n) = 1 - lambda(3) / lambda(2);   
    %Fp(n) = 1 - 2*lambda(3)/(lambda(1)+lambda(2));  % alternate definition

    % ENERGY
    pm.Ener(n) = trace(D);        % energy
    
    %INCIDENCE ANGLE
    %incidence(n) = rad2deg(atan( X(1)/sqrt(X(2)^2+X(3)^2) )); % Same as below
    pm.Inc(n) = 90 - acosd( X(1) ); % as measured from horizontal
   
    % AZIMUTH
    %azimuth(n) = rad2deg(atan(X(3)/X(2)));    % range in -90 to +90 degrees
    pm.Az(n) =  rad2deg(atan2(X(3),X(2)));     % range is -180 to 180
    pm.Az(n) = mod(pm.Az(n),360); 	           % range is 0 to 360
end
        
  
% SET THREECOMP PROPERTIES
basicWave = waveform(get(w(1),'station'),'JUNK',1/dt,Tstart,[]);
rec = set(basicWave,'channel','Rectilinearity','data',pm.Rec,'units','(arbitrary units)');
rec = addfield(rec,'THREECOMP_WINDOW',width);
plan = set(basicWave,'channel','Planarity','data',pm.Plan,'units','(arbitrary units)');
plan = addfield(plan,'THREECOMP_WINDOW',width);
energy = set(basicWave,'channel','Energy','data',pm.Ener,'units','energy (arbitrary units)');
energy = addfield(energy,'THREECOMP_WINDOW',width);
az = set(basicWave,'channel','Azimuth','data',pm.Az,'units','degrees');
az = addfield(az,'THREECOMP_WINDOW',width);
incl = set(basicWave,'channel','Incidence','data',pm.Inc,'units','degrees');
incl = addfield(incl,'THREECOMP_WINDOW',width);

