Game of the Goose
=================

"Oca" is the traditional Spanish game, programmed in Prolog + XPCE

Requirements
------------

The game requires SWI-Prolog with XPCE support. On macOS, the official
`SWI-Prolog.app` bundle provides both the Prolog runtime and the native GUI.

Run the game from the project directory:

```sh
/Applications/SWI-Prolog.app/Contents/MacOS/swipl -s oca.pl
```

If `swipl` is already on your `PATH`, this shorter command also works:

```sh
swipl -s oca.pl
```

Tests
-----

The PlUnit suite covers game-state initialization, player configuration,
board data, movement and bouncing, turn handling, every special-square event,
resource loading, dialogue wrapping, and XPCE components built off-screen.

Run all tests:

```sh
make test
```

Run the tests with clause coverage:

```sh
make coverage
```

If you want to know more about the "Oca":

http://en.wikipedia.org/wiki/Game_of_the_Goose

Screenshots
-----------

![Menu](https://raw.github.com/albertofem/Oca/master/screenshots/menu.jpg)

![Game](https://raw.github.com/albertofem/Oca/master/screenshots/game.jpg)
