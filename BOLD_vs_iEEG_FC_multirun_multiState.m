

Conditions={'gradCPT'};
Seeds={'SPL'; 'PMC'; 'daINS'};
%% Inputs
Patient=input('Patient: ','s');

%% Defaults
bold_runname='1';
plot_all='0'; % 0 = plot one seed
%chop_sec=21; % chop 21 secons from beginning
signal='4'; % HFB unsmoothed (0) smoothed (1) 0.1-1 Hz (2) <0.1 Hz (3) <1 Hz (4); must be string
load('cdcol.mat');
getECoGSubDir; global globalECoGDir;



%% Loop through conditions and seed regions
for i=1:length(Conditions)
   condition=Conditions{i};
    cd([globalECoGDir filesep  Conditions{i} filesep Patient]); 
    
    BOLD_scatter_all={}; iEEG_scatter_all={};
    elecHighlight_all=[]; elecHighlight2_all=[];
    corr_BOLD_vs_iEEG_all=[]; cutoff_all=[]; y_err_neg_all=[]; y_err_pos_all=[];
for j=1:length(Seeds)
%% Load seed, target, and neighbour electrode names
% elec1=seed, elec2=target 1 (to highlight), elec3=target 2,
% neighbour1+2=seed's neighbouring electrodes to exclude
cd([globalECoGDir filesep  'gradCPT' filesep Patient]); 
elecs=importdata([Seeds{j} '_FC.txt']);
elecs=elecs.data;
Seed=Seeds{j};
  cd([globalECoGDir filesep  Conditions{i} filesep Patient]); 
  
  % set colors for plots
    is_daINS=strmatch('daINS',Seeds{j},'exact');
    is_PMC=strmatch('PMC',Seeds{j},'exact');
    is_SPL=strmatch('SPL',Seeds{j},'exact');
    if ~isempty(is_daINS)
        line_color(j,:)=cdcol.russet; 
       elecHighlightColor(j,:)=cdcol.lightblue;
elecHighlightColor2(j,:)=cdcol.grassgreen;
    end
        if ~isempty(is_PMC)
                line_color(j,:)=cdcol.lightblue; 
       elecHighlightColor(j,:)=cdcol.grassgreen;
elecHighlightColor2(j,:)=cdcol.russet;
    end
        if ~isempty(is_SPL)
                       line_color(j,:)=cdcol.grassgreen; 
       elecHighlightColor(j,:)=cdcol.lightblue;
elecHighlightColor2(j,:)=cdcol.russet; 
        end
  
  [corr_BOLD_vs_iEEG,cutoff,y_err_neg,...
      y_err_pos,BOLD_scatter,iEEG_scatter,elecHighlight,elecHighlight2]=BOLD_vs_iEEG_FC_multirun_func(Patient,bold_runname,condition,plot_all,Seed,elecs)
BOLD_scatter_all{j}=BOLD_scatter;
iEEG_scatter_all{j}=iEEG_scatter;
elecHighlight_all=[elecHighlight_all; elecHighlight];
elecHighlight2_all=[elecHighlight2_all; elecHighlight2];
end
end


%% plot
cd([globalECoGDir filesep  Conditions{i} filesep Patient]);
mkdir('figs'); cd('figs');
x_limit=2; y_limit=.8;
y_step=.4; x_step=1;

FigHandle = figure('Position', [500, 600, 400, 900]);
for i=1:length(Seeds)
    subplot(length(Seeds),1,i);
h1=scatter(BOLD_scatter_all{i},iEEG_scatter_all{i},50)
h1.MarkerFaceColor=[.2 .2 .2];
h1.MarkerEdgeColor=[.2 .2 .2];
h1.MarkerFaceAlpha=.5; h1.MarkerEdgeAlpha=.5;
%h1.MarkerType='o';
h=lsline; set(h(1),'color',line_color(:,i),'LineWidth',3);
set(gca,'Fontsize',22,'LineWidth',1,'TickDir','out');
set(gcf,'color','w');
%title({[elec_title ' FC']; ...
%    ['r = ' num2str(corr_BOLD_vs_iEEG) '; rho = ' num2str(rho_BOLD_vs_iEEG)]},'Fontsize',12);
if i==length(Seeds)
xlabel('BOLD <0.1 Hz FC');
else
    xlabel([' ']);
