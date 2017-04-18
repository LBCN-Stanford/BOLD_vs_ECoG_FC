% function crop_edges_postTF(freq_band,Patient,runname)

display(['Choose file to crop data']);
fname=spm_select;
D=spm_eeg_load(fname);

% Set number of ms to crop at edges
cropping=2000;
 last=D.nsamples-cropping;
 
S=[];
S.D=D;
S.timewin= [cropping last];
S.freqwin = [-Inf Inf];
S.all = 'all';
S.prefix = 'p';

% Crop first and last 2 seconds

D=spm_eeg_crop(S)

