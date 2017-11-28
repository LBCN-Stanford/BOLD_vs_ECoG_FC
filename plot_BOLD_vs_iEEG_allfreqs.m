% must first run BOLD_vs_ECoG_FC_corr_iElvis.m
% dFC_preproc_list.txt file should contain subject name (column 1), sub number (column 2),
% ECoG run1 number (column 3), ECoG run2 number (column 4), electrode number (column 5), and network identity (column 6)
% network identity: 1=DMN, 2=DAN, 3=FPCN

%Patient=input('Patient: ','s');
bold_runname=input('BOLD Run (e.g. 2): ','s');
%ecog_runname=input('ECoG Run (e.g. 2): ','s');
% hemi=input('Hemisphere (r or l): ','s');
depth=input('depth(1) or subdural(0)? ','s');
%region=input('Seed location (e.g. mPFC) ','s');
%freq=input('HFB 0.1-1Hz (1) or alpha (2) or HFB <0.1Hz (3) or SCP (4) ','s');
depth=str2num(depth);
bold_run_num=['run' bold_runname];
%ecog_run_num=['run' ecog_runname];
load('cdcol.mat');

globalECoGDir=getECoGSubDir;
cd([globalECoGDir '/Rest']);
mkdir('Figs');
cd Figs;
mkdir('DMN_Core'); cd ..

%% Load subject, ECoG run number, and electrode list
list=importdata('dFC_preproc_list.txt',' ');
subjects=list.textdata;
subject_nums=list.data(:,1);
ecog_run1=list.data(:,2);
ecog_run2=list.data(:,3);
elecs=list.data(:,4);
networks=list.data(:,5);
allsubs_seedcorr_allfreqs=NaN(length(subjects),7);

for sub=1:length(subjects)
    Patient=subjects{sub}
    ecog_run1name=num2str(ecog_run1(sub));
    ecog_run2name=num2str(ecog_run2(sub));
    elec=elecs(sub)
    network=networks(sub);
%% Load corr/partial corr values for each freq
cd([globalECoGDir '/Rest/' Patient '/Run' ecog_run1name '/BOLD_ECoG_figs/GSR']);
BOLD_Delta_partial_run1=load('partialcorr_BOLD_Delta_medium_allelecs.mat');
BOLD_Theta_partial_run1=load('partialcorr_BOLD_Theta_medium_allelecs.mat');
BOLD_Alpha_partial_run1=load('partialcorr_BOLD_alpha_medium_allelecs.mat');
BOLD_Beta1_partial_run1=load('partialcorr_BOLD_beta1_medium_allelecs.mat');
BOLD_Beta2_partial_run1=load('partialcorr_BOLD_beta2_medium_allelecs.mat');
BOLD_Gamma_partial_run1=load('partialcorr_BOLD_Gamma_medium_allelecs.mat');
BOLD_HFB_partial_run1=load('partialcorr_BOLD_HFB_medium_allelecs.mat');
BOLD_Delta_run1=load('corr_BOLD_Delta_medium_allelecs.mat');
BOLD_Theta_run1=load('corr_BOLD_Theta_medium_allelecs.mat');
BOLD_Alpha_run1=load('corr_BOLD_alpha_medium_allelecs.mat');
BOLD_Beta1_run1=load('corr_BOLD_beta1_medium_allelecs.mat');
BOLD_Beta2_run1=load('corr_BOLD_beta2_medium_allelecs.mat');
BOLD_Gamma_run1=load('corr_BOLD_Gamma_medium_allelecs.mat');
BOLD_HFB_run1=load('corr_BOLD_HFB_medium_allelecs.mat');
cd ../..
run1_allfreq_FC=load('StaticFC_allfreqs.mat');

