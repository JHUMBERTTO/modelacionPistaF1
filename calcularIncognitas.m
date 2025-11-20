function [a,b,c,d] = calcularIncognitas(points)
    % disp(fn)
    
    % hacemos una matriz de nuestros coeficientes x
    x = zeros(4);
    j = 1;
    for i = 3:-1:0
     x(:,j) = points(:,1).^i;
     j = j + 1;
    end

    % hacemos un matriz de nuestros resultados y
    y = points(:,2);

    % calculamos valor de matriz
    value = x\y;

    a = value(1);
    b = value(2);
    c = value(3);
    d = value(4);
end