function modelacion_pista()
    clc; close all;
    
    % ==========================================
    % INPUT DE USUARIO
    % ==========================================
    prompt = {'Ingrese la velocidad del auto (km/h):'};
    dlgtitle = 'F1 Telemetry Setup';
    dims = [1 50];
    definput = {'30'};
    ans_user = inputdlg(prompt, dlgtitle, dims, definput);
    if isempty(ans_user), return; end
    vel_auto_kmh = str2double(ans_user{1});
    if isnan(vel_auto_kmh) || vel_auto_kmh < 0, return; end
    vel_auto_ms = vel_auto_kmh / 3.6; 

    % ==========================================
    % DATOS FÍSICOS
    % ==========================================
    points = [10 290; 110 250; 140 200; 280 120];
    xi = 10; xf = 280;
    
    m_auto = 798;       % Masa F1 (kg)
    % m_auto2 = 800;      % Masa Obstáculo
    g = 9.81; 
    mu_s = 0.8; mu_k = 0.6; theta = deg2rad(3); 
    % dt_impacto = 0.1;

    [a,b,c,d] = calcularIncognitas(points);
    coefs = [a b c d];
    
    x_track = xi:0.5:xf;
    y_track = polyval(coefs, x_track);
    der1 = polyder(coefs);
    dy_track = polyval(der1, x_track); 
    R = calcularRadioCurvatura(coefs, x_track); 
    
    % Zonas Críticas y Vel Max
    idx_zona_amarilla = R < 50; 
    num = sin(theta) + mu_s * cos(theta);
    den = cos(theta) - mu_s * sin(theta);
    V_max_array = sqrt(abs(R) .* g .* (num / den)); 

    % ==========================================
    % PREPARACIÓN GRÁFICA
    % ==========================================
    fig = figure('Name', 'F1 Telemetry System', 'Color', 'w', 'Position', [50 50 1200 800]);
    hold on; grid on; axis equal;
    
    % Ejes y Fondo
    set(gca, 'Color', 'w', 'XColor', 'k', 'YColor', 'k');
    title(['Modelacion de la particula en la pista: ' num2str(vel_auto_kmh) ' km/h'], 'Color', 'k');
    xlabel('Distancia X [m]'); ylabel('Distancia Y [m]');
    
    % Dibujar Pista
    plot(x_track, y_track, 'Color', [0.4 0.4 0.4], 'LineWidth', 8, 'DisplayName', 'Pista'); 
    plot(x_track, y_track, 'w--', 'LineWidth', 1, 'HandleVisibility', 'off');
    
    if any(idx_zona_amarilla)
        plot(x_track(idx_zona_amarilla), y_track(idx_zona_amarilla), ...
             '.', 'Color', [1 0.8 0], 'MarkerSize', 15, 'DisplayName', 'Zona Riesgo');
    end
    
    colocarGradaManual(22, coefs, -25, 'Grada A');
    colocarGradaManual(222, coefs, 25, 'Grada B');
    
    legend('show', 'Location', 'northeast');

    % ==========================================
    % TABLERO DE TELEMETRÍA (HUD)
    % ==========================================
    % Creamos una caja de texto vacía en la esquina superior izquierda
    hud_box = text(xi, 290, '', ...
        'FontName', 'Consolas', 'FontSize', 10, ...
        'BackgroundColor', [0 0 0 0.8], ... 
        'Color', 'w', ...                   
        'EdgeColor', 'k', 'Margin', 5);

    % Objetos Móviles
    auto_dot = plot(x_track(1), y_track(1), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'HandleVisibility', 'off');
    estela = plot(x_track(1), y_track(1), 'r-', 'LineWidth', 1, 'HandleVisibility', 'off');
    
    se_derrapo = false;
    idx_fallo = 0;
    
    % ==========================================
    % ANIMACIÓN FÍSICA
    % ==========================================
    for i = 1:length(x_track)
        if ~isvalid(fig), break; end 
        
        % --- CÁLCULOS EN TIEMPO REAL ---
        radio_actual = abs(R(i));
        limite_v = V_max_array(i);
        vel_actual_kmh = vel_auto_ms * 3.6;
        
        % Energía Cinética: K = 1/2 * m * v^2
        E_cinetica = 0.5 * m_auto * vel_auto_ms^2;
        

        % --- ACTUALIZAR HUD (TEXTO) ---
        mensaje = sprintf([ ...
            'Velocidad:  %6.1f km/h\n' ...
            'Límite Max: %6.1f km/h\n' ...
            'Radio Curva:%6.1f m\n' ...
            'Energía K:  %6.1f kJ'], ...
            vel_actual_kmh, limite_v*3.6, radio_actual, E_cinetica/1000);
            
        set(hud_box, 'String', mensaje, 'Position', [x_track(i)+10, y_track(i)+20, 0]); % El texto sigue al auto
        
        % --- LÓGICA DE DERRAPE ---
        if (vel_auto_ms > limite_v) && (radio_actual < 1000)
            se_derrapo = true; idx_fallo = i;
            plot(x_track(i), y_track(i), 'kx', 'MarkerSize', 15, 'LineWidth', 3);
            break; 
        end
        
        set(auto_dot, 'XData', x_track(i), 'YData', y_track(i));
        set(estela, 'XData', x_track(1:i), 'YData', y_track(1:i));
        drawnow; pause(0.01); 
    end
    
    % ==========================================
    % 6. FÍSICA POST-DERRAPE (Colisión)
    % ==========================================
    if se_derrapo
        m_tan = dy_track(idx_fallo);
        theta_v = atan(m_tan);
        
        % Barrera
        x_skid = x_track(idx_fallo); y_skid = y_track(idx_fallo);
        dist_barrera = 40;
        xb = x_skid + dist_barrera * cos(theta_v);
        yb = y_skid + dist_barrera * sin(theta_v);
        line([xb-2, xb+2], [yb+5, yb-5], 'Color', 'k', 'LineWidth', 5, "DisplayName", "Barrera");
        
        % Animación Derrape
        x_trace = x_skid; y_trace = y_skid;
        ruta_derrape = plot(x_skid, y_skid, 'Color', [1 0.5 0], 'LineWidth', 2, 'LineStyle', '--', "DisplayName","Trayectoria Tangencial");
        
        vel_actual = vel_auto_ms;
        dist_recorrida = 0;
        dt = 0.05;
        
        while dist_recorrida < dist_barrera && vel_actual > 0
             if ~isvalid(fig), break; end
             
             % Fisica: Disipación de Energía
             vel_actual = vel_actual - (mu_k * g * dt);
             if vel_actual < 0, vel_actual = 0; end
             
             % Energia actual bajando
             E_cinetica = 0.5 * m_auto * vel_actual^2;
             
             % Mover
             dx = vel_actual * cos(theta_v) * dt;
             dy = vel_actual * sin(theta_v) * dt;
             x_skid = x_skid + dx; y_skid = y_skid + dy;
             dist_recorrida = dist_recorrida + sqrt(dx^2 + dy^2);
             
             % Actualizar HUD con caida de energia
             mensaje = sprintf([ ...
                '--- Impacto ---\n' ...
                'Velocidad:  %6.1f km/h\n' ...
                'Energía K:  %6.1f kJ\n' ...
                'Estado:     Derrapado'], ...
                vel_actual*3.6, E_cinetica/1000);
             set(hud_box, 'String', mensaje, 'Color', 'r', 'Position', [x_skid+10, y_skid+10, 0]);
             
             set(auto_dot, 'XData', x_skid, 'YData', y_skid);
             x_trace = [x_trace, x_skid]; y_trace = [y_trace, y_skid];
             set(ruta_derrape, 'XData', x_trace, 'YData', y_trace);
             drawnow; pause(0.01);
        end
        
    end
    hold off;
