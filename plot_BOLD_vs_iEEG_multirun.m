% must first run BOLD_vs_ECoG_FC_corr_iElvis.m for each run used
% dFC_replicate.txt file should contain subject name (column 1), sub number (column 2),
% electrode number (column 3), and network identity (column 4), run numbers (columns 5+6) 
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
list=importdata('dFC_replicate.txt',' ');
subjects=list.textdata;
subject_nums=list.data(:,1);
elecs=list.data(:,2);
networks=list.data(:,3);
ecog_run1=list.data(:,4); ecog_run2=list.data(:,5);
%allsubs_seedcorr_allfreqs=NaN(length(subjects),7);

for sub=1:length(subjects)
    Patient=subjects{sub}
    ecog_run1name=num2str(ecog_run1(sub));
    ecog_run2name=num2str(ecog_run2(sub));
    elec=elecs(sub)
    network=networks(sub);
%% Load corr and partial corr values for each run
cd([globalECoGDir '/Rest/' Patient '/Run' ecog_run1name '/BOLD_ECoG_figs/GSR']);
run1_HFB_medium=load('corr_BOLD_HFB_medium_allelecs.mat');
run1_HFB_medium_partial=load('partialcorr_BOLD_HFB_medium_allelecs.mat');
run1_alpha_medium=load('corr_BOLD_alpha_medium_allelecs.mat');
run1_alpha_medium_partial=load('partialcorr_BOLD_alpha_medium_allelecs.mat');

cd([globalECoGDir '/Rest/' Patient '/Run' ecog_run2name '/BOLD_ECoG_figs/GSR']);
run2_HFB_medium=load('corr_BOLD_HFB_medium_allelecs.mat');
run2_HFB_medium_partial=load('partialcorr_BOLD_HFB_medium_allelecs.mat');
run2_alpha_medium=load('corr_BOLD_alpha_medium_allelecs.mat');
run2_alpha_medium_partial=load('partialcorr_BOLD_alpha_medium_allelecs.mat');

%% get elec names
fsDir=getFsurfSubDir();
parcOut=elec2Parc_v2([Patient],'DK',0);
elecNames = parcOut(:,1);

%% Get BOLD-ECoG corr for electrode of interest
seed_HFB_medium_run1=run1_HFB_medium.corr_BOLD_HFB_medium_allelecs(elec);
seed_HFB_medium_run2=run2_HFB_medium.corr_BOLD_HFB_medium_allelecs(elec);

seed_HFB_medium_run1_partial=run1_HFB_medium_partial.partialcorr_BOLD_HFB_medium_allelecs(elec);
seed_HFB_medium_run2_partial=run2_HFB_medium_partial.partialcorr_BOLD_HFB_medium_allelecs(elec);

seed_alpha_medium_run1=run1_alpha_medium.corr_BOLD_alpha_medium_allelecs(elec);
seed_alpha_medium_run2=run2_alpha_medium.corr_BOLD_alpha_medium_allelecs(elec);

seed_alpha_medium_run1_partial=run1_alpha_medium_partial.partialcorr_BOLD_alpha_medium_allelecs(elec);
seed_alpha_medium_run2_partial=run2_alpha_medium_partial.partialcorr_BOLD_alpha_medium_allelecs(elec);

%% concatenate across subjects
allsubs_seed_HFB_medium_allruns(:,sub)=[seed_HFB_medium_run1 seed_HFB_medium_run2];
allsubs_seed_HFB_medium_allruns_partial(:,sub)=[seed_HFB_medium_run1_partial seed_HFB_medium_run2_partial];

allsubs_seed_alpha_medium_allruns(:,sub)=[seed_alpha_medium_run1 seed_alpha_medium_run2];
allsubs_seed_alpha_medium_allruns_partial(:,sub)=[seed_alpha_medium_run1_partial seed_alpha_medium_run2_partial];

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
        network_color(i,:)=cdcol.orange 
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

% plot HFB corr
FigHandle = figure('Position', [400, 600, 400, 700]);
figure(1)
for i=1:length(allsubs_seed_HFB_medium_allruns)
    plot(1:size(allsubs_seed_HFB_medium_allruns,1),allsubs_seed_HFB_medium_allruns(:,i),[subjectmarker{i,:} '-'], ...
        'LineWidth',1,'Color',network_color(i,:),'MarkerFaceColor',network_color(i,:), ...
        'MarkerSize',8,'MarkerEdgeColor',network_color(i,:));      
    ylim([0 0.8]);
    xlim([0.5 2.5]);
       set(gca,'Xtick',1:1:3)
 set(gca,'XTickLabel',{'','1', '2'})
 set(gca,'Fontsize',18,'FontWeight','bold','LineWidth',2,'TickDir','out');
  ylabel('BOLD-ECoG FC correlation (r)'); 
  
    hold on
   set(gca,'box','off'); 
