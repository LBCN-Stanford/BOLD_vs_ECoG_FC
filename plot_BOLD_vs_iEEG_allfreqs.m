% must first run BOLD_vs_ECoG_FC_corr_iElvis.m
% dFC_preproc_list.txt file should contain subject name (column 1), electrode1 name (column2), 
% electrode2 name (column 3), hemisphere (L or R; column 4),
% subject number (column 5),
% ECoG run1 number (column 6), ECoG run2 number (column 7), electrode number (column 8), 
% and network identity (column 9)
% network identity: 1=DMN, 2=DAN, 3=FPCN

load('cdcol.mat');
depth='0';
globalECoGDir=getECoGSubDir;
cd([globalECoGDir '/Rest']);
mkdir('Figs');
cd Figs;
mkdir('DMN_Core'); cd ..

%% Load subject, ECoG run number, and electrode list
list=importdata('dFC_preproc_list.txt',' ');
subjects=list.textdata(:,1);
subject_nums=list.data(:,1);
elec1_name=list.textdata(:,2);
elec2_name=list.textdata(:,3);
hemi=list.textdata(:,4);
ecog_run1=list.data(:,2);
ecog_run2=list.data(:,3);
elecs=list.data(:,4);
networks=list.data(:,5);
allsubs_seedcorr_allfreqs=NaN(length(subjects),7);


for sub=1:length(subjects)
    bad_chans_run1=[]; bad_chans_run2=[];
run1_bad=[]; run2_bad=[]; bad_iElvis_run1=[]; bad_iElvis_run2=[];

    Patient=subjects{sub}
    ecog_run1name=num2str(ecog_run1(sub));
    ecog_run2name=num2str(ecog_run2(sub));
    elec=elecs(sub)
    network=networks(sub);
    
    %% Load ECoG-HFB corr between seed and target
    cd([globalECoGDir '/Rest/' Patient '/Run' ecog_run1name]);
    HFB_pair_corr_run1=load(['StaticFC_allfreqs_' elec1_name{sub} elec2_name{sub} '.mat']);
    cd([globalECoGDir '/Rest/' Patient '/Run' ecog_run2name]);
    HFB_pair_corr_run2=load(['StaticFC_allfreqs_' elec1_name{sub} elec2_name{sub} '.mat']);
    
%% Load BOLD corr/partial corr values for each ECoG freq
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

%% Load correlation matrix for each frequency, and bad chan indices
cd([globalECoGDir '/Rest/' Patient '/Run' ecog_run1name]);
run1_HFB_medium_corr=load('HFB_medium_corr.mat');
run1_Alpha_medium_corr=load('alpha_medium_corr.mat');
run1_Beta1_medium_corr=load('Beta1_medium_corr.mat');
run1_Beta2_medium_corr=load('Beta2_medium_corr.mat');
run1_Theta_medium_corr=load('Theta_medium_corr.mat');
run1_Delta_medium_corr=load('Delta_medium_corr.mat');
run1_Gamma_medium_corr=load('Gamma_medium_corr.mat');
run1_bad=load('all_bad_indices.mat');

cd([globalECoGDir '/Rest/' Patient '/Run' ecog_run2name]);
run2_HFB_medium_corr=load('HFB_medium_corr.mat');
run2_Alpha_medium_corr=load('alpha_medium_corr.mat');
run2_Beta1_medium_corr=load('Beta1_medium_corr.mat');
run2_Beta2_medium_corr=load('Beta2_medium_corr.mat');
run2_Theta_medium_corr=load('Theta_medium_corr.mat');
run2_Delta_medium_corr=load('Delta_medium_corr.mat');
run2_Gamma_medium_corr=load('Gamma_medium_corr.mat');
run2_bad=load('all_bad_indices.mat');

%% convert from iEEG to iElvis order
[iEEG_to_iElvis_chanlabel, iElvis_to_iEEG_chanlabel, chanlabels, channumbers_iEEG,elecNames] = iEEG_iElvis_transform(Patient,hemi{sub},depth);

