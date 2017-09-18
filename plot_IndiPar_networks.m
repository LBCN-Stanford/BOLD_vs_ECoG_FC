Patient=input('Patient: ','s');
hemi=input('l or r: ','s');
run_num=input('run (e.g. 1): ','s');
viewpoint=input('medial (m), lateral (l), inferior (i), omni (o): ','s');
plotElecs=input('Plot electrodes (1) or not (0)? ','s');
condition=input('Rst or OBJ or RFg or ARN or VRN: ','s');
networks=input('plot all (0) or just 4 networks (1)? ','s');
runname=['run' run_num];
FSdir=getFsurfSubDir;
fsdir=[FSdir '/' Patient ];

if condition=='Rst'
annot=[FSdir '/' Patient '/label/' hemi 'h_parc_result_' runname '.annot'];
elseif condition=='OBJ'
     annot=[FSdir '/' Patient '/label/' hemi 'h_parc_result_OBJ.annot'];  
elseif condition=='RFg'
    annot=[FSdir '/' Patient '/label/' hemi 'h_parc_result_Rt_Finger.annot']; 
    elseif condition=='ARN'
    annot=[FSdir '/' Patient '/label/' hemi 'h_parc_result_ARN.annot'];
    elseif condition=='VRN'
    annot=[FSdir '/' Patient '/label/' hemi 'h_parc_result_VRN.annot'];
    end
%annot=[fsdir '/label/' hemi 'h.Yeo2011_17Networks_N1000.annot'];

plotElecs=str2num(plotElecs);


cd([fsdir '/elec_recon'])
if plotElecs==1    
coords=importdata([Patient '.LEPTO']);
nElec=size(coords.data,1);
whiteElecs=ones(nElec,3)*1;
end

pullOut=6;
%title={['Depth electrodes on resting state networks'];['DMN = yellow, olive, dark blue']...
    %;['DAN = green, dark green'];['Salience = pink, magenta'];['FPN = orange, maroon, dark red'];['Visual: bright red, purple'] };
%title={['RS-fMRI Networks & Electrode Locations']; ...
    %['DMN (blue), Salience (Red), FPN (green)']};
    if networks=='1'
title={['DMN (blue); DAN (yellow)']; ['Salience (red); FPN (green)']};
    load('DMN_DAN_FPN_SN_colors.mat')
    else
        title=[' '];
    end

cfg=[];
if viewpoint=='m';
cfg.view=[hemi 'm'];
elseif viewpoint=='l';
    cfg.view=[hemi];
elseif viewpoint=='i';
    cfg.view=[hemi 'i'];
elseif viewpoint=='o';
    cfg.view=[hemi 'omni'];
end

if plotElecs==1
   cfg.elecColorScale=[0 1];
cfg.edgeBlack='y'; 
cfg.ignoreDepthElec='n';
cfg.elecSize=4;
cfg.pullOut=pullOut;
cfg.clickElec='y';
cfg.showLabels='y';
%cfg.elecShape='sphere';
%cfg.elecColors=whiteElecs;
%cfg.elecColors='r';
end

cfg.title=title;
cfg.overlayParcellation=annot;
if networks=='1'
cfg.parcellationColors=DMN_DAN_FPN_SN_colors;
end
cfg.opaqueness=1;

cfgOut=plotPialSurf(Patient,cfg);

if networks=='0'
print('-opengl','-r300','-dpng',strcat(['IndiPar_all_' runname '_' viewpoint '_' condition '_' hemi 'h']));
elseif networks=='1'
print('-opengl','-r300','-dpng',strcat(['IndiPar_4networks_' runname '_' viewpoint '_' condition '_' hemi 'h']));  
end
