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
%bold_run_num=['run1'];
%bold_run_num=['run1' bold_runname];
%ecog_run_num=['run' ecog_runname];
load('cdcol.mat');
depth='0';
globalECoGDir=getECoGSubDir;
cd([globalECoGDir '/Rest']);
mkdir('Figs');
cd Figs;
mkdir('DMN_Core'); cd ..

allsubs_HFB_vs_alpha_spatialcorr=[];

%% Load subject, ECoG run numbers, and electrode list
list=importdata('dFC_replicate.txt',' ');
subjects=list.textdata(:,1);
hemis=list.textdata(:,2);
subject_nums=list.data(:,1);
elecs=list.data(:,2);
networks=list.data(:,3);
ecog_run1=list.data(:,4); ecog_run2=list.data(:,5);
%allsubs_seedcorr_allfreqs=NaN(length(subjects),7);


%% Loop through subjects and electrodes
allsubs_HFB_vs_alpha_local_elec1=[];
allsubs_HFB_vs_alpha_local_elec2=[];
for sub=1:length(subjects)
    Patient=subjects{sub}
    run1=num2str(ecog_run1(sub));
    run2=num2str(ecog_run2(sub));
    elec=elecs(sub);
    network=networks(sub);
    hemi=hemis{sub};

    bad_chans_run1=[]; bad_run1.all_bad_indices=[]; bad_iElvis_run1=[];
    bad_chans_run2=[]; bad_run2.all_bad_indices=[]; bad_iElvis_run2=[];
% Load correlation matrix for all frequencies, bad indices, inter-electrode
% distances
cd([globalECoGDir '/Rest/' Patient '/Run' run1]);
HFB_run1=load('HFB_medium_corr.mat');
Alpha_run1=load('alpha_medium_corr.mat');
Beta1_run1=load('Beta1_medium_corr.mat');
Beta2_run1=load('Beta2_medium_corr.mat');
Theta_run1=load('Theta_medium_corr.mat');
Delta_run1=load('Delta_medium_corr.mat');
Gamma_run1=load('Gamma_medium_corr.mat');
bad_run1=load('all_bad_indices.mat');
load('distances.mat');

cd([globalECoGDir '/Rest/' Patient '/Run' run2]);
HFB_run2=load('HFB_medium_corr.mat');
Alpha_run2=load('alpha_medium_corr.mat');
Beta1_run2=load('Beta1_medium_corr.mat');
Beta2_run2=load('Beta2_medium_corr.mat');
Theta_run2=load('Theta_medium_corr.mat');
Delta_run2=load('Delta_medium_corr.mat');
Gamma_run2=load('Gamma_medium_corr.mat');
bad_run2=load('all_bad_indices.mat');
load('distances.mat');

iElvis_to_iEEG_chanlabel=[];
% convert from iEEG to iElvis order
[iEEG_to_iElvis_chanlabel, iElvis_to_iEEG_chanlabel, chanlabels, channumbers_iEEG,elecNames] = iEEG_iElvis_transform(Patient,hemi,depth);

% Convert bad indices to iElvis order
 for i=1:length(bad_run1.all_bad_indices)
    ind_iElvis=find(iElvis_to_iEEG_chanlabel==bad_run1.all_bad_indices(i));
    if isempty(ind_iElvis)~=1
    bad_iElvis_run1(i,:)=ind_iElvis;
    end
end
bad_chans_run1=bad_iElvis_run1(find(bad_iElvis_run1>0));

 for i=1:length(bad_run2.all_bad_indices)
    ind_iElvis=find(iElvis_to_iEEG_chanlabel==bad_run2.all_bad_indices(i));
    if isempty(ind_iElvis)~=1
    bad_iElvis_run2(i,:)=ind_iElvis;
    end
end
bad_chans_run2=bad_iElvis_run2(find(bad_iElvis_run2>0));

seed_distances_run1=[]; seed_distances_run2=[];
seed_HFB_medium_run1=[]; seed_Alpha_medium_run1=[];
% extract FC values from seed
seed_HFB_medium_run1=HFB_run1.HFB_medium_corr(:,elec);
seed_Alpha_medium_run1=Alpha_run1.alpha_medium_corr(:,elec);
seed_Beta1_medium_run1=Beta1_run1.Beta1_medium_corr(:,elec);
seed_Beta2_medium_run1=Beta2_run1.Beta2_medium_corr(:,elec);
seed_Theta_medium_run1=Theta_run1.Theta_medium_corr(:,elec);
seed_Delta_medium_run1=Delta_run1.Delta_medium_corr(:,elec);
seed_Gamma_medium_run1=Gamma_run1.Gamma_medium_corr(:,elec);
seed_distances_run1=distances(:,elec);

seed_HFB_medium_run1(bad_chans_run1)=[]; seed_HFB_medium_run1(find(seed_HFB_medium_run1==1))=[];
seed_Alpha_medium_run1(bad_chans_run1)=[]; seed_Alpha_medium_run1(find(seed_Alpha_medium_run1==1))=[];
seed_Beta1_medium_run1(bad_chans_run1)=[]; seed_Beta1_medium_run1(find(seed_Beta1_medium_run1==1))=[];
seed_Beta2_medium_run1(bad_chans_run1)=[]; seed_Beta2_medium_run1(find(seed_Beta2_medium_run1==1))=[];
seed_Theta_medium_run1(bad_chans_run1)=[]; seed_Theta_medium_run1(find(seed_Theta_medium_run1==1))=[];
seed_Delta_medium_run1(bad_chans_run1)=[]; seed_Delta_medium_run1(find(seed_Delta_medium_run1==1))=[];
seed_Gamma_medium_run1(bad_chans_run1)=[]; seed_Gamma_medium_run1(find(seed_Gamma_medium_run1==1))=[];
seed_distances_run1([elec; bad_chans_run1])=[];

