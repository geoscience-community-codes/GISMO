statefile = fullfile(products_dir, sprintf('%s_state.mat',subnetName));

% load state
if exist(statefile, 'file')
    load(statefile)
    if snum < snum0 
        return
    end
end

% save state
ds0=ds; ChannelTagList0=ChannelTagList; snum0=snum; enum0=enum; subnetName0 = subnetName;
mkdir(fileparts(statefile));
save(statefile, 'ds0', 'ChannelTagList0', 'snum0', 'enum0', 'subnetName0');
clear ds0 ChannelTagList0 snum0 enum0 subnetName0