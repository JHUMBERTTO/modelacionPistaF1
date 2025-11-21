function puntos_riesgo = analizarZonasCriticas(R, x_track, coefs)
    % INPUTS:
    %   R: Vector de radios de curvatura
    %   x_track: Vector de posiciones x (tu x_track)
    %   coefs: Los coeficientes del polinomio (para calcular Y exacto)
    % OUTPUT:
    %   puntos_riesgo: Matriz donde cada fila es [x_derrape, y_derrape, R_min]

    puntos_riesgo = []; % Inicializamos vacío por si no hay peligros
    
    % Filtramos la zonas criticas donde complete la condicion de (10 < R < 100)
    indices_criticos = find(R > 10 & R < 100);
    % disp(indices_criticos);

    % Puede dar el caso que no tengamos indices_criticos por que la pista
    % es muy perfecta.
    if isempty(indices_criticos)
        disp("No hay zonas críticas en esta pista.");
        return; 
    end

    % Queremos saber donde se rompe la cadena de numeros consecutivos.
    saltos = find(diff(indices_criticos) > 1);

    % definimos inicios y finales.
    inicios = indices_criticos([1, saltos + 1]);

    % 'saltos' son donde se rompió la cadena. 'end' es el último dato.
    finales = indices_criticos([saltos, end]);
    
    fprintf('\n--- REPORTE DE ZONAS CRÍTICAS Y DERRAPE ---\n');
    
    % este bucle itera por cada indice critico de los rangos que
    % se determinaron con inicio y final, y nos devuelve las coordenadas
    % de derrape si el radio es menor y es mas peligroso por que la fuerza
    % centripeta es maxima.
    for k = 1:length(inicios)
        idx_start = inicios(k);
        idx_end = finales(k);
        
        % Datos del intervalo
        x_start = x_track(idx_start);
        x_end = x_track(idx_end);
        
        % Encontrar el punto EXACTO de derrape (mínimo radio local)
        vec_radios_zona = R(idx_start:idx_end);
        [r_min, idx_local] = min(vec_radios_zona);
        
        % Convertir a indice global y coordenadas
        idx_global = idx_start + idx_local - 1;
        x_derrape = x_track(idx_global);
        y_derrape = polyval(coefs, x_derrape);
        
        % Imprimir reporte (Cumple Puntos 8 y 9)
        fprintf('ZONA %d | Intervalo: [%.1f m - %.1f m]\n', k, x_start, x_end);
        fprintf('   >> PUNTO DERRAPE: Coordenada (%.2f, %.2f)\n', x_derrape, y_derrape);
        fprintf('   >> Radio Mínimo: %.2f m\n', r_min);
        fprintf('------------------------------------------------\n');
        
        % Guardar en la matriz de salida
        puntos_riesgo = [puntos_riesgo; x_derrape, y_derrape, r_min];
    end
end