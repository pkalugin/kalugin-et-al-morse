javaaddpath '/mnt/nasquatch/data/code/peter/20231122fromsantiago/mij/mij.jar'
javaaddpath '/mnt/nasquatch/data/code/peter/20231122fromsantiago/mij/ij-1.52a.jar'
javaaddpath '/mnt/nasquatch/data/code/peter/20231122fromsantiago/turboreg/TurboReg/TurboReg_.jar'
%javaaddpath 'C:\code\turboreg\TurboReg\MultiStackReg1.45_.jar'

%% Playing with Demons/Deformable reg on Cellpose probabilities
scale = 2;
path = '/mnt/nasquatch/data/2p/peter/in_vivo/231025_DG56PL62/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg';
tempin = readNPY([path '/prob_movie.npy']);
temp = permute(tempin,[3 4 2 1]);
temp = imresize(temp,1/scale);
%%
%aligneddem = zeros(size(temp));
%aligneddef = zeros(size(temp));
aligneddem2 = zeros(size(temp));
%aligneddef2 = zeros(size(temp));
dispsdem = zeros([size(temp) 3]);
%dispsdef = zeros([size(temp) 3]);
%dispsdem2 = zeros([size(temp) 3]);
%dispsdem85 = zeros([size(temp) 3]);
%dispsdef2 = zeros([size(temp) 3]);
%aligneddem(:,:,:,1) = squeeze(temp(:,:,:,1));
%aligneddef(:,:,:,1) = squeeze(temp(:,:,:,1));
%aligneddem(:,:,:,60) = squeeze(temp(:,:,:,60));
%aligneddef(:,:,:,60) = squeeze(temp(:,:,:,60));
%aligneddem2(:,:,:,1) = squeeze(temp(:,:,:,1));
%aligneddef2(:,:,:,1) = squeeze(temp(:,:,:,1));
%aligneddem2(:,:,:,60) = squeeze(temp(:,:,:,60));
%aligneddef2(:,:,:,60) = squeeze(temp(:,:,:,60));

%% trials on GPU vs CPU
scale = 2;
afs = 2.0;
i = 2;
%ref = i-1;
ref = 85;
tempg = gpuArray(temp);

tic
[dispsdem(:,:,:,i,:),~] = imregdemons(squeeze(temp(:,:,:,i)),squeeze(temp(:,:,:,ref)),'AccumulatedFieldSmoothing',afs,'PyramidLevels',4);
toc
norm(squeeze(dispsdem(100,100,15,i,:)))

tic
[dispsdem(:,:,:,i,:),~] = imregdemons(gpuArray(squeeze(temp(:,:,:,i))),gpuArray(squeeze(temp(:,:,:,ref))),'AccumulatedFieldSmoothing',afs,'PyramidLevels',4);
toc
norm(squeeze(dispsdem(100,100,15,i,:)))
%%
tempg = gpuArray(temp);
dispsdem = zeros([size(temp) 3]);

tic
for i = 1:5
    [dispsdem(:,:,:,i,:),~] = imregdemons(squeeze(tempg(:,:,:,i)),squeeze(tempg(:,:,:,ref)),'AccumulatedFieldSmoothing',afs,'PyramidLevels',4);
end
toc

reset(D);
tempg = gpuArray(temp);
tic
for i = 1:15
    [dispsdem(:,:,:,i,:),~] = imregdemons(squeeze(tempg(:,:,:,i)),squeeze(tempg(:,:,:,ref)),'AccumulatedFieldSmoothing',afs,'PyramidLevels',4);
end
toc

reset(D);
tempg = gpuArray(temp);
tic
H = parfor_progressbar(size(temp,4),'Demons registration');
for i = 1:15
    [dispsdem(:,:,:,i,:),~] = imregdemons(squeeze(tempg(:,:,:,i)),squeeze(tempg(:,:,:,ref)),'AccumulatedFieldSmoothing',afs,'PyramidLevels',4);
    H.iterate(1);
end
close(H);
toc



reset(D);
%tempg = gpuArray(temp);
%tic
%for i = 1:50
%    [dispsdem(:,:,:,i,:),~] = imregdemons(squeeze(tempg(:,:,:,i)),squeeze(tempg(:,:,:,ref)),'AccumulatedFieldSmoothing',afs,'PyramidLevels',4);
%end
%toc
%norm(squeeze(dispsdem(100,100,15,i,:)))
%% trials imwarp on GPU vs CPU
tempg = gpuArray(temp);
dispsdemg = gpuArray(dispsdem);
tic
aligneddem2(:,:,:,i) = imwarp(squeeze(temp(:,:,:,i)),squeeze(dispsdem(:,:,:,i,:)));
toc
aligneddem2(100,100,15,i)

tic
aligneddem2(:,:,:,i) = imwarp(gpuArray(squeeze(temp(:,:,:,i))),squeeze(dispsdem(:,:,:,i,:)));
toc
aligneddem2(100,100,15,i)

tic
aligneddem2(:,:,:,i) = imwarp(squeeze(tempg(:,:,:,i)),squeeze(dispsdem(:,:,:,i,:)));
toc
aligneddem2(100,100,15,i)

tic
aligneddem2(:,:,:,i) = imwarp(squeeze(tempg(:,:,:,i)),squeeze(dispsdemg(:,:,:,i,:)));
toc
aligneddem2(100,100,15,i)

%% 12/29 GPU batch codes
prob_prefix = "/mnt/nasquatch/data/2p/";

save_prefix = "/mnt/santiago/2p_data/";

prob_paths = ["peter/in_vivo/231108_DG61PL62/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231108_DG61PL62/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231108_DG61PL62/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231108_DG61PL62/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231108_DG61PL62/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231108_DG61PL62/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231108_DG61PL62/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231108_DG61PL62/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231107_DG44PL58/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231107_DG44PL58/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231107_DG44PL58/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231107_DG44PL58/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231107_DG44PL58/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231107_DG44PL58/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231107_DG44PL58/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231107_DG44PL58/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231106_DG52PL68/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231106_DG52PL68/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231106_DG52PL68/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231106_DG52PL68/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231106_DG52PL68/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231106_DG52PL68/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231106_DG52PL68/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231106_DG52PL68/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG43PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG43PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG43PL32/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG43PL32/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG39PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG39PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG39PL32/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG39PL32/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG39PL32/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG39PL32/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG39PL32/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231105_DG39PL32/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231031_DG53PL28/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231031_DG53PL28/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231031_DG53PL28/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231031_DG53PL28/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231031_DG53PL28/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231031_DG53PL28/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231031_DG53PL28/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231031_DG53PL28/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231030_DG60PL67/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231030_DG60PL67/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231030_DG60PL67/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231030_DG60PL67/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231030_DG60PL67/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231030_DG60PL67/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231030_DG60PL67/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231030_DG60PL67/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231029_DG58PL64/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231029_DG58PL64/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231029_DG58PL64/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231029_DG58PL64/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231027_DG57PL69/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231027_DG57PL69/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231027_DG57PL69/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231027_DG57PL69/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231025_DG56PL62/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231025_DG56PL62/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231025_DG56PL62/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231025_DG56PL62/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231025_DG56PL62/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231025_DG56PL62/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231025_DG56PL62/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231025_DG56PL62/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231024_DG54PL61/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231024_DG54PL61/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231024_DG54PL61/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231024_DG54PL61/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231024_DG54PL61/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231024_DG54PL61/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231024_DG54PL61/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231024_DG54PL61/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231019_DG53PL68/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231019_DG53PL68/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231019_DG53PL68/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231019_DG53PL68/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231018_DG52PL66/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231018_DG52PL66/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231018_DG52PL66/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231018_DG52PL66/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231018_DG52PL66/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231018_DG52PL66/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231018_DG52PL66/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231018_DG52PL66/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231017_DG49PL70/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231017_DG49PL70/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231017_DG49PL70/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/231017_DG49PL70/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230909_DG88PL58/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230909_DG88PL58/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230909_DG88PL58/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230909_DG88PL58/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230909_DG88PL58/wells/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230909_DG88PL58/wells/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230909_DG88PL58/wells/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230909_DG88PL58/wells/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230908_PK109PL52/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230908_PK109PL52/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230908_PK109PL52/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230908_PK109PL52/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230908_PK109PL52/wells/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230908_PK109PL52/wells/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230908_PK109PL52/wells/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230908_PK109PL52/wells/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230907_PK108PL54/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230907_PK108PL54/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230907_PK108PL54/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230907_PK108PL54/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230906_PS57PL56/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230906_PS57PL56/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230906_PS57PL56/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230906_PS57PL56/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230906_PS57PL56/wells/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230906_PS57PL56/wells/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230906_PS57PL56/wells/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230906_PS57PL56/wells/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230905_PS56PL58/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230905_PS56PL58/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230905_PS56PL58/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230905_PS56PL58/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230905_PS56PL58/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230905_PS56PL58/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230905_PS56PL58/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230905_PS56PL58/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230904_PS54PL60/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230904_PS54PL60/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230904_PS54PL60/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230904_PS54PL60/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230904_PS54PL60/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230904_PS54PL60/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230904_PS54PL60/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230904_PS54PL60/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230902_DG90PL61/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230902_DG90PL61/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230902_DG90PL61/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230902_DG90PL61/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230902_DG90PL61/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230902_DG90PL61/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230902_DG90PL61/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230902_DG90PL61/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230901_DG89PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230901_DG89PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230901_DG89PL32/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230901_DG89PL32/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230901_DG89PL32/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230901_DG89PL32/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230901_DG89PL32/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230901_DG89PL32/wells/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"];

prob_refs = [repmat(85,1,4)...
    repmat(34,1,4)...
    repmat(85,1,4)...
    repmat(34,1,4)...
    repmat(85,1,4)...
    repmat(34,1,4)...
    repmat(19,1,4)...
    repmat(85,1,4)...
    repmat(34,1,4)...
    repmat(85,1,4)...
    repmat(34,1,4)...
    repmat(49,1,4)...
    repmat(34,1,4)...
    repmat(10,1,4)...
    repmat(85,1,4)...
    repmat(85,1,4)...
    repmat(34,1,4)...
    repmat(71,1,4)...
    repmat(34,1,4)...
    repmat(85,1,4)...
    repmat(71,1,4)...
    repmat(34,1,4)...
    repmat(71,1,4)...
    repmat(71,1,4)...
    repmat(34,1,4)...
    repmat(65,1,4)...
    repmat(34,1,4)...
    repmat(80,1,4)...
    repmat(60,1,4)...
    repmat(34,1,4)...
    repmat(89,1,4)...
    repmat(34,1,4)...
    repmat(89,1,4)...
    repmat(38,1,4)...
    repmat(75,1,4)...
    repmat(38,1,4)...
    repmat(30,1,4)...
    repmat(38,1,4)]';

%% slice movies
prob_prefix = "/mnt/nasquatch/data/2p/";

save_prefix = "/mnt/santiago/2p_data/";

