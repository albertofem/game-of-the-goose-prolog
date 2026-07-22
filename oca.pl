:- encoding(utf8).

% *******************************************************
% 
% El juego de la OCA gráfica, Programado en Prolog + XPCE
% Por: Alberto Fernández Martínez, 1º de Ing. Informática
% Universidad de Alicante, Lógica Computacional
% 
% *******************************************************

% Cargamos las librerías XPCE

:- use_module(library(pce)).
:- use_module(library(random), [random_between/3]).
:- use_module('src/oca_board.pl').
:- use_module('src/oca_rules.pl', []).

% Le indicamos el directorio base donde estarán ubicadas las imágenes de
% nuestro programa, el tablero, los dados, las fichas, etc...

:- prolog_load_context(directory, ProjectDir),
   directory_file_path(ProjectDir, assets, AssetsDir),
   pce_image_directory(AssetsDir).

% ******** OPERACIONES INICIALES ********
% 
% Limpiamos la pantalla y generamos los recursos que vamos a usar, la
% imagen del tablero, los distintos menús, fondos, en defintiva, los
% gráficos del programa
% 
% ***************************************


% Imágenes del menú principal

resource(menu, menu, image('menu_oca.jpg')).
resource(salida, salida, image('salida.jpg')).
resource(iniciar, iniciarjuego, image('iniciar_juego.jpg')).
resource(ayuda, ayuda, image('ayuda.jpg')).
resource(instrucciones, instrucciones, image('instrucciones.jpg')).

% Pantalla de ayuda

resource(ayuda_menu, ayudam, image('ayuda_menu.jpg')).
resource(ayuda_back, ayudab, image('back_ayuda.jpg')).

% Pantalla de configuración

resource(config, config, image('config.jpg')).

% Pantalla de instrucciones

resource(instrucciones_v, image, image('instrucciones_v.jpg')).

% Todas las imágenes de la pantalla de la OCA

resource(tablero, image, image('tablero.jpg')).     
resource(dado1, image, image('dado1.gif')).          
resource(dado2, image, image('dado2.gif')).
resource(dado3, image, image('dado3.gif')).
resource(dado4, image, image('dado4.gif')).
resource(dado5, image, image('dado5.gif')).
resource(dado6, image, image('dado6.gif')).
resource(actual, image, image('actual2.gif')).       
resource(fondo_oca, image, image('fondo.jpg')).      
resource(oca_gif, image, image('ocanormal.gif')).    
resource(oca_act, image, image('ocaact.gif')).
resource(dialogo, imagen, image('dialogo.gif')).    
resource(fantasma, imagen, image('fantasma.gif')).  
resource(estrella, imagen, image('estrella.gif')).   

% Fichas de los jugadores

resource(fichaazul, fichaazul, image('ficha_azul.gif')).
resource(fichaamari, image, image('ficha_amarillo.gif')).
resource(ficharoja, image, image('ficha_roja.gif')).
resource(fichaverde, image, image('ficha_verde.gif')).

% ******** PREDICADOS AUXILIARES ********
% 
% Predicados que se van a usar en muchos otros subprogramas
% 
% ***************************************


% Este predicado nos creará una imagen a partir de un recurso.

imagen(Ventana, Figura, Imagen, Posicion) :-
	new(Figura, figure),
	new(Bitmap, bitmap(resource(Imagen))),
	send(Bitmap, name, 1),
	send(Figura, display, Bitmap),
	send(Figura, status, 1),
	send(Ventana, display, Figura, Posicion).

% Juntar una cadena de 6 cadenas y variables

juntar(Cosa1, Cosa2, Cosa3, Cosa4, Cosa5, Cosa6, Resultado):-
	atom_concat(Cosa1,Cosa2,Cosa11),
	atom_concat(Cosa11,Cosa3,Cosa22),
        atom_concat(Cosa22,Cosa4,Cosa33),
	atom_concat(Cosa33,Cosa5,Cosa44),
	atom_concat(Cosa44,Cosa6,Resultado).

% Las pantallas usan fondos rasterizados y coordenadas fijas. Impedir que el
% usuario cambie su tamaño evita recortes y controles desalineados.

fixed_window(Title, Size, Window):-
	new(Window, window(Title, Size)),
	send(Window, can_resize, @off).


% ******** PREDICADOS DINÁMICOS  ********
% 
% Todos los predicados dinámicos que vamos a usar en nuestro juego, con
% un pequeño comentario como aclaración al lado
% 
% ***************************************

:- dynamic turno/1.             % Este predicado controla el turno
:- dynamic ubicacion/2.
:- dynamic finDeJuego/0.
:- dynamic tiradas/1.           % Número de tiradas de una partida
:- dynamic numjug/1.            % Número de jugadores de la partida
:- dynamic estado_jugador/2.    % ready, skip(N) o jailed
:- dynamic namejugador/3.       % Identificador, nombre y color


% ******** PREDICADOS DEL INICIO ********
% 
% Aquí están todos los predicados iniciales que cargan el menú
% principal, la pantalla de ayuda, la de instrucciones, el modo
% configuración, etc...
% 
% ***************************************