cd([globalECoGDir '/Rest/' Patient '/Run' ecog_run2name '/BOLD_ECoG_figs/GSR']);
BOLD_Delta_partial_run2=load('partialcorr_BOLD_Delta_medium_allelecs.mat');
BOLD_Theta_partial_run2=load('partialcorr_BOLD_Theta_medium_allelecs.mat');
BOLD_Alpha_partial_run2=load('partialcorr_BOLD_alpha_medium_allelecs.mat');
BOLD_Beta1_partial_run2=load('partialcorr_BOLD_beta1_medium_allelecs.mat');
BOLD_Beta2_partial_run2=load('partialcorr_BOLD_beta2_medium_allelecs.mat');
BOLD_Gamma_partial_run2=load('partialcorr_BOLD_Gamma_medium_allelecs.mat');
BOLD_HFB_partial_run2=load('partialcorr_BOLD_HFB_medium_allelecs.mat');
BOLD_Delta_run2=load('corr_BOLD_Delta_medium_allelecs.mat');
BOLD_Theta_run2=load('corr_BOLD_Theta_medium_allelecs.mat');
BOLD_Alpha_run2=load('corr_BOLD_alpha_medium_allelecs.mat');
BOLD_Beta1_run2=load('corr_BOLD_beta1_medium_allelecs.mat');
BOLD_Beta2_run2=load('corr_BOLD_beta2_medium_allelecs.mat');
BOLD_Gamma_run2=load('corr_BOLD_Gamma_medium_allelecs.mat');
BOLD_HFB_run2=load('corr_BOLD_HFB_medium_allelecs.mat');
cd ../..
run2_allfreq_FC=load('StaticFC_allfreqs.mat');

%% Load corr for other BOLD preproc pipelines
cd([globalECoGDir '/Rest/' Patient '/Run' ecog_run1name '/BOLD_ECoG_figs/AROMA']);
%AROMA_Delta=load('corr_BOLD_Delta_medium_allelecs.mat');
%AROMA_Theta=load('corr_BOLD_Theta_medium_allelecs.mat');
%AROMA_alpha=load('corr_BOLD_alpha_medium_allelecs.mat');
%AROMA_beta1=load('corr_BOLD_beta1_medium_allelecs.mat');
%AROMA_beta2=load('corr_BOLD_beta2_medium_allelecs.mat');
%AROMA_Gamma=load('corr_BOLD_Gamma_medium_allelecs.mat');
AROMA_HFB_run1=load('corr_BOLD_HFB_medium_allelecs.mat');
cd([globalECoGDir '/Rest/' Patient '/Run' ecog_run2name '/BOLD_ECoG_figs/AROMA']);
AROMA_HFB_run2=load('corr_BOLD_HFB_medium_allelecs.mat');

cd([globalECoGDir '/Rest/' Patient '/Run' ecog_run1name '/BOLD_ECoG_figs/aCompCor']);
%aCompCor_Delta=load('corr_BOLD_Delta_medium_allelecs.mat');
%aCompCor_Theta=load('corr_BOLD_Theta_medium_allelecs.mat');
%aCompCor_alpha=load('corr_BOLD_alpha_medium_allelecs.mat');
%aCompCor_beta1=load('corr_BOLD_beta1_medium_allelecs.mat');
%aCompCor_beta2=load('corr_BOLD_beta2_medium_allelecs.mat');
%aCompCor_Gamma=load('corr_BOLD_Gamma_medium_allelecs.mat');
aCompCor_HFB_run1=load('corr_BOLD_HFB_medium_allelecs.mat');
cd([globalECoGDir '/Rest/' Patient '/Run' ecog_run2name '/BOLD_ECoG_figs/aCompCor']);
aCompCor_HFB_run2=load('corr_BOLD_HFB_medium_allelecs.mat');

partialcorr_allseeds_allfreqs_run1=[BOLD_Delta_partial_run1.partialcorr_BOLD_Delta_medium_allelecs BOLD_Theta_partial_run1.partialcorr_BOLD_Theta_medium_allelecs ...
    BOLD_Alpha_partial_run1.partialcorr_BOLD_alpha_medium_allelecs BOLD_Beta1_partial_run1.partialcorr_BOLD_beta1_medium_allelecs ...
    BOLD_Beta2_partial_run1.partialcorr_BOLD_beta2_medium_allelecs BOLD_Gamma_partial_run1.partialcorr_BOLD_Gamma_medium_allelecs ... 
    BOLD_HFB_partial_run1.partialcorr_BOLD_HFB_medium_allelecs];

partialcorr_allseeds_allfreqs_run2=[BOLD_Delta_partial_run2.partialcorr_BOLD_Delta_medium_allelecs BOLD_Theta_partial_run2.partialcorr_BOLD_Theta_medium_allelecs ...
    BOLD_Alpha_partial_run2.partialcorr_BOLD_alpha_medium_allelecs BOLD_Beta1_partial_run2.partialcorr_BOLD_beta1_medium_allelecs ...
    BOLD_Beta2_partial_run2.partialcorr_BOLD_beta2_medium_allelecs BOLD_Gamma_partial_run2.partialcorr_BOLD_Gamma_medium_allelecs ... 
    BOLD_HFB_partial_run2.partialcorr_BOLD_HFB_medium_allelecs];