seed_HFB_medium_run2=HFB_run2.HFB_medium_corr(:,elec);
seed_Alpha_medium_run2=Alpha_run2.alpha_medium_corr(:,elec);
seed_Beta1_medium_run2=Beta1_run2.Beta1_medium_corr(:,elec);
seed_Beta2_medium_run2=Beta2_run2.Beta2_medium_corr(:,elec);
seed_Theta_medium_run2=Theta_run2.Theta_medium_corr(:,elec);
seed_Delta_medium_run2=Delta_run2.Delta_medium_corr(:,elec);
seed_Gamma_medium_run2=Gamma_run2.Gamma_medium_corr(:,elec);
seed_distances_run2=distances(:,elec);

seed_HFB_medium_run2(bad_chans_run2)=[]; seed_HFB_medium_run2(find(seed_HFB_medium_run2==1))=[];
seed_Alpha_medium_run2(bad_chans_run2)=[]; seed_Alpha_medium_run2(find(seed_Alpha_medium_run2==1))=[];
seed_Beta1_medium_run2(bad_chans_run2)=[]; seed_Beta1_medium_run2(find(seed_Beta1_medium_run2==1))=[];
seed_Beta2_medium_run2(bad_chans_run2)=[]; seed_Beta2_medium_run2(find(seed_Beta2_medium_run2==1))=[];
seed_Theta_medium_run2(bad_chans_run2)=[]; seed_Theta_medium_run2(find(seed_Theta_medium_run2==1))=[];
seed_Delta_medium_run2(bad_chans_run2)=[]; seed_Delta_medium_run2(find(seed_Delta_medium_run2==1))=[];
seed_Gamma_medium_run2(bad_chans_run2)=[]; seed_Gamma_medium_run2(find(seed_Gamma_medium_run2==1))=[];
seed_distances_run2([elec; bad_chans_run2])=[];

% Inter-freq correlations

HFB_alpha_corr_run1(sub,:)=corr(seed_HFB_medium_run1,seed_Alpha_medium_run1);
HFB_alpha_partialcorr_run1(sub,:)=partialcorr(seed_HFB_medium_run1,seed_Alpha_medium_run1,seed_distances_run1);

HFB_alpha_corr_run2(sub,:)=corr(seed_HFB_medium_run2,seed_Alpha_medium_run2);
HFB_alpha_partialcorr_run2(sub,:)=partialcorr(seed_HFB_medium_run2,seed_Alpha_medium_run2,seed_distances_run2);
end
HFB_alpha_corr_allruns=[HFB_alpha_corr_run1'; HFB_alpha_corr_run2'];
HFB_alpha_partialcorr_allruns=[HFB_alpha_partialcorr_run1'; HFB_alpha_partialcorr_run2'];



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

% plot HFB vs alpha spatial corr in both runs
FigHandle = figure('Position', [400, 600, 400, 700]);
figure(1)
for i=1:length(HFB_alpha_corr_allruns)
    plot(1:size(HFB_alpha_corr_allruns,1),HFB_alpha_corr_allruns(:,i),[subjectmarker{i,:} '-'], ...
        'LineWidth',1,'Color',network_color(i,:),'MarkerFaceColor',network_color(i,:), ...
        'MarkerSize',8,'MarkerEdgeColor',network_color(i,:));      
    ylim([0 0.8]);
    xlim([0.5 2.5]);
       set(gca,'Xtick',1:1:3)
 set(gca,'XTickLabel',{'','1', '2'})
 set(gca,'Fontsize',18,'FontWeight','bold','LineWidth',2,'TickDir','out');
  
    hold on
   set(gca,'box','off'); 
set(gca,'Fontsize',18,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
%title({[elec_name ': BOLD FC vs iEEG FC']},'Fontsize',12);
  ylim([0 0.8]);
  xlim([0.5 2.5]);
   set(gca,'Xtick',0:1:8)
 set(gca,'XTickLabel',{'', '1','2'})
ylabel('HFB-alpha FC correlation (r)');
xlabel('ECoG Run');
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'HFB_vs_alpha_spatialcorr_multirun']));
end
pause; close;

% plot HFB vs alpha partial corr

FigHandle = figure('Position', [400, 600, 400, 700]);
figure(1)
for i=1:length(HFB_alpha_partialcorr_allruns)
    plot(1:size(HFB_alpha_partialcorr_allruns,1),HFB_alpha_partialcorr_allruns(:,i),[subjectmarker{i,:} '-'], ...
        'LineWidth',1,'Color',network_color(i,:),'MarkerFaceColor',network_color(i,:), ...
        'MarkerSize',8,'MarkerEdgeColor',network_color(i,:));      
    ylim([0 0.8]);
    xlim([0.5 2.5]);
       set(gca,'Xtick',1:1:3)
 set(gca,'XTickLabel',{'','1', '2'})
 set(gca,'Fontsize',18,'FontWeight','bold','LineWidth',2,'TickDir','out');
  
    hold on
   set(gca,'box','off'); 
set(gca,'Fontsize',18,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
%title({[elec_name ': BOLD FC vs iEEG FC']},'Fontsize',12);
  ylim([0 0.8]);
  xlim([0.5 2.5]);
   set(gca,'Xtick',0:1:8)
 set(gca,'XTickLabel',{'', '1','2'})
ylabel('HFB-alpha FC partial correlation (r)');
xlabel('ECoG Run');
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'HFB_vs_alpha_spatialcorr_multirun_partial']));
end
pause; close;


