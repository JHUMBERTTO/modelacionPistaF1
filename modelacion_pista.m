function modelacion_pista()
    % 290 = a10.^3 + b10.^2 + c10 + d 
    % 120 = a280.^3 + b280.^2 + c280 + d
    points = [10 290;0 0; 0 0; 280 120];
    
    % Propuesta de puntos lo voy a comentar momentaneamente para hacer
    % testing mas rapido
    % [p2,p3] = propuestaPuntos();
    
    % Los ingresamos a nuestra matriz de puntos
    % points(2, :) = p2;
    % points(3, :) = p3;
    points(2, :) = [100, 250];
    points(3, :) = [150, 200];

    % Obtenemos Incognitas realizando una matriz de 4x4
    [a,b,c,d] = calcularIncognitas(points)
    
    coefs = [a b c d];
    fn = @(x) a*(x.^3) + b*(x.^2) + c*x + d

    % Primer filtro que nuestra funcion si pase por pi, pf.
    if (pasaPorPiPf(points,coefs))
        disp("Si pasan por Pi y Pf");
    else
        disp("No pasan por Pi y Pf");
        %restart desde 0
    end

    % Segundo filtro nuestra funcion debe tener una longitud de curva entre
    % [300m,500m]
    if (calcularLongitudCurva(coefs))
        disp("La longitud de Curva esta dentro del rango");
    else
        disp("La longitud de Curva no esta dentro del rango");
        %restart desde 0
    end

    p = calcularRadioCurvatura(coefs, points(1,1), points(4,1));
    
    % Primer filtro
    if ((l >= 300 && l <= 500) && (p < 100))
        disp("La longitud está en el rango [300, 500].");
        pCriticos = roots(coefs);
        x = linspace(10, 280, 100); 
        % Los metemos a coords
        pCriticos(1,2) = fn(pCriticos(1));
        pCriticos(2,2) = fn(pCriticos(2));

        disp("Maximos y minimos coordenadas:")
        disp(pCriticos)

        figure
        plot(x, fn, 'b-', 'LineWidth', 1.5)
        xlabel('x')
        ylabel('f(x)')
        title('Gráfica')
        grid on
    else
        fprintf("FALLO. La longitud o el radio de curvatura fuera de rango. \nDebes proponer pendientes diferentes.");
    end
    

end


% Funcion que me escoje puntos automaticamente hasta que la longitud sea la
% indicada
function [p2,p3] = propuestaPuntos()
   % hagamos que el usuario sea quien meta los puntos por ahora, despues
   % estaria bueno automatizarlo.
   % FALTA AGREGAR QUE NO SE REPITAN PUNTOS MANEJO DE ERROES BASICAMENTE
   disp("nuestros puntos actuales son pi = (10,290) y pf = (280,120) \n");
   p2x = input("ingresa coordenada x para fn3: ");
   p2y = input("ingresa coordenada y para fn3: ");
   p3x = input("ingresa coordenada x para fn4: ");
   p3y = input("ingresa coordenada y para fn4: ");
   p2 = [p2x,p2y];
   p3 = [p3x, p3y];
end