% Función que reseteará todas las variables dinámicas para crear un
% juego nuevo independientemente de los anteriores. Se usará en la
% ventana de la OCA

inicializar:-
	
	retractall(turno(_)),
	assertz(turno(1)),
	retractall(ubicacion(_,_)),
	assertz(ubicacion(1, 1)),
	assertz(ubicacion(2, 1)),
	assertz(ubicacion(3, 1)),
	assertz(ubicacion(4, 1)),
	retractall(finDeJuego),
	retractall(tiradas(_)),
	assertz(tiradas(1)),
	retractall(estado_jugador(_,_)),
	assertz(estado_jugador(1, ready)),
	assertz(estado_jugador(2, ready)),
	assertz(estado_jugador(3, ready)),
	assertz(estado_jugador(4, ready)).

% Usaremos este predicado en todas las secciones del menú para liberar
% las imágenes previas, etc... 

free_menu:-
	free(@ayudam),
	free(@ayudab),
	free(@menu),
	free(@mprincipal),
	free(@inst),
	free(@ayuda),
	free(@salir),
	free(@config),
	free(@labelj1),
	free(@labelj2),
	free(@labelj3),	
	free(@labelj4),
	free(@numJug),
	free(@submit),
	free(@instrucciones).


% Menú principal de la OCA.

menu_principal:-
	
	% Borramos los jugadores anteriores. No se hace en la ventana de la OCA 
	% para que nos permita reiniciar un juego y no perder los datos de los jugadores
	retractall(namejugador(_, _, _)),
	
	% En los predicados que se ejecutan al principio hay que liberar las variables
	% a mano, o tirará error	
	free(@menu),
	free(@mprincipal),
	free(@inst),
	free(@ayuda),
	free(@salir),
	free(@config),
	
	fixed_window('El Juego de la OCA: Menú Principal', size(800, 600), Menu),
	
	% Imprimimos las imágenes del menú principal en sus respectivas posiciones
	imagen(Menu, @menu, menu, point(0,0)),
	imagen(Menu, @mprincipal, iniciar, point(33, 186)),
	imagen(Menu, @inst, instrucciones, point(32, 238)),
	imagen(Menu, @ayuda, ayuda, point(82, 284)),
	imagen(Menu, @salir, salida, point(84, 336)),
	
	% A continuación, le asignamos la propiedad para poder capturar los clicks 
	% de ratón del usuario, y ejecutamos una acción
	
	send(@mprincipal, recogniser,
	     click_gesture(left, '', single,
			   message(@prolog, config, Menu))),
	
	send(@inst, recogniser,
	     click_gesture(left, '', single,
			   message(@prolog, instrucciones, Menu))),	
	
	send(@ayuda, recogniser,
	     click_gesture(left, '', single,
			   message(@prolog, lanzar_ayuda, Menu))),	
	
	send(@salir, recogniser,
	     click_gesture(left, '', single,
			   message(Menu, destroy))),
	
	% Ahora le asignamos un cursos para cuando pasamos el ratón por encima
	send(@mprincipal, cursor, hand2),
	send(@ayuda, cursor, hand2),
	send(@salir, cursor, hand2),
	send(@inst, cursor, hand2),	
	
	send(Menu, open_centered).      % Abrimos el menú centrado

% Punto de entrada de la aplicación. El bucle consulta las ventanas abiertas
% después de cada evento. Esto permite sustituir el menú por el tablero (y
% viceversa) sin que el proceso termine al destruir la ventana anterior.

start(_Argv):-
	write('\033[2J'),
	write('[p] Creando imágenes...\n'),
	write('[p] Creando imágenes de la OCA...\n'),
	write('[p] Creando fichas de los jugadores...\n'),
	write('[p] Creando predicados dinámicos...\n'),
	write('[p] Lanzando menú principal...\n'),
	menu_principal.

application_open_frame_count(Count):-
	get(@display?frames, find_all, @arg1?kind == toplevel, Frames),
	get(Frames, size, Count).

application_event_loop:-
	application_open_frame_count(Count),
	(   Count =:= 0
	->  true
	;   (   catch(send(@display, dispatch), Error,
			  print_message(error, Error))
	    ->  true
	    ;   true
	    ),
	    application_event_loop
	).

oca_main:-
	current_prolog_flag(argv, Argv),
	start(Argv),
	application_event_loop.

:- initialization(oca_main, main).

% Esta regla la creé ya que cuando salimos del tablero de la OCA,
% volvemos al menú principal para iniciar otra partida, ver la ayuda,
% etc... Intentar ejecutar esta regla nada más compilar tiraba error

