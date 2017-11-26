% Plot 2 resting state runs vs sleep and 7heaven
% must first run BOLD_vs_ECoG_FC_corr_iElvis.m for each run used
% must first run ECoG_vs_ECoG_FC.m for each run pair used
% dFC_iEEG_multirun.txt file should contain subject name (column 1), sub number (column 2),
% electrode number (column 3), network identity (column 4), rest 1 number (column 5),
% rest 2 number (column 6), sleep number (column 7), 7 heaven number
% (column 8)
% network identity: 1=DMN, 2=DAN, 3=FPCN

%Patient=input('Patient: ','s');
%bold_runname=input('BOLD Run (e.g. 2): ','s');
%ecog_runname=input('ECoG Run (e.g. 2): ','s');
% hemi=input('Hemisphere (r or l): ','s');
%depth=input('depth(1) or subdural(0)? ','s');
%region=input('Seed location (e.g. mPFC) ','s');
%freq=input('HFB 0.1-1Hz (1) or alpha (2) or HFB <0.1Hz (3) or SCP (4) ','s');
% depth=str2num(depth);
bold_run_num=['run1']
%bold_run_num=['run1' bold_runname];
%ecog_run_num=['run' ecog_runname];
load('cdcol.mat');

globalECoGDir=getECoGSubDir;
cd([globalECoGDir '/Rest']);
mkdir('Figs');
cd Figs;
mkdir('DMN_Core'); cd ..

%% Load subject, ECoG run numbers, and electrode list
list=importdata('dFC_iEEG_multirun.txt',' ');
subjects=list.textdata;
subject_nums=list.data(:,1);
elecs=list.data(:,2);
networks=list.data(:,3);
rest_run1=list.data(:,4); rest_run2=list.data(:,5);
sleep_run=list.data(:,6); heaven_run=list.data(:,7);
%allsubs_seedcorr_allfreqs=NaN(length(subjects),7);

for sub=1:length(subjects)
    Patient=subjects{sub}
    curr_rest_run1=rest_run1(sub);
    curr_rest_run2=rest_run2(sub);
    elec=elecs(sub)
    network=networks(sub);
    curr_sleep_run=sleep_run(sub);
    curr_heaven_run=heaven_run(sub);

 %% get elec names
fsDir=getFsurfSubDir();
parcOut=elec2Parc_v2([Patient],'DK',0);
elecNames = parcOut(:,1);

%% Load corr values for each run
cd([fsDir '/' Patient '/elec_recon/electrode_spheres/SBCA/figs/iEEG_vs_iEEG']);
rest1sleep1=load(['Run' num2str(curr_rest_run1) 'RestRun' num2str(curr_sleep_run) 'Sleep.mat']);
rest1heaven1=load(['Run' num2str(curr_rest_run1) 'RestRun' num2str(curr_heaven_run) '7heaven.mat']);
rest2sleep1=load(['Run' num2str(curr_rest_run2) 'RestRun' num2str(curr_sleep_run) 'Sleep.mat']);
rest2heaven1=load(['Run' num2str(curr_rest_run1) 'RestRun' num2str(curr_heaven_run) '7heaven.mat']);

%% get elec names
fsDir=getFsurfSubDir();
parcOut=elec2Parc_v2([Patient],'DK',0);
elecNames = parcOut(:,1);

%% Get ECoG vs ECoG corr (fisher z) for electrode of interest
seed_rest1sleep1=rest1sleep1.allelecs_run1run2_corr(elec);
seed_rest2sleep1=rest2sleep1.allelecs_run1run2_corr(elec);
seed_rest1heaven1=rest1heaven1.allelecs_run1run2_corr(elec);
seed_rest2heaven1=rest2heaven1.allelecs_run1run2_corr(elec);

%% concatenate across subjects/seeds
allsubs_seed_sleep(:,sub)=[seed_rest1sleep1 seed_rest2sleep1];
%allsubs_seed_rest2(:,sub)=[seed_rest2sleep1 seed_rest2heaven1];
end

