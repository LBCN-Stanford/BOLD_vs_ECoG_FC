% must first run iEEG_FC.m and BOLD_vs_ECoG_FC_corr_iElvis (to get bad
% chans)
% to remove WM electrodes, include WM_iElvis.mat list 

Patient=input('Patient: ','s');
bold_runname=input('BOLD Run (e.g. 2): ','s');
rest=input('Rest(1) Sleep(0) gradCPT (2)? ','s');
plot_all=input('Plot all electrodes (1) or one seed (0)? ','s');
Seed=input('Seed (e.g. daINS) ','s');
if plot_all=='0'
    elec_number=input('electrode number (iElvis order): ');
end
bold_run_num=['run' bold_runname];

%% defaults
globalECoGDir=getECoGSubDir;
load('cdcol.mat');
elec_highlight=40; % target electrode to highlight in plot (iElvis number)
elec_highlight2=80; 
% for S18_124, LAI7=40 ; LDP1=86; LDP7=80; LDP2=85.
elecHighlightColor=cdcol.russet';
elecHighlightColor2=cdcol.grassgreen';
elec_remove=[85]; % vector: exclude this/these electrode(s) from analysis (e.g. neighbours)
line_color=cdcol.lightblue;
BOLD_run=['run1'];
fsDir=getFsurfSubDir();


if rest=='1'
    Rest='Rest';
elseif rest=='0'
    Rest='Sleep';
elseif rest=='2'
    Rest='gradCPT';
end
cd([globalECoGDir filesep Rest filesep Patient]);

%% Load WM/out of brain electrode list
WM_iElvis=dir('WM_iElvis.mat');
if ~isempty(WM_iElvis)
    load(WM_iElvis(1,1).name);
    display('Removing white matter channels from analysis');
    elec_remove=[elec_remove; WM_iElvis];
end

