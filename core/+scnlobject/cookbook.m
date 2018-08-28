%% The SCNLOBJECT cookbook
% This cookbook is designed to familiarize yourself with the scnlobjects used within waveform. There's not really all that much to them, so there'll not be much to this, either.

%% Properties
% Scnlobjects are comprised of only four fields:
%%
%
% * Station
% * Channel
% * Network
% * Location

%%
% STATION and CHANNEL are not optional, while NETWORK and LOCATION are.

%%
% Create a series of scnls for seismic stations on Redoubt volcano
    red = scnlobject('RED','EHZ','AV','--') % full declaration
    rso = scnlobject('RSO','EHZ','AV')      % leaving out location

%%
% 3-component station, this creates rdbw as a 1x3 scnlobject
    rdbw = scnlobject('RDBW',{'BHZ','BHE','BHN'},'AV')
 

%% Using SET to modify a SCNLOBJECT
% use SET to create another 3 component broadband using rdbw as a template...
    rdjh = set(rdbw,'station','RDJH');

%% Grouping SCNLOBJECTS through concatenation% and finally, create something that will parse through all stations

    redstas = [red rso rdbw rdjh]
%%
% Create a couple scnls with wildcard values
% The value '*' can be entered in place of a field, so that searches can be made.

    anyehz = scnlobject('*','EHZ','*','*') % this one prints as an example...
    anybroadband = scnlobject('*',{'BHZ','BHE','BHN'},'*','*');
    anyNorthComponent = scnlobject('*',{'EHN','SHN','BHN'},'*','*');
 
%%
% Let's display all the variables we've got, thus far

    whos            

%% Methods
% Find out what manipulations can be done with scnlobjects

    methods(redstas)  

%%    
% I could have typed "methods(scnlobject)", instead      

%% using ISMEMBER to see if a particular locale (SCNLOBJECT) is represented
% Ismember will not only tell you if a scnlobject exists, but is also capable of telling WHERE

    [IsInList, whereInList] = ismember(rso,redstas)


%%
% ismember is sensitive to the order in which you place the scnlobjects. The size of the returned values match the size of the first argument. The previous example asks '' where can RSO be found in REDSTAS? '', while the following example essentially asks '' which REDSTAS can be found in RSO (and where)?''

    [IsInList, whereInList] = ismember(redstas,rso)

%% using ISMEMBER with wildcards
% The ismember function looks for a scnlobject in an array of scnlobjects. Lets grab the EHZ component stations using a search, then display each one

    stationsOfInterest = redstas(ismember(redstas,anyehz)) %should get 2

    for n = 1 : numel(stationsOfInterest);
        display(stationsOfInterest(n));
    end
    
    
    
    
%%
% repeat the exercise for broadband and stations... there should be 6

    mybroadbands = redstas(ismember(redstas,anybroadband));
    size(mybroadbands)

%% Use GET to see which stations we have...
% Get can also retrieve CHANNEL, NETWORK, and LOCATION information.

    get(mybroadbands,'station')

%%
% There are 3 of each because there are three components to each.

    strcat(get(mybroadbands,'station'),'|',get(mybroadbands,'channel'))

%%
% to get a vertical list, I could transpose mybroadbands using (')

    strcat( get(mybroadbands', 'station') , '|' , get(mybroadbands', 'channel') )

%% Using UNIQUE to whittle down a bunch of scnlobjects
% Assume that for some reason, you have a list of scnlobjects with some members being repeated. This may happen when you retrieve scnlobjects from a group of waveforms. You'd like to know which station/channels are actually being represented within your data set. Here's how:
%
% set up the situation as listed:
    manyscnls = [redstas, red, rso, red, redstas]
%%
% Find out which ones we have:
    unique(manyscnls)
