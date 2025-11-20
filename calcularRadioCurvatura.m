

% recibe coeficientes y pI,pF de la funcion
function [p] = calcularRadioCurvatura(coefs, pi, pf)
    x_track = pi:1:pf;  
    
    coefs_d1 = polyder(coefs);    
    coefs_d2 = polyder(coefs_d1);
    
    % Derivadas
    yp = polyval(coefs_d1, x_track); % f'(x)
    ypp = polyval(coefs_d2, x_track); % f''(x)
    
    p = ( (1 + yp.^2).^(3/2) ) ./ abs(ypp);
    
    % 5. Ahora BUSCA el peligro
    %    Queremos saber en qué X el radio está entre 10 y 20
    % indices_peligro = find(R >= 10 & R <= 20);
    % zonas_peligrosas_x = x_track(indices_peligro);
    % radios_peligrosos = R(indices_peligro);
    % 
    % % Imprimir resultados
    % if isempty(zonas_peligrosas_x)
    %     disp('¡Felicidades! No hay zonas de peligro (R entre 10 y 20m).');
    % else
    %     disp('¡ALERTA! Se detectaron zonas de riesgo en los siguientes metros x:');
    %     disp(zonas_peligrosas_x);
    % end
    
end