% must first run BOLD_vs_ECoG_FC_corr_iElvis.m

Patient=input('Patient: ','s');
bold_runname=input('BOLD Run (e.g. 2): ','s');
ecog_runname=input('ECoG Run (e.g. 2): ','s');
% hemi=input('Hemisphere (r or l): ','s');
depth=input('depth(1) or subdural(0)? ','s');
%freq=input('HFB 0.1-1Hz (1) or alpha (2) or HFB <0.1Hz (3) or SCP (4) ','s');
depth=str2num(depth);
bold_run_num=['run' bold_runname];
ecog_run_num=['run' ecog_runname];

%% Load partial corr values for each freq
globalECoGDir=getECoGSubDir;
cd([globalECoGDir '/Rest/' Patient '/Run' ecog_runname '/BOLD_ECoG_figs/GSR']);
mkdir('all_frequencies');
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

%% Make plots
cd all_frequencies

for i=1:size(corr_allseeds_allfreqs,1)
    if corr_allseeds_allfreqs(i,:)~=0
    elec_name=char(elecNames(i));
 
    plot(1:length(corr_allseeds_allfreqs(i,:)),corr_allseeds_allfreqs(i,:),'k.-', ...
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
    end
end





