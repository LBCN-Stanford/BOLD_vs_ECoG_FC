sub=input('Patient: ','s');

globalECoGDir=getECoGSubDir;
cd([globalECoGDir '/Rest/' sub]);

bad_chans=input('Bad channels (e.g. "[31:34 60]": ');

save('bad_chans','bad_chans');