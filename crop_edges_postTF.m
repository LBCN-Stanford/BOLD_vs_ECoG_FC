function crop_edges_postTF(freq_band,Patient,runname)

freq_band=input('Freq band (Alpha, Beta1, HFB): ','s');
Patient=input('Patient: ','s');
runname=input('Run name: ','s');
tdt=input('TDT data? (1=TDT,0=EDF): ','s');
tdt=str2num(tdt);
if tdt==0
    edfname=input('EDF prefix (e.g. "E16-517"): ','s');
    edfname=[edfname '_' runname];
end

globalECoGDir=getECoGSubDir;

%tdt=1; % tdt=1, edf=0
%edfname=['E16-517_' runname];
if tdt==0
rm_last=1; else rm_last=0; % remove last iEEG chan (e.g. if it is reference)
end

% Set number of ms to crop at edges
cropping=20000;

% Load HFB data
if tdt==1
cd([globalECoGDir '/Rest/' Patient '/' runname]);
load([freq_band 'tf_aMfffdspm8_iEEG' runname '.mat']);
else
cd([globalECoGDir '/Rest/' Patient '/' runname]);
load([freq_band 'tf_aMfffECoG_' edfname '.mat']);
end

if tdt==1
S.D = [freq_band 'tf_aMfffdspm8_iEEG' runname '.mat'];
last=D.Nsamples-cropping;
else
    S.D=[freq_band 'tf_aMfffECoG_' edfname '.mat']
    last=D.Nsamples-cropping;
end
S.timewin= [cropping last];
S.freqwin = [-Inf Inf];
S.all = 'all';
S.prefix = 'p';

% Crop first and last 2 seconds

D=spm_eeg_crop(S)

