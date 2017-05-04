Patient=input('Patient: ','s');
runname=input('Run (e.g. 2): ','s');
hemi=input('Hemisphere (r or l): ','s');
depth=input('depth(1) or subdural(0)? ','s');
depth=str2num(depth);
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






