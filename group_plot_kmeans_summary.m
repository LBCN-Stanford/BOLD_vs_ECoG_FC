% must first run plot_dFC_pair.m and then dFC_states_BOLD_vs_iEEG.m for each seed, subject and frequency

% network identity: 1=DMN, 2=DAN, 3=FPCN

% kmeans_summary.txt file should contain subject name (column 1), electrode1 name (column 2),
% electrode2 name (column 3), subject number (4) run number (5), network number
% (6),

load('cdcol.mat');
fsDir=getFsurfSubDir();
globalECoGDir=getECoGSubDir;
cd([globalECoGDir '/Rest']);
mkdir('Figs');
cd Figs;
mkdir('dFC_analysis'); cd ..

%% Load subject, ECoG run numbers, and electrode list
cd(['dFC_analysis']);
list=importdata('kmeans_summary.txt',' ');
subjects=list.textdata(:,1);
subject_nums=list.data(:,1);
roi1=list.textdata(:,2); roi2=list.textdata(:,3);
run_num=list.data(:,2);
networks=list.data(:,3);

%% Loop through subjects and electrodes
%allsubs_HFB=[];

for sub=1:length(subjects)
    Patient=subjects{sub}
    run1=num2str(run_num(sub));
    elec1=roi1(sub);
    elec2=roi2(sub);
    network=networks(sub);
%% Load BOLD vs ECoG between-state change correlations for each freqeuency
cd([globalECoGDir '/Rest/' Patient '/Run' run1]);
HFB_k2_30sec=load([char(elec1) '_k1k2BOLD_vs_iEEG_change_HFB_30.mat']);
Delta_k2_30sec=load([char(elec1) '_k1k2BOLD_vs_iEEG_change_Delta_30.mat']);
Theta_k2_30sec=load([char(elec1) '_k1k2BOLD_vs_iEEG_change_Theta_30.mat']);
Alpha_k2_30sec=load([char(elec1) '_k1k2BOLD_vs_iEEG_change_Alpha_30.mat']);
Beta1_k2_30sec=load([char(elec1) '_k1k2BOLD_vs_iEEG_change_Beta1_30.mat']);
Beta2_k2_30sec=load([char(elec1) '_k1k2BOLD_vs_iEEG_change_Beta2_30.mat']);
Gamma_k2_30sec=load([char(elec1) '_k1k2BOLD_vs_iEEG_change_Gamma_30.mat']);

%% Extract r value (absolute value for k=2) and concatenate frequencies
HFB_k2_30sec=abs(HFB_k2_30sec.k1k2BOLD_vs_iEEG_change(1));
Delta_k2_30sec=abs(Delta_k2_30sec.k1k2BOLD_vs_iEEG_change(1));
Theta_k2_30sec=abs(Theta_k2_30sec.k1k2BOLD_vs_iEEG_change(1));
Alpha_k2_30sec=abs(Alpha_k2_30sec.k1k2BOLD_vs_iEEG_change(1));
Beta1_k2_30sec=abs(Beta1_k2_30sec.k1k2BOLD_vs_iEEG_change(1));
Beta2_k2_30sec=abs(Beta2_k2_30sec.k1k2BOLD_vs_iEEG_change(1));
Gamma_k2_30sec=abs(Gamma_k2_30sec.k1k2BOLD_vs_iEEG_change(1));

k2_30sec_allfreqs=[Delta_k2_30sec Theta_k2_30sec Alpha_k2_30sec Beta1_k2_30sec Beta2_k2_30sec Gamma_k2_30sec HFB_k2_30sec];
%% Concatenate across subjects
k2_30sec_allfreqs_allsubs(sub,:)=k2_30sec_allfreqs;

end
k2_30sec_allfreqs_allsubs=k2_30sec_allfreqs_allsubs';

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
        subjectmarker{i,:}='^';
        
    end
end

% plot
FigHandle = figure('Position', [400, 600, 700, 300]);
figure(1)
mean_k2_30sec_allfreqs_allsubs=mean(k2_30sec_allfreqs_allsubs,2);
for i=1:length(k2_30sec_allfreqs_allsubs)+1
    if i>length(k2_30sec_allfreqs_allsubs)
        plot(1:size(k2_30sec_allfreqs_allsubs,1),mean_k2_30sec_allfreqs_allsubs, ...
        'LineWidth',2,'Color','k')           
    else
    plot(1:size(k2_30sec_allfreqs_allsubs,1),k2_30sec_allfreqs_allsubs(:,i),[subjectmarker{i,:} '-'], ...
        'LineWidth',1,'Color',network_color(i,:),'MarkerFaceColor',network_color(i,:), ...
        'MarkerSize',8,'MarkerEdgeColor',network_color(i,:)); 
    end
    ylim([0 0.8]);
     xlim([0.5 7.5]);
       set(gca,'Xtick',0:1:8)
 set(gca,'XTickLabel',{'','δ', 'θ','α','β1','β2','γ','HFB'})
 set(gca,'Fontsize',12,'FontWeight','bold','LineWidth',2,'TickDir','out');
  ylabel({'BOLD-ECoG Between-state', 'Change Correspondence (r)'}); 
  
    hold on
   set(gca,'box','off'); 
set(gca,'Fontsize',12,'FontWeight','bold','LineWidth',2,'TickDir','out');
set(gcf,'color','w');
%title({[elec_name ': BOLD FC vs iEEG FC']},'Fontsize',12);
  ylim([0 0.8]);
   xlim([0.5 7.5]);
   set(gca,'Xtick',0:1:8)
 set(gca,'XTickLabel',{'', 'δ','θ', 'α','β1','β2','γ','HFB'})
ylabel({'BOLD-ECoG Between-state', 'Change Correspondence (r)'}); 
print('-opengl','-r300','-dpng',strcat([pwd,filesep,'BOLD_vs_ECoG_k2_30sec']));
end
pause; close;




