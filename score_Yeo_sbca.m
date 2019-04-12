%% Extract mean DMN, DAN and SN scores from Schaefer atlas for a given seed-based FC map
% Must first run register_Schaefer_brainmask

%% settings
% PMC
subjects={'S18_119'; 'S18_124'; 'S18_127'; 'S18_128'; 'S18_123'};
sub_labels={'S1'; 'S2'; 'S3'; 'S4'; 'S6'};
iElvis_chans={'70'; '86'; '20', '10', '100'};

% dPPC
%subjects={'S18_119'; 'S18_124'; 'S18_127'; 'S18_128'; 'S18_123'};
%sub_labels={'S1'; 'S2'; 'S3'; 'S4'; 'S6'};
%iElvis_chans={'61'; '80'; '14'; '2'; '33'};

% dAIC
%subjects={'S18_119'; 'S18_124'; 'S18_127'};
%sub_labels={'S1'; 'S2'; 'S3'};
iElvis_chans={'119'; '40'; '59'};

%% Defaults
load('cdcol.mat')
getECoGSubDir; global globalECoGDir;

%%  