
Conditions={'gradCPT'; 'Rest'; 'Sleep'};
%Conditions={'gradCPT'; 'Rest'; 'Sleep';};
Seeds={'SPL'; 'PMC'; 'daINS'};
SeedLabels={'DPC';'PMC'; 'daIC'};
%% Inputs
Patient=input('Patient: ','s');

%% Defaults
bold_runname='1';
plot_all='0'; % 0 = plot one seed
%chop_sec=21; % chop 21 secons from beginning
signal='3'; % HFB unsmoothed (0) smoothed (1) 0.1-1 Hz (2) <0.1 Hz (3) <1 Hz (4); must be string
load('cdcol.mat');
getECoGSubDir; global globalECoGDir;

if signal=='3'
   filtering='slow'; 
elseif signal=='2'
    filtering='medium';
elseif signal=='0'
    filtering='unfiltered';
end

%% Loop through conditions and seed regions
 corr_BOLD_vs_iEEG_all={}; 
 cutoff_all={}; y_err_neg_all={}; y_err_pos_all={};
 r_allCond=[]; p_allCond=[];
for i=1:length(Conditions)
   condition=Conditions{i};
    cd([globalECoGDir filesep  Conditions{i} filesep Patient]); 
    
    BOLD_scatter_all={}; iEEG_scatter_all={};
    elecHighlight_all=[]; elecHighlight2_all=[];
 
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
      y_err_pos,BOLD_scatter,iEEG_scatter,elecHighlight,elecHighlight2]=BOLD_vs_iEEG_FC_multirun_func(Patient,bold_runname,condition,plot_all,Seed,elecs,signal)
BOLD_scatter_all{j}=BOLD_scatter;
iEEG_scatter_all{j}=iEEG_scatter;
elecHighlight_all=[elecHighlight_all; elecHighlight];
elecHighlight2_all=[elecHighlight2_all; elecHighlight2];
corr_BOLD_vs_iEEG_all{i,j}=corr_BOLD_vs_iEEG;
cutoff_all{i,j}=cutoff; 
y_err_neg_all{i,j}=y_err_neg; 
y_err_pos_all{i,j}=y_err_pos;
end

%% concatenate data across seeds and correlate BOLD vs iEEG
BOLD_scatter_allSeeds=[]; iEEG_scatter_allSeeds=[];
% extract seed-seed corr values
if size(BOLD_scatter_all,2)==3 % assuming order: SPL, PMC, daINS
   BOLD_pair1=BOLD_scatter_all{:,1}(elecHighlight_all(1)); % SPL-PMC
   iEEG_pair1=iEEG_scatter_all{:,1}(elecHighlight_all(1));
   BOLD_pair2=BOLD_scatter_all{:,1}(elecHighlight2_all(1)); % SPL-daINS
   iEEG_pair2=iEEG_scatter_all{:,1}(elecHighlight2_all(1));
   BOLD_pair3=BOLD_scatter_all{:,2}(elecHighlight2_all(2)); % PMC-daINS
   iEEG_pair3=iEEG_scatter_all{:,2}(elecHighlight2_all(2));
elseif size(BOLD_scatter_all,2)==2
    BOLD_pair1=BOLD_scatter_all{:,1}(elecHighlight_all(1)); % SPL-PMC
   iEEG_pair1=iEEG_scatter_all{:,1}(elecHighlight_all(1));
end

