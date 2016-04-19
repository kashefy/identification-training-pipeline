classdef FeatureSet1VarBlocks < FeatureCreators.Base
% uses magnitude ratemap with cubic compression and scaling to a max value
% of one. Reduces each freq channel to its mean and std + mean and std of
% finite differences.

    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        freqChannels;
        freqChannelsStatistics;
        amFreqChannels;
        onsfreqChannels;
        deltasLevels;
        amChannels;
        nlmoments;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = FeatureSet1VarBlocks( )
            obj = obj@FeatureCreators.Base();
            obj.freqChannels = 16;
            obj.onsfreqChannels = 8;
            obj.amFreqChannels = 8;
            obj.freqChannelsStatistics = 32;
            obj.deltasLevels = 2;
            obj.amChannels = 9;
        end
        %% ----------------------------------------------------------------

        function afeRequests = getAFErequests( obj )
            afeRequests{1}.name = 'amsFeatures';
            afeRequests{1}.params = genParStruct( ...
                'pp_bNormalizeRMS', false, ...
                'fb_nChannels', obj.amFreqChannels, ...
                'ams_fbType', 'log', ...
                'ams_nFilters', obj.amChannels, ...
                'ams_lowFreqHz', 1, ...
                'ams_highFreqHz', 256' ...
                );
            afeRequests{2}.name = 'ratemap';
            afeRequests{2}.params = genParStruct( ...
                'pp_bNormalizeRMS', false, ...
                'rm_scaling', 'magnitude', ...
                'fb_nChannels', obj.freqChannels ...
                );
            afeRequests{3}.name = 'spectralFeatures';
            afeRequests{3}.params = genParStruct( ...
                'pp_bNormalizeRMS', false, ...
                'fb_nChannels', obj.freqChannelsStatistics ...
                );
            afeRequests{4}.name = 'onsetStrength';
            afeRequests{4}.params = genParStruct( ...
                'pp_bNormalizeRMS', false, ...
                'fb_nChannels', obj.onsfreqChannels ...
                );
        end
        %% ----------------------------------------------------------------

        function x = constructVector( obj )
            x = obj.concatFeats( obj.constructVectorForBlock( 0.2 ), ...
                                 obj.constructVectorForBlock( 0.5 ), ...
                                 obj.constructVectorForBlock( 1.0 ) );
        end
        %% ----------------------------------------------------------------

        function x = constructVectorForBlock( obj, blLen )
            rmR = obj.makeBlockFromAfe( 2, 1, @(a)(compressAndScale( ...
                    a.getSignalBlock(blLen), 0.33, @(x)(median( x(x>0.01) )), 0 )), ...
                {@(a)(a.Name),@(a)([num2str(numel(a.cfHz)) '-ch']),...
                @(a)(a.Channel),['blLen ' num2str(blLen)]},...
                {'t'}, {@(a)(strcat('f', arrayfun(@(f)(num2str(f)),a.cfHz,'UniformOutput',false)))} );
            rmL = obj.makeBlockFromAfe( 2, 2, @(a)(compressAndScale( ...
                a.getSignalBlock(blLen), 0.33, @(x)(median( x(x>0.01) )), 0 )), ...
                {@(a)(a.Name),@(a)([num2str(numel(a.cfHz)) '-ch']),...
                @(a)(a.Channel),['blLen ' num2str(blLen)]},...
                {'t'}, {@(a)(strcat('f', arrayfun(@(f)(num2str(f)),a.cfHz,'UniformOutput',false)))} );
            rm = obj.combineBlocks( @(b1,b2)(0.5*b1+0.5*b2), 'LRmean', rmR, rmL );
            spfR = obj.makeBlockFromAfe( 3, 1, ...
                @(a)(compressAndScale( a.getSignalBlock(blLen), 0.33 )), ...
                {@(a)(a.Name),[num2str(obj.freqChannelsStatistics) '-ch'],...
                @(a)(a.Channel),['blLen ' num2str(blLen)]},...
                {'t'}, {@(a)(a.fList)} );
            spfL = obj.makeBlockFromAfe( 3, 2, ...
                @(a)(compressAndScale( a.getSignalBlock(blLen), 0.33 )), ...
                {@(a)(a.Name),[num2str(obj.freqChannelsStatistics) '-ch'],...
                @(a)(a.Channel),['blLen ' num2str(blLen)]},...
                {'t'}, {@(a)(a.fList)} );
            spf = obj.combineBlocks( @(b1,b2)(0.5*b1+0.5*b2), 'LRmean', spfR, spfL );
            onsR = obj.makeBlockFromAfe( 4, 1, ...
                @(a)(compressAndScale( a.getSignalBlock(blLen), 0.33 )), ...
                {@(a)(a.Name),@(a)([num2str(numel(a.cfHz)) '-ch']),...
                @(a)(a.Channel),['blLen ' num2str(blLen)]},...
                {'t'}, {@(a)(strcat('f', arrayfun(@(f)(num2str(f)),a.cfHz,'UniformOutput',false)))} );
            onsL = obj.makeBlockFromAfe( 4, 2, ...
                @(a)(compressAndScale( a.getSignalBlock(blLen), 0.33 )), ...
                {@(a)(a.Name),@(a)([num2str(numel(a.cfHz)) '-ch']),...
                @(a)(a.Channel),['blLen ' num2str(blLen)]},...
                {'t'}, {@(a)(strcat('f', arrayfun(@(f)(num2str(f)),a.cfHz,'UniformOutput',false)))} );
            ons = obj.combineBlocks( @(b1,b2)(0.5*b1+0.5*b2), 'LRmean', onsR, onsL );
            xb = obj.concatBlocks( 2, rm, spf, ons );
            x = obj.block2feat( xb, @(b)(lMomentAlongDim( b, [1,2,3], 1, true )), ...
                2, @(idxs)(sort([idxs idxs idxs])),...
                {{'1.LMom',@(idxs)(idxs(1:3:end))},...
                 {'2.LMom',@(idxs)(idxs(2:3:end))},...
                 {'3.LMom',@(idxs)(idxs(3:3:end))}} );
            for ii = 1:obj.deltasLevels
                xb = obj.transformBlock( xb, 1, ...
                    @(b)(b(2:end,:) - b(1:end-1,:)), ...
                    @(idxs)(idxs(1:end-1)),...
                    {[num2str(ii) '.delta']} );
                xtmp = obj.block2feat( xb, ...
                    @(b)(lMomentAlongDim( b, [1,2,3,4], 1, true )), ...
                    2, @(idxs)(sort([idxs idxs idxs idxs])),...
                    {{'1.LMom',@(idxs)(idxs(1:4:end))},...
                     {'2.LMom',@(idxs)(idxs(2:4:end))},...
                     {'3.LMom',@(idxs)(idxs(3:4:end))},...
                     {'4.LMom',@(idxs)(idxs(4:4:end))}} );
                x = obj.concatFeats( x, xtmp );
            end
            modR = obj.makeBlockFromAfe( 1, 1, ...
                @(a)(compressAndScale( a.getSignalBlock(blLen), 0.33 )), ...
                {@(a)(a.Name),@(a)([num2str(numel(a.cfHz)) '-ch']),@(a)(a.Channel),['blLen ' num2str(blLen)]},...
                {'t'}, {@(a)(strcat('f', arrayfun(@(f)(num2str(f)),a.cfHz,'UniformOutput',false)))},...
                {@(a)(strcat('mf', arrayfun(@(f)(num2str(f)),a.modCfHz,'UniformOutput',false)))} );
            modL = obj.makeBlockFromAfe( 1, 2, ...
                @(a)(compressAndScale( a.getSignalBlock(blLen), 0.33 )), ...
                {@(a)(a.Name),@(a)([num2str(numel(a.cfHz)) '-ch']),@(a)(a.Channel),['blLen ' num2str(blLen)]},...
                {'t'}, {@(a)(strcat('f', arrayfun(@(f)(num2str(f)),a.cfHz,'UniformOutput',false)))},...
                {@(a)(strcat('mf', arrayfun(@(f)(num2str(f)),a.modCfHz,'UniformOutput',false)))} );
            mod = obj.combineBlocks( @(b1,b2)(0.5*b1+0.5*b2), 'LRmean', modR, modL );
            mod = obj.reshapeBlock( mod, 1 );
            x = obj.concatFeats( x, obj.block2feat( mod, ...
                @(b)(lMomentAlongDim( b, [1,2], 1, true )), ...
                2, @(idxs)(sort([idxs idxs])),...
                {{'1.LMom',@(idxs)(idxs(1:2:end))},...
                 {'2.LMom',@(idxs)(idxs(2:2:end))}} ) );
            for ii = 1:obj.deltasLevels
                mod = obj.transformBlock( mod, 1, ...
                    @(b)(b(2:end,:) - b(1:end-1,:)), ...
                    @(idxs)(idxs(1:end-1)),...
                    {[num2str(ii) '.delta']} );
                x = obj.concatFeats( x, obj.block2feat( mod, ...
                    @(b)(lMomentAlongDim( b, [1,2,3], 1, true )), ...
                    2, @(idxs)(sort([idxs idxs idxs])),...
                    {{'1.LMom',@(idxs)(idxs(1:3:end))},...
                     {'2.LMom',@(idxs)(idxs(2:3:end))},...
                     {'3.LMom',@(idxs)(idxs(3:3:end))}} ) );
            end
        end
        %% ----------------------------------------------------------------
        
        function outputDeps = getFeatureInternOutputDependencies( obj )
            outputDeps.freqChannels = obj.freqChannels;
            outputDeps.amFreqChannels = obj.amFreqChannels;
            outputDeps.freqChannelsStatistics = obj.freqChannelsStatistics;
            outputDeps.amChannels = obj.amChannels;
            outputDeps.deltasLevels = obj.deltasLevels;
            classInfo = metaclass( obj );
            [classname1, classname2] = strtok( classInfo.Name, '.' );
            if isempty( classname2 ), outputDeps.featureProc = classname1;
            else outputDeps.featureProc = classname2(2:end); end
            outputDeps.v = 5;
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
    end
    
end

