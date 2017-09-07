% Needed: manually created channel name-number mapping file (.xls format)
Patient=input('Patient: ','s'); sub=Patient;
run1name=input('Run (e.g. 1): ','s'); run1=['Run' run1name]; 
run2name=input('Run (e.g. 2): ','s'); run2=['Run' run2name];
hemi=input('hemi (R or L): ','s');
depth=input('depth (1) or subdural (0) ','s');

globalECoGDir=getECoGSubDir;
fsDir=getFsurfSubDir();

%% Make output directory for figures
cd([fsDir '/' Patient '/elec_recon/electrode_spheres/SBCA/figs']);
mkdir(['iEEG_vs_iEEG']);

% Load iEEG runs
cd([globalECoGDir '/Rest/' Patient '/' run1]);
display(['1. Select Run 1 file']);
run1_iEEG=spm_eeg_load;
cd([globalECoGDir '/Rest/' Patient '/' run2]);
display(['2. Select Run 2 file']);
run2_iEEG=spm_eeg_load;

%% Organize iEEG time series into columns

 for iEEG_chan=1:size(run1_iEEG,1)
    run1_iEEG_ts(:,iEEG_chan)=run1_iEEG(iEEG_chan,:)';      
 end
 
 for iEEG_chan=1:size(run2_iEEG,1)
    run2_iEEG_ts(:,iEEG_chan)=run2_iEEG(iEEG_chan,:)';      
 end
 
 %% Get bad channels (iEEG order)
bad_indices=[run1_iEEG.badchannels run2_iEEG.badchannels];
bad_indices=unique(bad_indices);
 
%% Rearrange time series and bad chans to iElvis order (for naming) 
[iEEG_to_iElvis_chanlabel, iElvis_to_iEEG_chanlabel, chanlabels, channumbers_iEEG,elecNames] = iEEG_iElvis_transform(Patient,hemi,depth);

run1_iElvis=NaN(size(run1_iEEG_ts,1),length(chanlabels));             
run2_iElvis=NaN(size(run2_iEEG_ts,1),length(chanlabels));

for i=1:length(chanlabels);
    curr_iEEG_chan=channumbers_iEEG(i);
    new_ind=iEEG_to_iElvis_chanlabel(i);
    run1_iElvis(:,new_ind)=run1_iEEG_ts(:,curr_iEEG_chan);
    run2_iElvis(:,new_ind)=run2_iEEG_ts(:,curr_iEEG_chan);
end
       
 for i=1:length(bad_indices)
    ind_iElvis=find(iElvis_to_iEEG_chanlabel==bad_indices(i));
    if isempty(ind_iElvis)~=1
    bad_iElvis(i,:)=ind_iElvis;
    end
end
bad_chans=bad_iElvis(find(bad_iElvis>0));

%% Change bad channels to NaN
for i=1:length(bad_chans)
    run1_iElvis(:,bad_chans(i))=NaN;
    run2_iElvis(:,bad_chans(i))=NaN;
end

%% Correlate all FC pairs for good electrodes between runs
run1_allcorr=corrcoef(run1_iElvis); run1_column=run1_allcorr(:);
run1_column(find(run1_column==1))=NaN;

run2_allcorr=corrcoef(run2_iElvis); run2_column=run2_allcorr(:);
run2_column(find(run2_column==1))=NaN;
run1_column(isnan(run1_column)==1)=[];
run2_column(isnan(run2_column)==1)=[];
[r,p]=corr(run1_column,run2_column);
run1run2_corr=num2str(r);

%% Correlate between-run seed-based FC for each good electrode and plot
for i=1:size(run1_allcorr,1)
if isempty(find(bad_chans==i))==1
    elec_name=char(elecNames(i));
run1_elec_FC=run1_allcorr(:,i);
run2_elec_FC=run2_allcorr(:,i);

run1_elec_FC(find(run1_elec_FC==1))=[];
run2_elec_FC(find(run2_elec_FC==1))=[];
run1_elec_FC(find(isnan(run1_elec_FC)))=[];
run2_elec_FC(find(isnan(run2_elec_FC)))=[];

elec_run1run2_corr=corr(run1_elec_FC,run2_elec_FC);

figure(1)
scatter(run1_elec_FC,run2_elec_FC,'MarkerEdgeColor','k','MarkerFaceColor',[0 0 0]); 
h=lsline; set(h(1),'color',[0 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title([elec_name ': Run1 vs Run2 FC; r = ' num2str(elec_run1run2_corr)],'Fontsize',12);
xlabel('Run1 FC');
ylabel('Run2 FC');
set(gcf,'PaperPositionMode','auto');
print('-opengl','-r300','-dpng',strcat([pwd '/electrode_spheres/SBCA/figs/iEEG_vs_iEEG/' elec_name '_' run1 run2]));
close;

end
end


%% Plots
figure(1)
scatter(run1_column,run2_column,'MarkerEdgeColor','k','MarkerFaceColor','k'); 
h=lsline; set(h(1),'color',[1 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({['Run1 vs Run2 FC spatial correlation']; ['r = ' run1run2_corr]},'Fontsize',12);
xlabel('run1 FC');
ylabel('run2 FC');
pause; close;

