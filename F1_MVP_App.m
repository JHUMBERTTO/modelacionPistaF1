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
            % 1. Calcular Matemática (Asumiendo que tienes esta función externa)
            % Si no la tienes, necesitarás definir 'app.Coefs' manualmente.
            [a,b,c,d] = calcularIncognitas(app.Points);
            app.Coefs = [a b c d];
            
            x = 10:0.5:280;
            y = polyval(app.Coefs, x);
            
            % 2. Dibujar Pista Base
            plot(app.AxPista, x, y, 'Color', 'k', 'LineWidth', 8); 
            hold(app.AxPista, 'on');
            plot(app.AxPista, x, y, 'w--', 'LineWidth', 1);
            
            % 3. Zonas Rojas (Pre-cálculo visual solo para referencia)
            % Nota: Usamos las funciones externas si existen, si no, usa polyder interno
            try
                R = calcularRadioCurvatura(app.Coefs, x);
                idx_bad = find(R < 50);
                if ~isempty(idx_bad)
                    plot(app.AxPista, x(idx_bad), y(idx_bad), 'r.', 'MarkerSize', 15);
                end
                calcularGradas(app);
            catch
                % Si fallan las funciones externas, no bloqueamos la app
            end
            
            axis(app.AxPista, 'equal');
            grid(app.AxPista, 'on');
            title(app.AxPista, 'Simulación: Método de Euler', 'Color', 'k');

            app.AxPista.BackgroundColor = 'w';
            app.AxPista.Box = 'on';
        end
        
        % --- BOTÓN INICIAR (REFACTORIZADO CON EULER) ---
        function iniciarTrayectoria(app, varargin)
            % 1. Configurar Interfaz
            app.RunID = app.RunID + 1;
            myLocalID = app.RunID;
            
            app.BtnIniciar.Text = '🔄 REINICIAR';
            app.BtnIniciar.BackgroundColor = [1 0.8 0];
            app.BtnIniciar.FontColor = 'k';
            app.LblEstado.Text = "Simulando (Euler)... 🏎️";
            app.LblEstado.FontColor = [0 0.4 1]; 
            
            delete(findobj(app.AxPista, 'Tag', 'movil'));
            
            % 2. Obtener Velocidad y Variables Físicas
            v_kmh = app.CampoVelocidad.Value;
            v_ms = v_kmh / 3.6; 
            
            % 3. Preparar Imagen del Carro
            try
                raw_img = imread('car.png');
                car_img = imresize(raw_img, [40, NaN]);
            catch
                car_img = zeros(20, 40, 3, 'uint8');
                car_img(:,:,3) = 255; car_img(5:15, 10:30, 1) = 255; 
            end
            w = 15; h = 8;
            
            % 4. Inicialización Euler
            % Derivadas del polinomio para calcular pendiente y radio
            d1_coefs = polyder(app.Coefs);      % f'
            d2_coefs = polyder(d1_coefs);       % f''
            
            % Paso de tiempo (Delta Time)
            dt = 0.05; 
            
            % Condiciones Iniciales
            x_curr = 10;                        % X Inicial
            y_curr = polyval(app.Coefs, x_curr); % Y Inicial
            
            % Dibujar carro inicial
            hold(app.AxPista, 'on');
            carrito = image(app.AxPista, ...
                'CData', car_img, ...
                'XData', [x_curr-w/2, x_curr+w/2], ... 
                'YData', [y_curr-h/2, y_curr+h/2], ... 
                'Tag', 'movil'); 
            app.AxPista.YDir = 'normal';
            
            crashed = false;
            
            % =============================================================
            % BUCLE DE EULER (Simulación paso a paso)
            % =============================================================
            while x_curr < 280
                % Check de interrupción
                if app.RunID ~= myLocalID, return; end
                
                % A. CALCULO DE GEOMETRÍA LOCAL
                yp  = polyval(d1_coefs, x_curr); % Pendiente (m)
                ypp = polyval(d2_coefs, x_curr); % Concavidad
                
                % Ángulo de la trayectoria
                angulo_rad = atan(yp);
                angulo_deg = rad2deg(angulo_rad);
                
                % B. MÉTODO DE EULER: Actualización de Posición
                % Descomponemos la velocidad en X y Y
                vx = v_ms * cos(angulo_rad);
                vy = v_ms * sin(angulo_rad);
                
                % x(t+dt) = x(t) + vx * dt
                x_next = x_curr + vx * dt;
                % y(t+dt) = y(t) + vy * dt
                y_next = y_curr + vy * dt;
                
                % *Corrección Visual*: Como Euler puro puede "salirse" de la curva 
                % por errores numéricos, ajustamos Y ligeramente al polinomio real 
                % para que se vea sobre el riel (opcional, pero recomendado para apps).
                % Si quieres Euler puro estricto, comenta la siguiente línea:
                y_next = polyval(app.Coefs, x_next); 

                % C. ROTACIÓN DE IMAGEN
                try
                    car_rot = imrotate(car_img, angulo_deg, 'crop');
                    carrito.CData = car_rot;
                catch
                end
                
                % D. MOVER OBJETO GRÁFICO
                carrito.XData = [x_next - w/2, x_next + w/2];
                carrito.YData = [y_next - h/2, y_next + h/2];
                
                % E. FÍSICA: CHECK DE DERRAPE
                % Radio de curvatura: R = (1 + y'^2)^(3/2) / |y''|
                R_val = (1 + yp^2)^1.5 / abs(ypp);
                
                % Velocidad Máxima en este punto
                th_peralte = deg2rad(app.Theta);
                num = sin(th_peralte) + app.Mu * cos(th_peralte);
                den = cos(th_peralte) - app.Mu * sin(th_peralte);
                
                % Evitar divisiones imaginarias si el denominador es malo
                if den <= 0, den = 0.001; end 
                V_max = sqrt(R_val * app.G * (num/den));
                
                if v_ms > V_max
                    crashed = true;
                    app.LblEstado.Text = "¡DERRAPE DETECTADO! 💥";
                    
                    % Animación de salida por tangente (Inercia)
                    v_dir = [vx, vy]; 
                    u_dir = v_dir / norm(v_dir); % Vector unitario dirección actual
                    p_curr = [x_next, y_next];
                    
                    for k = 1:20
                        if app.RunID ~= myLocalID, return; end
                        % Movimiento lineal simple post-choque
                        p_next = p_curr + u_dir * (k*2); 
                        
                        carrito.XData = [p_next(1)-w/2, p_next(1)+w/2];
                        carrito.YData = [p_next(2)-h/2, p_next(2)+h/2];
                        plot(app.AxPista, p_next(1), p_next(2), 'r.', 'MarkerSize', 5, 'Tag', 'movil');
                        drawnow; pause(0.02);
                    end
                    
                    app.TextAreaInfo.Value = {
                        sprintf("Derrape en X = %.1f m", x_next);
                        sprintf("Velocidad Carro: %.1f km/h", v_kmh);
                        sprintf("Velocidad Max: %.1f km/h", V_max * 3.6);
                        "-----------------";
                        "Fuerza centrífuga > Fricción";
                    };
                    break; % Romper bucle while
                end
                
                % Actualizar variables para siguiente iteración
                x_curr = x_next;
                y_curr = y_next;
                
                drawnow;
                % Pausa dinámica para intentar mantener velocidad visual constante
                % (Opcional, 0.01 es estándar)
                pause(0.01); 
            end
            
            if ~crashed && app.RunID == myLocalID
                app.LblEstado.Text = "Vuelta Exitosa ✅";
                app.LblEstado.FontColor = [0 0.5 0]; 
                app.BtnIniciar.Text = '▶ INICIAR TRAYECTORIA';
                app.BtnIniciar.BackgroundColor = [0.2 0.6 1]; 
                app.BtnIniciar.FontColor = 'w';
            end
        end
    end 

    % =====================================================================
    % 3. DISEÑO VISUAL (LAYOUT) - SIN CAMBIOS
    % =====================================================================
    methods (Access = public)
        function app = F1_MVP_App
            % Ventana Principal
            app.UIFigure = uifigure('Name', 'F1 MVP Simulator (Euler)', 'Position', [100 100 900 600], 'Color', 'w');
            
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {250, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.BackgroundColor = 'w';
            
            % --- PANEL IZQUIERDO ---
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;
            app.LeftPanel.BackgroundColor = 'w';
            app.LeftPanel.BorderType = 'line';
            app.LeftPanel.BorderWidth = 1;
            
            app.LblTitulo = uilabel(app.LeftPanel);
            app.LblTitulo.Position = [20 540 200 30];
            app.LblTitulo.Text = 'CONFIGURACIÓN';
            app.LblTitulo.FontSize = 18; 
            app.LblTitulo.FontWeight = 'bold';
            app.LblTitulo.FontColor = 'k'; 
            
            app.LblVelocidad = uilabel(app.LeftPanel);
            app.LblVelocidad.Position = [20 480 200 22];
            app.LblVelocidad.Text = 'Velocidad (km/h):';
            app.LblVelocidad.FontWeight = 'bold';
            app.LblVelocidad.FontColor = 'k';

            app.CampoVelocidad = uieditfield(app.LeftPanel, 'numeric');
            app.CampoVelocidad.Position = [20 450 100 30];
            app.CampoVelocidad.Value = 100;
            app.CampoVelocidad.FontSize = 14;
            app.CampoVelocidad.FontColor = 'k';
            app.CampoVelocidad.BackgroundColor = [0.95 0.95 0.95]; 
            
            app.BtnIniciar = uibutton(app.LeftPanel, 'push');
            app.BtnIniciar.Position = [20 380 210 50];
            app.BtnIniciar.Text = '▶ INICIAR TRAYECTORIA';
            app.BtnIniciar.FontSize = 14; 
            app.BtnIniciar.FontWeight = 'bold';
            app.BtnIniciar.BackgroundColor = [0.2 0.6 1]; 
            app.BtnIniciar.FontColor = 'w'; 
            app.BtnIniciar.ButtonPushedFcn = @app.iniciarTrayectoria;
            
            app.LblEstado = uilabel(app.LeftPanel);
            app.LblEstado.Position = [20 320 210 30];
            app.LblEstado.Text = 'Estado: Esperando...';
            app.LblEstado.FontSize = 14; 
            app.LblEstado.FontWeight = 'bold';
            app.LblEstado.FontColor = 'k';
            
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
            
            app.startupFcn();
        end
    end 
end