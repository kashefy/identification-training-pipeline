function test_glmnet_PDs_mc( ddt )
    
addpath( '../..' );
startIdentificationTraining();

featureCreators = {?featureCreators.FeatureSet1Blockmean,...
                   ?featureCreators.FeatureSet1Blockmean2Ch};
azimuths = {{0,0},...
    {0,45},{45,0},{22.5,-22.5},{67.5,112.5},{-157.5,157.5},...
    {0,90},{22.5,112.5},{45,135},{90,180},{22.5,-67.5},{45,-45},{90,0},{-157.5,112.5},...
    {0,180},{22.5,-157.5},{45,-135},{67.5,-112.5},{90,-90}}; % 19 cfgs
snrs = {0,-10,10,-20};
datasets = {'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_1.flist',...
            'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_1.flist',...
            'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_2.flist',...
            'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_2.flist',...
            'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_3.flist',...
            'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_3.flist',...
            'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TrainSet_4.flist',...
            'learned_models/IdentityKS/trainTestSets/NIGENS_75pTrain_TestSet_4.flist'
            };
classes = {'alarm','baby','femaleSpeech','fire','crash','dog','engine','footsteps',...
           'knock','phone','piano'};
       
if exist( 'pds_glmnet_mc_test.mat', 'file' )
    load( 'pds_glmnet_mc_test.mat' );
else
    doneCfgsTest = {};
end

for cc = 1 : numel( classes )
for ff = 1 %: numel( featureCreators )

dd = ddt-1;

% TODO: cross tests

fprintf( '\n\n==============\nTesting %s, dd = %d, ff = %d.==============\n\n', ...
    classes{cc}, ddt, ff );

if exist( ['pds_mc_' strrep(num2str([dd,ff]),' ','_') '_glmnet.mat'], 'file' )
    load( ['pds_mc_' strrep(num2str([dd,ff]),' ','_') '_glmnet'] );
else
    warning( 'Training mat file not found' );
    pause;
    continue;
end

if ~any( cellfun( @(x)(all(x==[cc dd ff])), doneCfgs ) )
    continue; % training not done yet
end
if any( cellfun( @(x)(all(x==[cc ddt ff])), doneCfgsTest ) )
    continue; % testing already done
end
    
pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = feval( featureCreators{ff}.Name );
pipe.modelCreator = ...
    modelTrainers.LoadModelNoopTrainer( ...
        @(cn)(fullfile( modelpathes{cc,dd,ff}, [cn '.model.mat'] )), ...
        'performanceMeasure', @performanceMeasures.BAC2, ...
        'modelParams', struct('lambda', []) );
pipe.modelCreator.verbose( 'on' );

pipe.trainset = [];
pipe.testset = datasets{ddt};
pipe.setupData();

mcsc = sceneConfig.SceneConfiguration.empty;
for aa = [1,4,12,19,14,6,7,9,10,13]
    for ss = 1:4
        sc = sceneConfig.SceneConfiguration();
        sc.addSource( sceneConfig.PointSource( ...
            'azimuth',sceneConfig.ValGen('manual',azimuths{aa}{1}) ) );
        sc.addSource( sceneConfig.PointSource( ...
            'azimuth',sceneConfig.ValGen('manual',azimuths{aa}{2}), ...
            'data',sceneConfig.FileListValGen(pipe.pipeline.data('general',:,'wavFileName')),...
            'offset', sceneConfig.ValGen('manual',0.0) ),...
            sceneConfig.ValGen( 'manual', snrs{ss} ),...
            true ); % loop
        mcsc(end+1) = sc;
    end
end
pipe.setSceneConfig( mcsc );

pipe.init();
pipe.pipeline.gatherFeaturesProc.setConfDataUseRatio( 0.1 );
modelpathes_test{cc,ddt,ff} = pipe.pipeline.run( classes(cc), 0 );

testmodel = load( [modelpathes_test{cc,ddt,ff} filesep classes{cc} '.model.mat'] );

test_performances{cc,ddt,ff} = [testmodel.testPerfresults.performance];
cv_performances{cc,ddt,ff} = testmodel.model.lPerfsMean;
cv_std{cc,ddt,ff} = testmodel.model.lPerfsStd;
[coefIdxs_b{cc,ddt,ff},...
 impacts_b{cc,ddt,ff},...
 perf_b{cc,ddt,ff},...
 lambda_b{cc,ddt,ff},...
 nCoefs_b{cc,ddt,ff}] = testmodel.model.getBestLambdaCVresults();
[coefIdxs_bms{cc,ddt,ff},...
 impacts_bms{cc,ddt,ff},...
 perf_bms{cc,ddt,ff},...
 lambda_bms{cc,ddt,ff},...
 nCoefs_bms{cc,ddt,ff}] = testmodel.model.getBestMinStdCVresults();
[coefIdxs_hws{cc,ddt,ff},...
 impacts_hws{cc,ddt,ff},...
 perf_hws{cc,ddt,ff},...
 lambda_hws{cc,ddt,ff},...
 nCoefs_hws{cc,ddt,ff}] = testmodel.model.getHighestLambdaWithinStdCVresults();
lbIdx = find( testmodel.model.model.lambda == lambda_b{cc,ddt,ff} );
lhwsIdx = find( testmodel.model.model.lambda == lambda_hws{cc,ddt,ff} );
test_performances_b{cc,ddt,ff} = test_performances{cc,ddt,ff}(lbIdx);
test_performances_hws{cc,ddt,ff} = test_performances{cc,ddt,ff}(lhwsIdx);
[lambdas{cc,ddt,ff},...
 nCoefs{cc,ddt,ff}] = testmodel.model.getLambdasAndNCoefs();
testTime{cc,ddt,ff} = testmodel.trainTime;
trainTime{cc,ddt,ff} = ...
    load( [modelpathes{cc,dd,ff} filesep classes{cc} '.model.mat'], 'trainTime' );

doneCfgsTest{end+1} = [cc ddt ff];

save( 'pds_glmnet_mc_test.mat', ...
    'modelpathes_test', 'doneCfgsTest', ...
    'test_performances', 'cv_performances', 'cv_std',...
    'coefIdxs_b', 'impacts_b', 'perf_b', 'lambda_b', 'nCoefs_b',...
    'coefIdxs_bms', 'impacts_bms', 'perf_bms', 'lambda_bms', 'nCoefs_bms',...
    'coefIdxs_hws', 'impacts_hws', 'perf_hws', 'lambda_hws', 'nCoefs_hws',...
    'test_performances_b', 'test_performances_hws', 'lambdas', 'nCoefs', ...
    'trainTime', 'testTime' );

end
end