remenu2:-

	retractall(namejugador(_, _, _)),
	
	free_menu, 
	
	fixed_window('El Juego de la OCA: Menú Principal', size(800, 600), Menu),
	
	imagen(Menu, @menu, menu, point(0,0)),
	imagen(Menu, @mprincipal, iniciar, point(33, 186)),
	imagen(Menu, @inst, instrucciones, point(32, 238)),
	imagen(Menu, @ayuda, ayuda, point(82, 284)),
	imagen(Menu, @salir, salida, point(84, 336)),
	
	send(@mprincipal, recogniser,
	     click_gesture(left, '', single,
			   message(@prolog, config, Menu))),
	
	send(@inst, recogniser,
	     click_gesture(left, '', single,
			   message(@prolog, instrucciones, Menu))),	
	
	send(@ayuda, recogniser,
	     click_gesture(left, '', single,
			   message(@prolog, lanzar_ayuda, Menu))),	
	
	send(@salir, recogniser,
	     click_gesture(left, '', single,
			   message(Menu, destroy))),
	
	send(@mprincipal, cursor, hand2),
	send(@ayuda, cursor, hand2),
	send(@salir, cursor, hand2),
	send(@inst, cursor, hand2),	
	
	send(Menu, open_centered).

% Finalmente, una regla similar que nos borre las variables de imágenes,
% textos, etc... de las distintas pantallas del menú principal para
% mostrar el menu principal del juego. Se necesita usar este predicado
% para evitar molestar al usuario cerrando y abriendo ventanas cada vez
% que pase de un menú a otro

remenu(Menu):-
	
	free_menu,
	
	imagen(Menu, @menu, menu, point(0,0)),
	imagen(Menu, @mprincipal, iniciar, point(33, 186)),
	imagen(Menu, @inst, instrucciones, point(32, 238)),
	imagen(Menu, @ayuda, ayuda, point(82, 284)),
	imagen(Menu, @salir, salida, point(84, 336)),
	
	send(@mprincipal, recogniser,
	     click_gesture(left, '', single,
			   message(@prolog, config, Menu))),
	
	send(@inst, recogniser,
	     click_gesture(left, '', single,
			   message(@prolog, instrucciones, Menu))),	
	
	send(@ayuda, recogniser,
	     click_gesture(left, '', single,
			   message(@prolog, lanzar_ayuda, Menu))),	
	
	send(@salir, recogniser,
	     click_gesture(left, '', single,
			   message(Menu, destroy))),
	
	send(@mprincipal, cursor, hand2),
	send(@ayuda, cursor, hand2),
	send(@salir, cursor, hand2),
	send(@inst, cursor, hand2).	

% La ventana de ayuda

lanzar_ayuda(Menu):-
	
	free_menu,
	
	imagen(Menu, @ayudam, ayuda_menu, point(0,0)),
	imagen(Menu, @ayudab, ayuda_back, point(578, 538)),
	
	send(@ayudab, recogniser,
	     click_gesture(left, '', single,
			   message(@prolog, remenu, Menu))),
	
	send(@ayudab, cursor, hand2).

% Ventana de las Instrucciones

instrucciones(Menu):-
	
	free_menu,
	
	imagen(Menu, @instrucciones, instrucciones_v, point(0,0)),
	imagen(Menu, @ayudab, ayuda_back, point(578, 538)),
	
	send(@ayudab, recogniser,
	     click_gesture(left, '', single,
			   message(@prolog, remenu, Menu))),
	
	send(@ayudab, cursor, hand2).
	
	
% *** Pantalla de configuración ***
% 
% Las siguientes reglas controlan todo lo que refiere a la pantalla de
% configuración, y merecen una descripción aparte
% 
% *********************************

% Aquí voy a almacenar las posiciones en la cuadrícula de los cuadros de
% texto de cada jugador, y del seleccionador del número de jugadores

poss_textitem(0, 29, 186, @labelint).
poss_textitem(1, 29, 235, @labelj1).
poss_textitem(2, 29, 270, @labelj2).
poss_textitem(3, 29, 305, @labelj3).
poss_textitem(4, 29, 340, @labelj4).

% Este predicado obtiene las coordenadas de un cuadro de texto y lo
% dibuja con una serie de propiedades

load_textitem(Num, Menu):-
	
	poss_textitem(Num, X, Y, Var),
	
	atom_concat('Jugador ', Num, Label),
	
	send(Menu, display, new(Var, text_item(Label)), point(X, Y)),
	send(Var, length, 20),
	send(Var, editable, true). 

% Con este predicado hacemos que un cuadro de texto no sea editable, por
% lo tanto, el usuario no podrá modificar su valor

free_textitems(Num):-
	
	poss_textitem(Num, _, _, Label),
	
	send(Label, editable, false).

unfree_textitems(Num):-
	
	poss_textitem(Num, _, _, Label),
	
	send(Label, editable, true).
	
% Con este otro cargamos la cantidad de cuadros de textos que nos pida
% el usuario. Si nos piden menos de 4, hacemos el resto no editables

load_textitems(2):-
	
	free_textitems(3),
	free_textitems(4),
	num_jugadores(2).

load_textitems(3):-
	
	unfree_textitems(3),
	free_textitems(4),
	num_jugadores(3).

load_textitems(4):-
	
	unfree_textitems(3),
	unfree_textitems(4),
	num_jugadores(4).