for k=1:size(BOLD_scatter_all,2)
    curr_BOLD_scatter=BOLD_scatter_all{:,k};
    curr_iEEG_scatter=iEEG_scatter_all{:,k};
    %seed_pair1_BOLD(i,:)=curr_BOLD_scatter(elecHighlight_all(i));
    %seed_pair1_iEEG(i,:)=curr_iEEG_scatter(elecHighlight_all(i));
    if elecHighlight2_all(k)>0
    curr_BOLD_scatter([elecHighlight_all(k) elecHighlight2_all(k)])=[]; % remove seed pair from main list
    curr_iEEG_scatter([elecHighlight_all(k) elecHighlight2_all(k)])=[];
    else
    curr_BOLD_scatter([elecHighlight_all(k)])=[]; % remove seed pair from main list
    curr_iEEG_scatter([elecHighlight_all(k)])=[]; 
    end
    BOLD_scatter_allSeeds=[BOLD_scatter_allSeeds; curr_BOLD_scatter];
    iEEG_scatter_allSeeds=[iEEG_scatter_allSeeds; curr_iEEG_scatter];
end

% add seed pairs back to main list of pairs
if size(BOLD_scatter_all,2)==3 
BOLD_scatter_allSeeds=[BOLD_scatter_allSeeds; BOLD_pair1; BOLD_pair2; BOLD_pair3];
iEEG_scatter_allSeeds=[iEEG_scatter_allSeeds; iEEG_pair1; iEEG_pair2; iEEG_pair3];
elseif size(BOLD_scatter_all,2)==2
BOLD_scatter_allSeeds=[BOLD_scatter_allSeeds; BOLD_pair1];
iEEG_scatter_allSeeds=[iEEG_scatter_allSeeds; iEEG_pair1];
end
% correlate BOLD vs iEEG (all pairs for all seeds)
nPairs=length(BOLD_scatter_allSeeds);
[corr_BOLD_vs_iEEG_allSeeds,p_BOLD_vs_iEEG_allSeeds]=corr(BOLD_scatter_allSeeds,iEEG_scatter_allSeeds);
r_allCond(i)=corr_BOLD_vs_iEEG_allSeeds;
p_allCond(i)=p_BOLD_vs_iEEG_allSeeds;

%% plot all pairs for all seeds in one scatter
mixed_colors=[cdcol.yellow; cdcol.lightcadmium; cdcol.orange];
cd([globalECoGDir filesep  Conditions{i} filesep Patient]);
mkdir('figs'); cd('figs');
y_vector=[-2:.2:2];

min_iEEG=min(iEEG_scatter_allSeeds);
max_iEEG=max(iEEG_scatter_allSeeds);
min_BOLD=min(BOLD_scatter_allSeeds);
max_BOLD=max(BOLD_scatter_allSeeds);
y_limit_lower=round(min_iEEG,1)-.1;
y_limit_upper=round(max_iEEG,1)+.1;
x_limit_lower=round(min_BOLD,1)-.1;
x_limit_upper=round(max_BOLD,1)+.1;
y_vector=[-2:.2:2]; x_vector=[-3:.5:3];

% x_limit_upper=max(BOLD_scatter_allSeeds)+.1; y_limit_upper=max(iEEG_scatter_allSeeds)+.1;
% y_limit_lower=min(iEEG_scatter_allSeeds)-.1; x_limit_lower=min(BOLD_scatter_allSeeds)-.1;
y_step=.2; x_step=0.5;

if size(BOLD_scatter_all,2)==3 % for 3 seeds (SPL, PMC, daINS)
%mixed_colors=[mean([line_color(1,:); line_color(2,:)]); mean([line_color(1,:); line_color(3,:)]); mean([line_color(2,:); line_color(3,:)])];
BOLD_seedseed_pairs=[BOLD_pair1; BOLD_pair2; BOLD_pair3];
iEEG_seedseed_pairs=[iEEG_pair1; iEEG_pair2; iEEG_pair3];
elseif size(BOLD_scatter_all,2)==2
%mixed_colors=[mean([line_color(1,:); line_color(2,:)])];
BOLD_seedseed_pairs=[BOLD_pair1];
iEEG_seedseed_pairs=[iEEG_pair1];
end

