% *******************************************************
% 
% El juego de la OCA gr�fica, Programado en Prolog + XPCE
% Por: Alberto Fern�ndez Mart�nez, 1� de Ing. Inform�tica
% Universidad de Alicante, L�gica Computacional
% 
% *******************************************************


% Cargamos las librer�as XPCE

:- use_module(library(pce)).

% Le indicamos el directorio base donde estar�n ubicadas las im�genes de
% nuestro programa, el tablero, los dados, las fichas, etc...

:- pce_image_directory('./img/').

% ******** OPERACIONES INICIALES ********
% 
% Limpiamos la pantalla y generamos los recursos que vamos a usar, la
% imagen del tablero, los distintos men�s, fondos, en defintiva, los
% gr�ficos del programa
% 
% ***************************************


:- write('\033[2J').    
:- write('[p] Creando im�genes...\n').

% Im�genes del men� principal

resource(menu, menu, image('menu_oca.jpg')).
resource(salida, salida, image('salida.jpg')).
resource(iniciar, iniciarjuego, image('iniciar_juego.jpg')).
resource(ayuda, ayuda, image('ayuda.jpg')).
resource(instrucciones, instrucciones, image('instrucciones.jpg')).

% Pantalla de ayuda

resource(ayuda_menu, ayudam, image('ayuda_menu.jpg')).
resource(ayuda_back, ayudab, image('back_ayuda.jpg')).

% Pantalla de configuraci�n

resource(config, config, image('config.jpg')).

% Pantalla de instrucciones

resource(instrucciones_v, image, image('instrucciones_v.jpg')).

% Todas las im�genes de la pantalla de la OCA

:- write('[p] Creando im�genes de la OCA...\n').

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

:- write('[p] Creando fichas de los jugadores...\n').

resource(fichaazul, fichaazul, image('ficha_azul.gif')).
resource(fichaamari, image, image('ficha_amarillo.gif')).
resource(ficharoja, image, image('ficha_roja.gif')).
resource(fichaverde, image, image('ficha_verde.gif')).

% ******** PREDICADOS AUXILIARES ********
% 
% Predicados que se van a usar en muchos otros subprogramas
% 
% ***************************************


% Este predicado nos crear� una imagen a partir de un recurso.

imagen(Ventana, Figura, Imagen, Posicion) :-
	new(Figura, figure),
	new(Bitmap, bitmap(resource(Imagen),@on)),
	send(Bitmap, name, 1),
	send(Figura, display, Bitmap),
	send(Figura, status, 1),
	send(Ventana, display, Figura, Posicion).

% Un predicado auxiliar que devolver� 'Yes' siempre
% �til para evitar el warning de Singleton Variables y para los
% condicionales

nada(_).

% Juntar una cadena de 6 cadenas y variables

juntar(Cosa1, Cosa2, Cosa3, Cosa4, Cosa5, Cosa6, Resultado):-
	atom_concat(Cosa1,Cosa2,Cosa11),
	atom_concat(Cosa11,Cosa3,Cosa22),
        atom_concat(Cosa22,Cosa4,Cosa33),
	atom_concat(Cosa33,Cosa5,Cosa44),
	atom_concat(Cosa44,Cosa6,Resultado).


% ******** PREDICADOS DIN�MICOS  ********
% 
% Todos los predicados din�micos que vamos a usar en nuestro juego, con
% un peque�o comentario como aclaraci�n al lado
% 
% ***************************************

:- write('[p] Creando predicados din�micos...\n').

:-dynamic turno/1.             % Este predicado controlar el turno 
:-dynamic ubicacion/2.         
:-dynamic finDeJuego/0.           
:-dynamic tiradas/1.           % Predicado para contabilizar el n�mero de tiradas de una partida
:-dynamic numjug/1.            % Predicado para controlar el n�mero de jugadores de la partida
:-dynamic turnosSinJugar/2.    % Controla los turnos que va a estar sin jugar un jugador
:-dynamic namejugador/3.       % Nombres de los jugadores

% NOTA sobre namejugador/3: El tercer par�metro es para el color, pero
% no he podido implementarlo a tiempo


% ******** PREDICADOS DEL INICIO ********
% 
% Aqu� est�n todos los predicados iniciales que cargan el men�
% principal, la pantalla de ayuda, la de instrucciones, el modo
% configuraci�n, etc...
% 
% ***************************************