%% Convert bad indices to iElvis order
 for i=1:length(run1_bad.all_bad_indices)
    ind_iElvis=find(iElvis_to_iEEG_chanlabel==run1_bad.all_bad_indices(i));
    if isempty(ind_iElvis)~=1
    bad_iElvis_run1(i,:)=ind_iElvis;
    end
end
bad_chans_run1=bad_iElvis_run1(find(bad_iElvis_run1>0));

 for i=1:length(run2_bad.all_bad_indices)
    ind_iElvis=find(iElvis_to_iEEG_chanlabel==run2_bad.all_bad_indices(i));
    if isempty(ind_iElvis)~=1
    bad_iElvis_run2(i,:)=ind_iElvis;
    end
end
bad_chans_run2=bad_iElvis_run2(find(bad_iElvis_run2>0));


% Get FC values for seed and remove bad chans
parcOut=elec2Parc_v2([Patient],'DK',0);
roi1_num=strmatch(elec1_name{sub},parcOut(:,1),'exact');

seed_HFB_medium_run1=run1_HFB_medium_corr.HFB_medium_corr(:,roi1_num);
seed_Alpha_medium_run1=run1_Alpha_medium_corr.alpha_medium_corr(:,roi1_num);
seed_Beta1_medium_run1=run1_Beta1_medium_corr.Beta1_medium_corr(:,roi1_num);
seed_Beta2_medium_run1=run1_Beta2_medium_corr.Beta2_medium_corr(:,roi1_num);
seed_Theta_medium_run1=run1_Theta_medium_corr.Theta_medium_corr(:,roi1_num);
seed_Delta_medium_run1=run1_Delta_medium_corr.Delta_medium_corr(:,roi1_num);
seed_Gamma_medium_run1=run1_Gamma_medium_corr.Gamma_medium_corr(:,roi1_num);

seed_HFB_medium_run1(bad_chans_run1)=[]; seed_HFB_medium_run1(find(seed_HFB_medium_run1==1))=[];
seed_Alpha_medium_run1(bad_chans_run1)=[]; seed_Alpha_medium_run1(find(seed_Alpha_medium_run1==1))=[];
seed_Beta1_medium_run1(bad_chans_run1)=[]; seed_Beta1_medium_run1(find(seed_Beta1_medium_run1==1))=[];
seed_Beta2_medium_run1(bad_chans_run1)=[]; seed_Beta2_medium_run1(find(seed_Beta2_medium_run1==1))=[];
seed_Theta_medium_run1(bad_chans_run1)=[]; seed_Theta_medium_run1(find(seed_Theta_medium_run1==1))=[];
seed_Delta_medium_run1(bad_chans_run1)=[]; seed_Delta_medium_run1(find(seed_Delta_medium_run1==1))=[];
seed_Gamma_medium_run1(bad_chans_run1)=[]; seed_Gamma_medium_run1(find(seed_Gamma_medium_run1==1))=[];

seed_HFB_medium_run2=run2_HFB_medium_corr.HFB_medium_corr(:,roi1_num);
seed_Alpha_medium_run2=run2_Alpha_medium_corr.alpha_medium_corr(:,roi1_num);
seed_Beta1_medium_run2=run2_Beta1_medium_corr.Beta1_medium_corr(:,roi1_num);
seed_Beta2_medium_run2=run2_Beta2_medium_corr.Beta2_medium_corr(:,roi1_num);
seed_Theta_medium_run2=run2_Theta_medium_corr.Theta_medium_corr(:,roi1_num);
seed_Delta_medium_run2=run2_Delta_medium_corr.Delta_medium_corr(:,roi1_num);
seed_Gamma_medium_run2=run2_Gamma_medium_corr.Gamma_medium_corr(:,roi1_num);

