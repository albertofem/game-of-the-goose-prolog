:- module(oca_board,
          [ coords/3,
            casillajug/2
          ]).

/** <module> Immutable Game of the Goose board data

This module contains only the board geometry and the event assigned to each
square.  Keeping these facts independent from XPCE makes them reusable by the
rules engine and testable without constructing widgets.
*/

coords(0, 0, 0).
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