% Funci�n que resetear� todas las variables din�micas para crear un
% juego nuevo independientemente de los anteriores. Se usar� en la
% ventana de la OCA

inicializar:-
	
	retractall(turno(_)),
	assert(turno(1)),
	retractall(ubicacion(_,_)),
	assert(ubicacion(1, 1)),
	assert(ubicacion(2, 1)),
	assert(ubicacion(3, 1)),
	assert(ubicacion(4, 1)),
	retractall(finDeJuego),
	retractall(tiradas(_)),
	assert(tiradas(1)),
	retractall(turnosSinJugar(_,_)),
	assert(turnosSinJugar(1, 0)),
	assert(turnosSinJugar(2, 0)),
	assert(turnosSinJugar(3, 0)),
	assert(turnosSinJugar(4, 0)),
	retractall(carcel(_)).

% Usaremos este predicado en todas las secciones del men� para liberar
% las im�genes previas, etc... 

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


% Menu principal de la OCA. En un predicado que lanza al inicio en
% cuanto compilamos nuestro programa
:- write('[p] Lanzando men� principal...\n').

:-
	
	% Borramos los jugadores anteriores. No se hace en la ventana de la OCA 
	% para que nos permita reiniciar un juego y no perder los datos de los jugadores
	retractall(namejugador(_, _, _)),
	
	% En los predicados que se ejecutan al principio hay que liberar las variables
	% a mano, o tirar� error	
	free(@menu),
	free(@mprincipal),
	free(@inst),
	free(@ayuda),
	free(@salir),
	free(@config),
	
	new(Menu, window('El Juego de la OCA: Men� Principal', size(800, 600))),      % Ventana principal
	
	% Imprimimos las im�genes del men� principal en sus respectivas posiciones
	imagen(Menu, @menu, menu, point(0,0)),
	imagen(Menu, @mprincipal, iniciar, point(33, 186)),
	imagen(Menu, @inst, instrucciones, point(32, 238)),
	imagen(Menu, @ayuda, ayuda, point(82, 284)),
	imagen(Menu, @salir, salida, point(84, 336)),
	
	% A continuaci�n, le asignamos la propiedad para poder capturar los clicks 
	% de rat�n del usuario, y ejecutamos una acci�n
	
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
	
	% Ahora le asignamos un cursos para cuando pasamos el rat�n por encima
	send(@mprincipal, cursor, hand2),
	send(@ayuda, cursor, hand2),
	send(@salir, cursor, hand2),
	send(@inst, cursor, hand2),	
	
	send(Menu, open_centered).      % Abrimos el men� centrado

% Esta regla la cre� ya que cuando salimos del tablero de la OCA,
% volvemos al men� principal para iniciar otra partida, ver la ayuda,
% etc... Intentar ejecutar esta regla nada m�s compilar tiraba error

remenu2:-

	retractall(namejugador(_, _, _)),
	
	free_menu, 
	
	new(Menu, window('El Juego de la OCA: Men� Principal', size(800, 600))),
	
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

% Finalmente, una regla similar que nos borre las variables de im�genes,
% textos, etc... de las distintas pantallas del men� principal para
% mostrar el menu principal del juego. Se necesita usar este predicado
% para evitar molestar al usuario cerrando y abriendo ventanas cada vez
% que pase de un men� a otro

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
	
	
% *** Pantalla de configuraci�n ***
% 
% Las siguientes reglas controlan todo lo que refiere a la pantalla de
% configuraci�n, y merecen una descripci�n aparte
% 
% *********************************

% Aqu� voy a almacenar las posiciones en la cuadr�cula de los cuadros de
% texto de cada jugador, y del seleccionador del n�mero de jugadores

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
	send(Var, length, 40),      
	send(Var, editable, true). 

% Con este predicado hacemos que un cuadro de texto no sea editable, por
% lo tanto, el usuario no podr� modificar su valor

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

% Introducimos el n�mero de jugadores que har�n uso de la partida

num_jugadores(Num):-
	
	retractall(numjug(_)),
	assert(numjug(Num)).

% A�adimos los nombres de los jugadores. Este predicado se usar� desde
% XPCE, por lo tanto se define para cada una de las posibilidades. Tanto
% como si hay 2, 3 o 4 jugadores, los a�adimos todos a la base de
% conocimientos

% NOTA: la propiedad de color de namejugador/3 es trivial