FigHandle = figure('Position', [500, 600, 600, 400]);
h0=scatter(BOLD_scatter_allSeeds,iEEG_scatter_allSeeds);
h=lsline; set(h(1),'color','k','LineWidth',2);
hold on;
%hfigure=figure('Color','w')
for k=1:length(Seeds)
    h1(k)=scatter(BOLD_scatter_all{k},iEEG_scatter_all{k},50)
    h1(k).MarkerFaceColor=line_color(k,:);
h1(k).MarkerEdgeColor=line_color(k,:);
h1(k).MarkerFaceAlpha=.5; h1(k).MarkerEdgeAlpha=.5;
set(gca,'Fontsize',18,'LineWidth',1,'TickDir','out');
set(gcf,'color','w');
%title(['r= ' num2str(corr_BOLD_vs_iEEG_allSeeds) '; n=' num2str(nPairs)]);
xlabel('BOLD <0.1 Hz FC');
ylabel('iEEG-HFB <0.1 Hz FC');
xlim([x_limit_lower x_limit_upper]); ylim([y_limit_lower y_limit_upper]);
%xticks(x_limit_lower:x_step:x_limit_upper);
xticks(x_vector);
yticks(y_vector);
%yticks(y_limit_lower:y_step:y_limit_upper);
legendInfo{k}=[Seeds{k} ' targets'];
hold on;
end
hlegend1=legend(h1,legendInfo,'Location','northeastoutside');
hlegend1.FontSize=12;
line([x_limit_lower x_limit_upper],[0 0],'LineWidth',1,'Color',[.6 .6 .6],'LineStyle','--');
line([0 0],[y_limit_lower y_limit_upper],'LineWidth',1,'Color',[.6 .6 .6],'LineStyle','--');

for k=1:size(BOLD_seedseed_pairs,1)
    h2=scatter(BOLD_seedseed_pairs(k),iEEG_seedseed_pairs(k),100)   
    h2.MarkerFaceColor=mixed_colors(k,:);
h2.MarkerEdgeColor=[0 0 0]; 
h2.LineWidth=2;
hold on;
end
print('-opengl','-r300','-dpng',[Patient '_BOLDvsIEEG_' condition '_allSeeds_allTargets_' filtering '.png']); 
close;

for k=1:size(BOLD_seedseed_pairs,1)
    h2(k)=scatter(BOLD_seedseed_pairs(k),iEEG_seedseed_pairs(k),100)   
    h2(k).MarkerFaceColor=mixed_colors(k,:);
h2(k).MarkerEdgeColor=[0 0 0]; 
h2(k).LineWidth=2;
if k==1
legendInfo{k}=['DPC-PMC'];
elseif k==2
    legendInfo{k}=['DPC-daIC'];
elseif k==3 
    legendInfo{k}=['PMC-daIC'];
end
hold on;
end
flegend=legend(h2,legendInfo,'Location','northeastoutside')
flegend.FontSize=12;
print('-opengl','-r300','-dpng',[Patient '_BOLDvsIEEG_' condition '_allSeeds_allTargets_legend.png']); 
close;
end

