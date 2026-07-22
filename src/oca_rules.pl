:- module(oca_rules,
          [ new_position/3,
            next_player/3,
            next_playable_player/5,
            crosses_jail/2,
            next_goose/2,
            paired_square/3,
            prepare_players/3,
            player_colour/2,
            player_piece/2,
            valid_player_status/1
          ]).

/** <module> Pure rules for Game of the Goose

None of the predicates in this module mutate the Prolog database or create
XPCE objects.  The UI layer owns persistence and rendering; this module owns
validation and deterministic rule calculations.
*/

:- use_module(oca_board, [casillajug/2]).
:- use_module(library(error), [must_be/2]).
:- use_module(library(lists), [same_length/2]).

%!  new_position(+Current, +Roll, -Next) is det.

new_position(Current, Roll, Next) :-
    must_be(integer, Current),
    must_be(integer, Roll),
    (   between(1, 63, Current)
    ->  true
    ;   domain_error(board_position, Current)
    ),
    (   between(1, 6, Roll)
    ->  true
    ;   domain_error(die_roll, Roll)
    ),
    Forward is Current + Roll,
    (   Forward > 63
    ->  Next is 126 - Forward
    ;   Next = Forward
    ).

%!  next_player(+Current, +PlayerCount, -Next) is det.

next_player(Current, PlayerCount, Next) :-
    must_be(integer, Current),
    must_be(integer, PlayerCount),
    (   between(2, 4, PlayerCount)
    ->  true
    ;   domain_error(player_count, PlayerCount)
    ),
    (   between(1, PlayerCount, Current)
    ->  true
    ;   domain_error(player_number, Current)
    ),
    (   Current =:= PlayerCount
    ->  Next = 1
    ;   Next is Current + 1
    ).

%!  next_playable_player(+Current, +PlayerCount, +Statuses0,
%!                       -Next, -Statuses) is det.
%
%   Statuses is an association list Player-Status, where Status is ready,
%   skip(N), or jailed.  Every skipped player has one turn consumed while
%   searching, and any number of consecutive blocked players is handled.
%   Next is none only when every active player is jailed.

next_playable_player(Current, PlayerCount, Statuses0, Next, Statuses) :-
    validate_statuses(PlayerCount, Statuses0),
    (   active_player_can_eventually_move(PlayerCount, Statuses0)
    ->  next_player(Current, PlayerCount, Candidate),
        find_playable(Candidate, PlayerCount, Statuses0, Next, Statuses)
    ;   Next = none,
        Statuses = Statuses0
    ).

find_playable(Candidate, PlayerCount, Statuses0, Next, Statuses) :-
    memberchk(Candidate-Status, Statuses0),
    (   Status == ready
    ->  Next = Candidate,
        Statuses = Statuses0
    ;   Status == jailed
    ->  next_player(Candidate, PlayerCount, Following),
        find_playable(Following, PlayerCount, Statuses0, Next, Statuses)
    ;   Status = skip(Turns),
        consume_skipped_turn(Turns, NewStatus),
        replace_status(Candidate, NewStatus, Statuses0, Statuses1),
        next_player(Candidate, PlayerCount, Following),
        find_playable(Following, PlayerCount, Statuses1, Next, Statuses)
    ).

consume_skipped_turn(1, ready) :- !.
consume_skipped_turn(Turns, skip(Remaining)) :-
    Remaining is Turns - 1.

replace_status(Player, Status, [Player-_|Rest], [Player-Status|Rest]) :- !.
replace_status(Player, Status, [Pair|Rest0], [Pair|Rest]) :-
    replace_status(Player, Status, Rest0, Rest).

active_player_can_eventually_move(PlayerCount, Statuses) :-
    member(Player-Status, Statuses),
    between(1, PlayerCount, Player),
    Status \== jailed,
    !.

validate_statuses(PlayerCount, Statuses) :-
    must_be(list, Statuses),
    numlist(1, PlayerCount, Players),
    pairs_keys(Statuses, StatusPlayers),
    (   same_length(Players, StatusPlayers),
        Players == StatusPlayers
    ->  true
    ;   domain_error(player_statuses, Statuses)
    ),
    maplist(valid_status_pair, Statuses).

pairs_keys([], []).
pairs_keys([Key-_|Pairs], [Key|Keys]) :-
    pairs_keys(Pairs, Keys).

valid_status_pair(_-Status) :-
    (   valid_player_status(Status)
    ->  true
    ;   domain_error(player_status, Status)
    ).

valid_player_status(ready).
valid_player_status(jailed).
valid_player_status(skip(Turns)) :-
    integer(Turns),
    Turns > 0.

crosses_jail(From, To) :-
    From < 52,
    To > 52.

next_goose(Current, Next) :-
    casillajug(Next, Event),
    Next > Current,
    memberchk(Event, [oca, meta]),
    !.

paired_square(Event, Current, Next) :-
    memberchk(Event, [puente, losdados]),
    casillajug(Next, Event),
    Next \= Current.

%!  prepare_players(+PlayerCount, +RawNames, -Players) is det.
%
%   Players is a list of player(Id, Name, Colour, PieceResource).  Names are
%   trimmed, non-empty, unique ignoring case, and limited to 20 characters so
%   they fit the fixed-width game panel.

prepare_players(PlayerCount, RawNames, Players) :-
    must_be(integer, PlayerCount),
    (   between(2, 4, PlayerCount)
    ->  true
    ;   domain_error(player_count, PlayerCount)
    ),
    must_be(list, RawNames),
    length(ActiveRawNames, PlayerCount),
    (   append(ActiveRawNames, _, RawNames)
    ->  true
    ;   domain_error(player_names, RawNames)
    ),
    maplist(normalise_player_name, ActiveRawNames, Names),
    ensure_unique_names(Names),
    numlist(1, PlayerCount, Ids),
    maplist(make_player, Ids, Names, Players).

normalise_player_name(RawName, Name) :-
    text_string(RawName, RawString),
    normalize_space(string(Trimmed), RawString),
    (   Trimmed == ""
    ->  domain_error(non_empty_player_name, RawName)
    ;   true
    ),
    string_length(Trimmed, Length),
    (   Length =< 20
    ->  true
    ;   domain_error(player_name_max_20_characters, RawName)
    ),
    atom_string(Name, Trimmed).

text_string(Value, String) :-
    (   string(Value)
    ->  String = Value
    ;   atom(Value)
    ->  atom_string(Value, String)
    ;   is_list(Value)
    ->  string_chars(String, Value)
    ;   type_error(text, Value)
    ).

ensure_unique_names(Names) :-
    maplist(downcase_atom, Names, FoldedNames),
    sort(FoldedNames, UniqueNames),
    length(FoldedNames, Count),
    length(UniqueNames, UniqueCount),
    (   Count =:= UniqueCount
    ->  true
    ;   domain_error(unique_player_names, Names)
    ).

make_player(Id, Name, player(Id, Name, Colour, Piece)) :-
    player_colour(Id, Colour),
    player_piece(Id, Piece).

player_colour(1, verde).
player_colour(2, azul).
player_colour(3, amarillo).
player_colour(4, rojo).

player_piece(1, fichaverde).
player_piece(2, fichaazul).
player_piece(3, fichaamari).
player_piece(4, ficharoja).
