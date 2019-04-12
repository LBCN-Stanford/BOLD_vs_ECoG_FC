%% Extract mean DMN, DAN and SN z scores from Schaefer atlas for a given seed-based FC map
% Must first run register_Schaefer_brainmask

%% settings
% PMC
subjects={'S18_119'; 'S18_124'; 'S18_127'; 'S18_128'; 'S18_123'};
sub_labels={'S1'; 'S2'; 'S3'; 'S4'; 'S6'};
iElvis_chans={'70'; '86'; '20'; '10'; '100'};

% dPPC
%subjects={'S18_119'; 'S18_124'; 'S18_127'; 'S18_128'; 'S18_123'};
%sub_labels={'S1'; 'S2'; 'S3'; 'S4'; 'S6'};
%iElvis_chans={'61'; '80'; '14'; '2'; '33'};

% dAIC
%subjects={'S18_119'; 'S18_124'; 'S18_127'};
%sub_labels={'S1'; 'S2'; 'S3'};
%iElvis_chans={'119'; '40'; '59'};

%% Defaults
networks={'DMN';'DAN';'SN'};
load('cdcol.mat')
getECoGSubDir; global globalECoGDir;
pdir='/media/jplinux/ExtraDrive1/data/freesurfer/subjects';

%% Get mean z score for each network 
% Loop through subjects
for i=1:length(subjects)
    for j=1:length(networks)
    curr_sub=subjects{i};
    cd([pdir filesep curr_sub filesep 'elec_recon'])
    % multiple network mask by sbca map
    cmd=['fslmaths  ' -Tmean mean.nii.gz'];
    [a,b]=system(cmd);
    pause;
    end
end

%% plot

