% Plot correlation matrices for inter-frequency FC spatial correlation from
% a given seed region to all other (non-bad) electrodes
% also outputs top 10 and 20 percentile target regions with highest HFB
% correlation to seed
% must first run iEEG_FC.m

Patient=input('Patient: ','s');
rest=input('Rest(1) Sleep(0) 7heaven (2)? ','s');
ecog_runname=input('ECoG Run (e.g. 2): ','s');
roi1=input('Seed (e.g. AFS9): ','s');
depth=input('depth(1) or subdural(0)? ','s');
hemi=input('hemi (R or L): ','s');
ecog_run_num=['run' ecog_runname];

fsDir=getFsurfSubDir();
cd([fsDir '/' Patient '/elec_recon']);
coords=dlmread([Patient '.PIALVOX'],' ',2,0);
parcOut=elec2Parc_v2([Patient],'DK',0);
elecNames = parcOut(:,1);

if rest=='1'
    Rest='Rest';
elseif rest=='0'
    Rest='Sleep';
elseif rest=='2'
    Rest='7heaven';
end

%% Load correlation matrix for all frequencies
globalECoGDir=getECoGSubDir;
if rest=='1'
cd([globalECoGDir '/Rest/' Patient '/Run' ecog_runname]);
elseif rest=='0'
    cd([globalECoGDir '/Sleep/' Patient '/Run' ecog_runname]);
elseif rest=='2'
    cd([globalECoGDir '/7heaven/' Patient '/Run' ecog_runname]);
end

load('HFB_medium_corr.mat');
load('alpha_medium_corr.mat');
load('Beta1_medium_corr.mat');
load('Beta2_medium_corr.mat');
load('Theta_medium_corr.mat');
load('Delta_medium_corr.mat');
load('Gamma_medium_corr.mat');
load('all_bad_indices.mat');

%% convert from iEEG to iElvis order
[iEEG_to_iElvis_chanlabel, iElvis_to_iEEG_chanlabel, chanlabels, channumbers_iEEG,elecNames] = iEEG_iElvis_transform(Patient,hemi,depth);

%% Convert bad indices to iElvis order
 for i=1:length(all_bad_indices)
    ind_iElvis=find(iElvis_to_iEEG_chanlabel==all_bad_indices(i));
    if isempty(ind_iElvis)~=1
    bad_iElvis(i,:)=ind_iElvis;
    end
end
bad_chans=bad_iElvis(find(bad_iElvis>0));

%% Get FC values for seed and remove bad chans
roi1_num=strmatch(roi1,parcOut(:,1),'exact');

seed_HFB_medium=HFB_medium_corr(:,roi1_num);
seed_Alpha_medium=alpha_medium_corr(:,roi1_num);
seed_Beta1_medium=Beta1_medium_corr(:,roi1_num);
seed_Beta2_medium=Beta2_medium_corr(:,roi1_num);
seed_Theta_medium=Theta_medium_corr(:,roi1_num);
seed_Delta_medium=Delta_medium_corr(:,roi1_num);
seed_Gamma_medium=Gamma_medium_corr(:,roi1_num);

seed_HFB_medium(bad_chans)=[]; seed_HFB_medium(find(seed_HFB_medium==1))=[];
seed_Alpha_medium(bad_chans)=[]; seed_Alpha_medium(find(seed_Alpha_medium==1))=[];
seed_Beta1_medium(bad_chans)=[]; seed_Beta1_medium(find(seed_Beta1_medium==1))=[];
seed_Beta2_medium(bad_chans)=[]; seed_Beta2_medium(find(seed_Beta2_medium==1))=[];
seed_Theta_medium(bad_chans)=[]; seed_Theta_medium(find(seed_Theta_medium==1))=[];
seed_Delta_medium(bad_chans)=[]; seed_Delta_medium(find(seed_Delta_medium==1))=[];
seed_Gamma_medium(bad_chans)=[]; seed_Gamma_medium(find(seed_Gamma_medium==1))=[];

elecNames(bad_chans)=[];
elecNames(strmatch(roi1,elecNames,'exact'))=[];
top20_prc_targets=find(seed_HFB_medium>prctile(seed_HFB_medium,80));
elecNames(top20_prc_targets)
top10_prc_targets=find(seed_HFB_medium>prctile(seed_HFB_medium,90));
elecNames(top10_prc_targets)

%% Inter-freq correlation matrix
allfreq_FC=[seed_Delta_medium seed_Theta_medium seed_Alpha_medium seed_Beta1_medium seed_Beta2_medium seed_Gamma_medium seed_HFB_medium];
interfreq_FC_corr=corrcoef(allfreq_FC);

%% Plot matrix
cd(['electrode_spheres/SBCA/figs/iEEG']);
mkdir(['Interfreq']); cd(['Interfreq'])
interfreq_lowertri=tril(interfreq_FC_corr);
load('redblue.m');

FigHandle = figure(1);
set(FigHandle,'Position',[50, 50, 800, 800]);
imagesc(interfreq_lowertri,[-1 1]); h=colorbar('northoutside'); colormap(flipud(redblue)/255)
set(gcf,'color','w');
set(h,'fontsize',11);
set(get(h,'title'),'string','r');
set(gca,'box','off')
xticks([1 2 3 4 5 6 7])
yticklabels({'δ','θ', 'α','β1','β2','γ','HFB'})
yticks([1 2 3 4 5 6 7])
xticklabels({'δ','θ', 'α','β1','β2','γ','HFB'})
set(gca,'Fontsize',24,'Fontweight','bold')
%title(['Inter-frequency Spatial FC Correlation'])
print('-opengl','-r300','-dpng',strcat([pwd,filesep,[roi1 'Interfreq_spatial_corr']]));
pause; close