corr_allseeds_allfreqs_run1=[BOLD_Delta_run1.corr_BOLD_Delta_medium_allelecs BOLD_Theta_run1.corr_BOLD_Theta_medium_allelecs ...
    BOLD_Alpha_run1.corr_BOLD_alpha_medium_allelecs BOLD_Beta1_run1.corr_BOLD_beta1_medium_allelecs ...
    BOLD_Beta2_run1.corr_BOLD_beta2_medium_allelecs BOLD_Gamma_run1.corr_BOLD_Gamma_medium_allelecs ...
    BOLD_HFB_run1.corr_BOLD_HFB_medium_allelecs];

corr_allseeds_allfreqs_run2=[BOLD_Delta_run2.corr_BOLD_Delta_medium_allelecs BOLD_Theta_run2.corr_BOLD_Theta_medium_allelecs ...
    BOLD_Alpha_run2.corr_BOLD_alpha_medium_allelecs BOLD_Beta1_run2.corr_BOLD_beta1_medium_allelecs ...
    BOLD_Beta2_run2.corr_BOLD_beta2_medium_allelecs BOLD_Gamma_run2.corr_BOLD_Gamma_medium_allelecs ...
    BOLD_HFB_run2.corr_BOLD_HFB_medium_allelecs];

%AROMA_corr_all_seeds_allfreqs=[AROMA_Delta AROMA_Theta AROMA_alpha AROMA_beta1 AROMA_beta2 AROMA_Gamma AROMA_HFB];
%aCompCor_corr_all_seeds_allfreqs=[aCompCor_Delta aCompCor_Theta aCompCor_alpha aCompCor_beta1 aCompCor_beta2 aCompCor_Gamma aCompCor_HFB];

fsDir=getFsurfSubDir();
parcOut=elec2Parc_v2([Patient],'DK',0);
elecNames = parcOut(:,1);

partialcorr_seed_allfreqs_run1=partialcorr_allseeds_allfreqs_run1(elec,:);
partialcorr_seed_allfreqs_run2=partialcorr_allseeds_allfreqs_run2(elec,:);
corr_seed_allfreqs_run1=corr_allseeds_allfreqs_run1(elec,:);
corr_seed_allfreqs_run2=corr_allseeds_allfreqs_run2(elec,:);
AROMA_corr_seed_HFB_run1=AROMA_HFB_run1.corr_BOLD_HFB_medium_allelecs(elec);
aCompCor_corr_seed_HFB_run1=aCompCor_HFB_run1.corr_BOLD_HFB_medium_allelecs(elec);
AROMA_corr_seed_HFB_run2=AROMA_HFB_run2.corr_BOLD_HFB_medium_allelecs(elec);
aCompCor_corr_seed_HFB_run2=aCompCor_HFB_run2.corr_BOLD_HFB_medium_allelecs(elec);

allsubs_seedcorr_allpreproc_HFB_run1(:,sub)=[corr_seed_allfreqs_run1(7) aCompCor_corr_seed_HFB_run1 AROMA_corr_seed_HFB_run1];
allsubs_seedcorr_allpreproc_HFB_run2(:,sub)=[corr_seed_allfreqs_run2(7) aCompCor_corr_seed_HFB_run2 AROMA_corr_seed_HFB_run2];
allsubs_seedcorr_allfreqs_run1(:,sub)=corr_seed_allfreqs_run1;
allsubs_seedcorr_allfreqs_run2(:,sub)=corr_seed_allfreqs_run2;
allsubs_seedpartialcorr_allfreqs_run1(:,sub)=partialcorr_seed_allfreqs_run1;
allsubs_seedpartialcorr_allfreqs_run2(:,sub)=partialcorr_seed_allfreqs_run2;
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

