function crop_edges_postTF(Patient,runname,fname_chop)

getECoGSubDir;
global globalECoGDir;
%cd([globalECoGDir '/Rest/' Patient '/Run' runname]);

%% Set number of ms to crop at edges
cropping=2000;

%% Crop data for each freq band
load([fname_chop]);
S.D = [fname_chop];
last=D.Nsamples-cropping;
S.timewin= [cropping last];
S.freqwin = [-Inf Inf];
S.all = 'all';
S.prefix = 'p';
D=spm_eeg_crop(S);
display(['done chopping ' num2str(cropping) 'ms from beginning and end']);


