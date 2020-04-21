function [hp,rt] = polar_hist_plot(cax,lim,fac)
    
    
    if nargin<3
        fac = [1.05 1.15];
    end
    
    % get hold state
    cax = newplot(cax);
    
    next = lower(get(cax, 'NextPlot'));
    hold_state = ishold(cax);

    if isa(handle(cax),'matlab.graphics.axis.PolarAxes')
        error(message('MATLAB:polar:PolarAxes'));
    end
    
    % The grid color will be based on the axes background and grid color.
    axColor = cax.Color;
    if strcmp(axColor,'none')
        % If the axes is transparent, fall back to the parent container
        parent = cax.Parent;
        
        if isprop(parent,'BackgroundColor')
            % Panels and Tabs use BackgroundColor
            axColor = parent.BackgroundColor;
        else
            % Figures use Color
            axColor = parent.Color;
        end
        
        if strcmp(axColor,'none')
            % A figure/tab with Color none is black.
            axColor = [0 0 0];
        end
    end
    
    gridColor = cax.GridColor;
    gridAlpha = cax.GridAlpha;
    if strcmp(gridColor,'none')
        % Grid color is none, ignore transparency.
        tc = gridColor;
    else
        % Manually blend the color of the axes with the grid color to mimic
        % the effect of GridAlpha.
        tc = gridColor.*gridAlpha + axColor.*(1-gridAlpha);
    end
    ls = cax.GridLineStyle;
    
    % Hold on to current Text defaults, reset them to the
    % Axes' font attributes so tick marks use them.
    fAngle = get(cax, 'DefaultTextFontAngle');
    fName = get(cax, 'DefaultTextFontName');
    fSize = get(cax, 'DefaultTextFontSize');
    fWeight = get(cax, 'DefaultTextFontWeight');
    fUnits = get(cax, 'DefaultTextUnits');
    set(cax, ...
        'DefaultTextFontAngle', get(cax, 'FontAngle'), ...
        'DefaultTextFontName', get(cax, 'FontName'), ...
        'DefaultTextFontSize', get(cax, 'FontSize'), ...
        'DefaultTextFontWeight', get(cax, 'FontWeight'), ...
        'DefaultTextUnits', 'data');
    
    % only do grids if hold is off
    if ~hold_state
        
        % make a radial grid
        hold(cax, 'on');
        % ensure that Inf values don't enter into the limit calculation.
        maxrho = lim;
        hhh = line([0, 0, maxrho, maxrho], [0, maxrho, maxrho, 0], 'Parent', cax);
        set(cax, 'DataAspectRatio', [1, 1, 1], 'PlotBoxAspectRatioMode', 'auto');
        v = [get(cax, 'XLim') get(cax, 'YLim')];
        ticks = sum(get(cax, 'YTick') >= 0);
        delete(hhh);
        % check radial limits and ticks
        rmin = 0;
        rmax = v(4);
        rticks = max(ticks - 1, 2);
        if rticks > 5   % see if we can reduce the number
            if rem(rticks, 2) == 0
                rticks = rticks / 2;
            elseif rem(rticks, 3) == 0
                rticks = rticks / 3;
            end
        end
        rinc = (rmax - rmin) / rticks;
        ticks = (rmin + rinc) : rinc : rmax;
        
        % define a circle
        th = linspace(0,pi/2,90);
        xunit = cos(th);
        yunit = sin(th);
        % now really force points on x/y axes to lie on them exactly
        xunit([1 end]) = [1 0];
        yunit([1 end]) = [0 1];
        % plot background if necessary
        if ~ischar(get(cax, 'Color'))
            patch('XData', [0 xunit * rmax 0], 'YData', [0 yunit * rmax 0], ...
                'EdgeColor', tc, 'FaceColor', get(cax, 'Color'), ...
                'HandleVisibility', 'off', 'Parent', cax);
        end
        % plot background for circular histogram
        patch('XData', [xunit*rmax*fac(2) fliplr(xunit*rmax*fac(1))], 'YData', [yunit*rmax*fac(2) fliplr(yunit*rmax*fac(1))], ...
                'EdgeColor', tc, 'FaceColor', get(cax, 'Color'), ...
                'HandleVisibility', 'off', 'Parent', cax);
        
        % draw radial circles
        for i = ticks
            hhh = line(xunit * i, yunit * i, 'LineStyle', ls, 'Color', tc, 'LineWidth', 1, ...
                'HandleVisibility', 'off', 'Parent', cax);
        end
        set(hhh, 'LineStyle', '-'); % Make outer circle solid
        
        cax.XTick = [0 ticks];
        cax.YTick = [0 ticks];
        cax.Color = 'none';
        cax.Layer = 'top';
        cax.TickLength = [0 0];
        % remove axis lines and plot new ones
        cax.XRuler.Axle.Visible = 'off';
        cax.YRuler.Axle.Visible = 'off';
        hp(2) = plot([0 rmax],[0 0],'k-');
        hp(1) = plot([0 0],[0 rmax],'k-');
        % set format of axis labels, and use latex interpreter for uniform
        % look
        if rmax<=.3
            fmt = '%.2f';
        else
            fmt = '%.1f';
        end
        cax.XRuler.TickLabelFormat = fmt;
        cax.XRuler.TickLabelInterpreter = 'latex';
        cax.YRuler.TickLabelFormat = fmt;
        cax.YRuler.TickLabelInterpreter = 'latex';
        
        % plot spokes
        % tangent = [tan(linspace(0,atan(sqrt(2)),5)) 2];   % to roughly
        % figure out where ref lines should be
        tangent = [0 .25 .5 .9 sqrt(2) 2];
        th = atan(tangent);
        cst = cos(th);
        snt = sin(th);
        cs = [zeros(size(cst(2:end))); cst(2:end)]; % don't draw line at 0 as that overlaps the x axis
        sn = [zeros(size(snt(2:end))); snt(2:end)];
        line(rmax * cs, rmax * sn, 'LineStyle', ls, 'Color', tc, 'LineWidth', 1, ...
            'HandleVisibility', 'off', 'Parent', cax);
        
        cs = [cst*rmax*fac(1); cst*rmax*fac(2)];
        sn = [snt*rmax*fac(1); snt*rmax*fac(2)];
        line(cs, sn, 'LineStyle', ls, 'Color', tc, 'LineWidth', 1, ...
            'HandleVisibility', 'off', 'Parent', cax);
        
        % annotate spokes in degrees
        rt = 1.05 * rmax * fac(2);
        for i = 1 : length(tangent)
            if tangent(i)==sqrt(2)
                lbl = '$\sqrt{2}$';
            else
                lbl = sprintf('%.2f',tangent(i));
            end
            text(rt * cst(i), rt * snt(i), lbl,...
                'HorizontalAlignment', 'center', ...
                'HandleVisibility', 'off', 'Parent', cax, ...
                'Interpreter','latex');
        end
        
        % set view to 2-D
        view(cax, 2);
        % set axis limits
        axis(cax, rmax * [0, fac(2), 0, fac(2)]);
    end
    
    % Reset defaults.
    set(cax, ...
        'DefaultTextFontAngle', fAngle , ...
        'DefaultTextFontName', fName , ...
        'DefaultTextFontSize', fSize, ...
        'DefaultTextFontWeight', fWeight, ...
        'DefaultTextUnits', fUnits );
    
    
    set(get(cax, 'XLabel'), 'Visible', 'on');
    set(get(cax, 'YLabel'), 'Visible', 'on');
    
    % Disable pan and zoom
    p = hggetbehavior(cax, 'Pan');
    p.Enable = false;
    z = hggetbehavior(cax, 'Zoom');
    z.Enable = false;
end