end
if i==median(1:length(Seeds))
ylabel('iEEG-HFB <0.1 Hz FC');
else
    ylabel([' ']);
end
xlim([-x_limit x_limit]); ylim([-y_limit y_limit]);
set(gcf,'PaperPositionMode','auto');
xticks(-x_limit:x_step:x_limit);
yticks(-y_limit:y_step:y_limit);
line([-x_limit x_limit],[0 0],'LineWidth',1,'Color',[.6 .6 .6],'LineStyle','--');
line([0 0],[-y_limit y_limit],'LineWidth',1,'Color',[.6 .6 .6],'LineStyle','--');
% show highlighted electrode 1
if elecHighlight_all(i)>0
hold on;
h2=scatter(BOLD_scatter_all{i}(elecHighlight_all(i)),iEEG_scatter_all{i}(elecHighlight_all(i)),100)
h2.MarkerFaceColor=elecHighlightColor(i,:); 
h2.MarkerEdgeColor=[0 0 0]; 
h1.MarkerFaceAlpha=.5; h1.MarkerEdgeAlpha=.5;
end
% show highlighted electrode 2
if elecHighlight2_all>0
hold on;
h2=scatter(BOLD_scatter_all{i}(elecHighlight2_all(i)),iEEG_scatter_all{i}(elecHighlight2_all(i)),100)
h2.MarkerFaceColor=elecHighlightColor2(i,:); 
h2.MarkerEdgeColor=[0 0 0]; 
h1.MarkerFaceAlpha=.5; h1.MarkerEdgeAlpha=.5;
end
hold on;
end
print('-opengl','-r300','-dpng',[Patient '_BOLDvsIEEG_' condition '_allSeeds.png']); 
pause; close;

% x_axis=1:length(conditions);
% cutoff_TaskRest=mean(p_TaskRest_all);
% cutoff_TaskSleep=mean(p_TaskSleep_all);
% cutoff_RestSleep=mean(p_RestSleep_all);
% cutoffs=[cutoff_TaskRest cutoff_TaskSleep cutoff_RestSleep];
% 
% FigHandle = figure('Position', [500, 600, 500, 600]);
% for i=1:length(Seeds)
% y_axis=[r_TaskRest_all(i); r_TaskSleep_all(i); r_RestSleep_all(i)];
% plot(x_axis,y_axis,'o-', 'LineWidth',1,'Color',line_colors(i,:), 'MarkerSize',10, ...
%     'MarkerEdgeColor',line_colors(i,:),'MarkerFaceColor',line_colors(i,:))
%     ylim([0 1]);
%     xlim([0.5 3.5]);
%     xticks([1 2 3])
%        set(gca,'XTickLabel',{'Task-Rest','Task-Sleep','Rest-Sleep'})
%        %xtickangle(45)
%        ylabel('Spatial Correlation (r)');
%  set(gca,'Fontsize',16,'LineWidth',1,'TickDir','out');
%     set(gca,'box','off'); 
% set(gcf,'color','w');
% hold on;
% errorbar(x_axis,y_axis,y_err_neg_all(:,i),y_err_pos_all(:,i),'Color',line_colors(i,:));
% hold on;
% end
% plot(x_axis,cutoffs,'o-', 'LineWidth',1,'LineStyle','--','Color',[.6 .6 .6], 'MarkerSize',6, ...
%     'MarkerEdgeColor',[.6 .6 .6],'MarkerFaceColor',[.6 .6 .6])
% 
% print('-opengl','-r300','-dpng',[Patient '_TaskRestSleep_FC_spatialCorr_' filtering 'allSeeds.png']); 