% Cargamos todos los cuadros de texto al principio para luego ir
% modificando los que se nos pidan

load_start(Menu):-
	
	load_textitem(1, Menu),
	load_textitem(2, Menu),
	load_textitem(3, Menu),
	load_textitem(4, Menu),
	num_jugadores(4).

% Introducimos el número de jugadores que harán uso de la partida

num_jugadores(Num):-
	must_be(integer, Num),
	(   between(2, 4, Num)
	->  true
	;   domain_error(player_count, Num)
	),
	retractall(numjug(_)),
	assertz(numjug(Num)).

% Valida y reemplaza la configuración completa de jugadores de forma atómica.
% Los colores coinciden ahora con las fichas que se dibujan en el tablero.

insert_jugador(Num, P1, P2, P3, P4):-
	oca_rules:prepare_players(Num, [P1, P2, P3, P4], Players),
	retractall(namejugador(_, _, _)),
	forall(member(player(Id, Name, Colour, _), Players),
	       assertz(namejugador(Id, Name, Colour))),
	fill_unused_players(Num).

fill_unused_players(Num):-
	forall(between(1, 4, Id),
	       (   Id =< Num
	       ->  true
	       ;   assertz(namejugador(Id, '', ''))
	       )).

start_configured_game(Menu, Num, P1, P2, P3, P4):-
	catch(( insert_jugador(Num, P1, P2, P3, P4),
	        go,
	        send(Menu, destroy)
	      ),
	      Error,
	      report_configuration_error(Error)).

report_configuration_error(Error):-
	configuration_error_message(Error, Message),
	send(@display, inform, Message).

configuration_error_message(error(domain_error(non_empty_player_name, _), _),
			    'Todos los jugadores necesitan un nombre.') :- !.
configuration_error_message(error(domain_error(player_name_max_20_characters, _), _),
			    'Los nombres pueden tener como máximo 20 caracteres.') :- !.
configuration_error_message(error(domain_error(unique_player_names, _), _),
			    'Los nombres de los jugadores deben ser distintos.') :- !.
configuration_error_message(Error, Message):-
	message_to_string(Error, Message).
	
% Por último, creamos la pantalla de configuración, usando todas las
% reglas anteriores

config(Menu):-
	
	free_menu,
	
	imagen(Menu, @config, config, point(0,0)),
	imagen(Menu, @ayudab, ayuda_back, point(578, 538)),
	
	send(@ayudab, recogniser,
	     click_gesture(left, '', single,
			   message(@prolog, remenu, Menu))),
	
	send(@ayudab, cursor, hand2),
	
	% Sacamos los cuadros de texto de configuración
	send(Menu, display, new(@numJug, 
				int_item('Número de jugadores', 4, 
					 message(@prolog, load_textitems, @numJug?selection))),
	     point(29, 190)),
	
	send(@numJug, range(low := 2, high := 4)),    % Definimos un rango máximo y mínimo
	
	load_start(Menu),
       	
	% Botón para iniciar el juego. Insertará todos los jugadores y lanzará la ventana de la OCA
	% También destruye la ventana actual
	
	send(Menu, display, new(@submit, button('Iniciar juego',
						message(@prolog, start_configured_game, Menu,
							@numJug?selection,
							@labelj1?value, @labelj2?value,
							@labelj3?value, @labelj4?value))),
	     point(29, 480)).



% ******** PREDICADOS REFERENTES AL JUEGO DE LA OCA ********
% 
% Aquí irán todos los predicados referentes al juego de la OCA, la
% ventana principal, las posiciones de los jugadores y un largo etc.
% 
% **********************************************************

% Programa principal que lanza la oca y todo el resto de funciones
 
go :-
	
	% Borramos todo indicio de juego anterior
	inicializar,
	
	% Creamos la ventana donde irá nuestro tablero y todo lo demás
	fixed_window('Juego de la Oca', size(1000, 566), Oca),
	
	% Liberamos variables
	free_all,
	
	imagen(Oca, @fondo, fondo_oca, point(0,0)),
	imagen(Oca, @tablerooca, tablero, point(0, 0)),
	
	% Creamos la imagen, la 'rallita' que irá debajo de cada jugador para indicar el turno
	imagen(Oca, @actual, actual, point(770, 30)),
	
	% Llamamos a otro predicado para crear las fichas
	crear_fichas(Oca),
	
	% Creamos un botón para lanzar los dados que llamará a la regla principal del juego	
	send(Oca, display, new(@lanzardado, 
			       button('Tirar',
				      message(@prolog, empezar_todo, Oca))),
	     point(900, 8)),
	
	% Botón para reiniciar el juego
	send(Oca, display, new(@reiniciar, 
			       button('Reiniciar',
				      and(
					  message(Oca, destroy),
					  message(@prolog, go)))), 
	     point(740, 531)),
	
	% Botón para salir
	send(Oca, display, new(@salir_button, 
			       button('Salir',
				      and(
					  message(Oca, destroy),
					  message(@prolog, remenu2)))),
	     point(900, 531)),
	
	% La imagen de la simpática OCA y su viñeta
	imagen(Oca, @dialogo, dialogo, point(750, 175)),
	imagen(Oca, @ocan2, oca_act, point(865, 390)),
	
	% Imprimimos el nombre del jugador que tiene el primer turno
	namejugador(1, Name, _),
	send_log('Bienvenido al juego de la OCA. \n\nEmpieza el jugador "', Name, '"', '', '', '', Oca),
	
	send(Oca, open_centered).

