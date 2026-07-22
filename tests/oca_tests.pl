:- encoding(utf8).

:- use_module(library(plunit)).
:- use_module(library(pce)).
:- use_module(library(lists)).
:- ensure_loaded('../oca.pl').
:- use_module('test_support.pl').


:- begin_tests(oca_helpers).

test(nada_always_succeeds) :-
    user:nada(any_value).

test(juntar_concatenates_six_atoms) :-
    user:juntar('El ', juego, ' de ', la, ' ', 'OCA', Result),
    assertion(Result == 'El juego de la OCA').

test(juntar_converts_atomic_values) :-
    user:juntar('Casilla ', 6, ' + ', 6, ' = ', 12, Result),
    assertion(Result == 'Casilla 6 + 6 = 12').

test(send_prolog_writes_joined_message) :-
    with_output_to(atom(Output),
                   user:send_prolog('Jugador ', 2, ': ', 'avanza ', 4, ' casillas')),
    assertion(Output == 'Jugador 2: avanza 4 casillas').

test(cara_dado_maps_every_face) :-
    findall(Number-Resource,
            ( between(1, 6, Number),
              user:cara_dado(Number, Resource)
            ),
            Pairs),
    assertion(Pairs == [1-dado1, 2-dado2, 3-dado3,
                        4-dado4, 5-dado5, 6-dado6]).

test(dados_only_returns_all_valid_faces,
     [setup(set_random(seed(20260721)))]) :-
    findall(Roll,
            ( between(1, 200, _),
              user:dados(Roll)
            ),
            Rolls),
    assertion(forall(member(Roll, Rolls), between(1, 6, Roll))),
    sort(Rolls, Distinct),
    assertion(Distinct == [1, 2, 3, 4, 5, 6]).

:- end_tests(oca_helpers).


:- begin_tests(oca_configuration).

test(inicializar_replaces_all_game_state,
     [ setup(( oca_test_support:cleanup_dynamic_state,
               assertz(user:turno(4)),
               assertz(user:ubicacion(1, 40)),
               assertz(user:finDeJuego),
               assertz(user:tiradas(99)),
               assertz(user:turnosSinJugar(1, 7))
             )),
       cleanup(oca_test_support:cleanup_dynamic_state)
     ]) :-
    user:inicializar,
    findall(Turn, user:turno(Turn), Turns),
    findall(Player-Position, user:ubicacion(Player, Position), Locations),
    findall(Throws, user:tiradas(Throws), ThrowCounts),
    findall(Player-Blocked,
            user:turnosSinJugar(Player, Blocked),
            BlockedTurns),
    assertion(Turns == [1]),
    assertion(Locations == [1-1, 2-1, 3-1, 4-1]),
    assertion(ThrowCounts == [1]),
    assertion(BlockedTurns == [1-0, 2-0, 3-0, 4-0]),
    assertion(\+ user:finDeJuego),
    assertion(\+ user:carcel(_)).

test(num_jugadores_keeps_one_value,
     [cleanup(oca_test_support:cleanup_dynamic_state)]) :-
    user:num_jugadores(2),
    user:num_jugadores(4),
    findall(Count, user:numjug(Count), Counts),
    assertion(Counts == [4]).

test(insert_two_players_fills_unused_slots,
     [ setup(oca_test_support:cleanup_dynamic_state),
       cleanup(oca_test_support:cleanup_dynamic_state)
     ]) :-
    user:insert_jugador(2, 'Ada', 'Grace', ignored, ignored),
    findall(Id-Name-Colour,
            user:namejugador(Id, Name, Colour),
            Players),
    assertion(Players == [1-'Ada'-rojo, 2-'Grace'-rojo,
                          3-''-'', 4-''-'']).

test(insert_three_players_fills_last_slot,
     [ setup(oca_test_support:cleanup_dynamic_state),
       cleanup(oca_test_support:cleanup_dynamic_state)
     ]) :-
    user:insert_jugador(3, uno, dos, tres, ignored),
    findall(Id-Name,
            user:namejugador(Id, Name, _),
            Players),
    assertion(Players == [1-uno, 2-dos, 3-tres, 4-'']).

test(insert_four_players_preserves_order,
     [ setup(oca_test_support:cleanup_dynamic_state),
       cleanup(oca_test_support:cleanup_dynamic_state)
     ]) :-
    user:insert_jugador(4, uno, dos, tres, cuatro),
    findall(Id-Name,
            user:namejugador(Id, Name, _),
            Players),
    assertion(Players == [1-uno, 2-dos, 3-tres, 4-cuatro]).

