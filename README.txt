BMO
===

Prototipo HTML de un sistema experto para diagnosticar cuatro estados básicos
de arranque de una computadora, usando la mascota robot como guía visual.
La interfaz funciona en modo manual: el usuario responde cada uno de los
cuatro casos con Sí, No o Pendiente. BMO reconoce una regla cuando el caso se
marca como Sí. Cada diagnóstico muestra el nombre del equipo, la hora, el
resultado, la regla aplicada y el camino en el árbol de estados.

Archivos
--------
index.html  Aplicación completa (HTML, CSS y JavaScript).
mascota.png Imagen adjunta usada en la animación.
logo-bmo.png Logo BMO usado en la interfaz.

Cómo ejecutarlo
---------------
1. Abre una terminal en esta carpeta.
2. Ejecuta:

   python -m http.server 8123

3. Abre en Chrome o Edge:

   http://localhost:8123/index.html

Uso manual
----------
1. Escribe el nombre de la laptop.
2. En cada caso R1, R2, R3 y R4 pulsa Sí, No o Pendiente.
3. Cuando las cuatro reglas tengan respuesta, pulsa "Analizar caso".
4. BMO reconoce la regla cuando existe una sola respuesta Sí.
5. Si hay más de un Sí, BMO pide revisar las respuestas.
6. Revisa el reporte con la hora, el resultado y la recomendación.

Reglas implementadas
--------------------
R1  No tiene corriente -> revisar cable y conexión.
R2  Tiene corriente y no enciende -> posible problema de alimentación.
R3  Enciende y no muestra imagen -> revisar monitor o cable de video.
R4  Enciende y muestra imagen -> inicio correcto.

El prototipo es una recomendación educativa. No realiza reparaciones físicas
ni sustituye una revisión técnica.