%% Load BOLD data and make correlation matrix (iElvis order)
%Load channel name-number mapping (to get # of channels)
cd([fsDir '/' Patient '/elec_recon']);
[channumbers_iEEG1,chanlabels1]=xlsread('channelmap.xls');

cd([fsDir '/' Patient '/elec_recon/electrode_spheres']);

for i=1:length(chanlabels1)
    elec_num=num2str(i);
    BOLD_ts(:,i)=load(['elec' elec_num BOLD_run '_ts_FSL.txt']);
end

%% Make BOLD correlation matrix
BOLD_bad=find(BOLD_ts(1,:)==0);
BOLD_ts(:,BOLD_bad)=NaN;
BOLD_mat=corrcoef(BOLD_ts);
BOLD_mat=fisherz(BOLD_mat);

%% Load correlation matrix
if rest=='1'
cd([globalECoGDir '/Rest/' Patient]);
elseif rest=='0'
    cd([globalECoGDir '/Sleep/' Patient]);
elseif rest=='2'
    cd([globalECoGDir '/gradCPT/' Patient]);
end
parcOut=elec2Parc_v2([Patient],'DK',0);
elecNames = parcOut(:,1);

run_list=load('runs.txt');
channelmap2_runs=dir('channelmap2*');
if ~isempty(channelmap2_runs)
    channelmap2_list=load('channelmap2_runs.txt');
end

%% loop through runs
 for i=1:length(run_list)
          HFB_slow_corr=[]; curr_bad=[]; all_bad_indices=[]; bad_iElvis=[]; bad_chans=[];
          channumbers_iEEG=[]; chanlabels=[]; iEEG_to_iElvis_chanlabel=[];
          iElvis_to_iEEG_chanlabel=[];
         curr_run=num2str(run_list(i));
%% Load channel name-number mapping (iEEG vs iElvis)
cd([fsDir '/' Patient '/elec_recon']);
if isempty(channelmap2_runs)
[channumbers_iEEG,chanlabels]=xlsread('channelmap.xls');
display(['Using channelmap.xls for ' curr_run]);
else
   if ~isempty(find(i==channelmap2_list))
       [channumbers_iEEG,chanlabels]=xlsread('channelmap2.xls');
       display(['Using channelmap2.xls for ' curr_run]);
   else
       [channumbers_iEEG,chanlabels]=xlsread('channelmap.xls');
       display(['Using channelmap.xls for ' curr_run]);
   end
end

% Load channel names (in freesurfer/elec recon order)
chan_names=importdata([Patient '.electrodeNames'],' ');
fs_chanlabels={};

cd([fsDir '/' Patient '/elec_recon']);
coords=dlmread([Patient '.PIALVOX'],' ',2,0);

for chan=3:length(chan_names)
    chan_name=chan_names(chan); chan_name=char(chan_name);
    [a b]=strtok(chan_name); 
    bsize=size(strfind(b,' '),2);
    if bsize==2
    [c d]=strtok(b); 
    fs_chanlabels{chan,1}=[d(2) a];
    elseif bsize==3
    [c d]=strtok(b); [e f]=strtok(d);
    fs_chanlabels{chan,1}=[f(2) a c];
    end
end
fs_chanlabels=fs_chanlabels(3:end);

% create iEEG to iElvis chanlabel transformation vector
for j=1:length(chanlabels)
    iEEG_to_iElvis_chanlabel(j,:)=strmatch(chanlabels(j),fs_chanlabels(:,1),'exact');    
end
    for j=1:length(chanlabels)
iElvis_to_iEEG_chanlabel(j,:)=channumbers_iEEG(strmatch(fs_chanlabels(j,1),chanlabels,'exact'));
    end
    
cd([globalECoGDir filesep Rest '/' Patient '/Run' curr_run]);
% Load iEEG correlation matrix (in iElvis order)
% load('HFB_corr.mat');
% load('HFB_medium_corr.mat');
% load('alpha_medium_corr.mat');
% load('Beta1_medium_corr.mat');
% load('Beta2_medium_corr.mat');
% load('Theta_medium_corr.mat');
% load('Delta_medium_corr.mat');
% load('Gamma_medium_corr.mat');
% load('SCP_medium_corr.mat');
HFB_slow_corr=load('HFB_slow_corr.mat');
%HFB_slow_corr=fisherz(HFB_sl HFB_slow_corr);

% fisher transform
HFB_slow_mat(:,:,i)=fisherz(HFB_slow_corr.HFB_slow_corr);
%HFB_medium_mat=fisherz(HFB_medium_corr);
% HFB_mat=fisherz(HFB_corr);

% load bad indices (iEEG order)
load('all_bad_indices.mat');

% Remove bad indices (convert from iEEG to iElvis order)
% convert bad indices to iElvis
for j=1:length(all_bad_indices)
    ind_iElvis=[];
    ind_iElvis=find(iElvis_to_iEEG_chanlabel==all_bad_indices(j));
    if isempty(ind_iElvis)~=1
    bad_iElvis(j,:)=ind_iElvis;
    end
end
bad_chans=[bad_iElvis(find(bad_iElvis>0)); elec_remove];
%ignoreChans=[elecNames(bad_chans)];
 
 %% change bad chans to NaN in iEEG FC matrices
HFB_slow_mat(bad_chans,:,i)=NaN; HFB_slow_mat(:,bad_chans,i)=NaN;

 end

%% Mean iEEG FC across runs
HFB_slow_mat_mean=nanmean(HFB_slow_mat,3);
 
%% change bad chans (based on iEEG) to NaN in BOLD FC matrix
for i=1:size(HFB_slow_mat_mean,1)
    curr_corr=HFB_slow_mat_mean(:,i);
    if sum(~isnan(curr_corr))>0
       good_bad(i)=1;
    else 
        good_bad(i)=0;
    end
end
BOLD_NaN_ind=find(good_bad==0);
BOLD_mat(:,BOLD_NaN_ind)=NaN;
BOLD_mat(BOLD_NaN_ind,:)=NaN;

%% stats
if plot_all=='0'
   coords=1;
   elec=elec_number;
end

iEEG_elec_vals=HFB_slow_mat_mean(:,elec);
BOLD_elec_vals=BOLD_mat(:,elec);
curr_elecNames=elecNames;

% remove FC with self
curr_elecNames([elec])=[];
BOLD_elec_vals(elec)=[];
iEEG_elec_vals(elec)=[];


% remove FC with NaNs
curr_elecNames=curr_elecNames(~isnan(iEEG_elec_vals));
BOLD_scatter=BOLD_elec_vals(~isnan(iEEG_elec_vals));
iEEG_scatter=iEEG_elec_vals(~isnan(iEEG_elec_vals));

[corr_BOLD_vs_iEEG, p_BOLD_vs_iEEG]=corr(BOLD_scatter,iEEG_scatter);
[rho_BOLD_vs_iEEG, p_rho]=corr(BOLD_scatter,iEEG_scatter,'type','Spearman');

%% plot
cd([globalECoGDir filesep Rest '/' Patient]);
mkdir('figs'); cd('figs');

elec_title=elecNames{elec};
if elec_highlight>0
   elecHighlight=elecNames{elec_highlight};
   elecHighlight=strmatch(elecHighlight,curr_elecNames,'exact');
end
if elec_highlight2>0
   elecHighlight2=elecNames{elec_highlight2};
   elecHighlight2=strmatch(elecHighlight2,curr_elecNames,'exact');
end
x_limit=2; y_limit=.8;
y_step=.4; x_step=1;

    figure(1)
h1=scatter(BOLD_scatter,iEEG_scatter,50)
h1.MarkerFaceColor=[.2 .2 .2];
h1.MarkerEdgeColor=[.2 .2 .2];
h1.MarkerFaceAlpha=.5; h1.MarkerEdgeAlpha=.5;
%h1.MarkerType='o';
h=lsline; set(h(1),'color',line_color,'LineWidth',3);
set(gca,'Fontsize',22,'LineWidth',1,'TickDir','out');
set(gcf,'color','w');
%title({[elec_title ' FC']; ...
%    ['r = ' num2str(corr_BOLD_vs_iEEG) '; rho = ' num2str(rho_BOLD_vs_iEEG)]},'Fontsize',12);
xlabel('BOLD <0.1 Hz FC');
ylabel('HFB <0.1 Hz FC');
xlim([-x_limit x_limit]); ylim([-y_limit y_limit]);
set(gcf,'PaperPositionMode','auto');
xticks(-x_limit:x_step:x_limit);
yticks(-y_limit:y_step:y_limit);
line([-x_limit x_limit],[0 0],'LineWidth',1,'Color',[.6 .6 .6],'LineStyle','--');
line([0 0],[-y_limit y_limit],'LineWidth',1,'Color',[.6 .6 .6],'LineStyle','--');
% show highlighted electrode 1
if elecHighlight>0
hold on;
h2=scatter(BOLD_scatter(elecHighlight),iEEG_scatter(elecHighlight),100)
h2.MarkerFaceColor=elecHighlightColor; 
h2.MarkerEdgeColor=[0 0 0]; 
h1.MarkerFaceAlpha=.5; h1.MarkerEdgeAlpha=.5;
end
% show highlighted electrode 2
if elecHighlight2>0
hold on;
h2=scatter(BOLD_scatter(elecHighlight2),iEEG_scatter(elecHighlight2),100)
h2.MarkerFaceColor=elecHighlightColor2; 
h2.MarkerEdgeColor=[0 0 0]; 
h1.MarkerFaceAlpha=.5; h1.MarkerEdgeAlpha=.5;
end
print('-opengl','-r300','-dpng',[Patient '_BOLDvsIEEG_' Rest '_' Seed '.png']); 
%h2.MarkerType='o';
%h2.MarkerEdgeColor=elecHighlightColor;


    
 

      



