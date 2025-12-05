function calcularGradas(app)
    x_min = 10;
    x_max = 280;

    % (Maximos y Mínimos)
    der1 = polyder(app.Coefs);
    posibles_picos = roots(der1);
    
    % Filtrar: raíces REALES
    picos_validos = posibles_picos(imag(posibles_picos) == 0 & ...
                                   posibles_picos >= x_min & ...
                                   posibles_picos <= x_max);
    
    % Dibuja las gradas
    hold(app.AxPista, 'on');
    
    for i = 1:length(picos_validos)
        x_c = picos_validos(i);
        y_c = polyval(app.Coefs, x_c);
        
        % Segunda derivada para determinar posicion de la grada
        der2 = polyder(der1);
        concavidad = polyval(der2, x_c);
        
        % settings de la grada
        distancia = 20; % Metros de separacion
        largo = 80;     % Largo de la grada
        ancho = 10;     % Profundidad de la grada
        
        % Si concavidad < 0 (Max) -> Curva dobla abajo -> Grada ABAJO
        % Si concavidad > 0 (Min)   -> Curva dobla arriba -> Grada ARRIBA
        if concavidad < 0
            y_base = y_c + distancia; 
            color_g = [0.8 0.3 0.3]; % Rojo suave (zona peligrosa)
        else
            y_base = y_c - distancia - ancho;
            color_g = [0.3 0.6 0.8]; % Azul suave
        end
        
        % Dibujar Rectángulo centrado en X
        rectangle('Parent', app.AxPista, ...
                  'Position', [x_c - (largo/2), y_base, largo, ancho], ...
                  'FaceColor', color_g, ...
                  'EdgeColor', 'w', ...
                  'LineWidth', 1.5);
              
        % Texto
        text(app.AxPista, x_c, y_base + ancho/2, 'GRADA', ...
             'HorizontalAlignment', 'center', ...
             'Color', 'w', 'FontWeight', 'bold', 'FontSize', 8);
             
        % Linea punteada de referencia (Distancia de seguridad)
        plot(app.AxPista, [x_c x_c], [y_c y_base + (concavidad<0)*0 + (concavidad>0)*ancho], ...
             'w:', 'LineWidth', 1);
    end
end