insert_jugador(2, P1, P2, _, _):-
	
	assert(namejugador(1, P1, 'rojo')),
	assert(namejugador(2, P2, 'rojo')),
	assert(namejugador(3, '', '')),
	assert(namejugador(4, '', '')).

insert_jugador(3, P1, P2, P3, _):-
	
	assert(namejugador(1, P1, 'rojo')),
	assert(namejugador(2, P2, 'rojo')),
	assert(namejugador(3, P3, 'rojo')),
	assert(namejugador(4, '', '')).

insert_jugador(4, P1, P2, P3, P4):-
	
	assert(namejugador(1, P1, 'rojo')),
	assert(namejugador(2, P2, 'rojo')),
	assert(namejugador(3, P3, 'rojo')),
	assert(namejugador(4, P4, 'rojo')).
	
% Por �ltimo, creamos la pantalla de configuraci�n, usando todas las
% reglas anteriores

config(Menu):-
	
	free_menu,
	
	imagen(Menu, @config, config, point(0,0)),
	imagen(Menu, @ayudab, ayuda_back, point(578, 538)),
	
	send(@ayudab, recogniser,
	     click_gesture(left, '', single,
			   message(@prolog, remenu, Menu))),
	
	send(@ayudab, cursor, hand2),
	
	% Sacamos los cuadros de texto de configuraci�n
	send(Menu, display, new(@numJug, 
				int_item('N�mero de jugadores', 4, 
					 message(@prolog, load_textitems, @numJug?selection))),
	     point(29, 190)),
	
	send(@numJug, range(low := 2, high := 4)),    % Definimos un rango m�ximo y m�nimo
	
	load_start(Menu),
       	
	% Bot�n para iniciar el juego. Insertar� todos los jugadores y lanzar� la ventana de la OCA
	% Tambi�n destruye la ventana actual
	
	send(Menu, display, new(@submit, button('Iniciar juego',
						and(
						    message(@prolog, insert_jugador, @numJug?selection,
							    @labelj1?value, @labelj2?value, 
							    @labelj3?value, @labelj4?value),
						    message(@prolog, go),
						    message(Menu, destroy)))),
	     point(29, 480)).



% ******** PREDICADOS REFERENTES AL JUEGO DE LA OCA ********
% 
% Aqu� ir�n todos los predicados referentes al juego de la OCA, la
% ventana principal, las posiciones de los jugadores y un largo etc.
% 
% **********************************************************

% Programa principal que lanza la oca y todo el resto de funciones
 
