function [tf] = calcularLongitudCurva(coefs)
    % primer derivada
    coefs = polyder(coefs);
    fprime = @(x) polyval(coefs,x);

    % Filter la longitud de curva de la funcion debe ser >= 300m y <= 500m
    lfn = @(x) sqrt(1 + (fprime(x)).^2)
    l = integral(lfn,10,280)
    tf = (l >= 300 && l <= 500)
end

