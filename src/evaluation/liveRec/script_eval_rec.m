%% mc1_models_dataset_1
% idModels(1).name = 'alarm';
% idModels(2).name = 'baby';
% idModels(5).name = 'fire';
% idModels(4).name = 'femaleSpeech';
% idModels(3).name = 'dog';
% idModels(6).name = 'piano';
% [idModels(1:6).dir] = deal( '../../../../twoears-database-internal/learned_models/IdentityKS/mc1_models_dataset_1' );

%% mc1b_models_dataset_1
idModels(1).name = 'alarm';
idModels(2).name = 'baby';
idModels(5).name = 'fire';
idModels(4).name = 'femaleSpeech';
idModels(3).name = 'dog';
[idModels(1:5).dir] = deal( '../../../../twoears-database-internal/learned_models/IdentityKS/mc1b_models_dataset_1' );

%% mc2_models_dataset_1
% idModels(1).name = 'alarm';
% idModels(2).name = 'baby';
% idModels(4).name = 'fire';
% idModels(3).name = 'femaleSpeech';
% [idModels(1:4).dir] = deal( '../../../../twoears-database-internal/learned_models/IdentityKS/mc2_models_dataset_1' );

%% mc2b_models_dataset_1
% idModels(1).name = 'alarm';
% idModels(2).name = 'baby';
% idModels(4).name = 'fire';
% idModels(3).name = 'femaleSpeech';
% [idModels(1:4).dir] = deal( '../../../../twoears-database-internal/learned_models/IdentityKS/mc2b_models_dataset_1' );

%% mc2segmented_models_dataset_1
% idModels(1).name = 'alarm';
% idModels(2).name = 'baby';
% idModels(4).name = 'fire';
% idModels(3).name = 'femaleSpeech';
% [idModels(1:4).dir] = deal( '../../../../twoears-database-internal/learned_models/IdentityKS/mc2segmented_models_dataset_1' );

%%
ppRemoveDc = true;
fs = 44100;

data_dir = '../../../../twoears-database-internal';
flist = ...
    {fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/alarm.mat'),...
    fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/baby.mat'),...
    fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/baby_dog_fire.mat'),...
    fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/baby_piano.mat'),...
    fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/dog.mat'),...
    fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/baby_dog_fire_moving.mat'),...
    fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/fire.mat'),...
    fullfile(data_dir, 'sound_databases/adream_1605/rec/raw/baby_dog_fire_piano.mat')}; % piano_baby -> baby_dog_fire_piano
% onset of first chirp to offset of final chirp
session_onOffSet = [1.236e+05, 8582556;...   % alarm
                    8.991e+04, 15096220;...   % baby
                    88944, min([15094288, 4819608, 30081565]);...   % baby_dog_fire
                    7.4822e+04, min([15066044, 8090428]);...   % baby_piano
                    9.2152e+04, 4826024;...   % dog # previously 9.927e+04
                    5.0477e+04, min([15017354, 4742674, 3000463]);...   % baby_dog_fire_moving
                    5.4325e+04, 30012327;...   % fire
                    1.1279e+05, min([15141980, 4867300, 30129257, 8166364]);...   % piano_baby -> baby_dog_fire_piano \
                   ];
session_onOffSet = session_onOffSet / 44100.0; % from samples to seconds
for ii = 1 : numel(flist)
    fpath_mixture_mat = flist{ii};
    [~, fname, ext] = fileparts(fpath_mixture_mat);
    if strcmp(ext, '.mat')
        wav_dir = fullfile(data_dir, 'sound_databases/adream_1605/rec/wav');
        fpath_mixture_wav = fullfile(wav_dir, [fname, '.wav']);
    elseif strcmp(ext, '.wav')
        % do nothing
    else
        error('Unrecognized mixture file %s', fpath_mixture_mat);
    end
    %[idLabels{ii}, perf{ii}] = identify_rec(idModels, fpath_mixture_mat, fpath_mixture_wav, session_onOffSet(ii,:), ppRemoveDc, fs);
    close all
end

p = arrayfun( @(x)(x.performance), vertcat( perf{:} ) );
disp( p );

perfOverview = vertcat( perf{:} );
tp1 = sum( arrayfun( @(x)(x.tp), perfOverview([1,2,5,7],:) ) );
fp1 = sum( arrayfun( @(x)(x.fp), perfOverview([1,2,5,7],:) ) );
tn1 = sum( arrayfun( @(x)(x.tn), perfOverview([1,2,5,7],:) ) );
fn1 = sum( arrayfun( @(x)(x.fn), perfOverview([1,2,5,7],:) ) );

tpfn1 = tp1 + fn1;
tnfp1 = tn1 + fp1;

sens1 = tp1 ./ tpfn1;
spec1 = tn1 ./ tnfp1;
bac1 = 0.5*sens1 + 0.5*spec1;

tp2 = sum( arrayfun( @(x)(x.tp), perfOverview([3,4,6,8],:) ) );
fp2 = sum( arrayfun( @(x)(x.fp), perfOverview([3,4,6,8],:) ) );
tn2 = sum( arrayfun( @(x)(x.tn), perfOverview([3,4,6,8],:) ) );
fn2 = sum( arrayfun( @(x)(x.fn), perfOverview([3,4,6,8],:) ) );

tpfn2 = tp2 + fn2;
tnfp2 = tn2 + fp2;

sens2 = tp2 ./ tpfn2;
spec2 = tn2 ./ tnfp2;
bac2 = 0.5*sens2 + 0.5*spec2;