% Esto nos permite liberar todas las variables seteadas

free_all:-
	free(@tablerooca),
	free(@fichaj1),
	free(@fichaj2),
	free(@fichaj3),
	free(@fichaj4),
	free(@fichaj12),
	free(@fichaj22),
	free(@fichaj32),
	free(@fichaj42),
	free(@txjug1),
	free(@txjug2),
	free(@txjug3),
	free(@txjug4),
	free(@lanzardado),
	free(@stargame),
	free(@actual),
	free(@dado),
	free(@logt2),
	free(@logs),
	free(@buffer),
	free(@reiniciar),
	free(@salir_button),
	free(@fondo),
	free(@ocan),
	free(@ocan2),
	free(@dialogo),
	free(@fantasma),
	free(@estrella).

% Esto crea todas las fichas, con sus respectivos colores, y los textos
% de jcada jugador. También borrar aquellas fichas de jugadores que no
% vayan a jugar (como cuando escogemos que halla sólo 2 jugadores)

crear_fichas(Oca):-
	
	% Creamos dos fichas de cada, una para indicar, y otra para moverla por el escenario
	imagen(Oca, @fichaj1, fichaverde, point(739,9)),
	imagen(Oca, @fichaj2, fichaazul, point(739,47)),
	imagen(Oca, @fichaj3, fichaamari, point(739,85)),
	imagen(Oca, @fichaj4, ficharoja, point(739,124)),
	imagen(Oca, @fichaj12, fichaverde, point(739,9)),
	imagen(Oca, @fichaj22, fichaazul, point(739,47)),
	imagen(Oca, @fichaj32, fichaamari, point(739,85)),
	imagen(Oca, @fichaj42, ficharoja, point(739,124)),
	
	% Dibujamos el texto de cada jugador
	namejugador(1, Name1, _), namejugador(2, Name2, _), namejugador(3, Name3, _), namejugador(4, Name4, _),
	send(Oca, display, new(@txjug1, text(Name1)), point(774,6)),
	send(Oca, display, new(@txjug2, text(Name2)), point(774,45)),
	send(Oca, display, new(@txjug3, text(Name3)), point(774,83)),
	send(Oca, display, new(@txjug4, text(Name4)), point(774,122)),
	
	% Fuente de los textos
	send(@txjug1, font, font('Arial', sans, 14)),
	send(@txjug2, font, font('Arial', bold, 14)),
	send(@txjug3, font, font('Arial', bold, 14)),
	send(@txjug4, font, font('Arial', bold, 14)),
	
	numjug(NumJug),
	
	(   NumJug =:= 2
	->  borrar_fichas(3),
	    borrar_fichas(4)
	;   NumJug =:= 3
	->  borrar_fichas(4)
	;   true
	).

% Predicado para borrar las fichas que no vayan a ser utilizadas

borrar_fichas(3):-
	
	free(@fichaj3),
	free(@fichaj4),
	free(@fichaj32),
        free(@fichaj42).

borrar_fichas(4):-
	
	free(@fichaj4),
	free(@fichaj42).

% Las coordenadas que debemos sumar a cada cuadro de casilla para
% colocar las fichas dentro de la cuadrícula de modo correcto

posicion_ficha(0, 0, 0).
posicion_ficha(1, 0, 0).
posicion_ficha(2, 15, 0).
posicion_ficha(3, 0, 15).
posicion_ficha(4, 15, 15).

% Calcular la posición de una ficha en una determinada casilla

pos_ficha(IDficha, Casilla, PosX, PosY):-
	
	coords(Casilla, X, Y),
	
	posicion_ficha(IDficha, Xpos, Ypos),
	
	PosX is Xpos+X,
	PosY is Ypos+Y.

% Identificamos cada ficha con su variable y su color

identifica_ficha(@fantasma, 0, fantasma).
identifica_ficha(@fichaj1, 1, fichaverde).
identifica_ficha(@fichaj2, 2, fichaazul).
identifica_ficha(@fichaj3, 3, fichaamari).
identifica_ficha(@fichaj4, 4, ficharoja).

% Predicado para mover una ficha a una posición

move_ficha(IDficha, X, Y, Oca):-
	
	identifica_ficha(Ficha, IDficha, Color),
	
	send(Ficha, destroy),
	imagen(Oca, Ficha, Color, point(X,Y)).

% Predicado para mover una ficha a una casilla

move_ficha_casilla(IDficha, Casilla, Oca):-
	pos_ficha(IDficha, Casilla, PosX, PosY),
	move_ficha(IDficha, PosX, PosY, Oca).

