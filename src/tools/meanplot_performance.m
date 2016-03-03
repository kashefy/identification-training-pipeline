function meanplot_performance( figTitle, labels, nvPairs, varargin )

% figure('Name', figTitle,'defaulttextfontsize', 12, ...
%        'position', [0, 0, sqrt(numel( varargin )*40000), 600]);

grps = cell( size( varargin ) );
setlabels = isempty( labels );
for ii = 1 : numel( varargin )
    grps{ii} = ii * ones( size( varargin{ii} ) );
    if setlabels
        labels{ii} = inputname( ii + 3 );
    end
end
    
if isempty( nvPairs )
    nvPairs = {
         'notch', 'on', ...
         'whisker', inf, ...
         'widths', 0.8,...
         };
end

plot( cellfun(@mean,varargin), 'DisplayName', figTitle, 'LineWidth', 2 );

set( gca, 'XTick', 1:numel(labels), 'XTickLabel', labels );

ylabel( 'test performance' );
set( gca,'YGrid','on' );
% ylim( [(min([varargin{:}])-mod(min([varargin{:}]),0.10)) 1] );

saveTitle = figTitle;
savePng( saveTitle );
