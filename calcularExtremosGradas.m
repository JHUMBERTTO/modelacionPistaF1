function calcularExtremosGradas(coefs, x_start, x_end, distancia)
    % Vector con solo los dos puntos de interés (inicio y fin de la zona)
    x_puntos = [x_start, x_end];
    
    % Trigonometría / Vectores
    y_pista = polyval(coefs, x_puntos);
    der = polyder(coefs);
    dydx = polyval(der, x_puntos);
    theta = atan(dydx);
    
    % IMPORTANTE: El signo depende de hacia dónde es la curva.
    % Si la curva es hacia la izquierda, la grada va a la derecha (y viceversa).
    
    x_g = x_puntos - distancia * sin(theta);
    y_g = y_pista + distancia * cos(theta);
    
    % --- REPORTE ---
    fprintf('   GRADAS (Distancia seguridad %.0fm):\n', distancia);
    fprintf('     Extremo Inicio: (%.2f, %.2f)\n', x_g(1), y_g(1));
    fprintf('     Extremo Final:  (%.2f, %.2f)\n', x_g(2), y_g(2));
    
end