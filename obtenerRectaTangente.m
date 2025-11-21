function [m, b] = obtenerRectaTangente(coefs, x_punto)
    % Calcular la coordenada Y exacta en ese punto
    y_punto = polyval(coefs, x_punto);
    
    % Calcular la pendiente (derivada) en ese punto
    d1_coefs = polyder(coefs);
    m = polyval(d1_coefs, x_punto);
    
    % Calcular b (Intercepto) -> y = mx + b  =>  b = y - mx
    b = y_punto - (m * x_punto);
    
    % Imprimir la ecuacion bonita
    fprintf('   Recta Tangente en x=%.2f:  y = (%.4f)x + (%.4f)\n', x_punto, m, b);
end