end

% FUNCIONES AUXILIARES (Dejar igual que antes)
function [a,b,c,d] = calcularIncognitas(p)
    X = [p(:,1).^3, p(:,1).^2, p(:,1), ones(4,1)];
    Y = p(:,2);
    C = X\Y; a=C(1); b=C(2); c=C(3); d=C(4);
end
function R = calcularRadioCurvatura(coefs, x)
    der1 = polyder(coefs); der2 = polyder(der1);
    dy = polyval(der1, x); ddy = polyval(der2, x);
    R = ((1 + dy.^2).^(1.5)) ./ abs(ddy);
end
function colocarGradaManual(x, c, o, t)
    y = polyval(c, x); d = polyval(polyder(c), x); th = atan(d);
    xg = x + o*sin(th); yg = y - o*cos(th);
    ancho = 60; prof = 10;
    Xr = [-ancho/2, ancho/2, ancho/2, -ancho/2]; Yr = [-prof/2, -prof/2, prof/2, prof/2];
    Xrot = Xr*cos(th)-Yr*sin(th)+xg; Yrot = Xr*sin(th)+Yr*cos(th)+yg;
    patch(Xrot, Yrot, [0 0.8 0], 'FaceAlpha', 1, 'EdgeColor', 'k', 'DisplayName', t);
    text(xg, yg, t, 'HorizontalAlignment', 'center', 'Color', 'k', 'FontSize', 8);
end