% Predicado que carga la imagen del la cara del dado con valor X

cara_dado(Num, Resource):-
	
	atom_concat('dado', Num, Resource).
	
% Obtener un número al azar del 1 al 6 // From: Fases OCA

dados(X):-
	random_between(1, 6, X).

% Utilizamos este predicado para enviar texto al log de la OCA

send_log(Msg1, Msg2, Msg3, Msg4, Msg5, Msg6, Oca):-
	free(@logs),
	juntar(Msg1, Msg2, Msg3, Msg4, Msg5, Msg6, Resultado),	
        send(Oca, display, new(@logs, text(Resultado)), point(765, 185)),
        send(@logs, font, font('Arial', normal, 12)),          % Fuente
        send(@logs, margin, 190, wrap_fixed_width).            % Ajustar el texto a la viñeta

% Y este otro predicado para imprimir un mensaje por la consola de
% Prolog

send_prolog(Msg1, Msg2, Msg3, Msg4, Msg5, Msg6):-
	juntar(Msg1, Msg2, Msg3, Msg4, Msg5, Msg6, Resultado),
	write(Resultado).

% *** Secuencia principal del juego ***
% 
% Este predicado lo controlará todo, se encarga de obtener la posición
% del jugador, tirar el dado, mover la ficha, etc...
%
% *************************************

empezar_todo(_):-
	finDeJuego,
	!.
empezar_todo(Oca):-
	turno(none),
	!,
	send_log('No hay jugadores disponibles para continuar.', '', '', '', '', '', Oca).
empezar_todo(Oca):-
	
	% Liberamos la ficha fantasma y la volvemos a crear para moverla posteriormente
	free(@fantasma),
	imagen(Oca, @fantasma, fantasma, point(923, 469)),
       
	send(@logs, clear),
	
	% Obtener el número de tiradas que llevamos hasta ahora y sumarle
	tiradas(Tiradas),
	
	TiradasNew is Tiradas+1,
	retractall(tiradas(_)),
	assertz(tiradas(TiradasNew)),

	free(@dado),
	
	% Obtenemos el turno del jugador actual
	turno(TurnoA),
	
	dados(N),
	
	% Liberamos a todos los jugadores encarcelados si se cruza la casilla 52.
	ubicacion(TurnoA, CarcelP),
	newpos(CarcelP, N, NewPossC),
	release_jailed_players(CarcelP, NewPossC),
	
	% Imprimimos la cara del dado correspondiende
	cara_dado(N, Imagen),
	imagen(Oca, @dado, Imagen, point(900, 35)),
	
	% Movemos al jugador
	moveplayer(TurnoA, N),
	
	% Chequeamos si el jugador ha caido en una casilla con evento
	check_casilla(TurnoA, Oca),
	
	turno(SiguienteJugador),	

	% Cambiamos la barra de turno 
	cambia_token(SiguienteJugador, Oca),
	
	% Obtenemos la ubicacion del jugador nueva
	ubicacion(TurnoA, Poss),
	
	% Movemos la ficha de la casilla anterior a la siguiente
	move_ficha_casilla(TurnoA, Poss, Oca).

% *** Miscelánea ***
% 
% Predicados varios que se usan a lo largo de las reglas 
% de eventos
% 
% ******************

% Posiciones de las barras de turno

barras_turno(0, 0, 0).
barras_turno(1, 771, 31).
barras_turno(2, 771, 70).
barras_turno(3, 771, 110).
barras_turno(4, 771, 149).

% Regla que cambia las barras de turno

cambia_token(none, Oca):-
	!,
	send(@actual, destroy),
	imagen(Oca, @actual, actual, point(0, 0)).
cambia_token(Siguiente, Oca):-

	barras_turno(Siguiente, X, Y),
	
	send(@actual, destroy),
	imagen(Oca, @actual, actual, point(X,Y)).

% Cuando un usuario cae en una casilla con evento, hacemos que la oca
% "hable"

animar_oca(Oca):-
	
	free(@ocan),
	free(@ocan2),
	
        imagen(Oca, @ocan2, oca_act, point(865, 390)).

% Este predicado imprime la ficha fantasma en una casilla determinada
% 
fantasma(Casilla, Oca):-
	
	move_ficha_casilla(0, Casilla, Oca).

% Creamos las posiciones de la estrellita que cargará encima de la ficha
% del ganador

estrella_ganador(1, 739, 9).
estrella_ganador(2, 739, 47).
estrella_ganador(3, 739, 85).
estrella_ganador(4, 739, 124).

% Y finalmente, otro perdicado para imprimir la estrella en una
% determinada posición

ganador_imagen(IDplayer, Oca):-
	
	estrella_ganador(IDplayer, X, Y),
	imagen(Oca, @estrella, estrella, point(X, Y)).

% Calcular la nueva posición del jugador teniendo en cuenta que no
% sobrepase de la casilla 63

newpos(PosA,N,NewPos):-
	oca_rules:new_position(PosA, N, NewPos).

