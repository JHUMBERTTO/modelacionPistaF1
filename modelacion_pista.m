function modelacion_pista()
    % nuestros puntos inciales
    points = [10 290;0 0; 0 0; 280 120];
    
    % Propuesta de puntos lo voy a comentar momentaneamente 
    % [p2,p3] = propuestaPuntos();
    
    % Los ingresamos a nuestra matriz de puntos
    % points(2, :) = p2;
    % points(3, :) = p3;
    points(2, :) = [100, 250];
    points(3, :) = [150, 200];

    % Obtenemos Incognitas realizando una matriz de 4x4
    [a,b,c,d] = calcularIncognitas(points)
    coefs = [a b c d];

    % Primer filtro verificar que nuestra funcion si pase por pi, pf.
    if (pasaPorPiPf(points,coefs))
        disp("Si pasan por Pi y Pf");
    else
        disp("No pasan por Pi y Pf");
        %restart desde 0
    end

    % Segundo filtro nuestra funcion debe tener una longitud de curva entre
    % [300m,500m]
    if (calcularLongitudCurva(coefs))
        fprintf("La longitud de Curva esta dentro del rango \n");
    else
        disp("La longitud de Curva no esta dentro del rango");
        %restart desde 0
    end
    
    % Calcular Puntos Min y Max
    [puntosMin, puntosMax] = calcularMinMax(coefs);
    disp("Punto Max");
    disp(puntosMax);
    disp("Punto Min")
    disp(puntosMin);

    % Determinamos zonas criticas
    x_track = 10:1:280;
    [R, dy, y] = calcularRadioCurvatura(coefs, x_track);

    % Analizar Seguridad
    % Esta funcion imprime un reporte Y nos devuelve los puntos para graficar
    puntos_derrape = analizarZonasCriticas(R, x_track, coefs);
    
end

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
