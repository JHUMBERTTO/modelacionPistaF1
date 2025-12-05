classdef F1_MVP_App < matlab.apps.AppBase

    % =====================================================================
    % PROPIEDADES (VARIABLES)
    % =====================================================================
    properties (Access = public)
        UIFigure             matlab.ui.Figure
        GridLayout           matlab.ui.container.GridLayout
        
        % --- PANEL IZQUIERDO (CONTROLES) ---
        LeftPanel            matlab.ui.container.Panel
        LblTitulo            matlab.ui.control.Label
        LblVelocidad         matlab.ui.control.Label
        LblPunto1            matlab.ui.control.Label
        LblPunto2            matlab.ui.control.Label
        CampoVelocidad       matlab.ui.control.NumericEditField
        BtnIniciar           matlab.ui.control.Button
        LblEstado            matlab.ui.control.Label
        TextAreaInfo         matlab.ui.control.TextArea
        
        % --- ÁREA DERECHA (VISUALIZACIÓN) ---
        AxPista              matlab.ui.control.UIAxes
        
        % --- VARIABLES MATEMÁTICAS ---
        Coefs double
        Points double = [10 290; 110 250; 140 200; 280 120];
        Mass = 798;
        Mu = 0.8;
        G = 9.81;
        Theta = 3; % Grados
        
        % Control de Flujo
        RunID double = 0; 
    end

    % =====================================================================
    % 2. LÓGICA DE LA APP (FUNCIONES)
    % =====================================================================
    methods (Access = private)
        
        function startupFcn(app)
            % 1. Calcular Matemática
            [a,b,c,d] = calcularIncognitas(app.Points);
            app.Coefs = [a b c d];
            
            x = 10:0.5:280;
            y = polyval(app.Coefs, x);
            
            % 2. Dibujar Pista Base
            % Usamos negro para la pista base para mayor contraste en fondo blanco
            plot(app.AxPista, x, y, 'Color', 'k', 'LineWidth', 8); 
            hold(app.AxPista, 'on');
            plot(app.AxPista, x, y, 'w--', 'LineWidth', 1);
            
            % 3. Zonas Rojas
            R = calcularRadioCurvatura(app.Coefs, x);
            idx_bad = find(R < 50);
            if ~isempty(idx_bad)
                plot(app.AxPista, x(idx_bad), y(idx_bad), 'r.', 'MarkerSize', 15);
            end

            % calcular gradas
            calcularGradas(app);
            
            axis(app.AxPista, 'equal');
            grid(app.AxPista, 'on');
            title(app.AxPista, 'Simulación de Trayectoria', 'Color', 'k');

            app.AxPista.BackgroundColor = 'w';
            app.AxPista.Box = 'on';
        end
        
        % --- BOTÓN INICIAR ---
        function iniciarTrayectoria(app, varargin)
            % 1. Configurar Interfaz (Reiniciar)
            app.RunID = app.RunID + 1;
            myLocalID = app.RunID;
            
            app.BtnIniciar.Text = '🔄 REINICIAR';
            app.BtnIniciar.BackgroundColor = [1 0.8 0];
            app.BtnIniciar.FontColor = 'k'; % Texto negro para contraste con amarillo
            app.LblEstado.Text = "En carrera 🏎️";
            app.LblEstado.FontColor = [0 0.4 1]; 
            
            % Limpiar gráficas anteriores (borrar coche viejo)
            delete(findobj(app.AxPista, 'Tag', 'movil'));
            
            % 2. Leer Velocidad
            v_kmh = app.CampoVelocidad.Value;
            v_ms = v_kmh / 3.6; 
            
            % 3. Vectores de la Pista
            x_path = 10:1:280;
            y_path = polyval(app.Coefs, x_path);
            
            % Cálculos Físicos
            R_vec = calcularRadioCurvatura(app.Coefs, x_path);
            der = polyder(app.Coefs);
            dy_vec = polyval(der, x_path);
            
            th = deg2rad(app.Theta);
            num = sin(th) + app.Mu * cos(th);
            den = cos(th) - app.Mu * sin(th);
            V_max_vec = sqrt(R_vec .* app.G .* (num/den));
            
            % --- 4. CARGA DE IMAGEN SEGURA ---
            try
                raw_img = imread('car.png');
                car_img = imresize(raw_img, [40, NaN]); % Reducir tamaño
            catch
                % Si falla, bloque azul con linea roja
                car_img = zeros(20, 40, 3, 'uint8');
                car_img(:,:,3) = 255; 
                car_img(5:15, 10:30, 1) = 255; 
            end
            
            w = 15; h = 8;  % Dimensiones visuales
            
            hold(app.AxPista, 'on');
            carrito = image(app.AxPista, ...
                'CData', car_img, ...
                'XData', [x_path(1)-w/2, x_path(1)+w/2], ... 
                'YData', [y_path(1)-h/2, y_path(1)+h/2], ... 
                'Tag', 'movil'); 
            
            % Fix eje Y invertido
            app.AxPista.YDir = 'normal';
            
            crashed = false;
            
            % --- BUCLE DE ANIMACIÓN ---
            for i = 1:length(x_path)
                % Check de interrupción (Reiniciar)
                if app.RunID ~= myLocalID, return; end
                
                % A. CALCULAR ROTACIÓN
                angulo = atan(dy_vec(i)) * (180/pi);
                try
                    car_rot = imrotate(car_img, angulo, 'crop');
                    carrito.CData = car_rot;
                catch
                end
                
                % B. MOVER IMAGEN
                xc = x_path(i);
                yc = y_path(i);
                carrito.XData = [xc - w/2, xc + w/2];
                carrito.YData = [yc - h/2, yc + h/2];
                
                % C. CHECK DE DERRAPE
                if v_ms > V_max_vec(i)
                    crashed = true;
                    app.LblEstado.Text = "¡DERRAPE DETECTADO! 💥";
                    
                    % Salida por tangente
                    m = dy_vec(i);
                    v_dir = [1, m]; u_dir = v_dir / norm(v_dir);
                    p_curr = [xc, yc];
                    
                    for k = 1:20
                        if app.RunID ~= myLocalID, return; end
                        p_next = p_curr + u_dir * (k*2);
                        carrito.XData = [p_next(1)-w/2, p_next(1)+w/2];
                        carrito.YData = [p_next(2)-h/2, p_next(2)+h/2];
                        plot(app.AxPista, p_next(1), p_next(2), 'r.', 'MarkerSize', 5, 'Tag', 'movil');
                        drawnow; pause(0.02);
                    end
                    
                    app.TextAreaInfo.Value = {
                        sprintf("Fallo en X = %.1f m", xc);
                        sprintf("Velocidad: %.1f km/h", v_kmh);
                        "-----------------";
                        "Fuerza centrífuga excesiva.";
                    };
                    break;
                end
                
                drawnow;
                pause(0.01); 
            end
            
            if ~crashed && app.RunID == myLocalID
                app.LblEstado.Text = "Vuelta Exitosa ✅";
                app.LblEstado.FontColor = [0 0.5 0]; % Verde oscuro
                app.BtnIniciar.Text = '▶ INICIAR';
                app.BtnIniciar.BackgroundColor = [0.2 0.6 1]; % Regresa a azul
                app.BtnIniciar.FontColor = 'w';
            end
        end
    end 

    % =====================================================================
    % 3. DISEÑO VISUAL (LAYOUT)
    % =====================================================================
    methods (Access = public)
        function app = F1_MVP_App
            % Ventana Principal - Fondo Blanco ('w')
            app.UIFigure = uifigure('Name', 'F1 MVP Simulator', 'Position', [100 100 900 600], 'Color', 'w');
            
            % Grid Layout - Fondo Blanco
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {250, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.BackgroundColor = 'w';
            
            % --- PANEL IZQUIERDO ---
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;
            app.LeftPanel.BackgroundColor = 'w';
            % Borde sutil gris para separar
            app.LeftPanel.BorderType = 'line';
            app.LeftPanel.BorderWidth = 1;
            
            % Titulo (Negro y Grande)
            app.LblTitulo = uilabel(app.LeftPanel);
            app.LblTitulo.Position = [20 540 200 30];
            app.LblTitulo.Text = 'CONFIGURACIÓN';
            app.LblTitulo.FontSize = 18; 
            app.LblTitulo.FontWeight = 'bold';
            app.LblTitulo.FontColor = 'k'; % Negro
            
            % Label Velocidad
            app.LblVelocidad = uilabel(app.LeftPanel);
            app.LblVelocidad.Position = [20 480 200 22];
            app.LblVelocidad.Text = 'Velocidad (km/h):';
            app.LblVelocidad.FontWeight = 'bold';
            app.LblVelocidad.FontColor = 'k';

            % Label Punto 1 Ingresado por Usr
            % app.LblPunto1 = uilabel(app.LeftPanel);
            % app.LblPunto1.Text = 'Punto 1';
            % app.Lbl.FontWeight = 'bold';
            % app.LblVelocidad.FontColor = 'k';
            
            % Campo Velocidad (Input)
            app.CampoVelocidad = uieditfield(app.LeftPanel, 'numeric');
            app.CampoVelocidad.Position = [20 450 100 30];
            app.CampoVelocidad.Value = 100;
            app.CampoVelocidad.FontSize = 14;
            app.CampoVelocidad.FontColor = 'k';
            app.CampoVelocidad.BackgroundColor = [0.95 0.95 0.95]; % Gris muy suave para input
            
            % Botón Iniciar (Azul con Texto Blanco)
            app.BtnIniciar = uibutton(app.LeftPanel, 'push');
            app.BtnIniciar.Position = [20 380 210 50];
            app.BtnIniciar.Text = '▶ INICIAR TRAYECTORIA';
            app.BtnIniciar.FontSize = 14; 
            app.BtnIniciar.FontWeight = 'bold';
            app.BtnIniciar.BackgroundColor = [0.2 0.6 1]; 
            app.BtnIniciar.FontColor = 'w'; % Blanco
            app.BtnIniciar.ButtonPushedFcn = @app.iniciarTrayectoria;
            
            % Estado (Negro default)
            app.LblEstado = uilabel(app.LeftPanel);
            app.LblEstado.Position = [20 320 210 30];
            app.LblEstado.Text = 'Estado: Esperando...';
            app.LblEstado.FontSize = 14; 
            app.LblEstado.FontWeight = 'bold';
            app.LblEstado.FontColor = 'k';
            
            % Info (Fondo blanco, texto negro)
            app.TextAreaInfo = uitextarea(app.LeftPanel);
            app.TextAreaInfo.Position = [20 50 210 250];
            app.TextAreaInfo.Editable = 'off';
            app.TextAreaInfo.Value = {'Ingresa una velocidad'; 'y presiona iniciar.'};
            app.TextAreaInfo.BackgroundColor = 'w';
            app.TextAreaInfo.FontColor = 'k';
            app.TextAreaInfo.FontSize = 12;
            
            % --- ÁREA DERECHA ---
            app.AxPista = uiaxes(app.GridLayout);
            app.AxPista.Layout.Row = 1;
            app.AxPista.Layout.Column = 2;
            app.AxPista.Title.String = 'Vista de Pista';
            app.AxPista.Title.FontSize = 16;
            app.AxPista.Title.FontWeight = 'bold';
            app.AxPista.BackgroundColor = 'w';
            app.AxPista.XColor = 'k'; 
            app.AxPista.YColor = 'k';
            app.AxPista.GridColor = [0.8 0.8 0.8];
            
            % Iniciar
            app.startupFcn();
        end
    end 
end