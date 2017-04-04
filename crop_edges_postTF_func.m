function crop_edges_postTF(Patient,runname,fname_spm_tf)

getECoGSubDir;
global globalECoGDir;
cd([globalECoGDir '/Rest/' Patient '/Run' runname]);

%% Set number of ms to crop at edges
cropping=10000;

%% Crop data for each freq band
load(['HFB' fname_spm_tf]);
S.D = ['HFB' fname_spm_tf];
last=D.Nsamples-cropping;
S.timewin= [cropping last];
S.freqwin = [-Inf Inf];
S.all = 'all';
S.prefix = 'p';
D=spm_eeg_crop(S);

load(['Alpha' fname_spm_tf]);
S.D = ['Alpha' fname_spm_tf];
last=D.Nsamples-cropping;
S.timewin= [cropping last];
S.freqwin = [-Inf Inf];
S.all = 'all';
S.prefix = 'p';
D=spm_eeg_crop(S);

load(['Delta' fname_spm_tf]);
S.D = ['Delta' fname_spm_tf];
last=D.Nsamples-cropping;
S.timewin= [cropping last];
S.freqwin = [-Inf Inf];
S.all = 'all';
S.prefix = 'p';
D=spm_eeg_crop(S);

load(['Theta' fname_spm_tf]);
S.D = ['Theta' fname_spm_tf];
last=D.Nsamples-cropping;
S.timewin= [cropping last];
S.freqwin = [-Inf Inf];
S.all = 'all';
S.prefix = 'p';
D=spm_eeg_crop(S);

load(['Beta1' fname_spm_tf]);
S.D = ['Beta1' fname_spm_tf];
last=D.Nsamples-cropping;
S.timewin= [cropping last];
S.freqwin = [-Inf Inf];
S.all = 'all';
S.prefix = 'p';
D=spm_eeg_crop(S);

load(['Beta2' fname_spm_tf]);
S.D = ['Beta2' fname_spm_tf];
last=D.Nsamples-cropping;
S.timewin= [cropping last];
S.freqwin = [-Inf Inf];
S.all = 'all';
S.prefix = 'p';
D=spm_eeg_crop(S);

load(['Gamma' fname_spm_tf]);
S.D = ['Gamma' fname_spm_tf];
last=D.Nsamples-cropping;
S.timewin= [cropping last];
S.freqwin = [-Inf Inf];
S.all = 'all';
S.prefix = 'p';
D=spm_eeg_crop(S);