% FigHandle = figure('Position', [500, 600, 600, 400]);
% h0=scatter(BOLD_scatter_allSeeds,iEEG_scatter_allSeeds);
% h=lsline; set(h(1),'color','k','LineWidth',2);
% hold on;
% %hfigure=figure('Color','w')
% for k=1:length(Seeds)
%     h1(k)=scatter(BOLD_scatter_all{k},iEEG_scatter_all{k},50)
%     h1(k).MarkerFaceColor=line_color(k,:);
% h1(k).MarkerEdgeColor=line_color(k,:);
% h1(k).MarkerFaceAlpha=.5; h1(k).MarkerEdgeAlpha=.5;
% set(gca,'Fontsize',18,'LineWidth',1,'TickDir','out');
% set(gcf,'color','w');
% title(['r= ' num2str(corr_BOLD_vs_iEEG_allSeeds) '; n=' num2str(nPairs)]);
% xlabel('BOLD <0.1 Hz FC');
% ylabel('iEEG-HFB <0.1 Hz FC');
% xlim([x_limit_lower x_limit_upper]); ylim([y_limit_lower y_limit_upper]);
% %xticks(x_limit_lower:x_step:x_limit_upper);
% xticks(x_vector);
% yticks(y_vector);
% %xticks(-x_limit:x_step:x_limit);
% %yticks(-1:y_step:1);
% legendInfo{k}=[Seeds{k} ' seed'];
% hold on;
% end
% hlegend1=legend(h1,legendInfo,'Location','northeastoutside');
% hlegend1.FontSize=12;
% line([x_limit_lower x_limit_upper],[0 0],'LineWidth',1,'Color',[.6 .6 .6],'LineStyle','--');
% line([0 0],[y_limit_lower y_limit_upper],'LineWidth',1,'Color',[.6 .6 .6],'LineStyle','--');
% 
% for k=1:size(BOLD_seedseed_pairs,1)
%     h2=scatter(BOLD_seedseed_pairs(k),iEEG_seedseed_pairs(k),100)   
%     h2.MarkerFaceColor=mixed_colors(k,:);
% h2.MarkerEdgeColor=[0 0 0]; 
% h2.LineWidth=2;
% hold on;
% end
% print('-opengl','-r300','-dpng',[Patient '_BOLDvsIEEG_' condition '_allSeeds_allTargets' filtering '.png']); 
% close;

for k=1:size(BOLD_seedseed_pairs,1)
    h2(k)=scatter(BOLD_seedseed_pairs(k),iEEG_seedseed_pairs(k),100)   
    h2(k).MarkerFaceColor=mixed_colors(k,:);
h2(k).MarkerEdgeColor=[0 0 0]; 
h2(k).LineWidth=2;
if k==1
legendInfo{k}=['SPL-PMC'];
elseif k==2
    legendInfo{k}=['SPL-daINS'];
elseif k==3 
    legendInfo{k}=['PMC-daINS'];
end
hold on;
end
flegend=legend(h2,legendInfo,'Location','northeastoutside')
flegend.FontSize=12;
print('-opengl','-r300','-dpng',[Patient '_BOLDvsIEEG_' condition '_allSeeds_allTargets_legend.png']); 
close;





%% plot all seeds in condition
x_limit=2; y_limit=.8;
y_step=.4; x_step=1;

FigHandle = figure('Position', [500, 600, 400, 900]);
for k=1:length(Seeds)
    subplot(length(Seeds),1,k);
h1=scatter(BOLD_scatter_all{k},iEEG_scatter_all{k},50)
h1.MarkerFaceColor=[.2 .2 .2];
h1.MarkerEdgeColor=[.2 .2 .2];
h1.MarkerFaceAlpha=.5; h1.MarkerEdgeAlpha=.5;
%h1.MarkerType='o';
h=lsline; set(h(1),'color',line_color(k,:),'LineWidth',3);
set(gca,'Fontsize',22,'LineWidth',1,'TickDir','out');
set(gcf,'color','w');
%title({[elec_title ' FC']; ...
%    ['r = ' num2str(corr_BOLD_vs_iEEG) '; rho = ' num2str(rho_BOLD_vs_iEEG)]},'Fontsize',12);
if k==length(Seeds)
xlabel('BOLD <0.1 Hz FC');
else
    xlabel([' ']);
end
if k==median(1:length(Seeds))
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
if elecHighlight_all(k)>0
hold on;
h2=scatter(BOLD_scatter_all{k}(elecHighlight_all(k)),iEEG_scatter_all{k}(elecHighlight_all(k)),100)
h2.MarkerFaceColor=elecHighlightColor(k,:); 
h2.MarkerEdgeColor=[0 0 0]; 
h1.MarkerFaceAlpha=.5; h1.MarkerEdgeAlpha=.5;
end
% show highlighted electrode 2
if elecHighlight2_all>0
hold on;
h2=scatter(BOLD_scatter_all{k}(elecHighlight2_all(k)),iEEG_scatter_all{k}(elecHighlight2_all(k)),100)
h2.MarkerFaceColor=elecHighlightColor2(k,:); 
h2.MarkerEdgeColor=[0 0 0]; 
h1.MarkerFaceAlpha=.5; h1.MarkerEdgeAlpha=.5;
end
hold on;
end
print('-opengl','-r300','-dpng',[Patient '_BOLDvsIEEG_' condition '_allSeeds.png']); 
close;