% Regla para mover al jugador X posiciones

moveplayer(Jug,N):-
	
        ubicacion(Jug, X),
	(   X =:= 63
	->  NewPos = 63
	;   newpos(X, N, NewPos)
	),
	retractall(ubicacion(Jug, _)),
	assertz(ubicacion(Jug, NewPos)).

% Mover un jugador a una casilla determinada

moveplayer_casilla(Jug, N):-
	retractall(ubicacion(Jug, _)),
	assertz(ubicacion(Jug, N)).

% Calcular el siguiente jugador en base al total de jugadores

siguiente_jugador(Actual,Siguiente):-
	numjug(NumJugadores),
	oca_rules:next_player(Actual, NumJugadores, Siguiente).

set_player_status(Player, Status):-
	must_be(integer, Player),
	(   between(1, 4, Player)
	->  true
	;   domain_error(player_number, Player)
	),
	oca_rules:valid_player_status(Status),
	retractall(estado_jugador(Player, _)),
	assertz(estado_jugador(Player, Status)).

active_player_statuses(Statuses):-
	numjug(NumJugadores),
	findall(Player-Status,
	        ( between(1, NumJugadores, Player),
	          estado_jugador(Player, Status)
	        ),
	        Statuses).

apply_player_statuses([]).
apply_player_statuses([Player-Status|Statuses]):-
	set_player_status(Player, Status),
	apply_player_statuses(Statuses).

advance_turn(Current, Next):-
	numjug(NumJugadores),
	active_player_statuses(Statuses0),
	oca_rules:next_playable_player(Current, NumJugadores,
	                               Statuses0, Next, Statuses),
	apply_player_statuses(Statuses),
	retractall(turno(_)),
	assertz(turno(Next)).

% *** Salir de la cárcel ***
% 
% A este regla le pasamos la posición anterior y nueva de un jugador
% para fijarnos si ha pasado por la cárcel. En caso afirmativo, lo
% liberar de la cárcel y seguirá jugando. Se repite por cada jugador, y
% no importa si está en la cárcel o no, pues siempre devuelve 'Yes'
% 
% **************************

salir_carcel(IDplayer, PossAct, Next):-
	(   oca_rules:crosses_jail(PossAct, Next),
	    estado_jugador(IDplayer, jailed)
	->  set_player_status(IDplayer, ready)
	;   true
	).

release_jailed_players(PossAct, Next):-
	numjug(NumJugadores),
	forall(between(1, NumJugadores, Player),
	       salir_carcel(Player, PossAct, Next)).

	

% ******** CASILLAS CON EVENTOS ESPECIALES ********
% 
% En esta sección están todos los predicados de los eventos especiales,
% que cargarán cuando el usuario caiga en la correspondiente casilla
% 
% ************************************************* 

% *** Casilla de la meta ***
% 
% Al llegar a la meta, introduce el perdicado dinámico finDeJuego/0 para
% que no pueda continuar e imprime un mensaje del ganador. También
% dibuja la estrella y obtienes el total de tiradas
% 
% **************************

meta(IDplayer, Oca):-
	
	animar_oca(Oca),
	( finDeJuego -> true ; assertz(finDeJuego) ),

        namejugador(IDplayer, Name, _),
        tiradas(Tiradas),
	
	send_log('¡"', Name, '" ha ganado el juego! =\'D', '\n\nTotal de tiradas: ', Tiradas, '', Oca),
	cambia_token(IDplayer, Oca),
	
	ganador_imagen(IDplayer, Oca).

% Este regla es para cuando un jugador caiga en la posición 59, la OCA
% en dónde ganará directamente

meta_oca(IDplayer, Oca):-
	moveplayer_casilla(IDplayer, 63),
	meta(IDplayer, Oca).

% Predicado para calcular la siguiente OCA

siguiente_oca(Actual, Siguiente):-
	oca_rules:next_goose(Actual, Siguiente).

% *** Evento de la OCA ***
% 
% Este evento obtiene la siguiente OCA y mueve al jugado hasta ella
% pero antes imprime la ficha fantasma, para indicar en que casilla 
% había caido anteriormente
% 
% ************************

oca(IDplayer, Oca):-
	
	animar_oca(Oca),
	
	ubicacion(IDplayer, OcaActual),	
	namejugador(IDplayer, Name, _),
	
	siguiente_oca(OcaActual, SiguienteOca),
	fantasma(OcaActual, Oca),
	
	moveplayer_casilla(IDplayer, SiguienteOca),
       
	send_log(Name, ' ha caido en la OCA\ny salta de la casilla ', OcaActual, '\na la casilla ', SiguienteOca, '\n\n¡Tira de nuevo!', Oca).

% *** Evento de la Calavera ***
% 
% Es sencillo, lleva al jugador a la casilla 1 y le deja tirar
% de nuevo
% 
% *****************************

calavera(IDplayer, Oca):-
	animar_oca(Oca),
        fantasma(58, Oca),
	namejugador(IDplayer, Name, _),
        moveplayer_casilla(IDplayer, 1),
	send_log('', Name, '" ha caido en la calavera\ny vuelve al inicio =(', '', '\n\n', '', Oca).

