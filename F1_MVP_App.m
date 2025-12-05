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
            plot(app.AxPista, x, y, 'Color', 'k', 'LineWidth', 8); 
            hold(app.AxPista, 'on');
            plot(app.AxPista, x, y, 'w--', 'LineWidth', 1);
            
            % 3. Zonas Rojas (Visualización estática)
            try
                R = calcularRadioCurvatura(app.Coefs, x);
                idx_bad = find(R < 50);
                if ~isempty(idx_bad)
                    plot(app.AxPista, x(idx_bad), y(idx_bad), 'r.', 'MarkerSize', 15);
                end
                calcularGradas(app);
            catch
            end
            
            axis(app.AxPista, 'equal');
            grid(app.AxPista, 'on');
            title(app.AxPista, 'Simulación: HUD & Euler', 'Color', 'k');

            app.AxPista.BackgroundColor = 'w';
            app.AxPista.Box = 'on';
        end
        
        % --- BOTÓN INICIAR CON HUD DE FÍSICA ---
        % --- BOTÓN INICIAR CORREGIDO ---
        function iniciarTrayectoria(app, varargin)
            % 1. Configurar Interfaz
            app.RunID = app.RunID + 1;
            myLocalID = app.RunID;
            
            app.BtnIniciar.Text = '🛑 DETENER / REINICIAR';
            app.BtnIniciar.BackgroundColor = [1 0.2 0.2]; % Rojo suave
            app.LblEstado.Text = "Calculando Físicas... 📊";
            app.LblEstado.FontColor = [0 0.4 1]; 
            
            delete(findobj(app.AxPista, 'Tag', 'movil'));
            
            % 2. Obtener Inputs
            v_kmh = app.CampoVelocidad.Value;
            v_ms = v_kmh / 3.6; 
            
            % 3. Cargar Imagen
            try
                raw_img = imread('car.png');
                car_img = imresize(raw_img, [40, NaN]);
            catch
                car_img = zeros(20, 40, 3, 'uint8');
                car_img(:,:,3) = 255; car_img(5:15, 10:30, 1) = 255; 
            end
            w = 15; h = 8;
            
            % 4. Inicialización Matemática
            d1_coefs = polyder(app.Coefs);
            d2_coefs = polyder(d1_coefs);
            
            dt = 0.05; % Paso de tiempo
            x_curr = 10;
            y_curr = polyval(app.Coefs, x_curr);
            
            % --- VARIABLES ACUMULADORAS (HUD) ---
            dist_total = 0;     % Metros recorridos
            time_total = 0;     % Segundos transcurridos
            heat_total = 0;     % Joules (Calor por fricción)
            
            % Energía Inicial
            K_initial = 0.5 * app.Mass * v_ms^2;
            
            hold(app.AxPista, 'on');
            carrito = image(app.AxPista, ...
                'CData', car_img, ...
                'XData', [x_curr-w/2, x_curr+w/2], ... 
                'YData', [y_curr-h/2, y_curr+h/2], ... 
                'Tag', 'movil'); 
            app.AxPista.YDir = 'normal';
            
            crashed = false;
            
            % =============================================================
            % BUCLE DE EULER + HUD
            % =============================================================
            while x_curr < 280
                if app.RunID ~= myLocalID, return; end
                
                % A. Geometría
                yp  = polyval(d1_coefs, x_curr);
                ypp = polyval(d2_coefs, x_curr);
                angulo_rad = atan(yp);
                
                % B. Euler (Cinemática)
                vx = v_ms * cos(angulo_rad);
                vy = v_ms * sin(angulo_rad);
                
                x_next = x_curr + vx * dt;
                y_next = y_curr + vy * dt;
                y_next = polyval(app.Coefs, x_next); % Ajuste al riel
                
                % C. Físicas
                dx = x_next - x_curr;
                dy = y_next - y_curr;
                dist_step = sqrt(dx^2 + dy^2);
                
                dist_total = dist_total + dist_step;
                time_total = time_total + dt;
                
                % Radio y Límites
                R_val = (1 + yp^2)^1.5 / abs(ypp);
                
                % Energía
                K_curr = 0.5 * app.Mass * v_ms^2;
                delta_E_mech = K_curr - K_initial; 
                
                % Calor (Q = Work fricción)
                f_fric = app.Mu * app.Mass * app.G;
                heat_step = f_fric * dist_step;
                heat_total = heat_total + heat_step;
                
                % Vel Max
                th = deg2rad(app.Theta);
                num = sin(th) + app.Mu * cos(th);
                den = cos(th) - app.Mu * sin(th);
                if den <= 0, den = 0.001; end
                V_max = sqrt(R_val * app.G * (num/den));
                
                % --- D. ACTUALIZAR HUD (SOLUCIÓN DEL ERROR) ---
                % Usamos string(...) para convertir todo explícitamente a String Array
                infoText = [
                    "📊 TELEMETRÍA EN VIVO";
                    "--------------------";
                    string(sprintf("⏱️ Tiempo: %.2f s", time_total));
                    string(sprintf("📍 Distancia: %.1f m", dist_total));
                    " ";
                    string(sprintf("🚀 Vel. Actual: %.1f km/h", v_kmh));
                    string(sprintf("⚠️ Vel. Máx: %.1f km/h", V_max * 3.6));
                    string(sprintf("🔄 Radio: %.1f m", R_val));
                    " ";
                    "⚡ ENERGÍA & CALOR";
                    string(sprintf("🔥 Calor (Q): %.2f kJ", heat_total/1000));
                    string(sprintf("🔋 E. Cinética: %.2f kJ", K_curr/1000));
                    string(sprintf("cj ΔE Mecánica: %.2f J", delta_E_mech));
                ];
                
                app.TextAreaInfo.Value = infoText;

                % E. Gráficos
                try
                    carrito.CData = imrotate(car_img, rad2deg(angulo_rad), 'crop');
                catch
                end
                carrito.XData = [x_next - w/2, x_next + w/2];
                carrito.YData = [y_next - h/2, y_next + h/2];
                
                % F. Check de Derrape
                if v_ms > V_max
                    crashed = true;
                    app.LblEstado.Text = "¡DERRAPE! 💥";
                    
                    v_dir = [vx, vy]; u_dir = v_dir/norm(v_dir);
                    p_curr = [x_next, y_next];
                    for k = 1:15
                        if app.RunID ~= myLocalID, return; end
                        p_next = p_curr + u_dir * (k*2);
                        carrito.XData = [p_next(1)-w/2, p_next(1)+w/2];
                        carrito.YData = [p_next(2)-h/2, p_next(2)+h/2];
                        plot(app.AxPista, p_next(1), p_next(2), 'rx');
                        drawnow; pause(0.02);
                    end
                    
                    % Concatenamos el mensaje de error al arreglo de strings existente
                    app.TextAreaInfo.Value = [infoText; " "; "❌ FUERZA G EXCESIVA"];
                    break;
                end
                
                x_curr = x_next;
                y_curr = y_next;
                
                drawnow;
                pause(0.01); 
            end
            
            if ~crashed && app.RunID == myLocalID
                app.LblEstado.Text = "Finalizado ✅";
                app.BtnIniciar.Text = '▶ NUEVA CARRERA';
                app.BtnIniciar.BackgroundColor = [0.2 0.6 1]; 
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