%% plot
cd([globalECoGDir filesep  'gradCPT' filesep Patient]);
mkdir('figs'); cd('figs');

corr_BOLD_vs_iEEG_all=cell2mat(corr_BOLD_vs_iEEG_all);
cutoff_all=cell2mat(cutoff_all);
y_err_neg_all=cell2mat(y_err_neg_all);
y_err_pos_all=cell2mat(y_err_pos_all);
x_axis=1:length(Conditions);

FigHandle = figure('Position', [500, 600, 700, 550]);

for i=1:length(Seeds)
    y_axis=[corr_BOLD_vs_iEEG_all(:,i)];
 plot(x_axis,y_axis,'o-', 'LineWidth',1,'Color',line_color(i,:), 'MarkerSize',10, ...
     'MarkerEdgeColor',line_color(i,:),'MarkerFaceColor',line_color(i,:))
 legendInfo{i}=[SeedLabels{i} ' seed'];
hold on;
end
legend(legendInfo)

for i=1:length(Seeds)
y_axis=[corr_BOLD_vs_iEEG_all(:,i)];
% plot(x_axis,y_axis,'o-', 'LineWidth',1,'Color',line_color(i,:), 'MarkerSize',10, ...
 %    'MarkerEdgeColor',line_color(i,:),'MarkerFaceColor',line_color(i,:))
errorbar(x_axis,y_axis,y_err_neg_all(:,i),y_err_pos_all(:,i)','Color',line_color(i,:), ...
    'MarkerSize',10,'MarkerEdgeColor',line_color(i,:),'MarkerFaceColor',line_color(i,:));

    ylim([-.2 .9]);
    xlim([0.5 3.5]);
    xticks([1 2 3])
       set(gca,'XTickLabel',{'Task','Rest','Sleep'})
       %xtickangle(45)
       ylabel('Spatial Correlation (r)');
 set(gca,'Fontsize',21,'LineWidth',1,'TickDir','out');
    set(gca,'box','off'); 
set(gcf,'color','w');
legendInfo{i}=[Seeds{i} ' seed'];
hold on;
%errorbar(x_axis,y_axis,y_err_neg_all(i,:)',y_err_pos_all(i,:)','Color',line_color(i,:));
hold on;
end
%legend(legendInfo,'Location','southwest')

plot(x_axis,mean(cutoff_all,2)','s','Color',[.6 .6 .6], 'MarkerSize',8, ...
    'MarkerEdgeColor',[.6 .6 .6],'MarkerFaceColor',[.6 .6 .6])
print('-opengl','-r300','-dpng',[Patient '_BOLDvsIEEG_' condition '_allSeeds_CIs.png']); 
pause; close;


%plot(x_axis,mean(cutoff_all)','s','Color',[.6 .6 .6], 'MarkerSize',8, ...
 %   'MarkerEdgeColor',[.6 .6 .6],'MarkerFaceColor',[.6 .6 .6])
%legend({'p<0.01'})
%plot(x_axis,mean(cutoff_all)','s-', 'LineWidth',2,'LineStyle','-','Color',[.6 .6 .6], 'MarkerSize',6, ...
%    'MarkerEdgeColor',[.6 .6 .6],'MarkerFaceColor',[.6 .6 .6])

% print('-opengl','-r300','-dpng',[Patient '_TaskRestSleep_FC_spatialCorr_' filtering 'allSeeds.png']); 
