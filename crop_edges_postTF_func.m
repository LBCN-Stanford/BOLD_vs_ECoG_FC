function D=crop_edges_postTF(Patient,runname,fname_chop,cropping,both,sampling)

% cropping = number of ms to crop at edges
% if both = 1, crop from beginning and end
% if both = 0, crop from beginning only

getECoGSubDir;
global globalECoGDir;
%cd([globalECoGDir '/Rest/' Patient '/Run' runname]);

%% Set number of ms to crop at edges
%cropping=2000;

%% Crop data for each freq band
load([fname_chop]);
S.D = [fname_chop];
cropping=(cropping/sampling)*1000; % convert to ms
if both==1
last=(D.Nsamples/sampling)*1000-cropping; % convert to ms
elseif both==0
    last=D.Nsamples-1;
end
S.timewin= [cropping last];
S.freqwin = [-Inf Inf];
S.all = 'all';
S.prefix = 'p';
D=spm_eeg_crop(S);
if both==1
display(['done chopping ' num2str(cropping) 'ms from beginning and end']);
elseif both==0
  display(['done chopping ' num2str(cropping) 'ms from beginning']);  
end


