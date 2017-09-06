% Needed: manually created channel name-number mapping file (.xls format)
Patient=input('Patient: ','s'); sub=Patient;
run1name=input('Run (e.g. 1): ','s'); run1=['Run' run1name]; 
run2name=input('Run (e.g. 2): ','s'); run2=['Run' run2name];

globalECoGDir=getECoGSubDir;
fsDir=getFsurfSubDir();

% tdt=1; % tdt=1, edf=0
%edfname_run1=['E16-168_' run1name];
%edfname_run2=['E16-168_' run2name];
% if tdt==0
% rm_last=1; else rm_last=0; % remove last iEEG chan (e.g. if it is reference)
% end

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
    
%% Change bad channels to NaN
bad_indices=run1_iEEG.badchannels;

for i=1:length(bad_indices)
    run1_iEEG_ts(:,bad_indices(i))=NaN;
    run2_iEEG_ts(:,bad_indices(i))=NaN;
end

bad_indices=run2_iEEG.badchannels;
for i=1:length(bad_indices)
    run1_iEEG_ts(:,bad_indices(i))=NaN;
    run2_iEEG_ts(:,bad_indices(i))=NaN;
end

run1_allcorr=corrcoef(run1_iEEG_ts); run1_column=run1_allcorr(:);
run1_column(find(run1_column==1))=NaN;

run2_allcorr=corrcoef(run2_iEEG_ts); run2_column=run2_allcorr(:);
run2_column(find(run2_column==1))=NaN;



run1_column(isnan(run1_column)==1)=[];
run2_column(isnan(run2_column)==1)=[];

% [r,p]=corr(BOLD_short,slow_short);
% slow_vs_BOLD_short=num2str(r);

[r,p]=corr(run1_column,run2_column);
run1run2_corr=num2str(r);


figure(1)
scatter(run1_column,run2_column,'MarkerEdgeColor','k','MarkerFaceColor','k'); 
h=lsline; set(h(1),'color',[1 0 0],'LineWidth',3);
set(gca,'Fontsize',14,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
title({['Run1 vs Run2 FC spatial correlation']; ['r = ' run1run2_corr]},'Fontsize',12);
xlabel('run1 FC');
ylabel('run2 FC');
pause; close;