%% Make plots
cd([globalECoGDir '/Rest/Figs/DMN_Core']);

% Network color coding
for i=1:length(networks)
    if networks(i)==1
   network_color(i,:)=cdcol.cobaltblue;
    elseif networks(i)==2
        network_color(i,:)=cdcol.grassgreen;
    elseif networks(i)==3
        network_color(i,:)=cdcol.orange; 
    end
end
% Subject marker coding
for i=1:length(subject_nums)
    if subject_nums(i)==1
   subjectmarker{i,:}='<';
    elseif subject_nums(i)==2
        subjectmarker{i,:}='s';
    elseif subject_nums(i)==3
        subjectmarker{i,:}='o';
    elseif subject_nums(i)==4
        subjectmarker{i,:}='>';
    elseif subject_nums(i)==5
        subjectmarker{i,:}='^'
    end
end

% plot
FigHandle = figure('Position', [400, 600, 200, 350]);
figure(1)
for i=1:length(allsubs_seed_sleep)
    plot(1:size(allsubs_seed_sleep,1),allsubs_seed_sleep(:,i),[subjectmarker{i,:} '-'], ...
        'LineWidth',1,'Color',network_color(i,:),'MarkerFaceColor',network_color(i,:), ...
        'MarkerSize',8,'MarkerEdgeColor',network_color(i,:));      
    ylim([0 1]);
    xlim([0.5 2.5]);
       set(gca,'Xtick',1:1:3)
       %set(gca,'Ytick',1:1:3);
 set(gca,'XTickLabel',{'Sleep','Task','2'})
 set(gca,'Fontsize',18,'FontWeight','bold','LineWidth',2,'TickDir','out');
  ylabel('BOLD-ECoG FC correlation (r)'); 
  
    hold on
   set(gca,'box','off'); 
set(gca,'Fontsize',18,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
%title({[elec_name ': BOLD FC vs iEEG FC']},'Fontsize',12);
  ylim([0 1]);
  xlim([0.5 2.5]);
   set(gca,'Xtick',1:1:3)
   %set(gca,'Ytick',1:1:3);
 set(gca,'XTickLabel',{'1','2','2'})
ylabel('Correlation with Sleep FC (r)');
xlabel('Rest Run');
%xlabel('ECoG Run');
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'iEEG_multirun_rest1']));
end
pause; close;

% FigHandle = figure('Position', [400, 600, 300, 700]);
% figure(1)
% for i=1:length(allsubs_seed_rest2)
%     plot(1:size(allsubs_seed_rest2,1),allsubs_seed_rest2(:,i),[subjectmarker{i,:} '-'], ...
%         'LineWidth',1,'Color',network_color(i,:),'MarkerFaceColor',network_color(i,:), ...
%         'MarkerSize',8,'MarkerEdgeColor',network_color(i,:));      
%     ylim([0 1]);
%     xlim([0.5 2.5]);
%        set(gca,'Xtick',1:1:3)
%        %set(gca,'Ytick',1:1:3);
%  set(gca,'XTickLabel',{'Sleep','Task','2'})
%  set(gca,'Fontsize',18,'FontWeight','bold','LineWidth',2,'TickDir','out');
%   ylabel('BOLD-ECoG FC correlation (r)'); 
%   
%     hold on
%    set(gca,'box','off'); 
% set(gca,'Fontsize',18,'FontWeight','bold','LineWidth',2,'TickDir','out');
% set(gcf,'color','w');
% %title({[elec_name ': BOLD FC vs iEEG FC']},'Fontsize',12);
%   ylim([0 1]);
%   xlim([0.5 2.5]);
%    set(gca,'Xtick',1:1:3)
%    %set(gca,'Ytick',1:1:3);
%  set(gca,'XTickLabel',{'Sleep','Task','2'})
% ylabel('Correlation with Rest 2 (r)');
% %xlabel('ECoG Run');
% print('-opengl','-r300','-dpng',strcat([pwd,filesep,'iEEG_multirun_rest2']));
% end
% pause; close;