set(gca,'Fontsize',18,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
%title({[elec_name ': BOLD FC vs iEEG FC']},'Fontsize',12);
  ylim([0 0.8]);
  xlim([0.5 2.5]);
   set(gca,'Xtick',0:1:8)
 set(gca,'XTickLabel',{'', '1','2'})
ylabel('Correlation with BOLD FC (r)');
xlabel('ECoG Run');
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'BOLD_vs_ECoG_multirun_HFB']));
end
pause; close;

%plot HFB partial corr (distance-corrected)
FigHandle = figure('Position', [400, 600, 400, 700]);
figure(1)
for i=1:length(allsubs_seed_HFB_medium_allruns)
    plot(1:size(allsubs_seed_HFB_medium_allruns_partial,1),allsubs_seed_HFB_medium_allruns_partial(:,i),[subjectmarker{i,:} '-'], ...
        'LineWidth',1,'Color',network_color(i,:),'MarkerFaceColor',network_color(i,:), ...
        'MarkerSize',8,'MarkerEdgeColor',network_color(i,:));      
    ylim([0 0.8]);
    xlim([0.5 2.5]);
       set(gca,'Xtick',1:1:3)
 set(gca,'XTickLabel',{'','1', '2'})
 set(gca,'Fontsize',18,'FontWeight','bold','LineWidth',2,'TickDir','out');
  %ylabel('BOLD-ECoG FC partial correlation (r)'); 
  
    hold on
   set(gca,'box','off'); 
set(gca,'Fontsize',18,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
%title({[elec_name ': BOLD FC vs iEEG FC']},'Fontsize',12);
  ylim([0 0.8]);
  xlim([0.5 2.5]);
   set(gca,'Xtick',0:1:8)
 set(gca,'XTickLabel',{'', '1','2'})
ylabel('Partial Correlation with BOLD FC (r)');
xlabel('ECoG Run');
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'BOLD_vs_ECoG_multirun_partialcorr_HFB']));
end
pause; close;

% plot alpha corr
FigHandle = figure('Position', [400, 600, 400, 700]);
figure(1)
for i=1:length(allsubs_seed_alpha_medium_allruns)
    plot(1:size(allsubs_seed_alpha_medium_allruns,1),allsubs_seed_alpha_medium_allruns(:,i),[subjectmarker{i,:} '-'], ...
        'LineWidth',1,'Color',network_color(i,:),'MarkerFaceColor',network_color(i,:), ...
        'MarkerSize',8,'MarkerEdgeColor',network_color(i,:));      
    ylim([0 0.8]);
    xlim([0.5 2.5]);
       set(gca,'Xtick',1:1:3)
 set(gca,'XTickLabel',{'','1', '2'})
 set(gca,'Fontsize',18,'FontWeight','bold','LineWidth',2,'TickDir','out');
  ylabel('BOLD-ECoG FC correlation (r)'); 
  
    hold on
   set(gca,'box','off'); 
set(gca,'Fontsize',18,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
%title({[elec_name ': BOLD FC vs iEEG FC']},'Fontsize',12);
  ylim([0 0.8]);
  xlim([0.5 2.5]);
   set(gca,'Xtick',0:1:8)
 set(gca,'XTickLabel',{'', '1','2'})
ylabel('Correlation with BOLD FC (r)');
xlabel('ECoG Run');
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'BOLD_vs_ECoG_multirun_alpha']));
end
pause; close;

%plot alpha partial corr (distance-corrected)
FigHandle = figure('Position', [400, 600, 400, 700]);
figure(1)
for i=1:length(allsubs_seed_alpha_medium_allruns)
    plot(1:size(allsubs_seed_alpha_medium_allruns_partial,1),allsubs_seed_alpha_medium_allruns_partial(:,i),[subjectmarker{i,:} '-'], ...
        'LineWidth',1,'Color',network_color(i,:),'MarkerFaceColor',network_color(i,:), ...
        'MarkerSize',8,'MarkerEdgeColor',network_color(i,:));      
    ylim([0 0.8]);
    xlim([0.5 2.5]);
       set(gca,'Xtick',1:1:3)
 set(gca,'XTickLabel',{'','1', '2'})
 set(gca,'Fontsize',18,'FontWeight','bold','LineWidth',2,'TickDir','out');
  %ylabel('BOLD-ECoG FC partial correlation (r)'); 
  
    hold on
   set(gca,'box','off'); 
set(gca,'Fontsize',18,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
%title({[elec_name ': BOLD FC vs iEEG FC']},'Fontsize',12);
  ylim([0 0.8]);
  xlim([0.5 2.5]);
   set(gca,'Xtick',0:1:8)
 set(gca,'XTickLabel',{'', '1','2'})
ylabel('Partial Correlation with BOLD FC (r)');
xlabel('ECoG Run');
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'BOLD_vs_ECoG_multirun_partialcorr_alpha']));
end
pause; close;

