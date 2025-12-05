classdef F1_MVP_App < matlab.apps.AppBase

    % ===========
    % PROPIEDADES
    % ===========
    properties (Access = public)
        UIFigure             matlab.ui.Figure
        GridLayout           matlab.ui.container.GridLayout
        
        % --- PANEL IZQUIERDO ---
        LeftPanel            matlab.ui.container.Panel
        LblTitulo            matlab.ui.control.Label
        
        % 1. Velocidad
        LblVelocidad         matlab.ui.control.Label
        CampoVelocidad       matlab.ui.control.NumericEditField
        
        % 2. Masa
        LblMasa              matlab.ui.control.Label
        CampoMasa            matlab.ui.control.NumericEditField
        
        % 3. Aceleración Inicial
        LblAcel              matlab.ui.control.Label
        CampoAcel            matlab.ui.control.NumericEditField
        
        % 4. Tiempo de Aceleración
        LblTiempoAcel        matlab.ui.control.Label
        CampoTiempoAcel      matlab.ui.control.NumericEditField
        
        % Botones y Estado
        BtnIniciar           matlab.ui.control.Button
        LblEstado            matlab.ui.control.Label
        TextAreaInfo         matlab.ui.control.TextArea
        
        % --- ÁREA DERECHA ---
        AxPista              matlab.ui.control.UIAxes
        
        % --- VARIABLES MATEMÁTICAS ---
        Coefs double
        Points double = [10 290; 110 250; 140 200; 280 120];
        
        % Física
        Mu = 0.8;       % Fricción Lateral (Curvas)
        Mu_Roll = 0.15; % Resistencia a la rodadura (Rectas)
        G = 9.81;
        Theta = 3;      % Grados de peralte
        
        RunID double = 0; 
    end

    % ==================
    % LOGICA (FUNCIONES)
    % ==================
    methods (Access = private)
        
        function startupFcn(app)
            % 1. Calcular Pista
            [a,b,c,d] = calcularIncognitas(app.Points);
            app.Coefs = [a b c d];
            
            x = 10:0.5:280;
            y = polyval(app.Coefs, x);
            
            % 2. Dibujar Pista
            plot(app.AxPista, x, y, 'Color', 'k', 'LineWidth', 8); 
            hold(app.AxPista, 'on');
            plot(app.AxPista, x, y, 'w--', 'LineWidth', 1);
            
            % Zonas Rojas
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
            title(app.AxPista, 'Simulación: Pista', 'Color', 'k');
            app.AxPista.BackgroundColor = 'w';

            % --- LAYOUT MANUAL (Posiciones) ---
            app.LblTitulo.Position = [20 560 200 30];
            
            app.LblVelocidad.Position = [20 530 200 20];
            app.CampoVelocidad.Position = [20 510 100 25];
            
            app.LblMasa.Position = [20 480 200 20];
            app.CampoMasa.Position = [20 460 100 25];
            
            app.LblAcel.Position = [20 430 200 20];
            app.CampoAcel.Position = [20 410 100 25];
            
            app.LblTiempoAcel.Position = [130 430 100 20];
            app.CampoTiempoAcel.Position = [130 410 80 25];

            app.BtnIniciar.Position = [20 350 210 40];
            app.LblEstado.Position = [20 310 210 30];
            app.TextAreaInfo.Position = [20 20 210 280];
        end
        
        % --- BOTÓN INICIAR ---
        function iniciarTrayectoria(app, varargin)
            % Reset
            app.RunID = app.RunID + 1;
            myLocalID = app.RunID;
            app.BtnIniciar.Text = 'Reiniciar';
            app.BtnIniciar.BackgroundColor = [1 0.2 0.2];
            app.LblEstado.Text = "En Pista...";
            app.LblEstado.FontColor = 'k'; 
            delete(findobj(app.AxPista, 'Tag', 'movil'));
            
            % 1. LEER INPUTS
            v_kmh = app.CampoVelocidad.Value;
            v_ms = v_kmh / 3.6; 
            masa_actual = app.CampoMasa.Value;
            
            % Configuramos la aceleración inicial desde los inputs
            acc_user_input = app.CampoAcel.Value;    
            acc_duration   = app.CampoTiempoAcel.Value; 
            acc_timer      = 0; 
            
            % Variables Lógicas
            estaba_en_recta = false; 
            umbral_recta = 150; 
            
            % Cargar Imagen
            try
                raw_img = imread('car.png');
                car_img = imresize(raw_img, [40, NaN]);
            catch
                car_img = zeros(20, 40, 3, 'uint8');
                car_img(:,:,3) = 255; car_img(5:15, 10:30, 1) = 255; 
            end
            w = 15; h = 8;
            
            % Derivadas
            d1_coefs = polyder(app.Coefs);
            d2_coefs = polyder(d1_coefs);
            
            % Simulación
            dt = 0.05; 
            x_curr = 10;
            y_curr = polyval(app.Coefs, x_curr);
            
            % ACUMULADORES
            dist_total = 0; 
            time_total = 0; 
            heat_total = 0;     
            K_initial = 0.5 * masa_actual * v_ms^2;
            
            hold(app.AxPista, 'on');
            carrito = image(app.AxPista, 'CData', car_img, ...
                'XData', [x_curr-w/2, x_curr+w/2], ... 
                'YData', [y_curr-h/2, y_curr+h/2], 'Tag', 'movil'); 
            app.AxPista.YDir = 'normal';
            crashed = false;
            
            % ===================
            % BUCLE PRINCIPAL
            % ===================
            while x_curr < 280
                if app.RunID ~= myLocalID, return; end
                
                yp  = polyval(d1_coefs, x_curr);
                ypp = polyval(d2_coefs, x_curr);
                
                % Radio de Curvatura
                R_val = (1 + yp^2)^1.5 / abs(ypp);
                es_recta_ahora = R_val > umbral_recta;
                
                % --- DETECCIÓN DE RECTA ---
                % Si acabamos de entrar a una recta (Rising Edge)
                if es_recta_ahora && ~estaba_en_recta
                    app.LblEstado.FontColor = [0 0.6 0]; % Verde
                    drawnow;
                    
                    % Preguntar SIEMPRE al entrar a recta
                    prompt = {
                        sprintf('¡Entrada a Recta!\nVelocidad: %.1f km/h.\nNueva Aceleración (m/s²):', v_ms*3.6), ...
                        'Duración (s):'
                    };
                    answer = inputdlg(prompt, 'Control de Motor', [1 50], {'2.0', '3.0'});
                    
                    if ~isempty(answer)
                        acc_new = str2double(answer{1});
                        dur_new = str2double(answer{2});
                        if ~isnan(acc_new) && ~isnan(dur_new)
                            acc_user_input = acc_new;
                            acc_duration = dur_new;
                            acc_timer = 0; % Reiniciar timer
                        end
                    end
                end
                
                % --- DETECCIÓN DE CURVA ---
                if ~es_recta_ahora && estaba_en_recta
                    app.LblEstado.Text = "Precaución: CURVA";
                    app.LblEstado.FontColor = [1 0.5 0]; % Naranja
                    
                    % SEGURIDAD: Cortar aceleración al entrar a curva
                    acc_user_input = 0; 
                end
                
                estaba_en_recta = es_recta_ahora;
                
                % --- FISICA: ACELERACIÓN VS FRICCIÓN ---
                acc_aplicada = 0;
                
                % Caso 1: Motor Empujando (Usuario definió aceleración y hay tiempo restante)
                if acc_user_input > 0 && acc_timer < acc_duration
                    acc_aplicada = acc_user_input;
                    acc_timer = acc_timer + dt;
                    txt_hud = sprintf("(Acel: %.1fs)", acc_duration - acc_timer);
                
                % Caso 2: Rodadura (Fricción Natural)
                else
                    acc_aplicada = - (app.Mu_Roll * app.G); 
                    txt_hud = "(Inercia/Fricción)";
                    if v_ms <= 0.1, acc_aplicada = 0; v_ms = 0; txt_hud = "(Detenido)"; end
                end
                
                % Euler: Velocidad
                v_ms = v_ms + (acc_aplicada * dt);
                if v_ms < 0, v_ms = 0; end
                
                % Cinemática
                angulo_rad = atan(yp);
                vx = v_ms * cos(angulo_rad);
                vy = v_ms * sin(angulo_rad);
                
                x_next = x_curr + vx * dt;
                y_next = y_curr + vy * dt;
                y_next = polyval(app.Coefs, x_next); 
                
                dx = x_next - x_curr; dy = y_next - y_curr;
                dist_step = sqrt(dx^2 + dy^2);
                dist_total = dist_total + dist_step;
                time_total = time_total + dt;
                
                % Energía y Calor
                K_curr = 0.5 * masa_actual * v_ms^2;
                delta_E_mech = K_curr - K_initial;
                
                f_fric = app.Mu * masa_actual * app.G; 
                heat_step = f_fric * dist_step;
                heat_total = heat_total + heat_step;
                
                % Límite Físico (Derrape)
                th = deg2rad(app.Theta);
                num = sin(th) + app.Mu * cos(th);
                den = cos(th) - app.Mu * sin(th);
                if den <= 0, den = 0.001; end
                V_max = sqrt(R_val * app.G * (num/den));
                
                % --- HUD ---
                infoText = [
                    "DATOS DE TELEMETRÍA";
                    "--------------------";
                    string(sprintf("Masa: %.0f kg", masa_actual));
                    string(sprintf("Tiempo: %.2f s", time_total));
                    string(sprintf("Distancia Recorrida: %.1f m", dist_total));
                    " ";
                    string(sprintf("Velocidad: %.1f km/h", v_ms*3.6));
                    string(txt_hud);
                    string(sprintf("Límite de Velocidad: %.1f km/h", V_max*3.6));
                    string(sprintf("Radio de Curvatura: %.1f m", R_val));
                    " ";
                    string(sprintf("Calor (Q): %.2f kJ", heat_total/1000));
                    string(sprintf("E.Cinetica: %.2f kJ", K_curr/1000));
                    string(sprintf("ΔE Mecanica: %.2f J", delta_E_mech));
                ];
                app.TextAreaInfo.Value = infoText;

                % Render
                try
                    carrito.CData = imrotate(car_img, rad2deg(angulo_rad), 'crop');
                catch
                end
                carrito.XData = [x_next - w/2, x_next + w/2];
                carrito.YData = [y_next - h/2, y_next + h/2];
                
                % --- CRASH CHECK & ANIMACIÓN ---
                if v_ms > V_max
                    crashed = true;
                    app.LblEstado.Text = "¡DERRAPE!";
                    app.LblEstado.FontColor = 'r';
                    
                    % Vector tangente unitario
                    v_dir = [vx, vy]; 
                    if norm(v_dir) == 0, v_dir=[1,0]; end
                    u_dir = v_dir / norm(v_dir);
                    
                    p_curr = [x_next, y_next];
                    
                    % Bucle de animación de salida de pista
                    for k = 1:15
                         if app.RunID ~= myLocalID, return; end
                         
                         p_next = p_curr + u_dir * (k*2.5);
                         
                         % Mover coche
                         carrito.XData = [p_next(1)-w/2, p_next(1)+w/2];
                         carrito.YData = [p_next(2)-h/2, p_next(2)+h/2];
                         
                         % Dibujar rastro
                         plot(app.AxPista, p_next(1), p_next(2), 'rx', 'LineWidth', 2);
                         
                         drawnow; 
                         pause(0.02);
                    end
                    break; % Fin de simulación por choque
                end
                
                % Stop Check
                if v_ms <= 0 && time_total > 2
                     app.LblEstado.Text = "Auto Detenido";
                     app.LblEstado.FontColor = 'k';
                     break;
                end
                
                x_curr = x_next;
                y_curr = y_next;
                drawnow;
                pause(0.01); 
            end
            
            if ~crashed && v_ms > 0 && app.RunID == myLocalID
                app.LblEstado.Text = "Meta Alcanzada";
                app.LblEstado.FontColor = 'k';
                app.BtnIniciar.Text = '▶';
                app.BtnIniciar.BackgroundColor = [0.2 0.6 1]; 
            end
        end
    end

    % =========
    % LAYOUT
    % =========
    methods (Access = public)
        function app = F1_MVP_App
            app.UIFigure = uifigure('Name', 'F1 Dynamics', 'Position', [100 100 950 600], 'Color', 'w');
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {260, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.BackgroundColor = 'w';
            
            % Left Panel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1; app.LeftPanel.Layout.Column = 1;
            app.LeftPanel.BackgroundColor = 'w';
            app.LeftPanel.BorderType = 'line';
            
            app.LblTitulo = uilabel(app.LeftPanel);
            app.LblTitulo.Text = 'CONFIGURACIÓN';
            app.LblTitulo.FontSize = 18; app.LblTitulo.FontWeight = 'bold';
            app.LblTitulo.FontColor = 'k'; 
            
            % --- VELOCIDAD ---
            app.LblVelocidad = uilabel(app.LeftPanel);
            app.LblVelocidad.Text = 'Vel. Inicial (km/h):';
            app.LblVelocidad.FontWeight = 'bold'; app.LblVelocidad.FontColor = 'k'; 
            
            app.CampoVelocidad = uieditfield(app.LeftPanel, 'numeric');
            app.CampoVelocidad.Value = 30; 
            app.CampoVelocidad.BackgroundColor = [0.95 0.95 0.95];
            app.CampoVelocidad.FontColor = 'k'; 
            
            % --- MASA ---
            app.LblMasa = uilabel(app.LeftPanel);
            app.LblMasa.Text = 'Masa (kg):';
            app.LblMasa.FontWeight = 'bold'; app.LblMasa.FontColor = 'k'; 
            
            app.CampoMasa = uieditfield(app.LeftPanel, 'numeric');
            app.CampoMasa.Value = 798; 
            app.CampoMasa.BackgroundColor = [0.95 0.95 0.95];
            app.CampoMasa.FontColor = 'k'; 
            
            % --- ACELERACION INICIAL ---
            app.LblAcel = uilabel(app.LeftPanel);
            app.LblAcel.Text = 'Acel. Inicial (m/s²):';
            app.LblAcel.FontWeight = 'bold'; app.LblAcel.FontColor = 'k'; 
            
            app.CampoAcel = uieditfield(app.LeftPanel, 'numeric');
            app.CampoAcel.Value = 0; 
            app.CampoAcel.BackgroundColor = [0.95 0.95 0.95];
            app.CampoAcel.FontColor = 'k'; 
            
            % --- TIEMPO ACEL ---
            app.LblTiempoAcel = uilabel(app.LeftPanel);
            app.LblTiempoAcel.Text = 'Duración (s):';
            app.LblTiempoAcel.FontWeight = 'bold'; app.LblTiempoAcel.FontColor = 'k'; 
            
            app.CampoTiempoAcel = uieditfield(app.LeftPanel, 'numeric');
            app.CampoTiempoAcel.Value = 0; 
            app.CampoTiempoAcel.BackgroundColor = [0.95 0.95 0.95];
            app.CampoTiempoAcel.FontColor = 'k'; 
            
            % UI Standard
            app.BtnIniciar = uibutton(app.LeftPanel, 'push');
            app.BtnIniciar.Text = '▶ INICIAR';
            app.BtnIniciar.FontSize = 14; app.BtnIniciar.FontWeight = 'bold';
            app.BtnIniciar.BackgroundColor = [0.2 0.6 1]; app.BtnIniciar.FontColor = 'w';
            app.BtnIniciar.ButtonPushedFcn = @app.iniciarTrayectoria;
            
            app.LblEstado = uilabel(app.LeftPanel);
            app.LblEstado.Text = 'Listo';
            app.LblEstado.FontSize = 14; app.LblEstado.FontWeight = 'bold'; app.LblEstado.FontColor = 'k'; 
            
            app.TextAreaInfo = uitextarea(app.LeftPanel);
            app.TextAreaInfo.Editable = 'off';
            app.TextAreaInfo.BackgroundColor = 'w'; app.TextAreaInfo.FontColor = 'k'; 
            
            % Right Panel
            app.AxPista = uiaxes(app.GridLayout);
            app.AxPista.Layout.Row = 1; app.AxPista.Layout.Column = 2;
            app.AxPista.BackgroundColor = 'w';
            app.AxPista.XColor = 'k'; app.AxPista.YColor = 'k';
            
            app.startupFcn();
        end
    end 
end