% Example script

load Examp/ExampleData.mat

% Example structural MRI with gray matter segmentation overlaid
VolView(T1_MPRAGE_Deface,AuditoryOverlay);

% Use the default, defaced, 1mm MPRAGE in MNI spcae by leaveing it empty
VolView([],Overlay0);

% Example structural MRI with randomly gnerated overlay, masked by
% white matter segmentation
OR = randi([-4 4],256,256,256);
OR = smooth3(OR,'gaussian',7);
VolView(T1_MPRAGE_Deface,AuditoryOverlay.*OR);

% Example using your real nifti, loaded with fieldtrip
mymri = '~/file/to/mri.nii';
mri   = ft_read_mri(mymri);
D     = ft_volumereslice([],D);
VolView(mri.anatomy,mri.anatomy);