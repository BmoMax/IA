:- module(bmo_diagnostico,
    [ diagnosticar/5,
      diagnostico/6,
      regla/4,
      ejemplo/0
    ]).

/*
   BMO - Sistema experto para diagnosticar el arranque de una computadora.

   Cada respuesta debe tener este formato:

     respuesta(r1, si).
     respuesta(r2, no).
     respuesta(r3, pendiente).
     respuesta(r4, no).

   Valores permitidos: si, no, pendiente.
*/

valor_respuesta(si).
valor_respuesta(no).
valor_respuesta(pendiente).

regla(r1,
      'No recibe corriente',
      'Falla de alimentacion',
      'Revisar el cable, la toma electrica, el adaptador y el conector de carga.').
regla(r2,
      'Tiene corriente, pero no enciende',
      'Problema de encendido',
      'Comprobar la fuente de poder, el boton de encendido y los indicadores de la tarjeta madre.').
regla(r3,
      'Enciende, pero no muestra imagen',
      'Problema de video',
      'Revisar el monitor, el cable de video, la entrada seleccionada y la tarjeta grafica.').
regla(r4,
      'Enciende y muestra imagen',
      'Arranque correcto',
      'No se observa una falla dentro de estas cuatro reglas.').

regla_valida(R) :- regla(R, _, _, _).

respuesta_valida(respuesta(R, Valor)) :-
    regla_valida(R),
    valor_respuesta(Valor).

respuestas_completas(Respuestas) :-
    is_list(Respuestas),
    length(Respuestas, 4),
    maplist(respuesta_valida, Respuestas),
    forall(regla_valida(R), member(respuesta(R, _), Respuestas)).

respuestas_si(Respuestas, ReglasSi) :-
    findall(R, member(respuesta(R, si), Respuestas), ReglasSi).

respuestas_pendientes(Respuestas, ReglasPendientes) :-
    findall(R, member(respuesta(R, pendiente), Respuestas), ReglasPendientes).

% diagnosticar(-Regla, -Resultado, -Recomendacion, +Respuestas, +NombreEquipo)
diagnosticar(NombreEquipo, Respuestas, Regla, Resultado, Recomendacion) :-
    nonvar(NombreEquipo),
    respuestas_completas(Respuestas),
    respuestas_si(Respuestas, ReglasSi),
    respuestas_pendientes(Respuestas, ReglasPendientes),
    resolver_respuestas(ReglasSi, ReglasPendientes, Regla, Resultado, Recomendacion).

resolver_respuestas([R], _, R, Resultado, Recomendacion) :-
    regla(R, _Caso, Resultado, Recomendacion).
resolver_respuestas(ReglasSi, _, revisar, 'Respuestas contradictorias', Recomendacion) :-
    length(ReglasSi, Cantidad),
    Cantidad > 1,
    format(atom(Recomendacion),
           'Hay varias respuestas SI (~w). Deja solo un caso principal como SI.',
           [ReglasSi]).
resolver_respuestas([], ReglasPendientes, pendiente, 'Diagnostico pendiente', Recomendacion) :-
    ReglasPendientes \= [],
    format(atom(Recomendacion),
           'Falta comprobar: ~w. Marca SI o NO cuando puedas observar el equipo.',
           [ReglasPendientes]).
resolver_respuestas([], [], sin_coincidencia, 'Sin coincidencia',
                    'Los cuatro casos quedaron en NO. Revisa nuevamente el arranque de la computadora.').

% Igual que diagnosticar/5, pero agrega la hora del reporte.
diagnostico(NombreEquipo, Respuestas, Regla, Resultado, Recomendacion, Hora) :-
    diagnosticar(NombreEquipo, Respuestas, Regla, Resultado, Recomendacion),
    get_time(Tiempo),
    format_time(atom(Hora), '%Y-%m-%d %H:%M:%S', Tiempo).

ejemplo :-
    Respuestas = [
        respuesta(r1, no),
        respuesta(r2, si),
        respuesta(r3, no),
        respuesta(r4, no)
    ],
    diagnostico('Laptop de Wilson', Respuestas, Regla, Resultado, Recomendacion, Hora),
    format('Equipo: ~w~nRegla: ~w~nResultado: ~w~nRecomendacion: ~w~nHora: ~w~n',
           ['Laptop de Wilson', Regla, Resultado, Recomendacion, Hora]).

/* Consultas de ejemplo en SWI-Prolog:

   ?- [bmo_diagnostico].
   ?- ejemplo.

   ?- diagnostico('Laptop de Wilson',
          [respuesta(r1,no), respuesta(r2,si),
           respuesta(r3,no), respuesta(r4,no)],
          Regla, Resultado, Recomendacion, Hora).

   ?- diagnosticar('Equipo 1',
          [respuesta(r1,pendiente), respuesta(r2,no),
           respuesta(r3,no), respuesta(r4,no)],
          Regla, Resultado, Recomendacion).
*/

