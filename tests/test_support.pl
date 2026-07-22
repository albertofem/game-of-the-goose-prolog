:- module(oca_test_support,
          [ cleanup_dynamic_state/0,
            cleanup_ui/0,
            reset_game/1,
            setup_canvas/1,
            setup_event_canvas/2,
            setup_full_game_canvas/2,
            cleanup_canvas/1,
            set_location/2,
            set_turn/1,
            set_test_player_status/2,
            text_value/2
          ]).

:- use_module(library(pce)).

cleanup_dynamic_state :-
    retractall(user:turno(_)),
    retractall(user:ubicacion(_, _)),
    retractall(user:finDeJuego),
    retractall(user:tiradas(_)),
    retractall(user:numjug(_)),
    retractall(user:estado_jugador(_, _)),
    retractall(user:namejugador(_, _, _)),
    true.

cleanup_ui :-
    global_test_objects(Objects),
    maplist(free_if_object, Objects).

global_test_objects([
    @ayudam, @ayudab, @menu, @mprincipal, @inst, @ayuda, @salir,
    @config, @instrucciones, @labelint,
    @logs, @actual, @dado, @ocan, @ocan2, @dialogo,
    @fantasma, @estrella, @fondo, @tablerooca,
    @fichaj1, @fichaj2, @fichaj3, @fichaj4,
    @fichaj12, @fichaj22, @fichaj32, @fichaj42,
    @txjug1, @txjug2, @txjug3, @txjug4,
    @labelj1, @labelj2, @labelj3, @labelj4,
    @numJug, @submit, @lanzardado, @reiniciar, @salir_button,
    @stargame, @logt2, @buffer, @test_bitmap
]).

free_if_object(Object) :-
    (   object(Object)
    ->  free(Object)
    ;   true
    ).

reset_game(PlayerCount) :-
    cleanup_dynamic_state,
    user:inicializar,
    user:num_jugadores(PlayerCount),
    insert_test_players(PlayerCount).

insert_test_players(2) :-
    user:insert_jugador(2, 'Ana', 'Beto', '', '').
insert_test_players(3) :-
    user:insert_jugador(3, 'Ana', 'Beto', 'Cora', '').
insert_test_players(4) :-
    user:insert_jugador(4, 'Ana', 'Beto', 'Cora', 'Dani').

setup_canvas(Canvas) :-
    cleanup_ui,
    new(Canvas, picture),
    send(Canvas, size, size(1000, 566)).

setup_event_canvas(PlayerCount, Canvas) :-
    reset_game(PlayerCount),
    setup_canvas(Canvas),
    user:imagen(Canvas, @actual, actual, point(771, 31)),
    user:imagen(Canvas, @fantasma, fantasma, point(923, 469)).

setup_full_game_canvas(PlayerCount, Canvas) :-
    setup_event_canvas(PlayerCount, Canvas),
    user:crear_fichas(Canvas),
    user:send_log('Preparado', '', '', '', '', '', Canvas).

cleanup_canvas(Canvas) :-
    free_if_object(Canvas),
    cleanup_ui,
    cleanup_dynamic_state.

set_location(Player, Position) :-
    retractall(user:ubicacion(Player, _)),
    assertz(user:ubicacion(Player, Position)).

set_turn(Player) :-
    retractall(user:turno(_)),
    assertz(user:turno(Player)).

set_test_player_status(Player, Status) :-
    user:set_player_status(Player, Status).

text_value(TextObject, Value) :-
    get(TextObject, string, Value).
