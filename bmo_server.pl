:- module(bmo_server,
    [ server/1,
      start/0
    ]).

/*
   Servidor HTTP de BMO.

   Este archivo conecta la interfaz con el motor de reglas de
   bmo_diagnostico.pl. Requiere SWI-Prolog.

   Ejecutar desde esta carpeta:

       swipl -q -s bmo_server.pl

   Después abre http://localhost:8080
*/

:- use_module('./bmo_diagnostico.pl').
:- use_module(library(apply)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_files)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/http_server)).
:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_cors)).

:- set_setting(http:cors, ['*']).

:- http_handler(root(api/estado), estado_handler, [method(get)]).
:- http_handler(root(api/diagnostico), diagnostico_handler, [methods([post, options])]).

static_directory(BaseDir, BaseDir) :-
    directory_file_path(BaseDir, 'index.html', Index),
    exists_file(Index),
    !.
static_directory(BaseDir, StaticDir) :-
    directory_file_path(BaseDir, 'diagnostico-usb', StaticDir).

:- prolog_load_context(directory, BaseDir),
   static_directory(BaseDir, StaticDir),
   http_handler(root(.),
                http_reply_from_files(StaticDir, [index_files(['index.html'])]),
                [prefix]).

server(Port) :-
    http_server(http_dispatch, [port(Port)]),
    format('BMO conectado a SWI-Prolog en http://localhost:~w~n', [Port]).

start :-
    current_prolog_flag(argv, Args),
    port_from_args(Args, Port),
    server(Port),
    thread_get_message(_).

port_from_args(Args, Port) :-
    (   member(Argument, Args),
        sub_atom(Argument, 0, 7, _, '--port='),
        sub_atom(Argument, 7, _, 0, PortAtom),
        atom_number(PortAtom, Port)
    ->  true
    ;   Port = 8080
    ).

estado_handler(_Request) :-
    cors_enable,
    reply_json_dict(_{
        ok: true,
        connected: true,
        engine: 'SWI-Prolog',
        module: 'bmo_diagnostico',
        predicate: 'diagnostico/6'
    }).

diagnostico_handler(Request) :-
    (   memberchk(method(options), Request)
    ->  cors_enable(Request, [methods([post]), headers([content_type, accept])])
    ;   cors_enable,
    http_read_json_dict(Request, Payload),
    payload_to_query(Payload, Equipo, Respuestas),
    bmo_diagnostico:diagnostico(
        Equipo,
        Respuestas,
        Regla,
        Resultado,
        Recomendacion,
        Hora
    ),
    bmo_diagnostico:regla(Regla, Caso, _ResultadoRegla, _RecomendacionRegla),
    prolog_call(Equipo, Respuestas, Consulta),
    reply_json_dict(_{
        ok: true,
        connected: true,
        engine: 'SWI-Prolog',
        equipment: Equipo,
        rule: Regla,
        case: Caso,
        result: Resultado,
        recommendation: Recomendacion,
        time: Hora,
        prolog_call: Consulta
    })
    ).

payload_to_query(Payload, Equipo, Respuestas) :-
    get_dict(equipment, Payload, RawEquipo),
    text_value(RawEquipo, Equipo),
    get_dict(answers, Payload, Answers),
    maplist(answer_from_dict(Answers), [r1, r2, r3, r4], Respuestas).

answer_from_dict(Answers, Rule, respuesta(Rule, Value)) :-
    get_dict(Rule, Answers, RawValue),
    answer_value(RawValue, Value).

answer_value(RawValue, Value) :-
    text_value(RawValue, Text),
    string_lower(Text, Lower),
    atom_string(RawAtom, Lower),
    answer_alias(RawAtom, Value),
    memberchk(Value, [si, no, pendiente]),
    !.

answer_alias(yes, si).
answer_alias(si, si).
answer_alias(no, no).
answer_alias(pending, pendiente).
answer_alias(pendiente, pendiente).

text_value(Value, Text) :-
    (   string(Value)
    ->  Text = Value
    ;   atom(Value)
    ->  atom_string(Value, Text)
    ;   term_string(Value, Text)
    ).

prolog_call(Equipo, Respuestas, Consulta) :-
    Respuestas = [respuesta(R1, V1), respuesta(R2, V2),
                  respuesta(R3, V3), respuesta(R4, V4)],
    format(string(Consulta),
           'diagnostico(~q, [respuesta(~w, ~w), respuesta(~w, ~w), respuesta(~w, ~w), respuesta(~w, ~w)], Regla, Resultado, Recomendacion, Hora).',
           [Equipo, R1, V1, R2, V2, R3, V3, R4, V4]).

:- initialization(start, main).

