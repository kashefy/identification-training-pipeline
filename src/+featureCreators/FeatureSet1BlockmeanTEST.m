classdef FeatureSet1BlockmeanTEST < featureCreators.Base
% uses magnitude ratemap with cubic compression and scaling to a max value
% of one. Reduces each freq channel to its mean and std + mean and std of
% finite differences.

    %% --------------------------------------------------------------------
    properties (SetAccess = private)
        freqChannels;
        freqChannelsStatistics;
        amFreqChannels;
        deltasLevels;
        amChannels;
        afeData;
        descriptionBuilt = false;
    end
    
    %% --------------------------------------------------------------------
    methods (Static)
    end
    
    %% --------------------------------------------------------------------
    methods (Access = public)
        
        function obj = FeatureSet1BlockmeanTEST( )
            obj = obj@featureCreators.Base( 0.5, 0.5/3, 0.75, 0.5 );
            obj.freqChannels = 16;
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
                'fb_nChannels', obj.freqChannels ...
                );
        end
        %% ----------------------------------------------------------------

        function x = makeDataPoint( obj, afeData )
            obj.afeData = afeData;
            x = obj.constructVector();
            obj.descriptionBuilt = true;
        end
        %% ----------------------------------------------------------------

        function b = makeBlockFromAfe( obj, afeIdx, chIdx, func, grps, varargin )
            afedat = obj.afeData(afeIdx);
            afedat = afedat{chIdx};
            b{1} = func( afedat );
            if obj.descriptionBuilt, return; end
            b2 = {};
            for ii = 1 : length( grps )
                if isa( grps{ii}, 'function_handle' )
                    fg = grps{ii};
                    b2{end+1} = fg( afedat );
                elseif ischar( grps{ii} )
                    b2{end+1} = grps{ii};
                end
            end
%             b{2} = repmat( {b2}, size( b{1} ) );
            for ii = 1 : length( varargin )
                vaii = varargin{ii};
                for jj = 1 : numel( vaii )
                    if isa( vaii{jj}, 'function_handle' )
                        fd = vaii{jj};
                        vaii{jj} = fd( afedat );
                    end
                    if isnumeric( vaii{jj} )
                        vaii{jj} = num2cell( vaii{jj}, numel( vaii{jj} ) );
                    end
                end
                vaii{1} = repmat( vaii(1), 1, size( b{1}, ii ) );
                if numel( vaii ) > 1 && numel( vaii{2} ) ~= size( b{1}, ii )
                    warning( 'dimensions not consistent' );
                end
                vaiic = cat( 1, vaii{:} );
                for jj = 1 : size( vaii{1}, 2 )
                    b1ii{1,jj} = { b2{:}, vaiic{:,jj}};
                end
                b{1+ii} = b1ii;
                clear b1ii;
            end
        end
        %% ----------------------------------------------------------------

        function b = concatBlocks( obj, dim, varargin )
            bs = vertcat( varargin{:} );
            b{1} = cat( dim, bs{:,1} );
            if obj.descriptionBuilt, return; end
