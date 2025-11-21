function generarPlanosFinales(coefs, x_track, puntos_riesgo, x_min_zona1, x_max_zona1, x_min_zona2, x_max_zona2)
    % Crear figura grande
    figure('Name', 'Plano de Ingeniería de Pista F1', 'Color', 'k', 'Position', [100 100 1200 800]);
    
    % --- PANEL 1: VISTA GENERAL ---
    subplot(2, 2, [1 2]); 
    hold on; grid on; axis equal; % <--- ESTO ES CLAVE PARA LA PROPORCIÓN
    title('Plano General: Trazo, Puntos Críticos y Gradas');
    xlabel('Distancia x (m)'); ylabel('Distancia y (m)');
    
    y_track = polyval(coefs, x_track);
    plot(x_track, y_track, 'b-', 'LineWidth', 2);
    
    % Dibujar zonas
    dibujarElementosZona(coefs, x_min_zona1, x_max_zona1, 'Zona 1');
    dibujarElementosZona(coefs, x_min_zona2, x_max_zona2, 'Zona 2');

    if ~isempty(puntos_riesgo)
        plot(puntos_riesgo(:,1), puntos_riesgo(:,2), 'rh', 'MarkerSize', 12, 'MarkerFaceColor', 'r');
    end
    hold off;

    % --- PANEL 2: ZOOM ZONA 1 ---
    subplot(2, 2, 3);
    hold on; grid on; axis equal; % <--- CORRECCIÓN DE ESCALA
    title('Ampliación: Zona Crítica 1');
    plot(x_track, y_track, 'b-', 'LineWidth', 1.5);
    dibujarElementosZona(coefs, x_min_zona1, x_max_zona1, '');
    
    % Dibujar punto de derrape específico de esta zona
    % (Buscamos el punto que cae dentro de este rango x)
    idx_p1 = find(puntos_riesgo(:,1) >= x_min_zona1 & puntos_riesgo(:,1) <= x_max_zona1);
    if ~isempty(idx_p1)
        plot(puntos_riesgo(idx_p1,1), puntos_riesgo(idx_p1,2), 'rh', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    end
    
    xlim([x_min_zona1 - 20, x_max_zona1 + 20]);
    % Ajuste automático de Y para que se vea bien con axis equal
    y_local = y_track(x_track >= x_min_zona1 & x_track <= x_max_zona1);
    ylim([min(y_local) - 30, max(y_local) + 30]);

    % --- PANEL 3: ZOOM ZONA 2 ---
    subplot(2, 2, 4);
    hold on; grid on; axis equal; % <--- CORRECCIÓN DE ESCALA
    title('Ampliación: Zona Crítica 2');
    plot(x_track, y_track, 'b-', 'LineWidth', 1.5);
    dibujarElementosZona(coefs, x_min_zona2, x_max_zona2, '');
    
    idx_p2 = find(puntos_riesgo(:,1) >= x_min_zona2 & puntos_riesgo(:,1) <= x_max_zona2);
    if ~isempty(idx_p2)
        plot(puntos_riesgo(idx_p2,1), puntos_riesgo(idx_p2,2), 'rh', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    end
    
    xlim([x_min_zona2 - 20, x_max_zona2 + 20]);
    y_local2 = y_track(x_track >= x_min_zona2 & x_track <= x_max_zona2);
    ylim([min(y_local2) - 30, max(y_local2) + 30]);
end

% --- FUNCIÓN AUXILIAR INTELIGENTE ---
function dibujarElementosZona(coefs, x_start, x_end, etiqueta)
    distancia_seguridad = 20;
    x_centro = (x_start + x_end) / 2;
    
    % Determinar si la grada va "arriba" o "abajo" usando la Segunda Derivada
    % Si d2 < 0 (concava abajo / montaña) -> Fuerza centrifuga va afuera (ARRIBA)
    % Si d2 > 0 (concava arriba / valle)  -> Fuerza centrifuga va afuera (ABAJO/DERECHA)
    d2_coefs = polyder(polyder(coefs));
    concavidad = polyval(d2_coefs, x_centro);
    
    % Factor de dirección: 1 normal, -1 invertido
    if concavidad < 0
        dir_factor = 1;  % Grada a la izquierda/arriba del vector
    else
        dir_factor = -1; % Grada a la derecha/abajo del vector
    end
    
    % Puntos de la grada (80m de largo)
    x_vec = [x_centro - 40, x_centro + 40];
    y_pista = polyval(coefs, x_vec);
    dydx = polyval(polyder(coefs), x_vec);
    theta = atan(dydx);
    
    % Aplicamos el factor de dirección
    x_grada = x_vec - (distancia_seguridad * dir_factor) * sin(theta);
    y_grada = y_pista + (distancia_seguridad * dir_factor) * cos(theta);
    
    % DIBUJAR
    line(x_grada, y_grada, 'Color', 'c', 'LineWidth', 8); 
    line(x_grada, y_grada, 'Color', 'b', 'LineWidth', 1, 'LineStyle', '--');
    
    if ~isempty(etiqueta)
        text(x_grada(1), y_grada(1), etiqueta, 'FontWeight', 'bold', 'BackgroundColor', 'k');
    end
    
    % TANGENTE
    m = polyval(polyder(coefs), x_centro);
    y_c = polyval(coefs, x_centro);
    b = y_c - m*x_centro;
    x_tan = [x_centro-15, x_centro+15];
    y_tan = m*x_tan + b;
    plot(x_tan, y_tan, 'g--', 'LineWidth', 1.5);
end