seed_HFB_medium_run2(bad_chans_run2)=[]; seed_HFB_medium_run2(find(seed_HFB_medium_run2==1))=[];
seed_Alpha_medium_run2(bad_chans_run2)=[]; seed_Alpha_medium_run2(find(seed_Alpha_medium_run2==1))=[];
seed_Beta1_medium_run2(bad_chans_run2)=[]; seed_Beta1_medium_run2(find(seed_Beta1_medium_run2==1))=[];
seed_Beta2_medium_run2(bad_chans_run2)=[]; seed_Beta2_medium_run2(find(seed_Beta2_medium_run2==1))=[];
seed_Theta_medium_run2(bad_chans_run2)=[]; seed_Theta_medium_run2(find(seed_Theta_medium_run2==1))=[];
seed_Delta_medium_run2(bad_chans_run2)=[]; seed_Delta_medium_run2(find(seed_Delta_medium_run2==1))=[];
seed_Gamma_medium_run2(bad_chans_run2)=[]; seed_Gamma_medium_run2(find(seed_Gamma_medium_run2==1))=[];

%% Inter-freq correlation matrix
allfreq_FC_run1=[seed_Delta_medium_run1 seed_Theta_medium_run1 seed_Alpha_medium_run1 ...
    seed_Beta1_medium_run1 seed_Beta2_medium_run1 seed_Gamma_medium_run1 seed_HFB_medium_run1];
interfreq_FC_corr_run1=corrcoef(allfreq_FC_run1);

allfreq_FC_run2=[seed_Delta_medium_run2 seed_Theta_medium_run2 seed_Alpha_medium_run2 ...
    seed_Beta1_medium_run2 seed_Beta2_medium_run2 seed_Gamma_medium_run2 seed_HFB_medium_run2];
interfreq_FC_corr_run2=corrcoef(allfreq_FC_run2);

interfreq_FC_corr_allruns_allsubs(:,:,sub)=(interfreq_FC_corr_run1+interfreq_FC_corr_run2)/2;

%% Get BOLD vs ECoG corr values 
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

allsubs_HFB_pair_corr_run1(:,sub)=HFB_pair_corr_run1.StaticFC_allfreqs; 
allsubs_HFB_pair_corr_run2(:,sub)=HFB_pair_corr_run2.StaticFC_allfreqs; 
allsubs_HFB_pair_fisher_run1=fisherz(allsubs_HFB_pair_corr_run1);
allsubs_HFB_pair_fisher_run2=fisherz(allsubs_HFB_pair_corr_run2);

allsubs_seedcorr_allpreproc_HFB_run1(:,sub)=[corr_seed_allfreqs_run1(7) aCompCor_corr_seed_HFB_run1 AROMA_corr_seed_HFB_run1];
allsubs_seedcorr_allpreproc_HFB_run2(:,sub)=[corr_seed_allfreqs_run2(7) aCompCor_corr_seed_HFB_run2 AROMA_corr_seed_HFB_run2];
allsubs_seedcorr_allfreqs_run1(:,sub)=corr_seed_allfreqs_run1;
allsubs_seedcorr_allfreqs_run2(:,sub)=corr_seed_allfreqs_run2;
allsubs_seedcorr_allfreqs_run1_fisher=fisherz(allsubs_seedcorr_allfreqs_run1);
allsubs_seedcorr_allfreqs_run2_fisher=fisherz(allsubs_seedcorr_allfreqs_run2);
allsubs_seedpartialcorr_allfreqs_run1(:,sub)=partialcorr_seed_allfreqs_run1;
allsubs_seedpartialcorr_allfreqs_run2(:,sub)=partialcorr_seed_allfreqs_run2;

% average across runs
allsubs_HFB_pair_corr_allruns=(allsubs_HFB_pair_corr_run1+allsubs_HFB_pair_corr_run2)/2;
allsubs_seedcorr_allfreqs_allruns=(allsubs_seedcorr_allfreqs_run1+allsubs_seedcorr_allfreqs_run2)/2;
allsubs_seedpartialcorr_allfreqs_allruns=(allsubs_seedpartialcorr_allfreqs_run1+allsubs_seedpartialcorr_allfreqs_run2)/2;
allsubs_seedcorr_allpreproc_HFB_allruns=(allsubs_seedcorr_allpreproc_HFB_run1+allsubs_seedcorr_allpreproc_HFB_run2)/2;
allsubs_HFB_pair_fisher_allruns=(allsubs_HFB_pair_fisher_run1+allsubs_HFB_pair_fisher_run2)/2;
allsubs_seed_corr_allruns_fisher=(allsubs_seedcorr_allfreqs_run1_fisher+allsubs_seedcorr_allfreqs_run2_fisher)/2;
end

