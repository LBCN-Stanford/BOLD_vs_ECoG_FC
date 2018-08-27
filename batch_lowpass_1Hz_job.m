%-----------------------------------------------------------------------
% Job saved on 14-Dec-2015 11:03:56 by cfg_util (rev $Rev: 6460 $)
% spm SPM - SPM12 (6470)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------

matlabbatch{1}.spm.meeg.preproc.filter.D = '<UNDEFINED>'
matlabbatch{1}.spm.meeg.preproc.filter.type = 'butterworth';
matlabbatch{1}.spm.meeg.preproc.filter.band = 'low';
matlabbatch{1}.spm.meeg.preproc.filter.freq = 1;
matlabbatch{1}.spm.meeg.preproc.filter.dir = 'twopass';
matlabbatch{1}.spm.meeg.preproc.filter.order = 4;
matlabbatch{1}.spm.meeg.preproc.filter.prefix = '1Hz';
disp('Done low-pass filtering (<0.1 Hz) averaged HFB time series');
