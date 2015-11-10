function testGlmNet_azms()
    
addpath( '../..' );
startIdentificationTraining();

classes = {'alarm','baby','femaleSpeech','fire'};
featureCreators = {?featureCreators.FeatureSet1Blockmean2Ch,...
                   ?featureCreators.FeatureSet1Blockmean};
azimuths = {0,45,90,180};

if exist( 'glmnet_azms.mat', 'file' )
    load( 'glmnet_azms.mat' );
else
    return;
end
if exist( 'glmnet_azms_test.mat', 'file' )
    load( 'glmnet_azms_test.mat' );
end

for ii = 1 : 4
for cc = 1 : numel( classes )
for fc = 1 : numel( featureCreators )
for aa = 1 : numel( azimuths )
for aatest = 1 : numel( azimuths )
    
fprintf( '.\n' );

if exist( 'modelpathes','var' )  &&  ...
        size(modelpathes,1) >= ii  &&  size(modelpathes,2) >= cc  &&  ...
        size(modelpathes,3) >= fc  &&  size(modelpathes,4) >= aa  ...
        &&  isempty( modelpathes{ii,cc,fc,aa} )
    continue;
end
if exist( 'modelpathes','var' )  &&  (...
        size(modelpathes,1) < ii  ||  size(modelpathes,2) < cc  ||  ...
        size(modelpathes,3) < fc  ||  size(modelpathes,4) < aa )
    continue;
end
if exist( 'modelpathes_test','var' )  &&  ...
        size(modelpathes_test,1) >= ii  &&  size(modelpathes_test,2) >= cc  &&  ...
        size(modelpathes_test,3) >= fc  &&  size(modelpathes_test,4) >= aa  &&  ...
        size(modelpathes_test,5) >= aatest  ...
        &&  ~isempty( modelpathes_test{ii,cc,fc,aa,aatest} )
    continue;
end
    
sc = sceneConfig.SceneConfiguration();
sc.addSource( sceneConfig.PointSource('azimuth',...
                                      sceneConfig.ValGen('manual',azimuths{aatest})) );

pipe = TwoEarsIdTrainPipe();
pipe.featureCreator = feval( featureCreators{fc}.Name );
pipe.modelCreator = ...
    modelTrainers.LoadModelNoopTrainer( ...
        @(cn)(fullfile( modelpathes{ii,cc,fc,aa}, [cn '.model.mat'] )), ...
        'performanceMeasure', @performanceMeasures.BAC2, ...
        'modelParams', struct('lambda', []) );
pipe.modelCreator.verbose( 'on' );

setsBasePath = 'learned_models/IdentityKS/trainTestSets/';
pipe.trainset = [];
pipe.testset = [setsBasePath 'NIGENS_75pTrain_TestSet_' num2str(ii) '.flist'];
pipe.setupData();

pipe.setSceneConfig( sc ); 

pipe.init();
modelpathes_test{ii,cc,fc,aa,aatest} = pipe.pipeline.run( {classes{cc}}, 0 );

testmodel = load( [modelpathes_test{ii,cc,fc,aa,aatest} filesep classes{cc} '.model.mat'] );

test_performances{ii,cc,fc,aa,aatest} = [testmodel.testPerfresults.performance];
cv_performances{ii,cc,fc,aa,aatest} = testmodel.model.lPerfsMean;
cv_std{ii,cc,fc,aa,aatest} = testmodel.model.lPerfsStd;
[coefIdxs_b{ii,cc,fc,aa,aatest},...
 impacts_b{ii,cc,fc,aa,aatest},...
 perf_b{ii,cc,fc,aa,aatest},...
 lambda_b{ii,cc,fc,aa,aatest},...
 nCoefs_b{ii,cc,fc,aa,aatest}] = testmodel.model.getBestLambdaCVresults();
[coefIdxs_bms{ii,cc,fc,aa,aatest},...
 impacts_bms{ii,cc,fc,aa,aatest},...
 perf_bms{ii,cc,fc,aa,aatest},...
 lambda_bms{ii,cc,fc,aa,aatest},...
 nCoefs_bms{ii,cc,fc,aa,aatest}] = testmodel.model.getBestMinStdCVresults();
[coefIdxs_hws{ii,cc,fc,aa,aatest},...
 impacts_hws{ii,cc,fc,aa,aatest},...
 perf_hws{ii,cc,fc,aa,aatest},...
 lambda_hws{ii,cc,fc,aa,aatest},...
 nCoefs_hws{ii,cc,fc,aa,aatest}] = testmodel.model.getHighestLambdaWithinStdCVresults();
lbIdx = find( testmodel.model.model.lambda == lambda_b{ii,cc,fc,aa,aatest} );
lhwsIdx = find( testmodel.model.model.lambda == lambda_hws{ii,cc,fc,aa,aatest} );
test_performances_b{ii,cc,fc,aa,aatest} = test_performances{ii,cc,fc,aa,aatest}(lbIdx);
test_performances_hws{ii,cc,fc,aa,aatest} = test_performances{ii,cc,fc,aa,aatest}(lhwsIdx);
[lambdas{ii,cc,fc,aa,aatest},...
 nCoefs{ii,cc,fc,aa,aatest}] = testmodel.model.getLambdasAndNCoefs();
trainTime{ii,cc,fc,aa,aatest} = testmodel.trainTime;

save( 'glmnet_azms_test.mat', 'classes', 'featureCreators', 'azimuths', ...
    'modelpathes_test', 'test_performances', 'cv_performances', 'cv_std',...
    'coefIdxs_b', 'impacts_b', 'perf_b', 'lambda_b', 'nCoefs_b',...
    'coefIdxs_bms', 'impacts_bms', 'perf_bms', 'lambda_bms', 'nCoefs_bms',...
    'coefIdxs_hws', 'impacts_hws', 'perf_hws', 'lambda_hws', 'nCoefs_hws',...
    'test_performances_b', 'test_performances_hws', 'lambdas', 'nCoefs', 'trainTime'  );

end
end
end
end
end

