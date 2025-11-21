function [R] = calcularRadioCurvatura(coefs, x_vals)
    % Derivar
    d1_coefs = polyder(coefs);   
    d2_coefs = polyder(d1_coefs);

    % Evaluar en TODO el vector x_vals
    y_track  = polyval(coefs, x_vals);     
    dy = polyval(d1_coefs, x_vals);  % Pendiente f'(x)
    d2 = polyval(d2_coefs, x_vals);  % Concavidad f''(x)

    % Calcular Radio formula que nos dio el profe
    R = ((1 + dy.^2).^(3/2)) ./ abs(d2);
end

