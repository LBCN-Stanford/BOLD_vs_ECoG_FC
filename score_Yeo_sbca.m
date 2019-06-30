%% Extract mean DMN, DAN and SN z scores from Schaefer atlas for a given seed-based FC map
% Must first run register_Schaefer_brainmask

%% settings
load('cdcol.mat')
ROI=2; % 1=PMC, 2=dPPC, 3=dAIC
% PMC
if ROI==1
subjects={'S18_119'; 'S18_124'; 'S18_127'; 'S18_128'; 'S18_123'};
sub_labels={'S1'; 'S2'; 'S3'; 'S4'; 'S6'};
sub_nums=[1;2;3;4;6];
iElvis_chans={'70'; '86'; '20'; '10'; '100'};
ROI_name='PMC';
network_num=1; edge_color=cdcol.lightblue;

% dPPC
elseif ROI==2
subjects={'S18_119'; 'S18_124'; 'S18_127'; 'S18_128'; 'S18_123'};
sub_labels={'S1'; 'S2'; 'S3'; 'S4'; 'S6'};
sub_nums=[1;2;3;4;6];
iElvis_chans={'61'; '80'; '14'; '2'; '33'};
ROI_name='dPPC'; 
network_num=2; edge_color=cdcol.grassgreen;

% dAIC
elseif ROI==3
subjects={'S18_119'; 'S18_124'; 'S18_127'};
sub_labels={'S1'; 'S2'; 'S3'};
sub_nums=[1;2;3];
iElvis_chans={'119'; '40'; '59'};
ROI_name='dAIC'; 
network_num=3; edge_color=cdcol.russet;
end

%% Defaults
networks={'DMN'; 'DAN';'SN'; 'FPCN'; 'SMN'; 'VIS'; 'Limbic'};
network_names={'DMN'; 'DAN';'SN'; 'FPCN'; 'SMN'; 'Visual'; 'Limbic'};
%networks={'DMN';'DAN';'SN'};
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

%% mean across subjects
for i=1:length(networks)
    network_means(i)=mean(cellfun(@str2double,network_scores_subs(:,i)));
end

%% plot all subjects and mean
% set colors
color_options=[cdcol.portraitdarkflesh5; cdcol.metalicscarlet; cdcol.emeraldgreen; cdcol.olive; ...
      cdcol.lightcobaltblue; cdcol.brown; cdcol.darkulamarine; cdcol.pink; cdcol.orange; cdcol.cobaltblue; cdcol.grassgreen; cdcol.russet; ];

for i=1:length(sub_nums)
   sub_colors(i,:)=color_options(sub_nums(i),:); 
end
% add black color for mean
sub_colors=[sub_colors; cdcol.black];

% make plot
cd([globalECoGDir filesep 'gradCPT']);
cd('Group_analysis/figs'); mkdir('fMRI_stats'); cd('fMRI_stats');
FigHandle = figure('Position', [500, 600, 600, 400])
for i=1:length(subjects)+1
    sub_scores=[]; sub_color=[];
    sub_color=sub_colors(i,:);
    if i<length(subjects)+1
    sub_scores=network_scores_subs(i,:);
    sub_scores=cellfun(@str2double,sub_scores);
  
    plot(1:size(network_scores_subs,2),sub_scores,'-', 'LineWidth',1,'Color',sub_color,'MarkerFaceColor', ...
        sub_color, 'MarkerSize',8,'MarkerEdgeColor',sub_color);
     legendInfo{i}=sub_labels{i};
    else
       plot(1:size(network_scores_subs,2),network_means,'o-', 'LineWidth',2,'Color',cdcol.black,'MarkerFaceColor', ...
        cdcol.black, 'MarkerSize',8,'MarkerEdgeColor',cdcol.black);  
    legendInfo{i}='Mean';
    end
    title([ROI_name]);
    xlim([0.5 length(networks)+.5])
    set(gca,'Xtick',0:1:length(networks))
     set(gca,'XTickLabel',[' ';network_names])
     xtickangle(45)
 set(gca,'Fontsize',16,'FontWeight','Normal','LineWidth',1,'TickDir','out');
 ylabel('BOLD Connectivity (z)')
 hold on
end
 line([0.5 length(networks)+.5],[0 0],'LineWidth',1,'Color',[0.6 0.6 0.6],'LineStyle','--');
legend(legendInfo,'Location','northeastoutside');
print('-opengl','-r300','-dpng',[ROI_name '_YeoSchaefer_z.png']);   

% plot mean in black, with target network outlined
%    plot(1:size(network_scores_subs,2),network_means,'o-', 'LineWidth',2,'Color',cdcol.black,'MarkerFaceColor', ...
 %       cdcol.black, 'MarkerSize',8,'MarkerEdgeColor',cdcol.black);
  %  legend('mean')
   % hold on;
    %scatter(network_num,network_means(network_num),80,'MarkerFaceColor',cdcol.black,'MarkerEdgeColor',edge_color,...
      %  'LineWidth',2);
   



    



