classdef vMFTrainer < modelTrainers.Base & Parameterized
    
    %% --------------------------------------------------------------------
    properties (Access = protected)
        model;
    end

    %% --------------------------------------------------------------------
    methods

        function obj = vMFTrainer( varargin )
            pds{1} = struct( 'name', 'performanceMeasure', ...
                             'default', @BAC2, ...
                             'valFun', @(x)(isa( x, 'function_handle' )), ...
                             'setCallback', @(ob, n, o)(ob.setPerformanceMeasure( n )) );
            pds{2} = struct( 'name', 'maxDataSize', ...
                             'default', inf, ...
                             'valFun', @(x)(isinf(x) || (rem(x,1) == 0 && x > 0)) );
            pds{3} = struct( 'name', 'nComp', ...
                'default', [1 2 3], ...
                'valFun', @(x)(sum(x)>=0) );
            pds{4} = struct( 'name', 'thr', ...
                             'default', [0.5 0.6], ...
                             'valFun', @(x)(x<=1 && x >= 0) );
            obj = obj@Parameterized( pds );
            obj.setParameters( true, varargin{:} );
        end
        %% ----------------------------------------------------------------

        function buildModel( obj, x, y )
%             glmOpts.weights = obj.setDataWeights( y );
            if length( y ) > obj.parameters.maxDataSize
                x(obj.parameters.maxDataSize+1:end,:) = [];
                y(obj.parameters.maxDataSize+1:end) = [];
            end
            obj.model = models.vMFModel();
            xScaled = obj.model.scale2zeroMeanUnitVar( x, 'saveScalingFactors' );
            gmmOpts.nComp = obj.parameters.nComp;
            gmmOpts.thr = obj.parameters.thr;
            %....... approach 1: explicit dimension reduction using PCA
            idFeature = featureSelectionPCA2(xScaled,gmmOpts.thr);
            xTrain = xScaled(:,idFeature);
            %....... approach 2: uncorrelate feature variables using PCA 
%             dataDim = size(xScaled,2);
%             ndims = floor(gmmOpts.thr*dataDim);
%             [~,reconst] = pcares(xScaled,ndims);
%             xTrain = reconst(:,1:ndims);
%             idFeature = ndims;
            
            
            gmmOpts.initComps = gmmOpts.nComp;
            [obj.model.model{1}, obj.model.model{2}] = trainVMF( y, (normvec(xTrain'))', gmmOpts );
            obj.model.model{3}=idFeature;
            verboseFprintf( obj, '\n' );
        end
        %% ----------------------------------------------------------------

    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
        
        function model = giveTrainedModel( obj )
            model = obj.model;
        end
        %% ----------------------------------------------------------------
        
        function wp = setDataWeights( obj, y )
            ypShare = ( mean( y ) + 1 ) * 0.5;
            cp = ( 1 - ypShare ) / ypShare;
            if isnan( cp ) || isinf( cp )
                warning( 'The share of positive to negative examples is inf or nan.' );
            end
            wp = ones( size(y) );
            wp(y==1) = cp;
        end
        %% ----------------------------------------------------------------
        
    end
    
end