% average Inter-freq correlation matrices across subjects

mean_interfreq_FC_corr_allruns_allsubs=mean(interfreq_FC_corr_allruns_allsubs,3);

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

% ECoG HFB intra-network pairs
FigHandle = figure('Position', [400, 600, 700, 300]);
figure(1)
mean_HFB_pair_corr_allruns=mean(allsubs_HFB_pair_corr_allruns,2);
for i=1:length(allsubs_HFB_pair_corr_allruns)+1
    if i>length(allsubs_HFB_pair_corr_allruns)
        plot(1:size(allsubs_HFB_pair_corr_allruns,1),mean_HFB_pair_corr_allruns, ...
        'LineWidth',2,'Color','k')           
    else
    plot(1:size(allsubs_HFB_pair_corr_allruns,1),allsubs_HFB_pair_corr_allruns(:,i),[subjectmarker{i,:} '-'], ...
        'LineWidth',1,'Color',network_color(i,:),'MarkerFaceColor',network_color(i,:), ...
        'MarkerSize',8,'MarkerEdgeColor',network_color(i,:)); 
    end
    ylim([0 0.8]);
     xlim([0.5 7.5]);
       set(gca,'Xtick',0:1:8)
 set(gca,'XTickLabel',{'','δ', 'θ','α','β1','β2','γ','HFB'})
 set(gca,'Fontsize',16,'FontWeight','bold','LineWidth',2,'TickDir','out');
  ylabel({'Envelope FC', 'Correlation (r)'}); 
  
    hold on
   set(gca,'box','off'); 
set(gca,'Fontsize',16,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
%title({[elec_name ': BOLD FC vs iEEG FC']},'Fontsize',12);
  ylim([0 0.8]);
   xlim([0.5 7.5]);
   set(gca,'Xtick',0:1:8)
 set(gca,'XTickLabel',{'', 'δ','θ', 'α','β1','β2','γ','HFB'})
ylabel({'ECoG-HFB envelope', 'Correlation (r)'}); 
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'ECoG_HFB_pair_corr_bothruns']));
end
pause; close;


% BOLD vs ECoG run1+2 average
FigHandle = figure('Position', [400, 600, 700, 300]);
figure(1)
mean_seedcorr_allfreqs_allruns=mean(allsubs_seedcorr_allfreqs_allruns,2);
for i=1:length(allsubs_seedcorr_allfreqs_allruns)+1
     if i>length(allsubs_HFB_pair_corr_allruns)
        plot(1:size(allsubs_HFB_pair_corr_allruns,1),mean_seedcorr_allfreqs_allruns, ...
        'LineWidth',2,'Color','k')           
    else
    plot(1:size(allsubs_seedcorr_allfreqs_allruns,1),allsubs_seedcorr_allfreqs_allruns(:,i),[subjectmarker{i,:} '-'], ...
        'LineWidth',1,'Color',network_color(i,:),'MarkerFaceColor',network_color(i,:), ...
        'MarkerSize',8,'MarkerEdgeColor',network_color(i,:));  
     end
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
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'BOLD_vs_ECoG_allfreqs_bothruns']));
end
pause; close;

