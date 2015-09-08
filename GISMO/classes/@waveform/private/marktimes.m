
%   marktimes    calculate travel times of phases and place in header
%
%   Calculates travel times of desired phases using TTBox and 
%   places the times in the header of a SACLAB file.
%
%   Requires:
%   SACLAB (http://gcc.asu.edu/mthorne/saclab)
%   TTBox (http://ifp.uni-muenster.de/spp1115/content/pub/TTBox02052004b.zip)
%
%   The SACLAB file must have the 'O' and 'GCARC' header variable set.
%   Function is similar to TauP_SetSac (http://www.seis.sc.edu/software/TauP/index.html)
%   
%   Examples:
%   1. 2004180KATHZ = marktimes(2004180KATHZ,'prem','P');
%   2. 2004180KATHZ = marktimes(2004180KATHZ,'prem','P',2);
%   3. 2004180KATHZ = marktimes(2004180KATHZ,'iasp91',{'S', 'SKS'});
%   4. 2004180KATHZ = marktimes(2004180KATHZ,'iasp91',{'S', 'SKS'},[2 3]);
%
%   1. 2004180KATHZ is the SACLAB file, PREM is the model, and phase P
%      The P arrival time is placed in T0 header
%   2. Just like Ex. 1, but the P arrival time is place in T2 header
%   3. 2004180KATHZ is the SACLAB file, iasp91 is the model, and both SKS
%      and S are calculated. It is important to make the phases a char and
%      put them in a cell array with curly brackets {}. S arrival time is 
%      placed in T0 and SKS in T1. 
%   4. Just like Ex. 3, but S is placed in T2 and SKS in T3
%   
%   For phase nomenclature see TTBox manual. 
%   Available models are prem, ak135, jb, and iasp91.
%
%   by Sean Ford (1/2005)  sean.ford@asu.edu
%   A SACLAB utility (http://gcc.asu.edu/mthorne/saclab)

function [outfile] = marktimes(infile,model,varargin1,varargin2);

% find if varargin2 is defined
if (nargin == 3)
    varargin2 = 0;
end

% test for sacfile
if (infile(303,3)~=77 & infile(304,3)~=73 & infile(305,3)~=75 & infile(306,3)~=69)
  error('Waveform:marktimes:notSacFormat','Specified Variable is not in SAC format')
end

outfile = infile;

% grab header variables from saclabfile using lh.m (SACLAB)
[dist,depth,o] = lh(infile,'GCARC','EVDP','O');

% make model using .nd models of TTBox
if (strcmpi(model,'prem'))
    mod = mkreadnd('/users/sean/MATLAB/ttbox02052004b/data/prem.nd','silent');
elseif (strcmp(model,'iasp91')) 
    mod = mkreadnd('/users/sean/MATLAB/ttbox02052004b/data/iasp91.nd','silent');
elseif (strcmp(model,'ak135')) 
    mod = mkreadnd('/users/sean/MATLAB/ttbox02052004b/data/ak135.nd','silent');
elseif (strcmp(model,'jb')) 
    mod = mkreadnd('/users/sean/MATLAB/ttbox02052004b/data/jb.nd','silent');
else
    error('Waveform:marktimes:unsuportedModel','Requested model is not supported')
end

% calculate travel times of requested phases using mkttime.h (TTBox)
if (ischar(varargin1))
    [tt,p] = mkttime(varargin1,dist,depth,mod);
else
    for i = 1:size(varargin1,2)
        [tt(i),p(i)] = mkttime(varargin1{i},dist,depth,mod);
    end
end

% correct time using header variable o
ttime = tt + o;

% place time in header using ch.m (SACLAB)
if (ischar(varargin1))
    if (varargin2 == 0)
        outfile = ch(outfile,'T0',ttime,'KT0',varargin1);
    else
        outfile = ch(outfile,['T' num2str(varargin2)],ttime,['KT' num2str(varargin2)],varargin1);
    end
else
    if (varargin2 == 0)
        for i = 1:size(varargin1,2)
            outfile = ch(outfile,['T' num2str(i-1)],ttime(i),['KT' num2str(i-1)],varargin1{i});
        end
    else
        for i = 1:length(varargin2)
            outfile = ch(outfile,['T' num2str(varargin2(i))],ttime(i),['KT' num2str(varargin2(i))],varargin1{i});
        end
    end
end