% Calculamos el siguiente puente en base a la posición actual

siguiente_puente(Actual, Siguiente):-
	oca_rules:paired_square(puente, Actual, Siguiente).

% *** Evento del Puente ***
% 
% Llevamos al usuario al siguiente o al anterior puente y le dejamos
% tirar de nuevo. El funcionamiento es similar que con la OCA
% 
% *************************

puente(IDplayer, Oca):-
	
	animar_oca(Oca),
	
        namejugador(IDplayer, Name, _),
	ubicacion(IDplayer, PuenteActual),
	
	fantasma(PuenteActual, Oca),
	siguiente_puente(PuenteActual, Next),
	
	atom_concat('\na la casilla ', Next, Concat),
	send_log('"', Name, '" ha caido en el puente\ny salta de la casilla ', PuenteActual, Concat, '\n\n¡Tira de nuevo!', Oca),
	
	moveplayer_casilla(IDplayer, Next).

% Calculamos la siguiente posición de los dados

siguiente_dados(Actual, Siguiente):-
	oca_rules:paired_square(losdados, Actual, Siguiente).

% *** Evento de los Dados ***
% 
% Similar al puente
% 
% ***************************

losdados(IDplayer, Oca):-
	
	animar_oca(Oca),
	
	namejugador(IDplayer, Name, _),
	ubicacion(IDplayer, DadosActual),
	
	fantasma(DadosActual, Oca),	
	siguiente_dados(DadosActual, Next),
	
	send_log('"', Name, '" ha caido en los dados\ny salta de la casilla ', DadosActual, '\na la casilla ', Next, Oca),
	
	moveplayer_casilla(IDplayer, Next).

% *** Evento del Laberinto ***
% 
% Cuando un jugador caiga aquí se le llevará a la casilla 30, pero
% seguirá el turno, es decir, no tirará de nuevo
% 
% ****************************

laberinto(IDplayer, Oca):-
	
	animar_oca(Oca),
	
	namejugador(IDplayer, Name, _),
	
	send_log('"', Name, '" se pierde en el laberinto\ny vuelve a la casilla 30\n', '', '\n\n', '', Oca),
	
	moveplayer_casilla(IDplayer, 30),
	advance_turn(IDplayer, _).

% *** Evento de la Posada ***
% 
% Cuando un jugador activa este evento, se introduce en la base de conocimientos
% el número de turnos que estará bloqueado, y que se irán restando cuando el jugador
% anterior al bloqueado tire dado
% 
% ***************************

posada(IDplayer, Oca):-
	
	animar_oca(Oca),
	
	set_player_status(IDplayer, skip(1)),
	
	namejugador(IDplayer, Name, _),
	
	send_log('"', Name, '" ha caido en la posada\ny estará 1 turno sin jugar. ','', '', '', Oca),
	
	advance_turn(IDplayer, _).

% *** Evento del Pozo ***
% 
% Similar al de la Posada, pero en vez de 1 turno, 2
% 
% ***********************

pozo(IDplayer, Oca):-
	
	animar_oca(Oca),
	
	set_player_status(IDplayer, skip(2)),
	
	namejugador(IDplayer, Name, _),
	
	send_log('"', Name, '" ha caido en el pozo\ny estará 2 turnos sin jugar =( ','', '', '', Oca),
	
	advance_turn(IDplayer, _).

% *** Evento de la Cárcel ***
% 
% Un jugador encarcelado permanece en estado `jailed` hasta que otro jugador
% cruce la casilla 52. No se usa un número mágico de turnos.
% 
% ***************************

lacarcel(IDplayer, Oca):-
	
	animar_oca(Oca),
	
	set_player_status(IDplayer, jailed),
	
	namejugador(IDplayer, Name, _),
	
	send_log('"', Name, '" está encerrado en la cárcel\ny saldrá cuando alguien pase \npor esa posición =( ','', '', '', Oca),
	
	advance_turn(IDplayer, _).
	
% *** Evento sin acción ***
% 
% Este evento ocurrirá cada vez que un usuario caiga en una casilla sin
% evento, y se encargará de pasar el turno al siguiente jugador, al contrario
% del resto de eventos (a excepción del laberinto), que mantiene el turno en el
% jugador (la OCA, el puente, los dados, etc.)
% 
% *************************

noact(IDplayer, Oca):-
	
	% Quitamos a la OCA parlante y dibujamos la normal, ya que en casilla normal
	% la OCA no habla
	free(@ocan2),
	free(@ocan),
	
	imagen(Oca, @ocan, oca_gif, point(865, 390)),
	
	advance_turn(IDplayer, _).
	    
% Por último, la regla que llama a los eventos en cuanto un usuario cae en
% ellos

check_casilla(Jug, Oca):-
	
	ubicacion(Jug, Poss),
	casillajug(Poss, Casilla),
	call(Casilla, Jug, Oca).


% ******** FINAL ********
