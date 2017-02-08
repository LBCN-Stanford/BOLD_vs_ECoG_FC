function [globalECoGDir] = getECoGSubDir

global globalECoGDir;

if ~isempty(globalECoGDir)
    fsurfSubDir=globalECoGDir;
else
    if ispc,
        error('Hey mon, if you be using Windows you need to define the global variable "globalECoGDir" and put the path to your FreeSurfer subject folder in it.');
    else
        fsurfSubDir=getenv('SUBJECTS_DIR');
        if isempty(fsurfSubDir)
            error('Could not read shell variable SUBJECTS_DIR. Try storing the path to your FreeSurfer subjects folder in the global variable globalECoGDir.');
        end
    end
end


end