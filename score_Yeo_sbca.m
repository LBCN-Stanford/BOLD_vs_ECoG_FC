%% Extract mean DMN, DAN and SN z scores from Schaefer atlas for a given seed-based FC map
% Must first run register_Schaefer_brainmask

%% settings
ROI=1; % 1=PMC, 2=dPPC, 3=dAIC
% PMC
if ROI==1
subjects={'S18_119'; 'S18_124'; 'S18_127'; 'S18_128'; 'S18_123'};
sub_labels={'S1'; 'S2'; 'S3'; 'S4'; 'S6'};
iElvis_chans={'70'; '86'; '20'; '10'; '100'};
ROI_name='PMC';

% dPPC
elseif ROI==2
subjects={'S18_119'; 'S18_124'; 'S18_127'; 'S18_128'; 'S18_123'};
sub_labels={'S1'; 'S2'; 'S3'; 'S4'; 'S6'};
iElvis_chans={'61'; '80'; '14'; '2'; '33'};
ROI_name='dPPC';

% dAIC
elseif ROI==3
subjects={'S18_119'; 'S18_124'; 'S18_127'};
sub_labels={'S1'; 'S2'; 'S3'};
iElvis_chans={'119'; '40'; '59'};
ROI_name='dAIC';
end

%% Defaults
%networks={'DMN'; 'DAN';'SN'; 'FPCN'; 'SMN'; 'Vis'; 'Limbic'};
networks={'DMN';'DAN';'SN'};
load('cdcol.mat')
getECoGSubDir; global globalECoGDir;
pdir='/media/jplinux/ExtraDrive1/data/freesurfer/subjects';

%% Get mean z score for each network 
network_scores_subs={};
% Loop through subjects
for i=1:length(subjects)
    for j=1:length(networks)
    curr_sub=subjects{i};
    cd([pdir filesep curr_sub filesep 'elec_recon'])
    
    % multiply network mask by sbca map
    %cmd=['fslmaths Schaefer_' networks{j} '_brainmask -mul' ...
     %   ' electrode_spheres/SBCA/elec' iElvis_chans{i} 'run1_z_brainmask_GSR electrode_spheres/SBCA/elec' iElvis_chans{i} 'run1_brainmask_GSR_' networks{j}];
    %[a,b]=system(cmd);
    
    % get mean value within network
    cmd=['fslmeants -i electrode_spheres/SBCA/elec' iElvis_chans{i} 'run1_z_brainmask_GSR ' ...
        '-m Schaefer_' networks{j} '_brainmask'];
    [a,b]=system(cmd);
    network_scores_subs{i,j}=b;
    end
end

%% plot all subjects

for i=1:length(subjects)
    sub_scores=[];
    sub_scores=network_scores_subs(i,:);
    sub_scores=cellfun(@str2double,sub_scores);
    plot(sub_scores);
    xlim([0.5 4.5])
    set(gca,'Xtick',0:1:4)
     set(gca,'XTickLabel',[' ';networks])
 set(gca,'Fontsize',16,'FontWeight','Normal','LineWidth',1,'TickDir','out');
 hold on
end






