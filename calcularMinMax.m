function [puntosMin, puntosMax] = calcularMinMax(coeficientes)
    % Check de errores
    if length(coeficientes) ~= 4
        error('La función requiere un vector de 4 coeficientes [a, b, c, d].');
    end
    
    a = coeficientes(1);
    b = coeficientes(2);
    c = coeficientes(3);
    d = coeficientes(4);
    
    coeficientes_derivada = [3*a, 2*b, c];
    x_criticos = roots(coeficientes_derivada);
    
    puntosMin = [];
    puntosMax = [];
    
    for i = 1:length(x_criticos)
        x_c = x_criticos(i);
        
        % Solo procesamos puntos críticos reales
        if isreal(x_c)
            % Evaluar la Segunda Derivada (Prueba para determinar min/max)
            f_segunda_derivada = 6*a*x_c + 2*b;
            
            y_c = polyval(coeficientes, x_c); 
            
            % Si f''(x) > 0: Mínimo (concavidad hacia arriba)
            if f_segunda_derivada > 0
                puntosMin = [puntosMin; real(x_c), y_c];
            % Si f''(x) < 0: Máximo (concavidad hacia abajo)
            elseif f_segunda_derivada < 0
                puntosMax = [puntosMax; real(x_c), y_c];
            end
        end
    end
    
end