prob_paths = ["peter/slice/20230831_SL1PL55/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230831_SL1PL55/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230831_SL1PL55/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230831_SL1PL55/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230831_SL1PL55/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230831_SL1PL55/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230831_SL1PL55/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230831_SL1PL55/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL2PL60/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL2PL60/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL2PL60/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL2PL60/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL1PL28/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL1PL28/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL1PL28/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL1PL28/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL1PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL1PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL1PL28/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL1PL28/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL3PL61/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL3PL61/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL3PL61/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL3PL61/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL2PL39/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL2PL39/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL2PL39/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL2PL39/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL1PL56/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL1PL56/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL1PL56/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL1PL56/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL1PL56/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL1PL56/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL1PL56/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL1PL56/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL2PL54/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL2PL54/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL2PL54/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL2PL54/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/wells101/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/wells101/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL3PL58/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL3PL58/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL3PL58/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL3PL58/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL2PL52/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL2PL52/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL2PL52/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL2PL52/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL2PL52/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL2PL52/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL2PL52/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL2PL52/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL1PL32/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL1PL32/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL1PL32/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL1PL32/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL2PL60/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL2PL60/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL2PL60/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL2PL60/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/slice/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/wells101/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/wells101/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230801_SL2PL34/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230801_SL2PL34/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230801_SL1PL35/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230801_SL1PL35/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230801_SL1PL35/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230801_SL1PL35/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230727_SL2PL32/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230727_SL2PL32/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230727_SL2PL32/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230727_SL2PL32/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230727_SL1PL52/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230727_SL1PL52/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230616_SL2PL39/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230616_SL2PL39/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230616_SL1PL28/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230616_SL1PL28/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230616_SL1PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230616_SL1PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230608_SL2PL45/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230608_SL2PL45/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230608_SL1PL37/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230608_SL1PL37/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230607_SL2PL42/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230607_SL2PL42/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230607_SL1PL47/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230607_SL1PL47/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230607_SL1PL47/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230607_SL1PL47/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230606_SL1PL35/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230606_SL1PL35/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230606_SL1PL35/washes/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230606_SL1PL35/washes/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230511_DA2PL45/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230511_DA2PL45/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230511_DA1PL37/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230511_DA1PL37/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230511_DA1PL37/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230511_DA1PL37/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230509_DA2PL55/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230509_DA2PL55/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230509_DA1PL53/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230509_DA1PL53/slice/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230509_DA1PL53/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230509_DA1PL53/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"];

prob_refs = [repmat(28,1,4)...
    repmat(52,1,4)...
    repmat(28,1,4)...
    repmat(28,1,4)...
    repmat(52,1,4)...
    repmat(28,1,4)...
    repmat(28,1,4)...
    repmat(28,1,4)...
    repmat(52,1,4)...
    repmat(33,1,4)...
    repmat(22,1,4)...
    repmat(18,1,4)...
    repmat(20,1,4)...
    repmat(28,1,4)...
    repmat(28,1,4)...
    repmat(52,1,4)...
    repmat(28,1,4)...
    repmat(27,1,4)...
    repmat(27,1,4)...
    repmat(18,1,4)...
    repmat(39,1,4)...
    repmat(27,1,2)...
    repmat(27,1,2)...
    repmat(76,1,2)...
    repmat(25,1,2)...
    repmat(39,1,2)...
    repmat(18,1,2)...
    repmat(18,1,2)...
    repmat(18,1,2)...
    repmat(11,1,2)...
    repmat(26,1,2)...
    repmat(18,1,2)...
    repmat(25,1,2)...
    repmat(15,1,2)...
    repmat(27,1,2)...
    repmat(18,1,2)...
    repmat(9,1,2)...
    repmat(18,1,2)...
    repmat(15,1,2)...
    repmat(7,1,2)...
    repmat(16,1,2)...
    repmat(10,1,2)...
    repmat(8,1,2)]';

prob_scales = [repmat(2,1,84)...
    repmat(2.2,1,4)...
    repmat(2,1,8)...
    repmat(2.2,1,20)...
    repmat(2,1,10)...
    repmat(2.2,1,2)]';

%% dipping 2023
prob_prefix = "/mnt/nasquatch/data/2p/";

save_prefix = "/mnt/santiago/2p_data/";

prob_paths = ["peter/dipping/20230927_PL58/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL58/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230927_PL34/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells501/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells501/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells501/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230926_PL56/wells501/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230925_PL58/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells501/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells501/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells501/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230923_PL35/wells501/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells501/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells501/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells501/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells501/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells601/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells601/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells601/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells601/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells701/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells701/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells701/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230922_PL28/wells701/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL58/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230920_PL56/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells501/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells501/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells501/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL54/wells501/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL48/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL48/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL48/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL48/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL48/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL48/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL48/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230916_PL48/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells001/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells001/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells101/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells101/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells201/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells201/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells301/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells301/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells401/segtrack/segs/ch0/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230915_PL52/wells401/segtrack/segs/ch1/31_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230825_PL57/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230825_PL57/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230825_PL57/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230825_PL57/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230825_PL39/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230825_PL39/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230825_PL39/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230825_PL39/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL61/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL61/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL61/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL61/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL48/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL48/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL48/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL48/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells101/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells101/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells201/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells201/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells201/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230823_PL28/wells201/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230821_PL57/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230821_PL57/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230821_PL57/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230821_PL57/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL62/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL62/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL62/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL62/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells001/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells101/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells101/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells201/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells201/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells201/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20230819_PL43/wells201/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"]; 

prob_refs = [repmat(25,1,4)...
    repmat(31,1,4)...
    repmat(30,1,4)...
    repmat(30,1,4)...
    repmat(20,1,4)...
    repmat(35,1,4)...
    repmat(37,1,4)...
    repmat(30,1,4)...
    repmat(25,1,4)...
    repmat(25,1,4)...
    repmat(32,1,4)...
    repmat(35,1,4)...
    repmat(30,1,4)...
    repmat(31,1,4)...
    repmat(30,1,4)...
    repmat(15,1,4)...
    repmat(37,1,4)...
    repmat(31,1,4)...
    repmat(31,1,4)...
    repmat(25,1,4)...
    repmat(37,1,4)...
    repmat(37,1,4)...
    repmat(26,1,4)...
    repmat(36,1,4)...
    repmat(31,1,4)...
    repmat(35,1,4)...
    repmat(15,1,4)...
    repmat(19,1,4)...
    repmat(35,1,4)...
    repmat(18,1,4)...
    repmat(15,1,4)...
    repmat(15,1,4)...
    repmat(40,1,4)...
    repmat(25,1,4)...
    repmat(15,1,4)...
    repmat(20,1,4)...
    repmat(40,1,4)...
    repmat(15,1,4)...
    repmat(4,1,4)...
    repmat(5,1,4)...
    repmat(18,1,4)...
    repmat(13,1,4)...
    repmat(25,1,4)...
    repmat(19,1,4)...
    repmat(15,1,4)...
    repmat(35,1,4)...
    repmat(25,1,4)...
    repmat(40,1,4)...
    repmat(18,1,4)...
    repmat(15,1,4)...
    repmat(31,1,4)...
    repmat(25,1,4)...
    repmat(19,1,4)...
    repmat(18,1,4)...
    repmat(15,1,4)...
    repmat(27,1,4)...
    repmat(25,1,4)...
    repmat(18,1,4)...
    repmat(15,1,4)...
    repmat(46,1,4)...
    repmat(22,1,4)...
    repmat(20,1,4)...
    repmat(34,1,4)...
    repmat(31,1,4)...
    repmat(1,1,4)]'; 
 
%% in vivo 2023 8/10 back

prob_prefix = "/mnt/nasquatch/data/2p/";

save_prefix = "/mnt/santiago/2p_data/";

prob_paths = ["peter/in_vivo/230810_DG87PL55/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230810_DG87PL55/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230810_DG87PL55/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230810_DG87PL55/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230809_DG86PL57/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230809_DG86PL57/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230809_DG86PL57/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230809_DG86PL57/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230808_DG85PL61/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230808_DG85PL61/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230808_DG85PL61/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230808_DG85PL61/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230807_DG84PL52/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230807_DG84PL52/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230807_DG84PL52/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230807_DG84PL52/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230802_DG48PL58/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230802_DG48PL58/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230802_DG48PL58/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230802_DG48PL58/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230728_DG80PL57/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230728_DG80PL57/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230727_DG79PL59/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230727_DG79PL59/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230726_DG47PL54/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230726_DG47PL54/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230726_DG47PL54/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230726_DG47PL54/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230721_DG46PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230721_DG46PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230721_DG46PL32/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230721_DG46PL32/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230720_PK97PL48/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230720_PK97PL48/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230720_PK97PL48/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230720_PK97PL48/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230714_PK95PL55/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230714_PK95PL55/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230713_PK94PL59/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230713_PK94PL59/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230713_PK94PL59/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230713_PK94PL59/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230712_PK93PL57/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230712_PK93PL57/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230712_PK93PL57/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230712_PK93PL57/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230711_DG44PL47/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230711_DG44PL47/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230711_DG44PL47/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230711_DG44PL47/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230711_DG43PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230711_DG43PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230708_DG70PL56/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230708_DG70PL56/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230708_DG70PL56/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230708_DG70PL56/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230707_DG72PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230707_DG72PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230707_DG72PL32/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230707_DG72PL32/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230706_DG71PL54/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230706_DG71PL54/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230706_DG71PL54/mouse2/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230706_DG71PL54/mouse2/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230706_DG71PL54/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230706_DG71PL54/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230617_DG70PL54/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230617_DG70PL54/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230617_DG70PL54/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230617_DG70PL54/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230615_DG69PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230615_DG69PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230615_DG69PL32/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230615_DG69PL32/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230614_DG63PL54/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230614_DG63PL54/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230614_DG63PL54/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230614_DG63PL54/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230601_PK85PL53/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230601_PK85PL53/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230601_PK85PL53/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230601_PK85PL53/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230531_PK80PL43/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230531_PK80PL43/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230531_PK80PL43/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230531_PK80PL43/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230526_PK84PL50/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230526_PK84PL50/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230526_PK84PL50/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230526_PK84PL50/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230525_DG42PL39/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230525_DG42PL39/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230525_DG42PL39/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230525_DG42PL39/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230519_DG41PL52/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230519_DG41PL52/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230519_DG41PL52/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230519_DG41PL52/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"];
         
prob_refs = [repmat(94,1,2)...
    repmat(48,1,2)...
    repmat(89,1,2)...
    repmat(48,1,2)...
    repmat(55,1,2)...
    repmat(48,1,2)...
    repmat(73,1,2)...
    repmat(48,1,2)...
    repmat(71,1,2)...
    repmat(57,1,2)...
    repmat(10,1,2)...
    repmat(1,1,2)...
    repmat(71,1,2)...
    repmat(30,1,2)...
    repmat(71,1,2)...
    repmat(57,1,2)...
    repmat(70,1,2)...
    repmat(50,1,2)...
    repmat(15,1,2)...
    repmat(71,1,2)...
    repmat(50,1,2)...
    repmat(35,1,2)...
    repmat(57,1,2)...
    repmat(53,1,2)...
    repmat(1,1,2)...
    repmat(29,1,2)...
    repmat(71,1,2)...
    repmat(57,1,2)...
    repmat(40,1,2)...
    repmat(35,1,2)...
    repmat(25,1,2)...
    repmat(3,1,2)...
    repmat(30,1,2)...
    repmat(71,1,2)...
    repmat(40,1,2)...
    repmat(71,1,2)...
    repmat(54,1,2)...
    repmat(50,1,2)...
    repmat(1,1,2)...
    repmat(1,1,2)...
    repmat(1,1,2)...
    repmat(20,1,2)...
    repmat(1,1,2)...
    repmat(62,1,2)...
    repmat(1,1,2)...
    repmat(70,1,2)...
    repmat(1,1,2)...
    repmat(71,1,2)...
    repmat(1,1,2)]';

%% in vivo 2022

prob_prefix = "/mnt/nasquatch/data/2p/";

save_prefix = "/mnt/santiago/2p_data/";

