function h=overlay_pr_curve(name, score, x, y, e, ideal, random, percent_l, pos, old_h)
%h=plot_pr_curve(name, score, x, y, e, old_h)
% Plot the learning curve 
% Inputs:
% x -- Number of samples
% y -- Performance
% e -- Error bar
% name -- experiment name
% Returns:
% h --      The plot handle

% Author: Isabelle Guyon -- November 2010 -- isabelle@clopinet.com

style_list = {'-r','-.b','-k','-.m','-b','-.k','-m','-.r'};

if nargin<7, e=[]; end
if nargin<10 || isempty(old_h);
    h=figure;
else
    h=figure(old_h); 
end
hold on

%rand_predict=0.5;

%x=log2(x);
last_point=x(end);
final_score=y(end);

% Show the area under the curve
%patch([x last_point 0 0], [y rand_predict rand_predict y(1)], [1 0.9 0.6]);
%patch([x last_point 0 0], [y 0 0 y(1)], [1 0.9 0.6]);

% Plot the curve with error bars
errorbar(x, y, e, style_list{pos}, 'LineWidth', 2);

plot(x, y, style_list{pos}, 'MarkerSize', 6);
if (pos == length(percent_l))
    if (ideal)
        plot([0 0.5 1], [1 1 0.5], ...
            'Color', [0.9100 0.4100 0.1700], ...
            'LineStyle', '-', ...
            'LineWidth', 2, ...
            'MarkerSize', 6);
        percent_l = [percent_l 'Ideal'];
    end
    if (random)
        plot([0 1], [1 0.5], ...
            'Color',[0.9100 0.4100 0.1700], ...
            'LineStyle', '-.', ...
            'LineWidth', 2, ...
            'MarkerSize', 6);
        percent_l = [percent_l 'Random'];
    end
    line_data = findobj(h,'Type','line');
    line_data = fliplr(line_data')';
    legend(line_data, percent_l,'FontSize',16,'Location', 'southwest');
    
    plot([0 1], [1 1], '-b');
    plot([1 1], [1 0], '-b');
end
    
%plot([0 last_point], [1 1]);
%plot([last_point last_point], [rand_predict 1]);
%plot([0 last_point], [rand_predict rand_predict]);
%plot([0 0], [rand_predict 1]);
%plot([0 last_point], [rand_predict 1], '-.');
%plot([last_point last_point+1], [final_score final_score], 'k--');
%name(name=='_')=' ';
%tt=[upper(name) ': AUPR=' num2str(score, '%5.4f')]; 
%title(tt);
%text(last_point+1, final_score, num2str(final_score, '-%5.4f\n'));
%text(last_point+0.15, final_score, num2str(final_score, '\t%5.4f\n'));
xlabel('Recall');
ylabel('Precision');
set(gca,'fontsize',16);
xl=xlim; yl=ylim;
xlim([0 last_point]);
ylim([0.5 1]);