# ModelacionPistaF1
Solución completa a un desafío de diseño e ingeniería civil/automotriz. El objetivo es modelar un tramo de pista de Fórmula Uno, con el uso de las matematicas y validar su diseño para garantizar la seguridad de los espectadores.

### 🎯 Objetivo del Proyecto
Diseñar una sección de pista de carreras a partir de dos puntos fijos (Pi y Pf), asegurando que el trazo cumpla con las restricciones de longitud y que las gradas se ubiquen en zonas libres de alto riesgo de derrape.

### 🛠️ Metodología y Conceptos Clave
El proyecto se desarrolla a través de un ciclo de diseño iterativo que utiliza herramientas avanzadas de Cálculo y Álgebra Lineal.
Se define una función polinomial cúbica f(x) = ax^3 + bx^2 + cx + d. 
Se establece nuestro sistema de 4 ecuaciones lineales (4x4) utilizando Pi,Pf y otros 2 puntos que propondra el usuario.
Los coeficientes (a, b, c, d) se obtienen resolviendo el sistema (4x4).
Filtro de Longitud: Se verifica que el diseño cumpla con la restricción de longitud de arco [300m, 500m] mediante la integración numérica de la fórmula de longitud.
Análisis de Seguridad: Se realiza un barrido a lo largo de toda la pista para calcular el Radio de Curvatura en cada metro, utilizando la primera y segunda derivada de la función.
Zona de Riesgo: Se identifican los intervalos donde el radio cae por debajo del límite crítico (R < 20m), ya que esto indica un alto riesgo de derrape y de que el vehículo salga disparado siguiendo la recta tangente. 
Diseño Final: Se proponen las coordenadas seguras para las gradas, garantizando una distancia mínima de 20m del eje de la pista y evitando las zonas de alto riesgo de impacto.

### ⚙️ Herramientas Utilizadas

MATLAB
