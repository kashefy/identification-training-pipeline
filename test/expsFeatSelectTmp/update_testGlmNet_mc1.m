function update_testGlmNet_mc1()
    
addpath( '../..' );
startIdentificationTraining();

classes = {'alarm','baby','femaleSpeech','fire'};
featureCreators = {?featureCreators.FeatureSet1Blockmean,...
                   ?featureCreators.FeatureSet1VarBlocks,...
                   ?featureCreators.FeatureSet1BlockmeanLowVsHighFreqRes};

if exist( 'glmnet_mc1_test.mat', 'file' )
    load( 'glmnet_mc1_test.mat' );
else return;
end
if exist( 'glmnet_mc1_test1.mat', 'file' )
    altmat = load( 'glmnet_mc1_test1.mat' );
end

for cc = 1 : numel( classes )
classname = classes{cc};
for fc = 1 : numel( featureCreators )
        
fprintf( '.\n' );

if exist( 'modelpathes_test','var' )  &&  ...
        size(modelpathes_test,1) >= fc  &&  size(modelpathes_test,2) >= cc  ...
        &&  isempty( modelpathes_test{fc,cc} )
    if exist( 'altmat', 'var' ) && isfield( altmat, 'modelpathes_test' )  &&  ...
            size(altmat.modelpathes_test,1) >= fc  &&  size(altmat.modelpathes_test,2) >= cc  ...
            &&  ~isempty( altmat.modelpathes_test{fc,cc} )
        modelpathes_test{fc,cc} = altmat.modelpathes_test{fc,cc};
    else
        continue;
    end
end
if exist( 'modelpathes_test','var' )  &&  ...
        (size(modelpathes_test,1) < fc  ||  size(modelpathes_test,2) < cc)
    if exist( 'altmat', 'var' ) && isfield( altmat, 'modelpathes_test' )  &&  ...
            size(altmat.modelpathes_test,1) >= fc  &&  size(altmat.modelpathes_test,2) >= cc  ...
            &&  ~isempty( altmat.modelpathes_test{fc,cc} )
        modelpathes_test{fc,cc} = altmat.modelpathes_test{fc,cc};
    else
        continue;
    end
end
if exist( 'lambdas','var' )  &&  ...
        size(lambdas,1) >= fc  &&  size(lambdas,2) >= cc  ...
        &&  ~isempty( lambdas{fc,cc} )
    continue;
end
    
testmodel = load( [modelpathes_test{fc,cc} filesep classname '.model.mat'] );

test_performances{fc,cc} = [testmodel.testPerfresults.performance];
cv_performances{fc,cc} = testmodel.model.lPerfsMean;
cv_std{fc,cc} = testmodel.model.lPerfsStd;
[coefIdxs_b{fc,cc},...
 impacts_b{fc,cc},...
 perf_b{fc,cc},...
 lambda_b{fc,cc},...
 nCoefs_b{fc,cc}] = testmodel.model.getBestLambdaCVresults();
[coefIdxs_bms{fc,cc},...
 impacts_bms{fc,cc},...
 perf_bms{fc,cc},...
 lambda_bms{fc,cc},...
 nCoefs_bms{fc,cc}] = testmodel.model.getBestMinStdCVresults();
[coefIdxs_hws{fc,cc},...
 impacts_hws{fc,cc},...
 perf_hws{fc,cc},...
 lambda_hws{fc,cc},...
 nCoefs_hws{fc,cc}] = testmodel.model.getHighestLambdaWithinStdCVresults();
lbIdx = find( testmodel.model.model.lambda == lambda_b{fc,cc} );
lhwsIdx = find( testmodel.model.model.lambda == lambda_hws{fc,cc} );
test_performances_b{fc,cc} = test_performances{fc,cc}(lbIdx);
test_performances_hws{fc,cc} = test_performances{fc,cc}(lhwsIdx);
[lambdas{fc,cc},...
 nCoefs{fc,cc}] = testmodel.model.getLambdasAndNCoefs();
trainTime{fc,cc} = testmodel.trainTime;

save( 'glmnet_mc1_test.mat', 'classes', 'featureCreators', ...
    'modelpathes_test', 'test_performances', 'cv_performances', 'cv_std',...
    'coefIdxs_b', 'impacts_b', 'perf_b', 'lambda_b', 'nCoefs_b',...
    'coefIdxs_bms', 'impacts_bms', 'perf_bms', 'lambda_bms', 'nCoefs_bms',...
    'coefIdxs_hws', 'impacts_hws', 'perf_hws', 'lambda_hws', 'nCoefs_hws',...
    'test_performances_b', 'test_performances_hws', 'lambdas', 'nCoefs', 'trainTime'  );
end
end
