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
mkdir('DMN_Core');

%% Load DMN Core subject and electrode list
sublist=importdata('DMN_Core_list.txt',' ');
subjects=sublist.textdata;
elecs=sublist.data;


allsubs_seedcorr_allfreqs=NaN(length(subjects),7);

for sub=1:length(subjects)
    Patient=subjects{sub}
    elec=elecs(sub)
%% Load partial corr values for each freq
cd([globalECoGDir '/Rest/' Patient '/Run' ecog_runname '/BOLD_ECoG_figs/GSR']);
load('partialcorr_BOLD_Delta_allelecs.mat');
load('partialcorr_BOLD_Theta_allelecs.mat');
load('partialcorr_BOLD_alpha_allelecs.mat');
load('partialcorr_BOLD_beta1_allelecs.mat');
load('partialcorr_BOLD_beta2_allelecs.mat');
load('partialcorr_BOLD_Gamma_allelecs.mat');
load('partialcorr_BOLD_HFB_allelecs.mat');

corr_allseeds_allfreqs=[partialcorr_BOLD_Delta_allelecs partialcorr_BOLD_Theta_allelecs partialcorr_BOLD_alpha_allelecs ...
    partialcorr_BOLD_beta1_allelecs partialcorr_BOLD_beta2_allelecs partialcorr_BOLD_Gamma_allelecs partialcorr_BOLD_HFB_allelecs];

fsDir=getFsurfSubDir();
parcOut=elec2Parc_v2([Patient],'DK',0);
elecNames = parcOut(:,1);

corr_seed_allfreqs=corr_allseeds_allfreqs(elec,:);

allsubs_seedcorr_allfreqs(sub,:)=corr_seed_allfreqs;
end

%% Make plots
cd([globalECoGDir '/Rest/Figs/DMN_Core']);

%     if corr_allseeds_allfreqs(i,:)~=0
%     elec_name=char(elecNames(i));
 
    plot(1:length(allsubs_seedcorr_allfreqs),allsubs_seedcorr_allfreqs','k.-', ...
        'LineWidth',2,'Color',[.8 .8 .8],'MarkerSize',20,'MarkerEdgeColor',[.6 .6 .6]);
    
    hold on
   set(gca,'box','off'); 
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({[elec_name ': BOLD FC vs iEEG FC']},'Fontsize',12);
  ylim([0 1]);
   set(gca,'Xtick',0:1:8)
 set(gca,'XTickLabel',{'', 'θ', 'δ', 'α','β1','β2','γ','HFB'})
ylabel('BOLD-ECoG partial correlation (r)'); 
print('-opengl','-r300','-dpng',strcat([pwd,filesep,elec_name '_allfreqs']));
close;
%     end