go :-
	
	% Borramos todo indicio de juego anterior
	inicializar,
	
	% Creamos la ventana donde ir� nuestro tablero y todo lo dem�s
	new(Oca, window('Juego de la Oca', size(1000, 566))),
	
	% Liberamos variables
	free_all,
	
	imagen(Oca, @fondo, fondo_oca, point(0,0)),
	imagen(Oca, @tablerooca, tablero, point(0, 0)),
	
	% Creamos la imagen, la 'rallita' que ir� debajo de cada jugador para indicar el turno
	imagen(Oca, @actual, actual, point(770, 30)),
	
	% Llamamos a otro predicado para crear las fichas
	crear_fichas(Oca),
	
	% Creamos un bot�n para lanzar los dados que llamar� a la regla principal del juego	
	send(Oca, display, new(@lanzardado, 
			       button('Tirar',
				      message(@prolog, empezar_todo, Oca))),
	     point(900, 8)),
	
	% Bot�n para reiniciar el juego
	send(Oca, display, new(@reiniciar, 
			       button('Reiniciar',
				      and(
					  message(Oca, destroy),
					  message(@prolog, go)))), 
	     point(740, 531)),
	
	% Bot�n para salir
	send(Oca, display, new(@salir_button, 
			       button('Salir',
				      and(
					  message(Oca, destroy),
					  message(@prolog, remenu2)))),
	     point(900, 531)),
	
	% La imagen de la simp�tica OCA y su vi�eta
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
% de jcada jugador. Tambi�n borrar aquellas fichas de jugadores que no
% vayan a jugar (como cuando escogemos que halla s�lo 2 jugadores)

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
	
	(   NumJug=2
	->  borrar_fichas(3),
	    borrar_fichas(4)
	;   NumJug=3
	->  borrar_fichas(4)
	;   nada(_)
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

% Coordenadas base de cada casilla dentro del tablero
% M�s tarde se utilizar�n para calcular la posici�n dentro de las mismas

coords(0,0,0).
coords(1, 14, 22).
coords(2, 14, 102).
coords(3, 14, 190).
coords(4, 14, 263).
coords(5, 14, 339).
coords(6, 14, 425).
coords(7, 14, 498).
coords(8, 96, 501).
coords(9, 175, 501).
coords(10, 252, 501).
coords(11, 339, 501).
coords(12, 420, 501).
coords(13, 504, 501).
coords(14, 579, 501).
coords(15, 658, 501).
coords(16, 661, 422).
coords(17, 661, 343).
coords(18, 661, 259).
coords(19, 661, 184).
coords(20, 661, 98).
coords(21, 661, 22).
coords(22, 579, 22).
coords(23, 495, 22).
coords(24, 415, 22).
coords(25, 333, 22).
coords(26, 252, 22).
coords(27, 175, 22).
coords(28, 92, 22).
coords(29, 92, 99).
coords(30, 92, 175).
coords(31, 92, 260).
coords(32, 92, 340).
coords(33, 94, 421).
coords(34, 177, 421).
coords(35, 256, 421).
coords(36, 337, 421).
coords(37, 416, 421).
coords(38, 499, 421).
coords(39, 581, 421).
coords(40, 581, 346).
coords(41, 581, 258).
coords(42, 581, 177).
coords(43, 581, 99).
coords(44, 498, 99).
coords(45, 416, 99).
coords(46, 336, 99).
coords(47, 253, 99).
coords(48, 171, 99).
coords(49, 171, 178).
coords(50, 171, 256).
coords(51, 171, 341).
coords(52, 251, 341).
coords(53, 335, 341).
coords(54, 419, 341).
coords(55, 500, 341).
coords(56, 500, 252).
coords(57, 500, 180).
coords(58, 413, 180).
coords(59, 339, 180).
coords(60, 254, 180).
coords(61, 254, 258).
coords(62, 333, 258).
coords(63, 438, 273).

% Las coordenadas que debemos sumar a cada cuadro de casilla para
% colocar las fichas dentro de la cuadr�cula de modo correcto

posicion_ficha(0, 0, 0).
posicion_ficha(1, 0, 0).
posicion_ficha(2, 15, 0).
posicion_ficha(3, 0, 15).
posicion_ficha(4, 15, 15).

% Calcular la posici�n de una ficha en una determinada casilla

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

% Predicado para mover una ficha a una posici�n

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
	
% Obtener un n�mero al azar del 1 al 6 // From: Fases OCA

dados(X):-
	
	X is random(6)+1.

% Utilizamos este predicado para enviar texto al log de la OCA

send_log(Msg1, Msg2, Msg3, Msg4, Msg5, Msg6, Oca):-
	free(@logs),
	juntar(Msg1, Msg2, Msg3, Msg4, Msg5, Msg6, Resultado),	
        send(Oca, display, new(@logs, text(Resultado)), point(765, 185)),
        send(@logs, font, font('Arial', normal, 12)),          % Fuente
        send(@logs, geometry(width := 255, height := 174)).    % Tama�o	

% Y este otro predicado para imprimir un mensaje por la consola de
% Prolog

send_prolog(Msg1, Msg2, Msg3, Msg4, Msg5, Msg6):-
	juntar(Msg1, Msg2, Msg3, Msg4, Msg5, Msg6, Resultado),
	write(Resultado).

% *** Secuencia principal del juego ***
% 
% Este predicado lo controlar� todo, se encarga de obtener la posici�n
% del jugador, tirar el dado, mover la ficha, etc...
%
% *************************************

empezar_todo(_):-finDeJuego.   % Si est� seteado el finDeJuego/0 no hace nada.
empezar_todo(Oca):-
	
	% Liberamos la ficha fantasma y la volvemos a crear para moverla posteriormente
	free(@fantasma),
	imagen(Oca, @fantasma, fantasma, point(923, 469)),
       
	send(@logs, clear),
	
	% Obtener el n�mero de tiradas que llevamos hasta ahora y sumarle
	tiradas(Tiradas),
	
	TiradasNew is Tiradas+1,
	retractall(tiradas(_)),
	assert(tiradas(TiradasNew)),

	free(@dado),
	
	% Obtenemos el turno del jugador actual
	turno(TurnoA),
	
	dados(N),
	
	% Comprobamos si el usuario ha pasado de largo por la casilla de la c�rcel
	% y llamamos a una regla que nos libera de la c�rcel a aquellos que estuvieran
	ubicacion(TurnoA, CarcelP),
	newpos(CarcelP, N, NewPossC),
	
	salir_carcel(1, CarcelP, NewPossC),
	salir_carcel(2, CarcelP, NewPossC),
	salir_carcel(3, CarcelP, NewPossC),
	salir_carcel(4, CarcelP, NewPossC),	
	
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

% *** Miscel�nea ***
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

% Creamos las posiciones de la estrellita que cargar� encima de la ficha
% del ganador

estrella_ganador(1, 739, 9).
estrella_ganador(2, 739, 47).
estrella_ganador(3, 739, 85).
estrella_ganador(4, 739, 124).

% Y finalmente, otro perdicado para imprimir la estrella en una
% determinada posici�n

ganador_imagen(IDplayer, Oca):-
	
	estrella_ganador(IDplayer, X, Y),
	imagen(Oca, @estrella, estrella, point(X, Y)).

% Calcular la nueva posici�n del jugador teniendo en cuenta que no
% sobrepase de la casilla 63

newpos(PosA,N,NewPos):-
	
	(   PosA+N>63
	->  NewPos is 63- (PosA+N-63)
	;   NewPos is PosA+N
	).

% Regla para mover al jugador X posiciones

moveplayer(Jug,N):-
	
        ubicacion(Jug, X),
	(   X=63
	->  NewPos=63
	;   newpos(X, N, NewPos)
	),
	
        retract(ubicacion(Jug, X)),
        assert(ubicacion(Jug, NewPos)).

% Mover un jugador a una casilla determinada

moveplayer_casilla(Jug, N):-
	
	ubicacion(Jug, X),
	retract(ubicacion(Jug, X)),
	assert(ubicacion(Jug, N)).

% Calcular el siguiente jugador en base al total de jugadores

siguiente_jugador(Actual,Siguiente):-
	
	numjug(Act),
	
	(   Actual is Act
	->  Siguiente is 1
	;   Siguiente is Actual+1
	).

% *** Salir de la c�rcel ***
% 
% A este regla le pasamos la posici�n anterior y nueva de un jugador
% para fijarnos si ha pasado por la c�rcel. En caso afirmativo, lo
% liberar de la c�rcel y seguir� jugando. Se repite por cada jugador, y
% no importa si est� en la c�rcel o no, pues siempre devuelve 'Yes'
% 
% **************************

salir_carcel(IDplayer, PossAct, Next):-
	
	turnosSinJugar(IDplayer, T),
	
	(   PossAct<52
	->  (   Next>52
	    ->  (   T>50
		->  retractall(turnosSinJugar(IDplayer, _)),
		    assert(turnosSinJugar(IDplayer, 0))
		;   nada(_)
		)
	    ;   nada(_)
	    )
	;   nada(_)
	).

	

% ******** CASILLAS CON EVENTOS ESPECIALES ********
% 
% En esta secci�n est�n todos los predicados de los eventos especiales,
% que cargar�n cuando el usuario caiga en la correspondiente casilla
% 
% ************************************************* 

% *** Casilla de la meta ***
% 
% Al llegar a la meta, introduce el perdicado din�mico finDeJuego/0 para
% que no pueda continuar e imprime un mensaje del ganador. Tambi�n
% dibuja la estrella y obtienes el total de tiradas
% 
% **************************

meta(IDplayer, Oca):-
	
	animar_oca(Oca),
	assert(finDeJuego),

        namejugador(IDplayer, Name, _),
        tiradas(Tiradas),
	
	send_log('�"', Name, '" ha ganado el juego! =\'D', '\n\nTotal de tiradas: ', Tiradas, '', Oca),
	cambia_token(IDplayer, Oca),
	
	ganador_imagen(IDplayer, Oca).

% Este regla es para cuando un jugador caiga en la posici�n 59, la OCA
% en d�nde ganar� directamente

meta_oca(IDplayer, Oca):-
	moveplayer_casilla(IDplayer, 63),
	meta(IDplayer, Oca).

% Predicado para calcular la siguiente OCA

siguiente_oca(Actual, Siguiente):-
	
	casillajug(Siguiente, Casilla),
	
	Siguiente > Actual,
	(Casilla=oca;Casilla=meta), !.

% *** Evento de la OCA ***
% 
% Este evento obtiene la siguiente OCA y mueve al jugado hasta ella
% pero antes imprime la ficha fantasma, para indicar en que casilla 
% hab�a caido anteriormente
% 
% ************************

oca(IDplayer, Oca):-
	
	animar_oca(Oca),
	
	ubicacion(IDplayer, OcaActual),	
	namejugador(IDplayer, Name, _),
	
	siguiente_oca(OcaActual, SiguienteOca),
	fantasma(OcaActual, Oca),
	
	moveplayer_casilla(IDplayer, SiguienteOca),
       
	send_log(Name, ' ha caido en la OCA\ny salta de la casilla ', OcaActual, '\na la casilla ', SiguienteOca, '\n\n�Tira de nuevo!', Oca).

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

% Calculamos el siguiente puente en base a la posici�n actual

siguiente_puente(Actual, Siguiente):-
	
	casillajug(Siguiente, puente),
	Siguiente \= Actual.

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
	send_log('"', Name, '" ha caido en el puente\ny salta de la casilla ', PuenteActual, Concat, '\n\n�Tira de nuevo!', Oca),
	
	moveplayer_casilla(IDplayer, Next).

% Calculamos la siguiente posici�n de los dados

siguiente_dados(Actual, Siguiente):-
	
	casillajug(Siguiente, losdados),
	Siguiente \= Actual.

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
% Cuando un jugador caiga aqu� se le llevar� a la casilla 30, pero
% seguir� el turno, es decir, no tirar� de nuevo
% 
% ****************************

laberinto(IDplayer, Oca):-
	
	animar_oca(Oca),
	
	namejugador(IDplayer, Name, _),
	
	send_log('"', Name, '" se pierde en el laberinto\ny vuelve a la casilla 30\n', '', '\n\n', '', Oca),
	
	moveplayer_casilla(IDplayer, 30),
	
	turno(TurnoA),
	
	% *** Comprobar si el siguiente jugador est� bloqueado ***
	% Desde aqu� comprobamos si el siguiente jugador no est� bloqueado
	% (sin turno), en caso afirmativo, le pasamos el turno al siguiente
	% ********************************************************
	
	siguiente_jugador(TurnoA, SiguienteJugador),
	turnosSinJugar(SiguienteJugador, SinJugar),
	siguiente_jugador(SiguienteJugador, SigSigJugador),
	
	(   SinJugar>0
	->  Turno=SigSigJugador,
	    NuevosTurnos is SinJugar-1,
	    retract(turnosSinJugar(SiguienteJugador, _)),
	    assert(turnosSinJugar(SiguienteJugador, NuevosTurnos))
	;   Turno=SiguienteJugador
	),
	
	retractall(turno(_)),
	assert(turno(Turno)).	

% *** Evento de la Posada ***
% 
% Cuando un jugador activa este evento, se introduce en la base de conocimientos
% el n�mero de turnos que estar� bloqueado, y que se ir�n restando cuando el jugador
% anterior al bloqueado tire dado
% 
% ***************************

posada(IDplayer, Oca):-
	
	animar_oca(Oca),
	
	retract(turnosSinJugar(IDplayer, _)),
	assert(turnosSinJugar(IDplayer, 1)),   % Introducimos 1 turno sin jugar para este jugador
	
	namejugador(IDplayer, Name, _),
	
	send_log('"', Name, '" ha caido en la posada\ny estar� 1 turno sin jugar. ','', '', '', Oca),
	
	siguiente_jugador(IDplayer, SiguienteJugador),
	
	retractall(turno(_)),
	assert(turno(SiguienteJugador)).

% *** Evento del Pozo ***
% 
% Similar al de la Posada, pero en vez de 1 turno, 2
% 
% ***********************

pozo(IDplayer, Oca):-
	
	animar_oca(Oca),
	
	retract(turnosSinJugar(IDplayer, _)),
	assert(turnosSinJugar(IDplayer, 2)),
	
	namejugador(IDplayer, Name, _),
	
	send_log('"', Name, '" ha caido en el pozo\ny estar� 2 turnos sin jugar =( ','', '', '', Oca),
	
	siguiente_jugador(IDplayer, SiguienteJugador),
	
	retractall(turno(_)),
	assert(turno(SiguienteJugador)).

% *** Evento de la C�rcel ***
% 
% Cuando un jugador caiga en la c�rcel, le pondremos 999 turnos sin poder tirar, es
% decir, hasta que no se le borren esa barbaridad de turnos, no podr� moverse. 
% Los turnos se borran con el predicado salir_carcel/3
% 
% ***************************

lacarcel(IDplayer, Oca):-
	
	animar_oca(Oca),
	
	retract(turnosSinJugar(IDplayer, _)),
	assert(turnosSinJugar(IDplayer, 999)),    % 999 Turnos sin tirar
	
	namejugador(IDplayer, Name, _),
	
	send_log('"', Name, '" est� encerrado en la c�rcel\ny saldr� cuando alguien pase \npor esa posici�n =( ','', '', '', Oca),
	
	siguiente_jugador(IDplayer, SiguienteJugador),
	
	retractall(turno(_)),
	assert(turno(SiguienteJugador)).	
	
% *** Evento sin acci�n ***
% 
% Este evento ocurrir� cada vez que un usuario caiga en una casilla sin
% evento, y se encargar� de pasar el turno al siguiente jugador, al contrario
% del resto de eventos (a excepci�n del laberinto), que mantiene el turno en el
% jugador (la OCA, el puente, los dados, etc.)
% 
% *************************

noact(_, Oca):-
	
	% Quitamos a la OCA parlante y dibujamos la normal, ya que en casilla normal
	% la OCA no habla
	free(@ocan2),
	free(@ocan),
	
	imagen(Oca, @ocan, oca_gif, point(865, 390)),
	
	turno(TurnoA),
	
	siguiente_jugador(TurnoA, SiguienteJugador),
	turnosSinJugar(SiguienteJugador, SinJugar),
	siguiente_jugador(SiguienteJugador, SigSigJugador),
	
	(   SinJugar>0
	->  Turno=SigSigJugador,
	    NuevosTurnos is SinJugar-1,
	    retract(turnosSinJugar(SiguienteJugador, _)),
	    assert(turnosSinJugar(SiguienteJugador, NuevosTurnos))
	;   Turno=SiguienteJugador
	),
	
	retractall(turno(_)),
	assert(turno(Turno)).
	    
% Definimos a cada casilla un evento

casillajug(1, noact).
casillajug(2, noact).
casillajug(3, noact).
casillajug(4, noact).
casillajug(5, oca).
casillajug(6, puente).
casillajug(7, noact).
casillajug(8, noact).
casillajug(9, oca).
casillajug(10, noact).
casillajug(11, noact).
casillajug(12, puente).
casillajug(13, noact).
casillajug(14, oca).
casillajug(15, noact).
casillajug(16, noact).
casillajug(17, noact).
casillajug(18, oca).
casillajug(19, posada).
casillajug(20, noact).
casillajug(21, noact).
casillajug(22, noact).
casillajug(23, oca).
casillajug(24, noact).
casillajug(25, noact).
casillajug(26, losdados).
casillajug(27, oca).
casillajug(28, noact).
casillajug(29, noact).
casillajug(30, noact).
casillajug(31, pozo).
casillajug(32, oca).
casillajug(33, noact).
casillajug(34, noact).
casillajug(35, noact).
casillajug(36, oca).
casillajug(37, noact).
casillajug(38, noact).
casillajug(39, noact).
casillajug(40, noact).
casillajug(41, oca).
casillajug(42, laberinto).
casillajug(43, noact).
casillajug(44, noact).
casillajug(45, oca).
casillajug(46, noact).
casillajug(47, noact).
casillajug(48, noact).
casillajug(49, noact).
casillajug(50, oca).
casillajug(51, noact).
casillajug(52, lacarcel).
casillajug(53, losdados).
casillajug(54, oca).
casillajug(55, noact).
casillajug(56, noact).
casillajug(57, noact).
casillajug(58, calavera).
casillajug(59, meta_oca).
casillajug(60, noact).
casillajug(61, noact).
casillajug(62, noact).
casillajug(63, meta).

% Por �ltimo, la regla que llama a los eventos en cuanto un usuario cae en
% ellos

check_casilla(Jug, Oca):-
	
	ubicacion(Jug, Poss),
	casillajug(Poss, Casilla),
	call(Casilla, Jug, Oca).


% ******** FINAL ********





























































