% plot
% BOLD vs ECoG run1
FigHandle = figure('Position', [400, 600, 700, 300]);
figure(1)
for i=1:length(allsubs_seedcorr_allfreqs_run1)
    plot(1:size(allsubs_seedcorr_allfreqs_run1,1),allsubs_seedcorr_allfreqs_run1(:,i),[subjectmarker{i,:} '-'], ...
        'LineWidth',1,'Color',network_color(i,:),'MarkerFaceColor',network_color(i,:), ...
        'MarkerSize',8,'MarkerEdgeColor',network_color(i,:));      
    ylim([0 0.8]);
     xlim([0.5 7.5]);
       set(gca,'Xtick',0:1:8)
 set(gca,'XTickLabel',{'','δ', 'θ','α','β1','β2','γ','HFB'})
 set(gca,'Fontsize',16,'FontWeight','bold','LineWidth',2,'TickDir','out');
  ylabel({'BOLD-ECoG FC', 'Correlation (r)'}); 
  
    hold on
   set(gca,'box','off'); 
set(gca,'Fontsize',16,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
%title({[elec_name ': BOLD FC vs iEEG FC']},'Fontsize',12);
  ylim([0 0.8]);
   xlim([0.5 7.5]);
   set(gca,'Xtick',0:1:8)
 set(gca,'XTickLabel',{'', 'δ','θ', 'α','β1','β2','γ','HFB'})
ylabel({'BOLD-ECoG FC', 'Correlation (r)'}); 
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'BOLD_vs_ECoG_run1_allfreqs']));
end
pause; close;

% BOLD vs ECoG run2
FigHandle = figure('Position', [400, 600, 700, 300]);
figure(1)
for i=1:length(allsubs_seedcorr_allfreqs_run2)
    plot(1:size(allsubs_seedcorr_allfreqs_run2,1),allsubs_seedcorr_allfreqs_run2(:,i),[subjectmarker{i,:} '-'], ...
        'LineWidth',1,'Color',network_color(i,:),'MarkerFaceColor',network_color(i,:), ...
        'MarkerSize',8,'MarkerEdgeColor',network_color(i,:));      
    ylim([0 0.8]);
     xlim([0.5 7.5]);
       set(gca,'Xtick',0:1:8)
 set(gca,'XTickLabel',{'','δ', 'θ','α','β1','β2','γ','HFB'})
 set(gca,'Fontsize',16,'FontWeight','bold','LineWidth',2,'TickDir','out');
  ylabel({'BOLD-ECoG FC', 'Correlation (r)'}); 
  
    hold on
   set(gca,'box','off'); 
set(gca,'Fontsize',16,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
%title({[elec_name ': BOLD FC vs iEEG FC']},'Fontsize',12);
  ylim([0 0.8]);
   xlim([0.5 7.5]);
   set(gca,'Xtick',0:1:8)
 set(gca,'XTickLabel',{'', 'δ','θ', 'α','β1','β2','γ','HFB'})
ylabel({'BOLD-ECoG FC', 'Correlation (r)'}); 
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'BOLD_vs_ECoG_run2_allfreqs']));
end
pause; close;

% BOLD preproc vs ECoG run1
FigHandle = figure('Position', [400, 600, 400, 700]);
figure(1)
for i=1:length(allsubs_seedcorr_allpreproc_HFB_run1)   
    plot(1:size(allsubs_seedcorr_allpreproc_HFB_run1,1),allsubs_seedcorr_allpreproc_HFB_run1(:,i),[subjectmarker{i,:} '-'], ...
        'LineWidth',1,'Color',network_color(i,:),'MarkerFaceColor',network_color(i,:), ...
        'MarkerSize',8,'MarkerEdgeColor',network_color(i,:));      
    ylim([0 0.8]);
    xlim([0.5 3.5]);
       set(gca,'Xtick',0:3)
       xtickangle(45)
 set(gca,'XTickLabel',{'','GSR', 'aCompCor','AROMA'})
 set(gca,'Fontsize',18,'FontWeight','bold','LineWidth',2,'TickDir','out');
  ylabel('BOLD-ECoG FC correlation (r)'); 
  
    hold on
   set(gca,'box','off'); 
set(gca,'Fontsize',18,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
%title({[elec_name ': BOLD FC vs iEEG FC']},'Fontsize',12);
xlim([0.5 3.5])
  ylim([0 0.8]);
   set(gca,'Xtick',0:3)
   xtickangle(45)
 set(gca,'XTickLabel',{'', 'GSR','aCompCor', 'AROMA'})
ylabel('BOLD-ECoG FC correlation (r)'); 
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'BOLD_vs_ECoG_run1_allpreproc']));
end
pause; close;