% BOLD vs ECoG run1+2 average - partial corr
FigHandle = figure('Position', [400, 600, 700, 300]);
figure(1)
mean_seedpartialcorr_allfreqs_allruns=mean(allsubs_seedpartialcorr_allfreqs_allruns,2);
for i=1:length(allsubs_seedpartialcorr_allfreqs_allruns)+1
         if i>length(allsubs_HFB_pair_corr_allruns)
        plot(1:size(allsubs_HFB_pair_corr_allruns,1),mean_seedpartialcorr_allfreqs_allruns, ...
        'LineWidth',2,'Color','k')           
    else
    plot(1:size(allsubs_seedpartialcorr_allfreqs_allruns,1),allsubs_seedpartialcorr_allfreqs_allruns(:,i),[subjectmarker{i,:} '-'], ...
        'LineWidth',1,'Color',network_color(i,:),'MarkerFaceColor',network_color(i,:), ...
        'MarkerSize',8,'MarkerEdgeColor',network_color(i,:));    
         end
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
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'BOLD_vs_ECoG_allfreqs_bothruns_partial']));
end
pause; close;

% BOLD preproc vs ECoG run1+2 average
FigHandle = figure('Position', [400, 600, 400, 700]);
figure(1)
for i=1:length(allsubs_seedcorr_allpreproc_HFB_allruns)   
    plot(1:size(allsubs_seedcorr_allpreproc_HFB_allruns,1),allsubs_seedcorr_allpreproc_HFB_allruns(:,i),[subjectmarker{i,:} '-'], ...
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
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'BOLD_vs_ECoG_allruns_allpreproc']));
end
pause; close;

%% Plot inter-frequency spatial correlation matrix (Mean across group)

interfreq_lowertri=tril(mean_interfreq_FC_corr_allruns_allsubs);
load('redblue.m');

interfreq_lowertri(find(interfreq_lowertri==0))=.5;

FigHandle = figure(1);
set(FigHandle,'Position',[50, 50, 800, 800]);
imagesc(interfreq_lowertri,[0 1]); h=colorbar('northoutside'); colormap('copper')
set(gcf,'color','w');
set(h,'fontsize',22);
set(get(h,'title'),'string','r');
set(gca,'box','off')
xticks([1 2 3 4 5 6 7])
yticklabels({'δ','θ', 'α','β1','β2','γ','HFB'})
yticks([1 2 3 4 5 6 7])
xticklabels({'δ','θ', 'α','β1','β2','γ','HFB'})
set(gca,'Fontsize',30,'Fontweight','bold')
%title(['Inter-frequency Spatial FC Correlation'])
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'Group_Interfreq_spatial_corr']));
pause; close


%% Correlate intra-network between-pair ECoG connectivity versus
%% ECoG-BOLD correlation across all frequencies, networks, subjects

[r,p]=corr(allsubs_HFB_pair_fisher_allruns(:),allsubs_seed_corr_allruns_fisher(:));
scatter(allsubs_HFB_pair_fisher_allruns(:),allsubs_seed_corr_allruns_fisher(:), ...
    'MarkerEdgeColor','k','MarkerFaceColor','k'); 
h=lsline; set(h(1),'color','k','LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title(['r = ' num2str(r) ' p = ' num2str(p)],'Fontsize',12);
xlabel('Within-network ECoG FC (z)');
ylabel('BOLD-ECoG FC correlation (z)');

%% Individual spatial correlations
for sub=1:length(subject_nums)
interfreq_lowertri=tril(interfreq_FC_corr_allruns_allsubs(:,:,sub));
load('redblue.m');

interfreq_lowertri(find(interfreq_lowertri==0))=.5;

FigHandle = figure(1);
set(FigHandle,'Position',[50, 50, 800, 800]);
imagesc(interfreq_lowertri,[0 1]); h=colorbar('northoutside'); colormap(flipud(redblue)/255)
set(gcf,'color','w');
set(h,'fontsize',22);
set(get(h,'title'),'string','r');
set(gca,'box','off')
xticks([1 2 3 4 5 6 7])
yticklabels({'δ','θ', 'α','β1','β2','γ','HFB'})
yticks([1 2 3 4 5 6 7])
xticklabels({'δ','θ', 'α','β1','β2','γ','HFB'})
set(gca,'Fontsize',30,'Fontweight','bold')
%title(['Inter-frequency Spatial FC Correlation'])
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'S' num2str(subject_nums(sub)) '_Network' num2str(networks(sub)) '_Interfreq_spatial_corr']));
pause; close

end