prob_paths = ["peter/in_vivo/221204_PS39PL51/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221204_PS39PL51/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221204_PS39PL51/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221204_PS39PL51/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221203_PS45PL50/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221203_PS45PL50/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221203_PS45PL50/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221203_PS45PL50/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221125_PS39PL50/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221125_PS39PL50/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221125_PS39PL50/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221125_PS39PL50/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221111_PS28PL41/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221111_PS28PL41/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221111_PS28PL41/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221111_PS28PL41/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221109_PS27PL28/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221109_PS27PL28/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221109_PS27PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221109_PS27PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221107_PS23PL42/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221107_PS23PL42/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221020_PS16PL39/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221020_PS16PL39/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221020_PS16PL39/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221020_PS16PL39/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221018_PS10PL24/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221018_PS10PL24/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221018_PS10PL24/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221018_PS10PL24/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220929_PS11PL37/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220929_PS11PL37/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220928_PK65PL30/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220928_PK65PL30/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220927_PK60PL33/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220927_PK60PL33/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220916_PK66PL28/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220916_PK66PL28/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220916_PK66PL28/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220916_PK66PL28/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220913_PK65PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220913_PK65PL32/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220903_PK63PL34/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220903_PK63PL34/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220903_PK63PL34/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220903_PK63PL34/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220902_PK61PL37/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220902_PK61PL37/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220902_PK61PL37/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220902_PK61PL37/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220901_PK60PL36/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220901_PK60PL36/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220901_PK60PL36/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220901_PK60PL36/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220701_PK49PL18/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220701_PK49PL18/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220701_PK49PL18/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220701_PK49PL18/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220629_PK46PL25/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220629_PK46PL25/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220629_PK46PL25/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220629_PK46PL25/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220628_PK45PL24/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220628_PK45PL24/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220624_PK45PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220624_PK45PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220624_PK45PL13/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220624_PK45PL13/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220622_PK44PL17/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220622_PK44PL17/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220622_PK44PL17/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220622_PK44PL17/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220621_PK24PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220621_PK24PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220621_PK24PL13/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220621_PK24PL13/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220617_PK26PL18/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220617_PK26PL18/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220617_PK26PL18/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220617_PK26PL18/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220616_PK25PL9/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220616_PK25PL9/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220615_PK24PL18/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220615_PK24PL18/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220530_PK25PL9/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220530_PK25PL9/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220530_PK25PL9/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220530_PK25PL9/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220519_PK43PL17/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220519_PK43PL17/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220519_PK43PL17/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220519_PK43PL17/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220518_PK40PL14/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220518_PK40PL14/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220515_PK27PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220515_PK27PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220514_PK26PL6/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220514_PK26PL6/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220514_PK26PL6/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220514_PK26PL6/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220512_PK24PL19/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220512_PK24PL19/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220506_PK26PL16/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220506_PK26PL16/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220504_PK24PL9/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220504_PK24PL9/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220504_PK24PL9/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220504_PK24PL9/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220427_PK27PL20/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220427_PK27PL20/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220427_PK27PL20/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220427_PK27PL20/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220423_PK24PL17/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220423_PK24PL17/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220408_PK27PL20/mouse_noart/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220408_PK27PL20/mouse_noart/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220408_PK27PL20/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220408_PK27PL20/wells/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220407_PK26PL15/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220407_PK26PL15/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220407_PK26PL15/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220407_PK26PL15/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220406_PK24PL10/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220406_PK24PL10/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220406_PK24PL10/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220406_PK24PL10/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220318_PK24PL14/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220318_PK24PL14/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220318_PK24PL14/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220318_PK24PL14/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220316_PK32PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220316_PK32PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220316_PK32PL13/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220316_PK32PL13/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220315_PK36PL18/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220315_PK36PL18/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220315_PK36PL18/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220315_PK36PL18/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220314_PL14BCH/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220314_PL14BCH/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220311_PK24PL9/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220311_PK24PL9/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220311_PK24PL9/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220311_PK24PL9/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220303_PK26PL21/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220303_PK26PL21/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220303_PK26PL21/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220303_PK26PL21/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220302_PK27PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220302_PK27PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220223_PK26PL19/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220223_PK26PL19/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220217_PK27PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220217_PK27PL13/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220217_PK26PL15/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220217_PK26PL15/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220216_PK25PL8/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220216_PK25PL8/mouse/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220216_PK25PL8/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220216_PK25PL8/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"];
         
prob_refs = [repmat(58,1,2)...
    repmat(1,1,2)...
    repmat(30,1,2)...
    repmat(115,1,2)...
    repmat(58,1,2)...
    repmat(1,1,2)...
    repmat(40,1,2)...
    repmat(1,1,2)...
    repmat(58,1,2)...
    repmat(1,1,2)...
    repmat(10,1,2)...
    repmat(18,1,2)...
    repmat(115,1,2)...
    repmat(31,1,2)...
    repmat(20,1,2)...
    repmat(53,1,2)...
    repmat(53,1,2)...
    repmat(53,1,2)...
    repmat(1,1,2)...
    repmat(115,1,2)...
    repmat(40,1,2)...
    repmat(55,1,2)...
    repmat(115,1,2)...
    repmat(1,1,2)...
    repmat(1,1,2)...
    repmat(67,1,2)...
    repmat(60,1,2)...
    repmat(76,1,2)...
    repmat(100,1,2)...
    repmat(76,1,2)...
    repmat(20,1,2)...
    repmat(1,1,2)...
    repmat(70,1,2)...
    repmat(1,1,2)...
    repmat(76,1,2)...
    repmat(115,1,2)...
    repmat(67,1,2)...
    repmat(10,1,2)...
    repmat(40,1,2)...
    repmat(120,1,2)...
    repmat(76,1,2)...
    repmat(35,1,2)...
    repmat(20,1,2)...
    repmat(80,1,2)...
    repmat(76,1,2)...
    repmat(115,1,2)...
    repmat(50,1,2)...
    repmat(60,1,2)...
    repmat(25,1,2)...
    repmat(60,1,2)...
    repmat(1,1,2)...
    repmat(76,1,2)...
    repmat(80,1,2)...
    repmat(13,1,2)...
    repmat(77,1,2)...
    repmat(80,1,2)...
    repmat(67,1,2)...
    repmat(71,1,2)...
    repmat(57,1,2)...
    repmat(20,1,2)...
    repmat(57,1,2)...
    repmat(40,1,2)...
    repmat(57,1,2)...
    repmat(80,1,2)...
    repmat(62,1,2)...
    repmat(70,1,2)...
    repmat(5,1,2)...
    repmat(71,1,2)...
    repmat(21,1,2)...
    repmat(57,1,2)...
    repmat(62,1,2)...
    repmat(100,1,2)...
    repmat(50,1,2)...
    repmat(91,1,2)...
    repmat(62,1,2)...
    repmat(67,1,2)...
    repmat(58,1,2)...
    repmat(53,1,2)...
    repmat(62,1,2)...
    repmat(45,1,2)]';

%% dipping 2022

prob_prefix = "/mnt/nasquatch/data/2p/";

save_prefix = "/mnt/santiago/2p_data/";

prob_paths = ["peter/dipping/20221129_PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221129_PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221129_PL28/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221129_PL28/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221118_PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221118_PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221116_PL44/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221116_PL44/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221115_PL42/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221115_PL42/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221115_PL42/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221115_PL42/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221115_PL42/wells201/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221115_PL42/wells201/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221104_PL45/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221104_PL45/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221103_PL47/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221103_PL47/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221103_PL38/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221103_PL38/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221102_PL44/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221102_PL44/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221102_PL44/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221102_PL44/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221101_PL42/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221101_PL42/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221101_PL42/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221101_PL42/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221014_PL36/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221014_PL36/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221014_PL36/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221014_PL36/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221013_PL33/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221013_PL33/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221013_PL33/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20221013_PL33/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220930_PL34/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220930_PL34/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220930_PL34/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220930_PL34/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220921_PL25/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220921_PL25/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220921_PL25/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220921_PL25/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220915_PL29/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220915_PL29/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220915_PL29/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220915_PL29/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220914_PL21/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220914_PL21/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220914_PL21/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220914_PL21/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220907_PL27/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220907_PL27/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220907_PL27/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220907_PL27/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220906_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220906_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220906_PL24/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220906_PL24/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220831_PL31/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220831_PL31/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220831_PL27/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220831_PL27/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220830_PL32/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220830_PL32/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220830_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220830_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220825_PL29/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220825_PL29/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220825_PL18/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220825_PL18/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220824_PL33/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220824_PL33/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220824_PL13/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220824_PL13/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220823_PL32/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220823_PL32/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220823_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220823_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220819_PL23/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220819_PL23/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220819_PL22/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220819_PL22/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220817_PL31/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220817_PL31/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220817_PL27/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220817_PL27/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220816_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220816_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220812_PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220812_PL28/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220812_PL22/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220812_PL22/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220811_PL30/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220811_PL30/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220811_PL18/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220811_PL18/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220810_PL27/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220810_PL27/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220810_PL20/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220810_PL20/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220809_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220809_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220809_PL14/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220809_PL14/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220729_PL27/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220729_PL27/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220728_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220728_PL24/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220727_PL14/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220727_PL14/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220707_PL18/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220707_PL18/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220705_PL9/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/dipping/20220705_PL9/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"];
         
prob_refs = [repmat(40,1,2)...
    repmat(18,1,2)...
    repmat(1,1,2)...
    repmat(76,1,2)...
    repmat(10,1,2)...
    repmat(1,1,2)...
    repmat(16,1,2)...
    repmat(66,1,2)...
    repmat(1,1,2)...
    repmat(76,1,2)...
    repmat(19,1,2)...
    repmat(115,1,2)...
    repmat(19,1,2)...
    repmat(34,1,2)...
    repmat(19,1,2)...
    repmat(16,1,2)...
    repmat(19,1,2)...
    repmat(80,1,2)...
    repmat(13,1,2)...
    repmat(50,1,2)...
    repmat(19,1,2)...
    repmat(46,1,2)...
    repmat(19,1,2)...
    repmat(11,1,2)...
    repmat(18,1,2)...
    repmat(115,1,2)...
    repmat(18,1,2)...
    repmat(115,1,2)...
    repmat(18,1,2)...
    repmat(115,1,2)...
    repmat(57,1,2)...
    repmat(57,1,2)...
    repmat(10,1,2)...
    repmat(10,1,2)...
    repmat(20,1,2)...
    repmat(20,1,2)...
    repmat(12,1,2)...
    repmat(1,1,2)...
    repmat(10,1,2)...
    repmat(13,1,2)...
    repmat(10,1,2)...
    repmat(20,1,2)...
    repmat(20,1,2)...
    repmat(57,1,2)...
    repmat(1,1,2)...
    repmat(15,1,2)...
    repmat(55,1,2)...
    repmat(40,1,2)...
    repmat(48,1,2)...
    repmat(8,1,2)...
    repmat(10,1,2)...
    repmat(25,1,2)...
    repmat(10,1,2)...
    repmat(1,1,2)...
    repmat(13,1,2)...
    repmat(8,1,2)...
    repmat(10,1,2)...
    repmat(40,1,2)]';

%% dipping anastasia

prob_prefix = "/mnt/anastasia/data/2p/";

save_prefix = "/mnt/santiago/2p_data/";

