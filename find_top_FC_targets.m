% Outputs top 10 and 20 percentile target regions with highest HFB
% correlation to seed based on the mean of two independent runs
% must first run iEEG_FC.m

Patient=input('Patient: ','s');
rest=input('Rest(1) Sleep(0) 7heaven (2)? ','s');
ecog_run1name=input('ECoG Run 1 (e.g. 1): ','s');
ecog_run2name=input('ECoG Run 2 (e.g. 2): ','s');
roi1=input('Seed (e.g. AFS9): ','s');
depth=input('depth(1) or subdural(0)? ','s');
hemi=input('hemi (R or L): ','s');
ecog_run1_num=['run' ecog_run1name];
ecog_run2_num=['run' ecog_run2name];

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
cd([globalECoGDir '/Rest/' Patient '/Run' ecog_run1name]);
elseif rest=='0'
    cd([globalECoGDir '/Sleep/' Patient '/Run' ecog_run1name]);
elseif rest=='2'
    cd([globalECoGDir '/7heaven/' Patient '/Run' ecog_run1name]);
end

run1_HFB=load('HFB_medium_corr.mat');
load('alpha_medium_corr.mat');
load('Beta1_medium_corr.mat');
load('Beta2_medium_corr.mat');
load('Theta_medium_corr.mat');
load('Delta_medium_corr.mat');
load('Gamma_medium_corr.mat');
run1_bad=load('all_bad_indices.mat');

if rest=='1'
cd([globalECoGDir '/Rest/' Patient '/Run' ecog_run2name]);
elseif rest=='0'
    cd([globalECoGDir '/Sleep/' Patient '/Run' ecog_run2name]);
elseif rest=='2'
    cd([globalECoGDir '/7heaven/' Patient '/Run' ecog_run2name]);
end
run2_HFB=load('HFB_medium_corr.mat');
run2_bad=load('all_bad_indices.mat');

all_bad_indices=unique([run1_bad.all_bad_indices run2_bad.all_bad_indices]);

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

seed_HFB_medium_run1=run1_HFB.HFB_medium_corr(:,roi1_num);
seed_HFB_medium_run2=run2_HFB.HFB_medium_corr(:,roi1_num);
seed_Alpha_medium=alpha_medium_corr(:,roi1_num);
seed_Beta1_medium=Beta1_medium_corr(:,roi1_num);
seed_Beta2_medium=Beta2_medium_corr(:,roi1_num);
seed_Theta_medium=Theta_medium_corr(:,roi1_num);
seed_Delta_medium=Delta_medium_corr(:,roi1_num);
seed_Gamma_medium=Gamma_medium_corr(:,roi1_num);

seed_HFB_medium_run1(bad_chans)=[]; seed_HFB_medium_run1(find(seed_HFB_medium_run1==1))=[];
seed_HFB_medium_run2(bad_chans)=[]; seed_HFB_medium_run2(find(seed_HFB_medium_run2==1))=[];
seed_Alpha_medium(bad_chans)=[]; seed_Alpha_medium(find(seed_Alpha_medium==1))=[];
seed_Beta1_medium(bad_chans)=[]; seed_Beta1_medium(find(seed_Beta1_medium==1))=[];
seed_Beta2_medium(bad_chans)=[]; seed_Beta2_medium(find(seed_Beta2_medium==1))=[];
seed_Theta_medium(bad_chans)=[]; seed_Theta_medium(find(seed_Theta_medium==1))=[];
seed_Delta_medium(bad_chans)=[]; seed_Delta_medium(find(seed_Delta_medium==1))=[];
seed_Gamma_medium(bad_chans)=[]; seed_Gamma_medium(find(seed_Gamma_medium==1))=[];

elecNames(bad_chans)=[];
elecNames(strmatch(roi1,elecNames,'exact'))=[];
seed_HFB_medium_allruns_mean=mean([seed_HFB_medium_run1 seed_HFB_medium_run2],2);

top20_prc_targets=find(seed_HFB_medium_allruns_mean>prctile(seed_HFB_medium_allruns_mean,80));
top20=elecNames(top20_prc_targets)
top10_prc_targets=find(seed_HFB_medium_allruns_mean>prctile(seed_HFB_medium_allruns_mean,90));
top10=elecNames(top10_prc_targets)