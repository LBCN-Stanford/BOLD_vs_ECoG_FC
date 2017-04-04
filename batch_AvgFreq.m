% List of open inputs
nrun = X; % enter the number of runs here
jobfile = {'/home/jplinux/Documents/MATLAB/BOLD_vs_ECoG_FC/batch_AvgFreq_job.m'};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(0, nrun);
for crun = 1:nrun
end
spm('defaults', 'EEG');
spm_jobman('run', jobs, inputs{:});