prob_paths = ["david/dipping_only/6plex/220304_PL7/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220304_PL7/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220211_PK8/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220211_PK8/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220210_PK7/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220210_PK7/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220208_PK8/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220208_PK8/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220207_PK5/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220207_PK5/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220204_PK6/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220204_PK6/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220203_PK9/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220203_PK9/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220127_PK9/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220127_PK9/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220126_PK8/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220126_PK8/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220125_PK9/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220125_PK9/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220121_PK8/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220121_PK8/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220120_DT1/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/220120_DT1/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211222_PK8/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211222_PK8/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211222_PK8/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211222_PK8/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211222_PK8/wells201/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211222_PK8/wells201/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211222_PK8/wells301/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211222_PK8/wells301/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211221_PK7/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211221_PK7/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211221_PK2/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211221_PK2/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             %"david/dipping_only/6plex/211221_PK2/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg" %nothing from cellpose??
             %"david/dipping_only/6plex/211221_PK2/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg" %nothing from cellpose??
             "david/dipping_only/6plex/211221_PK2/wells201/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211221_PK2/wells201/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211215_DT2/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211215_DT2/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211215_DT2/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211215_DT2/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211214_PK6/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211214_PK6/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211214_PK6/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211214_PK6/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211213_PK5/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211213_PK5/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211213_PK5/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211213_PK5/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211210_PL4_warped/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211210_PL4_warped/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211210_PL3_bumped/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211210_PL3_bumped/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211209_PK6/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211209_PK6/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211209_PK6/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211209_PK6/wells101/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211207_PK7/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211207_PK7/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211203_PK7/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211203_PK7/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211202_PK3/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211202_PK3/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211124_PK2/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211124_PK2/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211122_DT1/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211122_DT1/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211027_DT2/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211027_DT2/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211027_DT2/wells100/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211027_DT2/wells100/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211026_DT2/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211026_DT2/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211026_DT2/wells100/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211026_DT2/wells100/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211022_PK5/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211022_PK5/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211022_PK5/wells100/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211022_PK5/wells100/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211021_PK3/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211021_PK3/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211021_PK3/wells100/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211021_PK3/wells100/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211009_PK4/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211009_PK4/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211009_PK4/wells501/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211009_PK4/wells501/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211008_PK4/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211008_PK4/wells001/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211008_PK4/wells501/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "david/dipping_only/6plex/211008_PK4/wells501/segtrack/segs/ch0/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg"];
         
prob_refs = [repmat(30,1,2)...
    repmat(115,1,2)...
    repmat(60,1,2)...
    repmat(1,1,2)...
    repmat(1,1,2)...
    repmat(20,1,2)...
    repmat(18,1,2)...
    repmat(15,1,2)...
    repmat(1,1,2)...
    repmat(10,1,2)...
    repmat(20,1,2)...
    repmat(115,1,2)...
    repmat(22,1,2)...
    repmat(13,1,2)...
    repmat(22,1,2)...
    repmat(115,1,2)...
    repmat(50,1,2)...
    repmat(10,1,2)...
    repmat(13,1,2)...
    repmat(1,1,2)...
    repmat(1,1,2)...
    repmat(61,1,2)...
    repmat(1,1,2)...
    repmat(41,1,2)...
    repmat(100,1,2)...
    repmat(1,1,2)...
    repmat(1,1,2)...
    repmat(37,1,2)...
    repmat(115,1,2)...
    repmat(115,1,2)...
    repmat(115,1,2)...
    repmat(1,1,2)...
    repmat(115,1,2)...
    repmat(1,1,2)...
    repmat(18,1,2)...
    repmat(115,1,2)...
    repmat(18,1,2)...
    repmat(31,1,2)...
    repmat(24,1,2)...
    repmat(55,1,2)...
    repmat(18,1,2)...
    repmat(25,1,2)...
    repmat(60,1,2)...
    repmat(25,1,2)...
    repmat(72,1,2)...
    repmat(55,1,2)]';

%% 240511 fixing a couple mistakes

prob_prefix = "/mnt/nasquatch/data/2p/";

save_prefix = "/mnt/santiago/2p_data/";

prob_paths = ["peter/in_vivo/220408_PK27PL20/wells101/segtrack/segs/ch0/52_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
    "peter/slice/20230824_SL1PL60/wells001/segtrack/segs/ch0/52_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
    "peter/slice/20230824_SL1PL60/wells001/segtrack/segs/ch1/52_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"];

prob_refs = [57
    18
    18]';


%% 241130 repeat sequential runs to assess post-fit stability
% in vivo + dipping
% slice + dipping

prob_prefix = "/mnt/nasquatch/data/2p/";

save_prefix = "/mnt/santiago/2p_data/";

% first test group
prob_paths = [%"peter/in_vivo/231108_DG61PL62/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231108_DG61PL62/wells/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231107_DG44PL58/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231107_DG44PL58/wells/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231106_DG52PL68/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231106_DG52PL68/wells/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231105_DG43PL32/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231105_DG39PL32/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231105_DG39PL32/wells/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231031_DG53PL28/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231031_DG53PL28/wells/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231030_DG60PL67/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231030_DG60PL67/wells/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231029_DG58PL64/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231027_DG57PL69/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231025_DG56PL62/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231025_DG56PL62/wells/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231024_DG54PL61/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231024_DG54PL61/wells/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231019_DG53PL68/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231018_DG52PL66/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231018_DG52PL66/wells/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231017_DG49PL70/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230909_DG88PL58/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230909_DG88PL58/wells/segtrack/segs/ch0/31_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230908_PK109PL52/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230908_PK109PL52/wells/segtrack/segs/ch0/31_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230907_PK108PL54/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230906_PS57PL56/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230906_PS57PL56/wells/segtrack/segs/ch0/31_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230905_PS56PL58/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230905_PS56PL58/wells/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230904_PS54PL60/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230904_PS54PL60/wells/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230902_DG90PL61/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230902_DG90PL61/wells/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230901_DG89PL32/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230901_DG89PL32/wells/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             
             %"peter/in_vivo/231030_DG60PL67/mouse/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231025_DG56PL62/mouse/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231025_DG56PL62/wells101/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231024_DG54PL61/mouse/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231024_DG54PL61/wells101/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231018_DG52PL66/mouse/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/231018_DG52PL66/wells101/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230906_PS57PL56/mouse/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230905_PS56PL58/mouse/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230905_PS56PL58/wells101/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230902_DG90PL61/mouse/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230902_DG90PL61/wells101/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             
             %
             %"peter/slice/20230831_SL1PL55/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230831_SL1PL55/wells001/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230830_SL2PL60/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230830_SL1PL28/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230830_SL1PL28/wells001/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230829_SL3PL61/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230829_SL2PL39/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230829_SL1PL56/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230829_SL1PL56/wells001/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230824_SL2PL54/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230824_SL1PL60/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230824_SL1PL60/wells001/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230824_SL1PL60/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230822_SL3PL58/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230822_SL2PL52/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230822_SL2PL52/wells001/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230822_SL1PL32/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230817_SL2PL60/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230817_SL1PL55/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230817_SL1PL55/wells001/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230817_SL1PL55/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230801_SL2PL34/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230801_SL1PL35/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230801_SL1PL35/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230727_SL2PL32/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230727_SL2PL32/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230727_SL1PL52/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230616_SL2PL39/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230616_SL1PL28/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230616_SL1PL28/wells001/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230608_SL2PL45/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230608_SL1PL37/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230607_SL2PL42/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230607_SL1PL47/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230607_SL1PL47/wells001/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230606_SL1PL35/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230606_SL1PL35/washes/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230511_DA2PL45/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230511_DA1PL37/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230511_DA1PL37/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230509_DA2PL55/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230509_DA1PL53/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230509_DA1PL53/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             
             %"peter/slice/20230824_SL1PL60/wells001/segtrack/segs/ch0/52_mean_warped_fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             
             %"peter/slice/20230831_SL1PL55/wells001/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230830_SL1PL28/wells001/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230824_SL1PL60/slice/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230824_SL1PL60/wells101/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230822_SL2PL52/slice/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230822_SL2PL52/wells001/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             
             %"peter/slice/20230830_SL2PL60/slice/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230829_SL3PL61/slice/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230829_SL2PL39/slice/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230824_SL2PL54/slice/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230822_SL3PL58/slice/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/slice/20230822_SL1PL32/slice/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             
             %
             %"peter/in_vivo/230810_DG87PL55/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230810_DG87PL55/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230809_DG86PL57/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230809_DG86PL57/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230808_DG85PL61/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230808_DG85PL61/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230807_DG84PL52/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230807_DG84PL52/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230802_DG48PL58/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230802_DG48PL58/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230728_DG80PL57/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230727_DG79PL59/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230726_DG47PL54/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230726_DG47PL54/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230721_DG46PL32/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230721_DG46PL32/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230720_PK97PL48/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230720_PK97PL48/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230714_PK95PL55/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230713_PK94PL59/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230713_PK94PL59/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230712_PK93PL57/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230712_PK93PL57/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230711_DG44PL47/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230711_DG44PL47/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230711_DG43PL32/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230708_DG70PL56/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230708_DG70PL56/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230707_DG72PL32/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230707_DG72PL32/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230706_DG71PL54/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             %"peter/in_vivo/230706_DG71PL54/mouse2/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230706_DG71PL54/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230617_DG70PL54/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230617_DG70PL54/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230615_DG69PL32/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230615_DG69PL32/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230614_DG63PL54/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230614_DG63PL54/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230601_PK85PL53/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230601_PK85PL53/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230531_PK80PL43/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230531_PK80PL43/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230526_PK84PL50/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230526_PK84PL50/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230525_DG42PL39/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230525_DG42PL39/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230519_DG41PL52/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230519_DG41PL52/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             
             %
             "peter/in_vivo/221204_PS39PL51/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221204_PS39PL51/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221203_PS45PL50/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221203_PS45PL50/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221125_PS39PL50/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221125_PS39PL50/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221111_PS28PL41/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221111_PS28PL41/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221109_PS27PL28/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221109_PS27PL28/wells001/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221107_PS23PL42/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221020_PS16PL39/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221020_PS16PL39/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221018_PS10PL24/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221018_PS10PL24/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220929_PS11PL37/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220928_PK65PL30/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220927_PK60PL33/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220916_PK66PL28/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220916_PK66PL28/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220913_PK65PL32/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220903_PK63PL34/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220903_PK63PL34/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220902_PK61PL37/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220902_PK61PL37/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220901_PK60PL36/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220901_PK60PL36/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220701_PK49PL18/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220701_PK49PL18/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220629_PK46PL25/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220629_PK46PL25/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220628_PK45PL24/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220624_PK45PL13/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220624_PK45PL13/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220622_PK44PL17/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220622_PK44PL17/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220621_PK24PL13/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220621_PK24PL13/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220617_PK26PL18/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220617_PK26PL18/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220616_PK25PL9/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220615_PK24PL18/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220530_PK25PL9/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220530_PK25PL9/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220519_PK43PL17/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220519_PK43PL17/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220518_PK40PL14/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220515_PK27PL13/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220514_PK26PL6/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220514_PK26PL6/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220512_PK24PL19/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220506_PK26PL16/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220504_PK24PL9/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220504_PK24PL9/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220427_PK27PL20/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220427_PK27PL20/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220423_PK24PL17/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220408_PK27PL20/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220408_PK27PL20/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220407_PK26PL15/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220407_PK26PL15/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220406_PK24PL10/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220406_PK24PL10/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220318_PK24PL14/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220318_PK24PL14/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220316_PK32PL13/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220316_PK32PL13/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220315_PK36PL18/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220315_PK36PL18/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220314_PL14BCH/wells001/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220311_PK24PL9/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220311_PK24PL9/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220303_PK26PL21/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220303_PK26PL21/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220302_PK27PL13/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220223_PK26PL19/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220217_PK27PL13/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220217_PK26PL15/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220216_PK25PL8/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220216_PK25PL8/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             
             "peter/in_vivo/220408_PK27PL20/wells101/segtrack/segs/ch0/52_mean_warped_fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"];
         
prob_refs = [%repmat(85,1,1)...
    %repmat(34,1,1)...
    %repmat(85,1,1)...
    %repmat(34,1,1)...
    %repmat(85,1,1)...
    %repmat(34,1,1)...
    %repmat(19,1,1)...
    %repmat(85,1,1)...
    %repmat(34,1,1)...
    %repmat(85,1,1)...
    %repmat(34,1,1)...
    %repmat(49,1,1)...
    %repmat(34,1,1)...
    %repmat(10,1,1)...
    %repmat(85,1,1)... %123
    %repmat(85,1,1)...
    %repmat(34,1,1)...
    %repmat(71,1,1)...
    %repmat(34,1,1)...
    %repmat(85,1,1)...
    %repmat(71,1,1)...
    %repmat(34,1,1)...
    %repmat(71,1,1)...
    %repmat(71,1,1)...
    %repmat(34,1,1)...
    %repmat(65,1,1)...
    %repmat(34,1,1)...
    %repmat(80,1,1)...
    %repmat(60,1,1)...
    %repmat(34,1,1)...
    %repmat(89,1,1)...
    %repmat(34,1,1)...
    %repmat(89,1,1)...
    %repmat(38,1,1)...
    %repmat(75,1,1)...
    %repmat(38,1,1)...
    %repmat(30,1,1)...
    %repmat(38,1,1)...   %38 movies
    %repmat(49,1,1)...
    %repmat(85,1,1)...
    %repmat(34,1,1)...
    %repmat(71,1,1)...
    %repmat(34,1,1)...
    %repmat(71,1,1)...
    %repmat(34,1,1)...
    %repmat(60,1,1)...
    %repmat(89,1,1)...
    %repmat(34,1,1)...
    %repmat(75,1,1)...
    %repmat(38,1,1)...
    %repmat(28,1,1)...%
    %repmat(52,1,1)...
    %repmat(28,1,1)...
    %repmat(28,1,1)...
    %repmat(52,1,1)...
    %repmat(28,1,1)...
    %repmat(28,1,1)...
    %repmat(28,1,1)...
    %repmat(52,1,1)...
    %repmat(33,1,1)...
    %repmat(22,1,1)...
    %repmat(18,1,1)...
    %repmat(20,1,1)...
    %repmat(28,1,1)...
    %repmat(28,1,1)...
    %repmat(52,1,1)...
    %repmat(28,1,1)...
    %repmat(27,1,1)...
    %repmat(27,1,1)...
    %repmat(18,1,1)...
    %repmat(39,1,1)...
    %repmat(27,1,1)...
    %repmat(27,1,1)...
    %repmat(76,1,1)...
    %repmat(25,1,1)...
    %repmat(39,1,1)...
    %repmat(18,1,1)...
    %repmat(18,1,1)...
    %repmat(18,1,1)...
    %repmat(11,1,1)...
    %repmat(26,1,1)...
    %repmat(18,1,1)...
    %repmat(25,1,1)...
    %repmat(15,1,1)...
    %repmat(27,1,1)...
    %repmat(18,1,1)...
    %repmat(9,1,1)...
    %repmat(18,1,1)...
    %repmat(15,1,1)...
    %repmat(7,1,1)...
    %repmat(16,1,1)...
    %repmat(10,1,1)...
    %repmat(8,1,1)...     % 43 movies
    %repmat(18,1,1)...
    %repmat(52,1,1)...
    %repmat(52,1,1)...
    %repmat(22,1,1)...
    %repmat(20,1,1)...
    %repmat(28,1,1)...
    %repmat(52,1,1)...
    %repmat(28,1,1)...
    %repmat(28,1,1)...
    %repmat(28,1,1)...
    %repmat(33,1,1)...
    %repmat(28,1,1)...
    %repmat(28,1,1)...
    %repmat(94,1,1)...%
    %repmat(48,1,1)...
    %repmat(89,1,1)...
    %repmat(48,1,1)...
    %repmat(55,1,1)...
    %repmat(48,1,1)...
    %repmat(73,1,1)...
    %repmat(48,1,1)...
    %repmat(71,1,1)...
    %repmat(57,1,1)...
    %repmat(10,1,1)...
    %repmat(1,1,1)...
    %repmat(71,1,1)...
    %repmat(30,1,1)...
    %repmat(71,1,1)...
    %repmat(57,1,1)...
    %repmat(70,1,1)...
    %repmat(50,1,1)...
    %repmat(15,1,1)...
    %repmat(71,1,1)...
    %repmat(50,1,1)...
    %repmat(35,1,1)...
    %repmat(57,1,1)...
    %repmat(53,1,1)...
    %repmat(1,1,1)...
    %repmat(29,1,1)...
    %repmat(71,1,1)...
    %repmat(57,1,1)...
    %repmat(40,1,1)...
    %repmat(35,1,1)...
    %repmat(25,1,1)...
    %repmat(3,1,1)...
    repmat(30,1,1)...
    repmat(71,1,1)...
    repmat(40,1,1)...
    repmat(71,1,1)...
    repmat(54,1,1)...
    repmat(50,1,1)...
    repmat(1,1,1)...
    repmat(1,1,1)...
    repmat(1,1,1)...
    repmat(20,1,1)...
    repmat(1,1,1)...
    repmat(62,1,1)...
    repmat(1,1,1)...
    repmat(70,1,1)...
    repmat(1,1,1)...
    repmat(71,1,1)...
    repmat(1,1,1)...
    repmat(58,1,1)...%
    repmat(1,1,1)...
    repmat(30,1,1)...
    repmat(115,1,1)...
    repmat(58,1,1)...
    repmat(1,1,1)...
    repmat(40,1,1)...
    repmat(1,1,1)...
    repmat(58,1,1)...
    repmat(1,1,1)...
    repmat(10,1,1)...
    repmat(18,1,1)...
    repmat(115,1,1)...
    repmat(31,1,1)...
    repmat(20,1,1)...
    repmat(53,1,1)...
    repmat(53,1,1)...
    repmat(53,1,1)...
    repmat(1,1,1)...
    repmat(115,1,1)...
    repmat(40,1,1)...
    repmat(55,1,1)...
    repmat(115,1,1)...
    repmat(1,1,1)...
    repmat(1,1,1)...
    repmat(67,1,1)...
    repmat(60,1,1)...
    repmat(76,1,1)...
    repmat(100,1,1)...
    repmat(76,1,1)...
    repmat(20,1,1)...
    repmat(1,1,1)...
    repmat(70,1,1)...
    repmat(1,1,1)...
    repmat(76,1,1)...
    repmat(115,1,1)...
    repmat(67,1,1)...
    repmat(10,1,1)...
    repmat(40,1,1)...
    repmat(120,1,1)...
    repmat(76,1,1)...
    repmat(35,1,1)...
    repmat(20,1,1)...
    repmat(80,1,1)...
    repmat(76,1,1)...
    repmat(115,1,1)...
    repmat(50,1,1)...
    repmat(60,1,1)...
    repmat(25,1,1)...
    repmat(60,1,1)...
    repmat(1,1,1)...
    repmat(76,1,1)...
    repmat(80,1,1)...
    repmat(13,1,1)...
    repmat(77,1,1)...
    repmat(80,1,1)...
    repmat(67,1,1)...
    repmat(71,1,1)...
    repmat(57,1,1)...
    repmat(20,1,1)...
    repmat(57,1,1)...
    repmat(40,1,1)...
    repmat(57,1,1)...
    repmat(80,1,1)...
    repmat(62,1,1)...
    repmat(70,1,1)...
    repmat(5,1,1)...
    repmat(71,1,1)...
    repmat(21,1,1)...
    repmat(57,1,1)...
    repmat(62,1,1)...
    repmat(100,1,1)...
    repmat(50,1,1)...
    repmat(91,1,1)...
    repmat(62,1,1)...
    repmat(67,1,1)...
    repmat(58,1,1)...
    repmat(53,1,1)...
    repmat(62,1,1)...
    repmat(45,1,1)...%   80 movies
    repmat(57,1,1)]';

prob_scales = [%repmat(2,1,35)...%50
    %repmat(2,1,21)...%
    %repmat(2.2,1,2)...
    %repmat(2,1,4)...
    %repmat(2.2,1,10)...
    %repmat(2,1,5)...
    %repmat(2.2,1,1)...   % 43 movies
    %repmat(2,1,13)...
    repmat(2,1,17)...% %49
    repmat(2,1,81)]';%

%% slice movies for postwarp (DON'T RUN)
prob_prefix = "/mnt/nasquatch/data/2p/";

save_prefix = "/mnt/santiago/2p_data/";

prob_paths = ["peter/slice/20230831_SL1PL55/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230831_SL1PL55/wells001/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL2PL60/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL1PL28/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL1PL28/wells001/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL3PL61/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL2PL39/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL1PL56/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL1PL56/wells001/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL2PL54/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/wells001/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL3PL58/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL2PL52/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL2PL52/wells001/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL1PL32/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL2PL60/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/wells001/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230817_SL1PL55/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230801_SL2PL34/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230801_SL1PL35/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230801_SL1PL35/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230727_SL2PL32/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230727_SL2PL32/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230727_SL1PL52/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230616_SL2PL39/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230616_SL1PL28/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230616_SL1PL28/wells001/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230608_SL2PL45/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230608_SL1PL37/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230607_SL2PL42/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230607_SL1PL47/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230607_SL1PL47/wells001/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230606_SL1PL35/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230606_SL1PL35/washes/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230511_DA2PL45/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230511_DA1PL37/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230511_DA1PL37/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230509_DA2PL55/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230509_DA1PL53/slice/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230509_DA1PL53/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             
             "peter/slice/20230824_SL1PL60/wells001/segtrack/segs/ch0/52_mean_warped_fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             
             "peter/slice/20230831_SL1PL55/wells001/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230830_SL1PL28/wells001/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/slice/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL1PL60/wells101/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL2PL52/slice/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL2PL52/wells001/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             
             "peter/slice/20230830_SL2PL60/slice/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL3PL61/slice/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230829_SL2PL39/slice/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230824_SL2PL54/slice/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL3PL58/slice/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/slice/20230822_SL1PL32/slice/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"];

prob_refs = [repmat(28,1,1)...
    repmat(52,1,1)...
    repmat(28,1,1)...
    repmat(28,1,1)...
    repmat(52,1,1)...
    repmat(28,1,1)...
    repmat(28,1,1)...
    repmat(28,1,1)...
    repmat(52,1,1)...
    repmat(33,1,1)...
    repmat(22,1,1)...
    repmat(18,1,1)...
    repmat(20,1,1)...
    repmat(28,1,1)...
    repmat(28,1,1)...
    repmat(52,1,1)...
    repmat(28,1,1)...
    repmat(27,1,1)...
    repmat(27,1,1)...
    repmat(18,1,1)...
    repmat(39,1,1)...
    repmat(27,1,1)...
    repmat(27,1,1)...
    repmat(76,1,1)...
    repmat(25,1,1)...
    repmat(39,1,1)...
    repmat(18,1,1)...
    repmat(18,1,1)...
    repmat(18,1,1)...
    repmat(11,1,1)...
    repmat(26,1,1)...
    repmat(18,1,1)...
    repmat(25,1,1)...
    repmat(15,1,1)...
    repmat(27,1,1)...
    repmat(18,1,1)...
    repmat(9,1,1)...
    repmat(18,1,1)...
    repmat(15,1,1)...
    repmat(7,1,1)...
    repmat(16,1,1)...
    repmat(10,1,1)...
    repmat(8,1,1)...     % 43 movies
    repmat(18,1,1)...
    repmat(52,1,1)...
    repmat(52,1,1)...
    repmat(22,1,1)...
    repmat(20,1,1)...
    repmat(28,1,1)...
    repmat(52,1,1)...
    repmat(28,1,1)...
    repmat(28,1,1)...
    repmat(28,1,1)...
    repmat(33,1,1)...
    repmat(28,1,1)...
    repmat(28,1,1)]';
    
prob_scales = [repmat(2,1,21)...
    repmat(2.2,1,2)...
    repmat(2,1,4)...
    repmat(2.2,1,10)...
    repmat(2,1,5)...
    repmat(2.2,1,1)...   % 43 movies
    repmat(2,1,13)]';
%% in vivo 1 for postwarp (DON'T RUN)
prob_prefix = "/mnt/nasquatch/data/2p/";

save_prefix = "/mnt/santiago/2p_data/";

prob_paths = ["peter/in_vivo/230810_DG87PL55/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230810_DG87PL55/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230809_DG86PL57/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230809_DG86PL57/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230808_DG85PL61/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230808_DG85PL61/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230807_DG84PL52/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230807_DG84PL52/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230802_DG48PL58/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230802_DG48PL58/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230728_DG80PL57/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230727_DG79PL59/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230726_DG47PL54/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230726_DG47PL54/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230721_DG46PL32/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230721_DG46PL32/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230720_PK97PL48/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230720_PK97PL48/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230714_PK95PL55/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230713_PK94PL59/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230713_PK94PL59/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230712_PK93PL57/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230712_PK93PL57/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230711_DG44PL47/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230711_DG44PL47/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230711_DG43PL32/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230708_DG70PL56/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230708_DG70PL56/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230707_DG72PL32/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230707_DG72PL32/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230706_DG71PL54/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230706_DG71PL54/mouse2/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230706_DG71PL54/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230617_DG70PL54/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230617_DG70PL54/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230615_DG69PL32/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230615_DG69PL32/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230614_DG63PL54/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230614_DG63PL54/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230601_PK85PL53/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230601_PK85PL53/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230531_PK80PL43/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230531_PK80PL43/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230526_PK84PL50/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230526_PK84PL50/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230525_DG42PL39/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230525_DG42PL39/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230519_DG41PL52/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/230519_DG41PL52/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"];
         
prob_refs = [repmat(94,1,1)...
    repmat(48,1,1)...
    repmat(89,1,1)...
    repmat(48,1,1)...
    repmat(55,1,1)...
    repmat(48,1,1)...
    repmat(73,1,1)...
    repmat(48,1,1)...
    repmat(71,1,1)...
    repmat(57,1,1)...
    repmat(10,1,1)...
    repmat(1,1,1)...
    repmat(71,1,1)...
    repmat(30,1,1)...
    repmat(71,1,1)...
    repmat(57,1,1)...
    repmat(70,1,1)...
    repmat(50,1,1)...
    repmat(15,1,1)...
    repmat(71,1,1)...
    repmat(50,1,1)...
    repmat(35,1,1)...
    repmat(57,1,1)...
    repmat(53,1,1)...
    repmat(1,1,1)...
    repmat(29,1,1)...
    repmat(71,1,1)...
    repmat(57,1,1)...
    repmat(40,1,1)...
    repmat(35,1,1)...
    repmat(25,1,1)...
    repmat(3,1,1)...
    repmat(30,1,1)...
    repmat(71,1,1)...
    repmat(40,1,1)...
    repmat(71,1,1)...
    repmat(54,1,1)...
    repmat(50,1,1)...
    repmat(1,1,1)...
    repmat(1,1,1)...
    repmat(1,1,1)...
    repmat(20,1,1)...
    repmat(1,1,1)...
    repmat(62,1,1)...
    repmat(1,1,1)...
    repmat(70,1,1)...
    repmat(1,1,1)...
    repmat(71,1,1)...
    repmat(1,1,1)]'; % 49 movies

prob_scales = [repmat(2,1,49)]';

%% in vivo 2022 for postwarp (DON'T RUN)

prob_prefix = "/mnt/nasquatch/data/2p/";

save_prefix = "/mnt/santiago/2p_data/";

prob_paths = ["peter/in_vivo/221204_PS39PL51/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221204_PS39PL51/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221203_PS45PL50/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221203_PS45PL50/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221125_PS39PL50/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221125_PS39PL50/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221111_PS28PL41/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221111_PS28PL41/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221109_PS27PL28/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221109_PS27PL28/wells001/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221107_PS23PL42/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221020_PS16PL39/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221020_PS16PL39/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221018_PS10PL24/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/221018_PS10PL24/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220929_PS11PL37/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220928_PK65PL30/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220927_PK60PL33/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220916_PK66PL28/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220916_PK66PL28/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220913_PK65PL32/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220903_PK63PL34/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220903_PK63PL34/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220902_PK61PL37/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220902_PK61PL37/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220901_PK60PL36/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220901_PK60PL36/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220701_PK49PL18/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220701_PK49PL18/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220629_PK46PL25/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220629_PK46PL25/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220628_PK45PL24/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220624_PK45PL13/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220624_PK45PL13/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220622_PK44PL17/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220622_PK44PL17/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220621_PK24PL13/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220621_PK24PL13/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220617_PK26PL18/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220617_PK26PL18/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220616_PK25PL9/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220615_PK24PL18/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220530_PK25PL9/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220530_PK25PL9/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220519_PK43PL17/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220519_PK43PL17/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220518_PK40PL14/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220515_PK27PL13/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220514_PK26PL6/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220514_PK26PL6/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220512_PK24PL19/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220506_PK26PL16/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220504_PK24PL9/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220504_PK24PL9/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220427_PK27PL20/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220427_PK27PL20/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220423_PK24PL17/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220408_PK27PL20/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220408_PK27PL20/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220407_PK26PL15/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220407_PK26PL15/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220406_PK24PL10/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220406_PK24PL10/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220318_PK24PL14/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220318_PK24PL14/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220316_PK32PL13/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220316_PK32PL13/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220315_PK36PL18/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220315_PK36PL18/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220314_PL14BCH/wells001/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220311_PK24PL9/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220311_PK24PL9/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220303_PK26PL21/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220303_PK26PL21/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220302_PK27PL13/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220223_PK26PL19/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220217_PK27PL13/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220217_PK26PL15/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220216_PK25PL8/mouse/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             "peter/in_vivo/220216_PK25PL8/wells101/segtrack/segs/ch0/52_mean_warped_/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
             
             "peter/in_vivo/220408_PK27PL20/wells101/segtrack/segs/ch0/52_mean_warped_fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"];
         
prob_refs = [repmat(58,1,1)...
    repmat(1,1,1)...
    repmat(30,1,1)...
    repmat(115,1,2)...
    repmat(58,1,1)...
    repmat(1,1,1)...
    repmat(40,1,1)...
    repmat(1,1,1)...
    repmat(58,1,1)...
    repmat(1,1,1)...
    repmat(10,1,1)...
    repmat(18,1,1)...
    repmat(115,1,1)...
    repmat(31,1,1)...
    repmat(20,1,1)...
    repmat(53,1,1)...
    repmat(53,1,1)...
    repmat(53,1,1)...
    repmat(1,1,1)...
    repmat(115,1,1)...
    repmat(40,1,1)...
    repmat(55,1,1)...
    repmat(115,1,1)...
    repmat(1,1,1)...
    repmat(1,1,1)...
    repmat(67,1,1)...
    repmat(60,1,1)...
    repmat(76,1,1)...
    repmat(100,1,1)...
    repmat(76,1,1)...
    repmat(20,1,1)...
    repmat(1,1,1)...
    repmat(70,1,1)...
    repmat(1,1,1)...
    repmat(76,1,1)...
    repmat(115,1,1)...
    repmat(67,1,1)...
    repmat(10,1,1)...
    repmat(40,1,1)...
    repmat(120,1,1)...
    repmat(76,1,1)...
    repmat(35,1,1)...
    repmat(20,1,1)...
    repmat(80,1,1)...
    repmat(76,1,1)...
    repmat(115,1,1)...
    repmat(50,1,1)...
    repmat(60,1,1)...
    repmat(25,1,1)...
    repmat(60,1,1)...
    repmat(1,1,1)...
    repmat(76,1,1)...
    repmat(80,1,1)...
    repmat(13,1,1)...
    repmat(77,1,1)...
    repmat(80,1,1)...
    repmat(67,1,1)...
    repmat(71,1,1)...
    repmat(57,1,1)...
    repmat(20,1,1)...
    repmat(57,1,1)...
    repmat(40,1,1)...
    repmat(57,1,1)...
    repmat(80,1,1)...
    repmat(62,1,1)...
    repmat(70,1,1)...
    repmat(5,1,1)...
    repmat(71,1,1)...
    repmat(21,1,1)...
    repmat(57,1,1)...
    repmat(62,1,1)...
    repmat(100,1,1)...
    repmat(50,1,1)...
    repmat(91,1,1)...
    repmat(62,1,1)...
    repmat(67,1,1)...
    repmat(58,1,1)...
    repmat(53,1,1)...
    repmat(62,1,1)...
    repmat(45,1,1)...%   80 movies
    repmat(57,1,1)]';

prob_scales = [repmat(2,1,81)]';

%%
prob_prefix = "/mnt/nasquatch/data/2p/";

save_prefix = "/mnt/santiago/2p_data/";

prob_paths = [%"peter/chip_tiling/211103_PZ1/chunks/well3/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211103_PZ1/chunks/well6/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211104_PZ1/chunks/well3/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211104_PZ1/chunks/well6/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211109_PZ1/chunks/well3/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211109_PZ1/chunks/well6/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211110_PZ1/chunks/well3/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211110_PZ1/chunks/well6/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211111_PZ1/chunks/well3/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211111_PZ1/chunks/well6/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211112_PZ1/chunks/well3/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211112_PZ1/chunks/well6/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211121_PZ1/chunks/well3/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211121_PZ1/chunks/well6/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211121_PZ1/chunks/well9/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211123_PZ1/chunks/well3/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211123_PZ1/chunks/well6/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211123_PZ1/chunks/well9/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211103_PZ1/chunks/well2/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211103_PZ1/chunks/well5/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211104_PZ1/chunks/well2/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211104_PZ1/chunks/well5/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211109_PZ1/chunks/well2/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211109_PZ1/chunks/well5/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211110_PZ1/chunks/well2/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211110_PZ1/chunks/well5/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211111_PZ1/chunks/well2/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211111_PZ1/chunks/well5/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211112_PZ1/chunks/well2/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211112_PZ1/chunks/well5/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211121_PZ1/chunks/well2/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211121_PZ1/chunks/well5/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211121_PZ1/chunks/well8/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211123_PZ1/chunks/well2/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211123_PZ1/chunks/well5/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211123_PZ1/chunks/well8/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211103_PZ1/chunks/well1/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211103_PZ1/chunks/well4/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211104_PZ1/chunks/well1/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211104_PZ1/chunks/well4/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211109_PZ1/chunks/well1/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211109_PZ1/chunks/well4/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211110_PZ1/chunks/well1/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211110_PZ1/chunks/well4/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211111_PZ1/chunks/well1/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211111_PZ1/chunks/well4/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211112_PZ1/chunks/well1/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211112_PZ1/chunks/well4/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211121_PZ1/chunks/well1/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211121_PZ1/chunks/well4/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211121_PZ1/chunks/well7/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
        %"peter/chip_tiling/211123_PZ1/chunks/well1/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/chip_tiling/211123_PZ1/chunks/well4/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/chip_tiling/211123_PZ1/chunks/well7/segtrack/segs/ch0/10_mean__fix/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/slice/20230831_SL1PL55/slice/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/slice/20230830_SL1PL28/slice/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/slice/20230829_SL1PL56/wells001/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/slice/20230829_SL1PL56/slice/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/slice/20230824_SL1PL60/wells001/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/231108_DG61PL62/wells101/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/231108_DG61PL62/mouse/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/231107_DG44PL58/wells101/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/231107_DG44PL58/mouse/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/231106_DG52PL68/wells101/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/231106_DG52PL68/mouse/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/231105_DG43PL32/mouse/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/231105_DG39PL32/wells201/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/231105_DG39PL32/mouse/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/231031_DG53PL28/wells101/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/231031_DG53PL28/mouse/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/231030_DG60PL67/wells101/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/231029_DG58PL64/mouse/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/231027_DG57PL69/mouse/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/231019_DG53PL68/mouse/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/231017_DG49PL70/mouse/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/230909_DG88PL58/wells101/segtrack/segs/ch0/31_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/230909_DG88PL58/mouse/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/230908_PK109PL52/wells101/segtrack/segs/ch0/31_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/230908_PK109PL52/mouse/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/230907_PK108PL54/mouse/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/230906_PS57PL56/wells101/segtrack/segs/ch0/31_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/230904_PS54PL60/wells101/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/230904_PS54PL60/mouse/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/230901_DG89PL32/wells101/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"
         "peter/in_vivo/230901_DG89PL32/mouse/segtrack/segs/ch0/52_mean_warped_ch0/cellpose_model_1_o_relab042323_flow_aniso4_st0p4_blTrue_intFalse_3DeeC/seg"];
prob_refs = [repmat(1,1,2)...%54
    repmat(28,1,1)...
    repmat(28,1,1)...
    repmat(52,1,1)...
    repmat(28,1,1)...
    repmat(18,1,1)...
    repmat(34,1,1)...
    repmat(85,1,1)...
    repmat(34,1,1)...
    repmat(85,1,1)...
    repmat(34,1,1)...
    repmat(85,1,1)...
    repmat(19,1,1)...
    repmat(34,1,1)...
    repmat(85,1,1)...
    repmat(34,1,1)...
    repmat(85,1,1)...
    repmat(34,1,1)...
    repmat(10,1,1)...
    repmat(85,1,1)...
    repmat(85,1,1)...
    repmat(71,1,1)...
    repmat(34,1,1)...
    repmat(71,1,1)...
    repmat(34,1,1)...
    repmat(65,1,1)...
    repmat(80,1,1)...
    repmat(34,1,1)...
    repmat(38,1,1)...
    repmat(89,1,1)...
    repmat(38,1,1)...
    repmat(30,1,1)]';

prob_scales = [repmat(2,1,33)]';%85


%% 12/29 GPU batch codes ctd
afs = 2.0;
pyr = 4;
%scale = 2; %use 2 or 2.2; scale gets applied for sequential demons then 2 applied to get 2*scale downsampling for ref demons
D = gpuDevice;
J = parfor_progressbar(size(prob_paths,1),'Paths progress');
for p = 1:size(prob_paths,1)
    tic
    scale = prob_scales(p);
    tempin = readNPY(char(strcat(prob_prefix,prob_paths(p),"/prob_movie.npy")));
    temp = permute(tempin,[3 4 2 1]);
    clear tempin;
    ref = prob_refs(p);
    temp = imresize(temp,1/scale);
    tempg = gpuArray(temp);
    dispsdemseq = zeros([size(temp) 3]);
    H = parfor_progressbar(size(temp,4),'Sequential demons registration');
    for i = 2:size(temp,4)
        [dispsdemseq(:,:,:,i,:),~] = imregdemons(squeeze(tempg(:,:,:,i)),squeeze(tempg(:,:,:,i-1)),'AccumulatedFieldSmoothing',afs,'PyramidLevels',pyr);
        %reset(D);
        H.iterate(1);
    end
    close(H);
    reset(D);
    temp = imresize(temp,1/2);
    tempg = gpuArray(temp);
    dispsdemref = zeros([size(temp) 3]);
    K = parfor_progressbar(size(temp,4),'Reference demons registration');
    for j = 1:size(temp,4)
        [dispsdemref(:,:,:,j,:),~] = imregdemons(squeeze(tempg(:,:,:,j)),squeeze(tempg(:,:,:,ref)),'AccumulatedFieldSmoothing',afs,'PyramidLevels',pyr);
        %reset(D);
        K.iterate(1);
    end
    close(K);
    reset(D);
    mkdir([char(save_prefix) char(prob_paths(p))]);
    save([char(save_prefix) char(prob_paths(p)) '/prob_movie_scale' num2str(scale) 'AFS' num2str(afs) 'PL4_dispdemons_seq.mat'],'dispsdemseq',"-v7.3");
    save([char(save_prefix) char(prob_paths(p)) '/prob_movie_scale' num2str(2*scale) 'AFS' num2str(afs) 'PL4_dispdemons_toref' num2str(ref) '.mat'],'dispsdemref',"-v7.3");
    J.iterate(1);
    toc
end
close(J);

%% 4/30/24 inputs for example imregdemons on signal vs probmovies
prob_prefix = "/mnt/nasquatch/data/2p/";

save_prefix = "/mnt/santiago/2p_data/";

prob_paths = ["peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie.npy"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt.npy"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_global.npy"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt_norm_global.npy"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local_scale.npy"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local_df_filt_global.npy"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt_norm_local.npy"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt_norm_local_df_global.npy"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local.npy"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local_df_global.npy"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie.npy"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt.npy"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_global.npy"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt_norm_global.npy"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local_scale.npy"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local_df_filt_global.npy"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt_norm_local.npy"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt_norm_local_df_global.npy"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local.npy"
    "peter/in_vivo/231108_DG61PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local_df_global.npy"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch0/52_mean__/means_movie.npy"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt.npy"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_global.npy"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt_norm_global.npy"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local_scale.npy"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local_df_filt_global.npy"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt_norm_local.npy"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt_norm_local_df_global.npy"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local.npy"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local_df_global.npy"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch1/52_mean__/means_movie.npy"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt.npy"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_global.npy"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt_norm_global.npy"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local_scale.npy"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local_df_filt_global.npy"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt_norm_local.npy"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt_norm_local_df_global.npy"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local.npy"
    "peter/in_vivo/231105_DG39PL32/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local_df_global.npy"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie.npy"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt.npy"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_global.npy"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt_norm_global.npy"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local_scale.npy"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local_df_filt_global.npy"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt_norm_local.npy"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_filt_norm_local_df_global.npy"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local.npy"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch0/52_mean__/means_movie_norm_local_df_global.npy"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie.npy"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt.npy"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_global.npy"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt_norm_global.npy"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local_scale.npy"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local_df_filt_global.npy"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt_norm_local.npy"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_filt_norm_local_df_global.npy"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local.npy"
    "peter/in_vivo/231025_DG56PL62/mouse/segtrack/tiffs/ch1/52_mean__/means_movie_norm_local_df_global.npy"];

prob_refs = [repmat(85,1,20)...
    repmat(85,1,20)...
    repmat(85,1,20)]';

%% 4/30/24 adapting GPU batch run to example imregdemons on signal vs probmovies
afs = 2.0;
pyr = 4;
scale = 2; %use 2 or 2.2; scale gets applied for sequential demons then 2 applied to get 2*scale downsampling for ref demons
D = gpuDevice;
J = parfor_progressbar(size(prob_paths,1),'Paths progress');
for p = 1:size(prob_paths,1)
    tic
    %scale = prob_scales(p);
    tempin = readNPY(char(strcat(prob_prefix,prob_paths(p))));
    temp = permute(tempin,[3 4 2 1]);
    clear tempin;
    ref = prob_refs(p);
    temp = imresize(temp,1/scale);
    tempg = gpuArray(temp);
    dispsdemseq = zeros([size(temp) 3]);
    H = parfor_progressbar(size(temp,4),'Sequential demons registration');
    for i = 2:size(temp,4)
        [dispsdemseq(:,:,:,i,:),~] = imregdemons(squeeze(tempg(:,:,:,i)),squeeze(tempg(:,:,:,i-1)),'AccumulatedFieldSmoothing',afs,'PyramidLevels',pyr);
        %reset(D);
        H.iterate(1);
    end
    close(H);
    reset(D);
    temp = imresize(temp,1/2);
    tempg = gpuArray(temp);
    dispsdemref = zeros([size(temp) 3]);
    K = parfor_progressbar(size(temp,4),'Reference demons registration');
    for j = 1:size(temp,4)
        [dispsdemref(:,:,:,j,:),~] = imregdemons(squeeze(tempg(:,:,:,j)),squeeze(tempg(:,:,:,ref)),'AccumulatedFieldSmoothing',afs,'PyramidLevels',pyr);
        %reset(D);
        K.iterate(1);
    end
    close(K);
    reset(D);
    prob_path = char(prob_paths(p));
    prob_dir = prob_path(1:strfind(prob_path,'__')+1);
    mkdir([char(save_prefix) prob_dir]);
    save([char(save_prefix) prob_dir '/' prob_path(strfind(prob_path,'__')+3:end-4) '_scale' num2str(scale) 'AFS' num2str(afs) 'PL4_dispdemons_seq.mat'],'dispsdemseq',"-v7.3");
    save([char(save_prefix) prob_dir '/' prob_path(strfind(prob_path,'__')+3:end-4) '_scale' num2str(2*scale) 'AFS' num2str(afs) 'PL4_dispdemons_toref' num2str(ref) '.mat'],'dispsdemref',"-v7.3");
    J.iterate(1);
    toc
end
close(J);

%% batch code
scale = 4;
path = '//nasquatch/data/2p/peter/in_vivo/231025_DG56PL62/mouse/segtrack/segs/ch1/52_mean__/cellpose_model_1_o_relab042323_flow_aniso5_st0p4_blTrue_intFalse_3DeeC/seg';
ref = 85;
for afs = 0.2:0.2:0.8
    dispsdem = zeros([size(temp) 3]);
    H = parfor_progressbar(size(temp,4),'Reference demons registration');
    for i = 1:size(temp,4)
        tic
        [dispsdem(:,:,:,i,:),~] = imregdemons(squeeze(temp(:,:,:,i)),squeeze(temp(:,:,:,ref)),'AccumulatedFieldSmoothing',afs,'PyramidLevels',4);
        H.iterate(1);
        toc
    end
    save([path '/prob_movie_scale' num2str(scale) 'AFS' num2str(afs) 'PL4_dispdemons_toref' num2str(ref) '.mat'],'dispsdem',"-v7.3");
    close(H);
end

%H = parfor_progressbar(size(temp,4),'Demons-2 registration');
%for i = 3:size(temp,4)
%    tic
%    [dispsdem2(:,:,:,i,:),~] = imregdemons(squeeze(temp(:,:,:,i)),squeeze(temp(:,:,:,i-2)),'AccumulatedFieldSmoothing',2.0,'PyramidLevels',4);
%    H.iterate(1);
%    toc
%end
%close(H);

% save displacements
%save([path '/prob_movie_scale' num2str(scale) 'AFS5PL4_dispdemons.mat'],'dispsdem',"-v7.3");
%save([path '/filt_prob_movie_scale' num2str(scale) 'AFS2PL4_dispdemons-2.mat'],'dispsdem2',"-v7.3");
%%
scale = 2;
afs = 2.0;
H = parfor_progressbar(size(temp,4),'Sequential demons registration');
for i = 2:size(temp,4)
    tic
    [dispsdem(:,:,:,i,:),~] = imregdemons(squeeze(temp(:,:,:,i)),squeeze(temp(:,:,:,i-1)),'AccumulatedFieldSmoothing',afs,'PyramidLevels',4);
    H.iterate(1);
    toc
end
close(H);

% save displacements
save([path '/prob_movie_scale' num2str(scale) 'AFS' num2str(afs) 'PL4_dispdemons_seq.mat'],'dispsdem',"-v7.3");
    
%%
H = parfor_progressbar(size(aligneddef,4),'Deformable registration');
for i = 2:60 %2:size(aligned,4)
    tic
    [dispsdef(:,:,:,i,:),~] = imregdeform(squeeze(temp(:,:,:,i)),squeeze(temp(:,:,:,i-1)));
    H.iterate(1);
    toc
end
close(H);

%% fixing breaks with alignment every two


fixpoints = [22];
seed = 50;
dispsdemcum = zeros(size(dispsdem));
for j = seed-1:-1:1
    tic
    if ismember(j,fixpoints-1)
        dispsdemcum(:,:,:,j,:) = dispsdemcum(:,:,:,j+2,:) - dispsdem2(:,:,:,j+2,:);
    else
        dispsdemcum(:,:,:,j,:) = dispsdemcum(:,:,:,j+1,:) - dispsdem(:,:,:,j+1,:);
    end
    toc
end
for j = seed+1:size(aligneddem2,4)
    tic
    if ismember(j,fixpoints+1)
        dispsdemcum(:,:,:,j,:) = dispsdemcum(:,:,:,j-2,:) + dispsdem2(:,:,:,j,:);
    else
        dispsdemcum(:,:,:,j,:) = dispsdemcum(:,:,:,j-1,:) + dispsdem(:,:,:,j,:);
    end
    toc
end

for j = 1:size(aligneddem2,4)
    tic
    aligneddem2(:,:,:,j) = imwarp(squeeze(temp(:,:,:,j)),squeeze(dispsdemcum(:,:,:,j,:)));
    toc
end


%% quantifying quality of warp
corrpre = ones(1,size(aligneddem2,4));
%corrpost = ones(1,60);
corrpostfix = ones(1,size(aligneddem2,4));
slice = 16;

for k = 4:size(aligneddem2,4)
    corrpre(k) = corr2(squeeze(temp(:,:,slice,k)),squeeze(temp(:,:,slice,k-3)));
    %corrpost(k) = corr2(squeeze(aligneddem(:,:,slice,k)),squeeze(aligneddem(:,:,slice,k-1)));
    corrpostfix(k) = corr2(squeeze(aligneddem2(:,:,slice,k)),squeeze(aligneddem2(:,:,slice,k-3)));
end

figure,plot(corrpre)
hold on
%plot(corrpost)
plot(corrpostfix)
hold off

%% apply single displacements
aligneddem41p085 = zeros(size(temp));
H = parfor_progressbar(size(temp,4),'Reference alignment');
for j = 1:size(temp,4)
    tic
    aligneddem41p085(:,:,:,j) = imwarp(squeeze(temp(:,:,:,j)),squeeze(dispsdem(:,:,:,j,:)));
    H.iterate(1);
    toc
end
close(H);

%% apply sequential displacements
aligneddem_box21_21_3 = temp;

H = parfor_progressbar(size(temp,4),'Sequential alignment');
for j = 2:size(temp,4)
    tic
    for i = 1:j-1
        aligneddem_box21_21_3(:,:,:,i) = imwarp(squeeze(aligneddem_box21_21_3(:,:,:,i)),squeeze(-dispsdem_box21_21_3(:,:,:,j,:)));
    end
    H.iterate(1);
    toc
end
close(H);
%
implay(squeeze(aligneddem_box21_21_3(:,:,18,:)));
%% wrong here
for j = 2:60
    tic
    aligneddem(:,:,:,j) = imwarp(squeeze(temp(:,:,:,j)),squeeze(sum(dispsdem(:,:,:,1:j,:),4)));
    toc
end
aligneddem(:,:,:,1) = squeeze(temp(:,:,:,1));

for j = 2:60
    tic
    aligneddef(:,:,:,j) = imwarp(squeeze(temp(:,:,:,j)),squeeze(sum(dispsdef(:,:,:,1:j,:),4)));
    toc
end
aligneddef(:,:,:,1) = squeeze(temp(:,:,:,1));
%% displacement magnitude movie
dispsdem_mags = zeros(size(temp));
H = parfor_progressbar(size(temp,1),'Calculating warp magnitudes');
for i = 1:size(temp,1)
    tic
    for j = 1:size(temp,2)
        for k = 1:size(temp,3)
            for t = 1:size(temp,4)
                dispsdem_mags(i,j,k,t) = norm(squeeze(dispsdem20(i,j,k,t,:)));
            end
        end
    end
    toc
    H.iterate(1);
end
close(H);
%% gaussian blur dispsdems and make magnitude movie
dispsdem_box21_21_3 = zeros(size(dispsdem));
dispsdem_mags_box21_21_3 = zeros(size(temp));

H = parfor_progressbar(size(dispsdem,4),'Calculating warp magnitudes');
for t = 1:size(dispsdem,4)
    tic
    dispsdem_box21_21_3(:,:,:,t,1) = imboxfilt3(squeeze(dispsdem(:,:,:,t,1)),[21,21,3]);
    dispsdem_box21_21_3(:,:,:,t,2) = imboxfilt3(squeeze(dispsdem(:,:,:,t,1)),[21,21,3]);
    dispsdem_box21_21_3(:,:,:,t,3) = imboxfilt3(squeeze(dispsdem(:,:,:,t,1)),[21,21,3]);
    toc
    H.iterate(1);
end
close(H);

H = parfor_progressbar(size(temp,1),'Calculating warp magnitudes');
for i = 1:size(temp,1)
    tic
    for j = 1:size(temp,2)
        for k = 1:size(temp,3)
            for t = 1:size(temp,4)
                dispsdem_mags_box21_21_3(i,j,k,t) = norm(squeeze(dispsdem_box21_21_3(i,j,k,t,:)));
            end
        end
    end
    toc
    H.iterate(1);
end
close(H);
%% save as mat/Tiff
%save(['prob_movie_scale' num2str(scale) '_demons.mat'],'aligneddem2',"-v7.3");
%save(['prob_movie_scale' num2str(scale) '.mat'],'temp',"-v7.3");

filename = 'dispsdem_mags42p085.tiff';
mov = dispsdem_mags;
mov = reshape(mov,size(mov,1),size(mov,2),[]);
Miji(false);
MIJ.createImage(mov);
MIJ.run('Stack to Hyperstack...', sprintf('order=xyztc channels=%d slices=%d frames=%d display=Composite',1,size(temp,3),size(temp,4)));
MIJ.run('Save', strcat('Tiff..., path=[',filename,']'));
MIJ.closeAllWindows
MIJ.exit;


%writeTiff(aligneddem2,['prob_movie_scale' num2str(scale) '_demons.tif']);
%writeTiff(temp,['prob_movie_scale' num2str(scale) '.tif']);

%% upsample and apply single displacements to means movie
scale = 4; %fix for automatic scale detection
%parpool
path = '//nasquatch/data/2p/peter/in_vivo/231108_DG61PL62/wells/segtrack/tiffs/ch0/52_mean__';
tic
meansin = readNPY([path '/means_movie.npy']);
toc
means = permute(meansin,[3 4 2 1]);
%%
dispsdemup = zeros([size(means),3]);

% 2D upsampling for mean movies
H = parfor_progressbar(size(dispsdemup,4),'Upsampling displacements');
tic
for t = 1:size(dispsdemup,4)
    for z = 1:size(dispsdemup,3)
        dispsdemup(:,:,z,t,1) = scale*imresize(squeeze(dispsdemref(:,:,z,t,1)),[size(dispsdemup,1),size(dispsdemup,2)],'bilinear');
        dispsdemup(:,:,z,t,2) = scale*imresize(squeeze(dispsdemref(:,:,z,t,2)),[size(dispsdemup,1),size(dispsdemup,2)],'bilinear');
        dispsdemup(:,:,z,t,3) = imresize(squeeze(dispsdemref(:,:,z,t,3)),[size(dispsdemup,1),size(dispsdemup,2)],'bilinear');
    end
    H.iterate(1);
end
toc
close(H);

mov = zeros(size(means));
H = parfor_progressbar(size(means,4),'Warping movie');
tic
for t = 1:size(means,4)
    mov(:,:,:,t) = imwarp(squeeze(means(:,:,:,t)),squeeze(dispsdemup(:,:,:,t,:)));
    H.iterate(1);
end
toc
close(H);

% save movie as NPY
tic
filename = 'alignedmeans_wch1_aniso5_sc4_afs2p0_ref34_ch0.npy';

mov = cast(mov,'single'); 
movout = permute(mov,[4 3 1 2]); %permute axes to be TZYX from original YXZT to match upstream .npy movies/satisfy napari; for two color, Fiji tiffs become TZCYX, but for easy color splitting in napari, make it CTZYX!
writeNPY(movout,strcat(path,'/',filename));
toc

% GPU attempts
%D = gpuDevice;
%alignedmeans42p085 = zeros(size(means));
%meansg = gpuArray(means);
%dispsdemupg = gpuArray(dispsdemup); %too big for memory on Quadro K5200
%H = parfor_progressbar(size(means,4),'Warping movie');
%tic
%for t = 1:size(means,4)
%    alignedmeans42p085(:,:,:,t) = imwarp(squeeze(meansg(:,:,:,t)),squeeze(dispsdemup(:,:,:,t,:)));
%    H.iterate(1);
%end
%toc
%close(H);

%still working on this for Tiff
%tic
%filename = 'alignedmeans42p085ch0T.tiff';
%mov = alignedmeans42p085;
%out = Tiff(strcat(path,'/',filename),'w8');
%tags.ImageLength         = size(mov,1);
%tags.ImageWidth          = size(mov,2);
%tags.Photometric         = Tiff.Photometric.RGB;
%tags.BitsPerSample       = 8;
%tags.SamplesPerPixel     = size(mov,3);
%tags.TileWidth           = 128;
%tags.TileLength          = 128;
%tags.Compression         = Tiff.Compression.None;
%tags.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
%tags.Software            = 'MATLAB';
%setTag(out, tags);
%write(out,mov);
%close(out);
%toc

%mov = reshape(mov,size(mov,1),size(mov,2),[]);
%Miji(false);
%MIJ.createImage(mov);
%MIJ.run('Stack to Hyperstack...', sprintf('order=xyztc channels=%d slices=%d frames=%d display=Composite',1,size(means,3),size(means,4)));
%MIJ.run('Save', strcat('Tiff..., path=[',path,'/',filename,']'));
%MIJ.closeAllWindows
%MIJ.exit;
%toc

% what about movie as NPY??
%tic
%%
aligneddem41p085 = zeros(size(temp));
H = parfor_progressbar(size(temp,4),'Reference alignment');
for j = 1:size(temp,4)
    tic
    aligneddem41p085(:,:,:,j) = imwarp(squeeze(temp(:,:,:,j)),squeeze(dispsdem(:,:,:,j,:)));
    H.iterate(1);
    toc
end
close(H);

%% old demons code
D_reg = zeros(size(temp,2),size(temp,3),size(temp,4),3,size(temp,5));
tic
H = parfor_progressbar(size(temp,5),'Demons registration');
parfor i = 1:size(temp,5)
    tform = imregtform(squeeze(temp(refchan,:,:,:,i)),squeeze(refav(refchan,:,:,:)),'affine',optimizer,metric);
    D_reg(:,:,:,:,i) = imregdemons(squeeze(temp(refchan,:,:,:,i)),squeeze(refav(refchan,:,:,:)));
    H.iterate(1);
end
close(H);
toc