%             b{2} = cat( dim, bs{:,2} );
            d = 1 : size( bs, 2 ) - 1;
            d(dim) = [];
            for ii = d
                bs1d = cat( 1, bs{:,1+d} );
                for jj = 1 : size( bs1d, 2 )
                    b1d{1,jj} = cat( 2, bs1d{:,jj} );
                end
                b{1+d} = b1d;
                clear b1d;
                strs = {};
                nums = {};
                dels = {};
                for jj = 1 : size( b{1+d}, 2 )
                for kk = 1 : size( b{1+d}{jj}, 2 )
                    if ischar( b{1+d}{jj}{kk} )
                        if ~any( strcmp( strs, b{1+d}{jj}{kk} ) )
                            strs{end+1} = b{1+d}{jj}{kk};
                        else
                            dels{end+1} = [jj,kk];
                        end
                    else
                        if ~any( cellfun( @(n)(eq(n,b{1+d}{jj}{kk})), nums ) )
                            nums{end+1} = b{1+d}{jj}{kk};
                        else
                            dels{end+1} = [jj,kk];
                        end
                    end
                end
                end
                for jj = 1 : numel( dels )
                    b{1+d}{dels{jj}(1)}(dels{jj}(2)) = [];
                end
                clear dels;
                clear strs;
                clear nums;
                
            end
            b{2+dim} = cat( dim, bs{:,2+dim} );
        end
        %% ----------------------------------------------------------------

        function b = transformBlock( obj, bl, dim, func, grp )
        end
        %% ----------------------------------------------------------------

        function b = reshapeBlock( obj, bl, varargin )
        end
        %% ----------------------------------------------------------------

        function x = block2feat( obj, b, dim, func, grps )
            x = func( b{1} );
            if obj.descriptionBuilt, return; end
            
        end
        %% ----------------------------------------------------------------

        function b = concatFeats( obj, varargin )
            if obj.descriptionBuilt, return; end
        end
        %% ----------------------------------------------------------------
        
        function x = constructVector( obj )
            rmR = obj.makeBlockFromAfe( 2, 1, ...
                @(a)(compressAndScale( a.Data, 0.33, @(x)(median( x(x>0.01) )), 0 )), ...
                {@(a)(a.Name),@(a)(a.Channel)}, {'t'}, {'f',@(a)(a.cfHz)} );
            rmL = obj.makeBlockFromAfe( 2, 2, ...
                @(a)(compressAndScale( a.Data, 0.33, @(x)(median( x(x>0.01) )), 0 )), ...
                {@(a)(a.Name),@(a)(a.Channel)}, {'t'}, {'f',@(a)(a.cfHz)} );
            spfR = obj.makeBlockFromAfe( 3, 1, ...
                @(a)(compressAndScale( a.Data, 0.33 )), ...
                {@(a)(a.Name),@(a)(a.Channel)}, {'t'}, {'type',@(a)(a.fList)} );
            spfL = obj.makeBlockFromAfe( 3, 2, ...
                @(a)(compressAndScale( a.Data, 0.33 )), ...
                {@(a)(a.Name),@(a)(a.Channel)}, {'t'}, {'type',@(a)(a.fList)} );
            onsR = obj.makeBlockFromAfe( 4, 1, ...
                @(a)(compressAndScale( a.Data, 0.33 )), ...
                {@(a)(a.Name),@(a)(a.Channel)}, {'t'}, {'f',@(a)(a.cfHz)} );
            onsL = obj.makeBlockFromAfe( 4, 2, ...
                @(a)(compressAndScale( a.Data, 0.33 )), ...
                {@(a)(a.Name),@(a)(a.Channel)}, {'t'}, {'f',@(a)(a.cfHz)} );
            xb = obj.concatBlocks( 2, rmR, rmL, spfR, spfL, onsR, onsL );
            x = obj.block2feat( xb, 1, ...
                @(b)(lMomentAlongDim( b, [1,2,3], 1, true )), ...
                {'1.LMom','2.LMom','3.LMom'} );
            for ii = 1:obj.deltasLevels
                xb = obj.transformBlock( xb, 1, ...
                    @(b)(b(2:end,:) - b(1:end-1,:)), ...
                    {[num2str(ii) '.delta']} );
                xtmp = obj.block2feat( xb, 1, ...
                    @(b)(lMomentAlongDim( b, [1,2,3,4], 1, true )), ...
                    {'1.LMom','2.LMom','3.LMom','4.LMom'} );
                x = obj.concatFeats( x, xtmp );
            end
            modR = obj.makeBlockFromAfe( 1, 1, ...
                @(a)(compressAndScale( a.Data, 0.33 )), ...
                {@(a)(a.Name),@(a)(a.Channel)}, ...
                {'t'}, {'f',@(a)(a.cfHz)}, {'mf',@(a)(a.modCfHz)} );
            modL = obj.makeBlockFromAfe( 1, 2, ...
                @(a)(compressAndScale( a.Data, 0.33 )), ...
                {@(a)(a.Name),@(a)(a.Channel)}, ...
                {'t'}, {'f',@(a)(a.cfHz)}, {'mf',@(a)(a.modCfHz)} );
            modR = obj.reshapeBlock( modR, size( modR, 1 ), [] );
            modL = obj.reshapeBlock( modL, size( modL, 1 ), [] );
