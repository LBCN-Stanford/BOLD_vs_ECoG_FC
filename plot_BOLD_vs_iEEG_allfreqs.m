% must first run BOLD_vs_ECoG_FC_corr_iElvis.m
% DMN_Core_list.txt file should contain subject names (column 1) and
% electrode number (column 2)

%Patient=input('Patient: ','s');
bold_runname=input('BOLD Run (e.g. 2): ','s');
ecog_runname=input('ECoG Run (e.g. 2): ','s');
% hemi=input('Hemisphere (r or l): ','s');
depth=input('depth(1) or subdural(0)? ','s');
region=input('Seed location (e.g. mPFC) ','s');
%freq=input('HFB 0.1-1Hz (1) or alpha (2) or HFB <0.1Hz (3) or SCP (4) ','s');
depth=str2num(depth);
bold_run_num=['run' bold_runname];
ecog_run_num=['run' ecog_runname];

globalECoGDir=getECoGSubDir;
cd([globalECoGDir '/Rest']);
mkdir('Figs');
cd Figs;
mkdir('DMN_Core'); cd ..

%% Load DMN Core subject and electrode list
sublist=importdata('DMN_Core_list2.txt',' ');
subjects=sublist.textdata;
elecs=sublist.data;


allsubs_seedcorr_allfreqs=NaN(length(subjects),7);

for sub=1:length(subjects)
    Patient=subjects{sub}
    elec=elecs(sub)
%% Load partial corr values for each freq
cd([globalECoGDir '/Rest/' Patient '/Run' ecog_runname '/BOLD_ECoG_figs/GSR']);
load('partialcorr_BOLD_Delta_medium_allelecs.mat');
load('partialcorr_BOLD_Theta_medium_allelecs.mat');
load('partialcorr_BOLD_alpha_medium_allelecs.mat');
load('partialcorr_BOLD_beta1_medium_allelecs.mat');
load('partialcorr_BOLD_beta2_medium_allelecs.mat');
load('partialcorr_BOLD_Gamma_medium_allelecs.mat');
load('partialcorr_BOLD_HFB_medium_allelecs.mat');
load('corr_BOLD_Delta_medium_allelecs.mat');
load('corr_BOLD_Theta_medium_allelecs.mat');
load('corr_BOLD_alpha_medium_allelecs.mat');
load('corr_BOLD_beta1_medium_allelecs.mat');
load('corr_BOLD_beta2_medium_allelecs.mat');
load('corr_BOLD_Gamma_medium_allelecs.mat');
load('corr_BOLD_HFB_medium_allelecs.mat');

partialcorr_allseeds_allfreqs=[partialcorr_BOLD_Delta_medium_allelecs partialcorr_BOLD_Theta_medium_allelecs partialcorr_BOLD_alpha_medium_allelecs ...
    partialcorr_BOLD_beta1_medium_allelecs partialcorr_BOLD_beta2_medium_allelecs partialcorr_BOLD_Gamma_medium_allelecs partialcorr_BOLD_HFB_medium_allelecs];

corr_allseeds_allfreqs=[corr_BOLD_Delta_medium_allelecs corr_BOLD_Theta_medium_allelecs corr_BOLD_alpha_medium_allelecs ...
    corr_BOLD_beta1_medium_allelecs corr_BOLD_beta2_medium_allelecs corr_BOLD_Gamma_medium_allelecs corr_BOLD_HFB_medium_allelecs];

fsDir=getFsurfSubDir();
parcOut=elec2Parc_v2([Patient],'DK',0);
elecNames = parcOut(:,1);

partialcorr_seed_allfreqs=partialcorr_allseeds_allfreqs(elec,:);
corr_seed_allfreqs=corr_allseeds_allfreqs(elec,:);

allsubs_seedcorr_allfreqs(sub,:)=corr_seed_allfreqs;
allsubs_seedpartialcorr_allfreqs(sub,:)=partialcorr_seed_allfreqs;
end

%% Make plots
cd([globalECoGDir '/Rest/Figs/DMN_Core']);

%     if corr_allseeds_allfreqs(i,:)~=0
%elec_name=char(elecNames(i));
 
    plot(1:length(allsubs_seedcorr_allfreqs),allsubs_seedcorr_allfreqs','k.--', ...
        'LineWidth',2,'Color',[.6 .6 .6],'MarkerSize',25,'MarkerEdgeColor',[.3 .3 .3]);      
    ylim([0 0.8]);
       set(gca,'Xtick',0:1:8)
 set(gca,'XTickLabel',{'','δ', 'θ','α','β1','β2','γ','HFB'})
 set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
  ylabel('BOLD-ECoG FC correlation (r)'); 
  
    hold on
   set(gca,'box','off'); 
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
%title({[elec_name ': BOLD FC vs iEEG FC']},'Fontsize',12);
  ylim([0 0.8]);
   set(gca,'Xtick',0:1:8)
 set(gca,'XTickLabel',{'', 'δ','θ', 'α','β1','β2','γ','HFB'})
ylabel('BOLD-iEEG correlation (r)'); 
print('-opengl','-r300','-dpng',strcat([pwd,filesep,region '_allfreqs']));
pause; close;
%end





