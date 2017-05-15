% plot sliding-window dFC for a pair of regions - BOLD

Patient=input('Patient: ','s');
BOLD=input('BOLD (1) or iEEG (2): ','s');
runs=input('run (e.g. 1): ','s');
roi1=input('ROI 1 (e.g. AFS9): ','s');
roi2=input('ROI 2 (e.g. PIHS4): ','s');

if BOLD=='1'
    BOLD=['BOLD'];
else BOLD=['iEEG'];
end

%% BOLD Defaults
TR=2; % fMRI TR in seconds
BOLD_step=1; % step length (number of TRs)
BOLD_window_size=15; % number of TRs per window
BOLD_window_duration=TR*BOLD_window_size;

runnum=['run' runs];
fsDir=getFsurfSubDir();

parcOut=elec2Parc_v2([Patient],'DK',0);
elecNames = parcOut(:,1);
%% Convert ROI names to numbers
roi1_num=strmatch(roi1,parcOut(:,1),'exact');
roi2_num=strmatch(roi2,parcOut(:,1),'exact');

%% Load ROI time series
cd([fsDir '/' Patient '/elec_recon/electrode_spheres']);

roi1_ts=load(['elec' num2str(roi1_num) runnum '_ts_GSR.txt']);
roi2_ts=load(['elec' num2str(roi2_num) runnum '_ts_GSR.txt']);

%% Static FC
static_fc=corr(roi1_ts,roi2_ts);

%% Sliding windows
if BOLD=='BOLD'
for i=1:BOLD_step:length(roi1_ts)-BOLD_window_size;
    a=i+BOLD_window_size;
    roi1_window_ts=roi1_ts(i:a);
    roi2_window_ts=roi2_ts(i:a);
    window_corr=corr(roi1_window_ts,roi2_window_ts);
    window_fisher=fisherz(window_corr);
    all_windows_corr(i,:)=window_corr;
    all_windows_fisher(i,:)=window_fisher;
end
end

%% Normalize time series
roi1_ts_norm=(roi1_ts-mean(roi1_ts))/std(roi1_ts);
roi2_ts_norm=(roi2_ts-mean(roi2_ts))/std(roi2_ts);

%% Plots
% Static FC
FigHandle = figure('Position', [200, 600, 1200, 800]);
figure(1)
subplot(2,1,1);
title({[BOLD ': ' roi1 ' vs ' roi2]; ['r = ' num2str(static_fc)]} ,'Fontsize',12);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
hold on;
plot(1:length(roi1_ts),roi1_ts_norm,1:length(roi2_ts),roi2_ts_norm,'LineWidth',2);

hold on;

% Dynamic FC
subplot(2,1,2);
%set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
%hold on;
plot(1:length(all_windows_fisher),all_windows_fisher,'LineWidth',2);
title({['Dynamic FC: ' roi1 ' vs ' roi2]; ['FCV = ' num2str(std(all_windows_fisher))]} ,'Fontsize',12);
set(gca,'Fontsize',14,'Fontweight','bold','LineWidth',2,'TickDir','out','box','off');
pause; close;



