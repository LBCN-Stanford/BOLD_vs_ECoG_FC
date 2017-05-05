globalECoGDir=getECoGSubDir;
cd([globalECoGDir '/Rest']);
[a,subs]=xlsread('sublist_grid.xls');

for i=1:length(subs)
Patient=subs{i};
runname='1';
run_num=['run' runname];

globalECoGDir=getECoGSubDir;
cd([globalECoGDir '/Rest/' Patient '/Run' runname '/BOLD_ECoG_figs']);
fsDir=getFsurfSubDir();

cd('GSR');
load('partialcorr_BOLD_HFB_allelecs.mat');
GSR_corr=partialcorr_BOLD_HFB_allelecs;
load('p_BOLD_HFB_allelecs.mat');
GSR_p=p_BOLD_HFB_allelecs;

cd ..
cd('NoGSR');
load('partialcorr_BOLD_HFB_allelecs.mat');
NoGSR_corr=partialcorr_BOLD_HFB_allelecs;
load('p_BOLD_HFB_allelecs.mat');
NoGSR_p=p_BOLD_HFB_allelecs;

cd ..
cd('AROMA');
load('partialcorr_BOLD_HFB_allelecs.mat');
AROMA_corr=partialcorr_BOLD_HFB_allelecs;
load('p_BOLD_HFB_allelecs.mat');
AROMA_p=p_BOLD_HFB_allelecs;

cd ..
cd('aCompCor');
load('partialcorr_BOLD_HFB_allelecs.mat');
aCompCor_corr=partialcorr_BOLD_HFB_allelecs;
load('p_BOLD_HFB_allelecs.mat');
aCompCor_p=p_BOLD_HFB_allelecs;

pvals_GSR=GSR_p;
pvals_GSR(isnan(pvals_GSR))=[];
pvals_NoGSR=NoGSR_p;
pvals_NoGSR(isnan(pvals_NoGSR))=[];
pvals_AROMA=AROMA_p;
pvals_AROMA(isnan(pvals_AROMA))=[];
pvals_aCompCor=aCompCor_p;
pvals_aCompCor(isnan(pvals_aCompCor))=[];

%% Find FDR-corrected significant BOLD-ECoG seeds for each pipeline
[p_fdr_NoGSR,p_masked_NoGSR]=fdr(pvals_NoGSR,0.05);
[p_fdr_GSR,p_masked_GSR]=fdr(pvals_GSR,0.05);
[p_fdr_AROMA,p_masked_AROMA]=fdr(pvals_AROMA,0.05);
[p_fdr_aCompCor,p_masked_aCompCor]=fdr(pvals_aCompCor,0.05);

GSR_total_sig=sum(p_masked_GSR); GSR_total=length(p_masked_GSR);
GSR_percent_sig=(GSR_total_sig/GSR_total)*100
NoGSR_total_sig=sum(p_masked_NoGSR); NoGSR_total=length(p_masked_GSR);
NoGSR_percent_sig=(NoGSR_total_sig/NoGSR_total)*100
AROMA_total_sig=sum(p_masked_AROMA); AROMA_total=length(p_masked_GSR);
AROMA_percent_sig=(AROMA_total_sig/AROMA_total)*100
aCompCor_total_sig=sum(p_masked_aCompCor); aCompCor_total=length(p_masked_aCompCor);
aCompCor_percent_sig=(aCompCor_total_sig/aCompCor_total)*100

avg_percent=(GSR_percent_sig+AROMA_percent_sig+NoGSR_percent_sig+aCompCor_percent_sig)/4


%% Get group mean ECoG-BOLD correspondence (corr) for each method
NoGSR_meancorr_allsubs(i,:)=nanmean(fisherz(NoGSR_corr));
GSR_meancorr_allsubs(i,:)=nanmean(fisherz(GSR_corr));
AROMA_meancorr_allsubs(i,:)=nanmean(fisherz(AROMA_corr));
aCompCor_meancorr_allsubs(i,:)=nanmean(fisherz(aCompCor_corr));

end

%% Plot
allcorrs_allsubs=[NoGSR_meancorr_allsubs GSR_meancorr_allsubs AROMA_meancorr_allsubs aCompCor_meancorr_allsubs];


for i=1:length(allcorrs_allsubs)
plot(1:size(allcorrs_allsubs,2),allcorrs_allsubs(i,:),'-k.')
hold on;
end