test(player_count_controls_text_field_editability,
     [ setup(oca_test_support:setup_canvas(Canvas)),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:load_start(Canvas),
    user:load_textitems(2),
    get(@labelj3, editable, Player3AtTwo),
    get(@labelj4, editable, Player4AtTwo),
    assertion(Player3AtTwo == @off),
    assertion(Player4AtTwo == @off),
    assertion(user:numjug(2)),
    user:load_textitems(3),
    get(@labelj3, editable, Player3AtThree),
    get(@labelj4, editable, Player4AtThree),
    assertion(Player3AtThree == @on),
    assertion(Player4AtThree == @off),
    assertion(user:numjug(3)),
    user:load_textitems(4),
    get(@labelj4, editable, Player4AtFour),
    assertion(Player4AtFour == @on),
    assertion(user:numjug(4)).

test(text_field_positions_include_the_player_count_label) :-
    assertion(user:poss_textitem(0, 29, 186, @labelint)),
    assertion(user:poss_textitem(1, 29, 235, @labelj1)),
    assertion(user:poss_textitem(4, 29, 340, @labelj4)).

:- end_tests(oca_configuration).


:- begin_tests(oca_board).

test(board_has_exactly_one_coordinate_for_each_square) :-
    findall(Square, user:coords(Square, _, _), Squares),
    numlist(0, 63, Expected),
    assertion(Squares == Expected).

test(board_coordinates_are_unique_and_in_bounds) :-
    findall(X-Y, user:coords(_, X, Y), Coordinates),
    sort(Coordinates, Unique),
    length(Unique, 64),
    assertion(forall(member(X-Y, Coordinates),
                     (between(0, 661, X), between(0, 501, Y)))).

test(board_key_coordinates) :-
    assertion(user:coords(1, 14, 22)),
    assertion(user:coords(28, 92, 22)),
    assertion(user:coords(42, 581, 177)),
    assertion(user:coords(63, 438, 273)).

test(piece_offsets_are_applied_to_board_coordinates) :-
    user:pos_ficha(1, 10, X1, Y1),
    user:pos_ficha(2, 10, X2, Y2),
    user:pos_ficha(3, 10, X3, Y3),
    user:pos_ficha(4, 10, X4, Y4),
    assertion([X1-Y1, X2-Y2, X3-Y3, X4-Y4] ==
              [252-501, 267-501, 252-516, 267-516]).

test(piece_identifiers_map_to_expected_resources) :-
    assertion(user:identifica_ficha(@fantasma, 0, fantasma)),
    assertion(user:identifica_ficha(@fichaj1, 1, fichaverde)),
    assertion(user:identifica_ficha(@fichaj2, 2, fichaazul)),
    assertion(user:identifica_ficha(@fichaj3, 3, fichaamari)),
    assertion(user:identifica_ficha(@fichaj4, 4, ficharoja)).

test(turn_bar_coordinates_cover_every_player) :-
    findall(Player-X-Y, user:barras_turno(Player, X, Y), Bars),
    assertion(Bars == [0-0-0, 1-771-31, 2-771-70,
                       3-771-110, 4-771-149]).

test(winner_star_coordinates_cover_every_player) :-
    findall(Player-X-Y, user:estrella_ganador(Player, X, Y), Stars),
    assertion(Stars == [1-739-9, 2-739-47, 3-739-85, 4-739-124]).

test(every_playable_square_has_one_event) :-
    findall(Square, user:casillajug(Square, _), Squares),
    numlist(1, 63, Expected),
    assertion(Squares == Expected).

test(special_square_map_is_exact) :-
    findall(Square-Event,
            ( user:casillajug(Square, Event),
              Event \== noact
            ),
            Specials),
    assertion(Specials ==
              [5-oca, 6-puente, 9-oca, 12-puente, 14-oca,
               18-oca, 19-posada, 23-oca, 26-losdados, 27-oca,
               31-pozo, 32-oca, 36-oca, 41-oca, 42-laberinto,
               45-oca, 50-oca, 52-lacarcel, 53-losdados, 54-oca,
               58-calavera, 59-meta_oca, 63-meta]).

test(next_goose_sequence) :-
    findall(From-To,
            ( member(From, [5, 9, 14, 18, 23, 27, 32, 36, 41, 45, 50, 54]),
              user:siguiente_oca(From, To)
            ),
            Sequence),
    assertion(Sequence == [5-9, 9-14, 14-18, 18-23, 23-27, 27-32,
                           32-36, 36-41, 41-45, 45-50, 50-54, 54-63]).

test(next_goose_works_from_a_normal_square) :-
    user:siguiente_oca(37, Next),
    assertion(Next == 41).

test(no_goose_after_finish, [fail]) :-
    user:siguiente_oca(63, _).

test(bridges_are_bidirectional, [nondet]) :-
    user:siguiente_puente(6, FromSix),
    user:siguiente_puente(12, FromTwelve),
    assertion(FromSix == 12),
    assertion(FromTwelve == 6).

test(dice_squares_are_bidirectional, [nondet]) :-
    user:siguiente_dados(26, FromTwentySix),
    user:siguiente_dados(53, FromFiftyThree),
    assertion(FromTwentySix == 53),
    assertion(FromFiftyThree == 26).

test(all_image_resources_are_declared_and_loadable, [nondet]) :-
    Expected = [menu, salida, iniciar, ayuda, instrucciones,
                ayuda_menu, ayuda_back, config, instrucciones_v,
                tablero, dado1, dado2, dado3, dado4, dado5, dado6,
                actual, fondo_oca, oca_gif, oca_act, dialogo,
                fantasma, estrella, fichaazul, fichaamari,
                ficharoja, fichaverde],
    findall(Name, user:resource(Name, _, _), Names),
    assertion(Names == Expected),
    forall(member(Name, Names),
           setup_call_cleanup(
               new(Bitmap, bitmap(resource(Name))),
               ( get(Bitmap, width, Width),
                 get(Bitmap, height, Height),
                 assertion(Width > 0),
                 assertion(Height > 0)
               ),
               free(Bitmap))).

:- end_tests(oca_board).


:- begin_tests(oca_state).

test(new_position_regular_move) :-
    user:newpos(20, 4, Position),
    assertion(Position == 24).

test(new_position_can_land_exactly_on_finish) :-
    user:newpos(60, 3, Position),
    assertion(Position == 63).

test(new_position_bounces_after_finish) :-
    user:newpos(60, 6, Position),
    assertion(Position == 60).

test(new_position_always_stays_on_board) :-
    assertion(forall((between(1, 63, Start), between(1, 6, Roll)),
                     (user:newpos(Start, Roll, End), between(1, 63, End)))).

test(moveplayer_updates_one_location,
     [ setup(oca_test_support:reset_game(4)),
       cleanup(oca_test_support:cleanup_dynamic_state)
     ]) :-
    user:moveplayer(1, 4),
    findall(Position, user:ubicacion(1, Position), Positions),
    assertion(Positions == [5]).

test(moveplayer_bounces_after_finish,
     [ setup(( oca_test_support:reset_game(4),
               oca_test_support:set_location(1, 61)
             )),
       cleanup(oca_test_support:cleanup_dynamic_state)
     ]) :-
    user:moveplayer(1, 4),
    assertion(user:ubicacion(1, 61)).

test(moveplayer_stays_at_finish,
     [ setup(( oca_test_support:reset_game(4),
               oca_test_support:set_location(1, 63)
             )),
       cleanup(oca_test_support:cleanup_dynamic_state)
     ]) :-
    user:moveplayer(1, 6),
    assertion(user:ubicacion(1, 63)).

test(moveplayer_casilla_moves_directly,
     [ setup(oca_test_support:reset_game(4)),
       cleanup(oca_test_support:cleanup_dynamic_state)
     ]) :-
    user:moveplayer_casilla(2, 42),
    assertion(user:ubicacion(2, 42)).

test(next_player_wraps_for_two_players,
     [ setup(oca_test_support:reset_game(2)),
       cleanup(oca_test_support:cleanup_dynamic_state)
     ]) :-
    user:siguiente_jugador(1, Second),
    user:siguiente_jugador(2, First),
    assertion(Second == 2),
    assertion(First == 1).

test(next_player_wraps_for_four_players,
     [ setup(oca_test_support:reset_game(4)),
       cleanup(oca_test_support:cleanup_dynamic_state)
     ]) :-
    findall(Current-Next,
            ( between(1, 4, Current),
              user:siguiente_jugador(Current, Next)
            ),
            Sequence),
    assertion(Sequence == [1-2, 2-3, 3-4, 4-1]).

test(crossing_jail_releases_imprisoned_player,
     [ setup(( oca_test_support:reset_game(4),
               oca_test_support:set_blocked_turns(2, 999)
             )),
       cleanup(oca_test_support:cleanup_dynamic_state)
     ]) :-
    user:salir_carcel(2, 51, 53),
    assertion(user:turnosSinJugar(2, 0)).

test(landing_on_jail_does_not_release_player,
     [ setup(( oca_test_support:reset_game(4),
               oca_test_support:set_blocked_turns(2, 999)
             )),
       cleanup(oca_test_support:cleanup_dynamic_state)
     ]) :-
    user:salir_carcel(2, 51, 52),
    assertion(user:turnosSinJugar(2, 999)).

test(crossing_jail_does_not_change_normal_penalty,
     [ setup(( oca_test_support:reset_game(4),
               oca_test_support:set_blocked_turns(2, 2)
             )),
       cleanup(oca_test_support:cleanup_dynamic_state)
     ]) :-
    user:salir_carcel(2, 51, 53),
    assertion(user:turnosSinJugar(2, 2)).

test(player_already_past_jail_does_not_release_prisoner,
     [ setup(( oca_test_support:reset_game(4),
               oca_test_support:set_blocked_turns(2, 999)
             )),
       cleanup(oca_test_support:cleanup_dynamic_state)
     ]) :-
    user:salir_carcel(2, 52, 58),
    assertion(user:turnosSinJugar(2, 999)).

:- end_tests(oca_state).


:- begin_tests(oca_ui).

test(resized_window_can_be_replaced_without_ending_application,
     [ setup(( new(Original, window('OCA lifecycle original')),
               new(Replacement, window('OCA lifecycle replacement'))
             )),
       cleanup(( (object(Original) -> free(Original) ; true),
                 (object(Replacement) -> free(Replacement) ; true)
               )),
       nondet
     ]) :-
    user:application_open_frame_count(Baseline),
    send(Original, open),
    send(Original, size, size(420, 280)),
    send(Replacement, open),
    user:application_open_frame_count(WithBothWindows),
    assertion(WithBothWindows =:= Baseline + 2),
    send(Original, destroy),
    user:application_open_frame_count(AfterReplacement),
    assertion(AfterReplacement =:= Baseline + 1),
    send(Replacement, destroy),
    user:application_open_frame_count(AfterClosingBoth),
    assertion(AfterClosingBoth =:= Baseline).

test(imagen_loads_and_positions_a_resource,
     [ setup(oca_test_support:setup_canvas(Canvas)),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:imagen(Canvas, @test_bitmap, dado1, point(10, 20)),
    assertion(object(@test_bitmap)),
    get(@test_bitmap, x, X),
    get(@test_bitmap, y, Y),
    assertion(X == 10),
    assertion(Y == 20).

test(dialogue_text_is_wrapped_inside_the_vignette,
     [ setup(oca_test_support:setup_canvas(Canvas)),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:send_log('"', 'Jugador',
                  '" está encerrado en la cárcel\ny saldrá cuando alguien pase ',
                  '\npor esa posición =(', '', '', Canvas),
    assertion(object(@logs)),
    get(@logs, width, Width),
    get(@logs, height, Height),
    get(@logs, margin, Margin),
    get(@logs, wrap, Wrap),
    get(@logs, x, X),
    get(@logs, y, Y),
    assertion(Width == 190),
    assertion(Margin == 190),
    assertion(Wrap == wrap_fixed_width),
    assertion(Height =< 174),
    assertion(X == 765),
    assertion(Y == 185).

test(send_log_replaces_previous_text,
     [ setup(oca_test_support:setup_canvas(Canvas)),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:send_log('primero', '', '', '', '', '', Canvas),
    user:send_log('segundo ', 2, '', '', '', '', Canvas),
    oca_test_support:text_value(@logs, Value),
    assertion(Value == 'segundo 2').

test(two_player_game_removes_unused_pieces,
     [ setup(oca_test_support:setup_event_canvas(2, Canvas)),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:crear_fichas(Canvas),
    assertion(object(@fichaj1)),
    assertion(object(@fichaj2)),
    assertion(\+ object(@fichaj3)),
    assertion(\+ object(@fichaj4)),
    get(@txjug1, string, PlayerOne),
    get(@txjug2, string, PlayerTwo),
    assertion(PlayerOne == 'Ana'),
    assertion(PlayerTwo == 'Beto').

test(four_player_game_keeps_every_piece,
     [ setup(oca_test_support:setup_event_canvas(4, Canvas)),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:crear_fichas(Canvas),
    assertion(object(@fichaj1)),
    assertion(object(@fichaj2)),
    assertion(object(@fichaj3)),
    assertion(object(@fichaj4)),
    get(@txjug4, string, PlayerFour),
    assertion(PlayerFour == 'Dani').

test(three_player_game_removes_only_fourth_piece,
     [ setup(oca_test_support:setup_event_canvas(3, Canvas)),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:crear_fichas(Canvas),
    assertion(object(@fichaj1)),
    assertion(object(@fichaj2)),
    assertion(object(@fichaj3)),
    assertion(\+ object(@fichaj4)).

test(menu_content_can_be_built_off_screen,
     [ setup(oca_test_support:setup_canvas(Canvas)),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:remenu(Canvas),
    assertion(object(@menu)),
    assertion(object(@mprincipal)),
    assertion(object(@inst)),
    assertion(object(@ayuda)),
    assertion(object(@salir)),
    get(@mprincipal, cursor, Cursor),
    assertion(Cursor == @hand2_cursor).

test(help_content_can_be_built_off_screen,
     [ setup(oca_test_support:setup_canvas(Canvas)),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:lanzar_ayuda(Canvas),
    assertion(object(@ayudam)),
    assertion(object(@ayudab)),
    get(@ayudab, cursor, Cursor),
    assertion(Cursor == @hand2_cursor).

test(instructions_content_can_be_built_off_screen,
     [ setup(oca_test_support:setup_canvas(Canvas)),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:instrucciones(Canvas),
    assertion(object(@instrucciones)),
    assertion(object(@ayudab)).

test(configuration_content_can_be_built_off_screen,
     [ setup(oca_test_support:setup_canvas(Canvas)),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:config(Canvas),
    assertion(object(@config)),
    assertion(object(@numJug)),
    assertion(object(@labelj1)),
    assertion(object(@labelj4)),
    assertion(object(@submit)),
    get(@numJug, selection, Selection),
    assertion(Selection == 4),
    assertion(user:numjug(4)).

test(menu_cleanup_is_idempotent,
     [ setup(oca_test_support:setup_canvas(Canvas)),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:remenu(Canvas),
    user:free_menu,
    user:free_menu,
    assertion(\+ object(@menu)),
    assertion(\+ object(@mprincipal)).

test(game_ui_cleanup_removes_created_objects,
     [ setup(oca_test_support:setup_full_game_canvas(4, Canvas)),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:imagen(Canvas, @dialogo, dialogo, point(750, 175)),
    user:imagen(Canvas, @ocan2, oca_act, point(865, 390)),
    user:free_all,
    assertion(\+ object(@fichaj1)),
    assertion(\+ object(@actual)),
    assertion(\+ object(@logs)),
    assertion(\+ object(@dialogo)),
    assertion(\+ object(@ocan2)).

:- end_tests(oca_ui).


:- begin_tests(oca_events).

test(normal_square_advances_turn,
     [ setup(oca_test_support:setup_event_canvas(4, Canvas)),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:noact(1, Canvas),
    assertion(user:turno(2)),
    assertion(object(@ocan)).

test(normal_square_wraps_turn_to_first_player,
     [ setup(( oca_test_support:setup_event_canvas(4, Canvas),
               oca_test_support:set_turn(4)
             )),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:noact(4, Canvas),
    assertion(user:turno(1)).

test(normal_square_skips_one_blocked_player,
     [ setup(( oca_test_support:setup_event_canvas(4, Canvas),
               oca_test_support:set_blocked_turns(2, 2)
             )),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:noact(1, Canvas),
    assertion(user:turno(3)),
    assertion(user:turnosSinJugar(2, 1)).

test(goose_moves_to_next_goose_and_keeps_turn,
     [ setup(( oca_test_support:setup_event_canvas(4, Canvas),
               oca_test_support:set_location(1, 5)
             )),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:oca(1, Canvas),
    assertion(user:ubicacion(1, 9)),
    assertion(user:turno(1)),
    oca_test_support:text_value(@logs, Text),
    assertion(sub_atom(Text, _, _, _, 'Tira de nuevo')).

test(bridge_moves_between_six_and_twelve,
     [ setup(( oca_test_support:setup_event_canvas(4, Canvas),
               oca_test_support:set_location(1, 6)
             )),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:puente(1, Canvas),
    assertion(user:ubicacion(1, 12)),
    oca_test_support:set_location(1, 12),
    user:puente(1, Canvas),
    assertion(user:ubicacion(1, 6)),
    assertion(user:turno(1)).

test(dice_event_moves_between_twenty_six_and_fifty_three,
     [ setup(( oca_test_support:setup_event_canvas(4, Canvas),
               oca_test_support:set_location(1, 26)
             )),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:losdados(1, Canvas),
    assertion(user:ubicacion(1, 53)),
    oca_test_support:set_location(1, 53),
    user:losdados(1, Canvas),
    assertion(user:ubicacion(1, 26)),
    assertion(user:turno(1)).

test(skull_returns_player_to_start_and_keeps_turn,
     [ setup(( oca_test_support:setup_event_canvas(4, Canvas),
               oca_test_support:set_location(1, 58)
             )),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:calavera(1, Canvas),
    assertion(user:ubicacion(1, 1)),
    assertion(user:turno(1)).

test(maze_returns_player_to_thirty_and_advances_turn,
     [ setup(( oca_test_support:setup_event_canvas(4, Canvas),
               oca_test_support:set_location(1, 42)
             )),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:laberinto(1, Canvas),
    assertion(user:ubicacion(1, 30)),
    assertion(user:turno(2)).

test(maze_skips_and_decrements_a_blocked_next_player,
     [ setup(( oca_test_support:setup_event_canvas(4, Canvas),
               oca_test_support:set_location(1, 42),
               oca_test_support:set_blocked_turns(2, 1)
             )),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:laberinto(1, Canvas),
    assertion(user:ubicacion(1, 30)),
    assertion(user:turno(3)),
    assertion(user:turnosSinJugar(2, 0)).

test(inn_blocks_player_for_one_turn,
     [ setup(( oca_test_support:setup_event_canvas(4, Canvas),
               oca_test_support:set_location(1, 19)
             )),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:posada(1, Canvas),
    assertion(user:turnosSinJugar(1, 1)),
    assertion(user:turno(2)).

test(well_blocks_player_for_two_turns,
     [ setup(( oca_test_support:setup_event_canvas(4, Canvas),
               oca_test_support:set_location(1, 31)
             )),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:pozo(1, Canvas),
    assertion(user:turnosSinJugar(1, 2)),
    assertion(user:turno(2)).

test(jail_blocks_player_until_someone_passes,
     [ setup(( oca_test_support:setup_event_canvas(4, Canvas),
               oca_test_support:set_location(1, 52)
             )),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:lacarcel(1, Canvas),
    assertion(user:turnosSinJugar(1, 999)),
    assertion(user:turno(2)).

test(finish_marks_game_over_and_draws_winner,
     [ setup(( oca_test_support:setup_event_canvas(4, Canvas),
               oca_test_support:set_location(1, 63)
             )),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:meta(1, Canvas),
    assertion(user:finDeJuego),
    assertion(object(@estrella)),
    oca_test_support:text_value(@logs, Text),
    assertion(sub_atom(Text, _, _, _, 'ha ganado el juego')),
    assertion(sub_atom(Text, _, _, _, 'Total de tiradas: 1')).

test(square_fifty_nine_goes_directly_to_finish,
     [ setup(( oca_test_support:setup_event_canvas(4, Canvas),
               oca_test_support:set_location(1, 59)
             )),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:meta_oca(1, Canvas),
    assertion(user:ubicacion(1, 63)),
    assertion(user:finDeJuego).

test(check_square_dispatches_normal_event,
     [ setup(( oca_test_support:setup_event_canvas(4, Canvas),
               oca_test_support:set_location(1, 2)
             )),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:check_casilla(1, Canvas),
    assertion(user:turno(2)).

test(check_square_dispatches_special_event,
     [ setup(( oca_test_support:setup_event_canvas(4, Canvas),
               oca_test_support:set_location(1, 5)
             )),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:check_casilla(1, Canvas),
    assertion(user:ubicacion(1, 9)),
    assertion(user:turno(1)).

test(full_roll_updates_counter_position_turn_and_die,
     [ setup(( oca_test_support:setup_full_game_canvas(4, Canvas),
               set_random(seed(42))
             )),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:empezar_todo(Canvas),
    assertion(user:tiradas(2)),
    assertion(user:ubicacion(1, 3)),
    assertion(user:turno(2)),
    assertion(object(@dado)).

test(game_over_makes_roll_a_no_op,
     [ setup(( oca_test_support:setup_full_game_canvas(4, Canvas),
               assertz(user:finDeJuego)
             )),
       cleanup(oca_test_support:cleanup_canvas(Canvas)),
       nondet
     ]) :-
    user:empezar_todo(Canvas),
    assertion(user:tiradas(1)),
    assertion(user:ubicacion(1, 1)),
    assertion(user:turno(1)).

:- end_tests(oca_events).
