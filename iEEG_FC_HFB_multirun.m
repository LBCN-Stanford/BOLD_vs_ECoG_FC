Patient=input('Patient: ','s');
runnames=input('Run names (e.g. [1 2 3 4])');
condition=input('Rest(1) Sleep(0) gradCPT (2)? ','s');
hemi=input('hemisphere (lh or rh): ','s');
depth=input('depth(1) or subdural(0)? ','s');

globalECoGDir=getECoGSubDir;

for i=1:length(runnames)
    curr_run=num2str(runnames(i));
    iEEG_FC_HFB(Patient,curr_run,condition,hemi,depth)
    display(['done run ' curr_run ' for ' Patient ' ' condition]);
end