:- encoding(utf8).

:- use_module(library(plunit)).
:- ensure_loaded('oca_tests.pl').

:- prolog_load_context(directory, TestsDirectory),
   directory_file_path(TestsDirectory, '..', ProjectRoot0),
   absolute_file_name(ProjectRoot0, ProjectRoot,
                      [file_type(directory), access(read)]),
   nb_setval(oca_test_project_root, ProjectRoot).

:- initialization(run_all_tests, main).

run_all_tests :-
    current_prolog_flag(argv, Arguments),
    (   memberchk('--coverage', Arguments)
    ->  use_module(library(prolog_coverage)),
        nb_getval(oca_test_project_root, ProjectRoot),
        TestGoal = coverage(run_tests,
                            [ roots([ProjectRoot]),
                              width(120)
                            ])
    ;   TestGoal = run_tests
    ),
    (   call(TestGoal)
    ->  halt(0)
    ;   halt(1)
    ).