%            modR = reshape( modR, size( modR, 1 ), size( modR, 2 ) * size( modR, 3 ) );
%            modL = reshape( modL, size( modL, 1 ), size( modL, 2 ) * size( modL, 3 ) );
            x = obj.concatFeats( x, obj.block2feat( modR, 1, ...
                @(b)(lMomentAlongDim( b, [1,2], 1, true )), ...
                {'1.LMom','2.LMom'} ) );
            x = obj.concatFeats( x, obj.block2feat( modL, 1, ...
                @(b)(lMomentAlongDim( b, [1,2], 1, true )), ...
                {'1.LMom','2.LMom'} ) );
            for ii = 1:obj.deltasLevels
                modR = obj.transformBlock( modR, 1, ...
                    @(b)(b(2:end,:) - b(1:end-1,:)), ...
                    {[num2str(ii) '.delta']} );
                modL = obj.transformBlock( modL, 1, ...
                    @(b)(b(2:end,:) - b(1:end-1,:)), ...
                    {[num2str(ii) '.delta']} );
                x = obj.concatFeats( x, obj.block2feat( modR, 1, ...
                    @(b)(lMomentAlongDim( b, [1,2,3], 1, true )), ...
                    {'1.LMom','2.LMom','3.LMom'} ) );
                x = obj.concatFeats( x, obj.block2feat( modL, 1, ...
                    @(b)(lMomentAlongDim( b, [1,2,3], 1, true )), ...
                    {'1.LMom','2.LMom','3.LMom'} ) );
            end
        end
        %% ----------------------------------------------------------------

%         function x = makeDataPoint( obj, afeData )
%             rmRL = afeData(2);
%             rmR = compressAndScale( rmRL{1}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
%             rmL = compressAndScale( rmRL{2}.Data, 0.33, @(x)(median( x(x>0.01) )), 0 );
%             spfRL = afeData(3);
%             spfR = compressAndScale( spfRL{1}.Data, 0.33 );
%             spfL = compressAndScale( spfRL{2}.Data, 0.33 );
%             onsRL = afeData(4);
%             onsR = compressAndScale( onsRL{1}.Data, 0.33 );
%             onsL = compressAndScale( onsRL{2}.Data, 0.33 );
%             xBlock = [rmR, rmL, spfR, spfL, onsR, onsL];
%             x = lMomentAlongDim( xBlock, [1,2,3], 1, true );
%             for i = 1:obj.deltasLevels
%                 xBlock = xBlock(2:end,:) - xBlock(1:end-1,:);
%                 x = [x  lMomentAlongDim( xBlock, [1,2,3,4], 1, true )];
%             end
%             modRL = afeData(1);
%             modR = compressAndScale( modRL{1}.Data, 0.33 );
%             modL = compressAndScale( modRL{2}.Data, 0.33 );
%             modR = reshape( modR, size( modR, 1 ), size( modR, 2 ) * size( modR, 3 ) );
%             modL = reshape( modL, size( modL, 1 ), size( modL, 2 ) * size( modL, 3 ) );
%             x = [x lMomentAlongDim( modR, [1,2], 1, true )];
%             x = [x lMomentAlongDim( modL, [1,2], 1, true )];
%             for i = 1:obj.deltasLevels
%                 modR = modR(2:end,:) - modR(1:end-1,:);
%                 modL = modL(2:end,:) - modL(1:end-1,:);
%                 x = [x lMomentAlongDim( modR, [1,2,3], 1, true )];
%                 x = [x lMomentAlongDim( modL, [1,2,3], 1, true )];
%             end
%         end
%         %% ----------------------------------------------------------------
        
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
            outputDeps.v = 1;
        end
        %% ----------------------------------------------------------------
        
    end
    
    %% --------------------------------------------------------------------
    methods (Access = protected)
    end
    
end

