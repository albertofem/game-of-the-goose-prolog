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
        TestGoal = run_with_coverage(ProjectRoot)
    ;   TestGoal = run_tests
    ),
    (   call(TestGoal)
    ->  halt(0)
    ;   halt(1)
    ).

run_with_coverage(ProjectRoot) :-
    setup_call_cleanup(
        true,
        ( coverage(run_tests, [show(false)]),
          show_coverage([roots([ProjectRoot]), width(120)]),
          application_coverage(ProjectRoot, Covered, Total, Percentage),
          format('Application coverage: ~d/~d clauses (~1f%)~n',
                 [Covered, Total, Percentage]),
          CoverageFloor = 85.0,
          (   Percentage >= CoverageFloor
          ->  true
          ;   format(user_error,
                     'Coverage ~1f% is below the required ~1f%.~n',
                     [Percentage, CoverageFloor]),
              fail
          )
        ),
        cov_reset).

application_coverage(ProjectRoot, Covered, Total, Percentage) :-
    prolog_coverage:covered(Succeeded, Failed),
    findall(File,
            application_source_file(ProjectRoot, File),
            Files0),
    sort(Files0, Files),
    maplist(file_coverage_counts(Succeeded, Failed),
            Files, CoveredCounts, TotalCounts),
    sum_list(CoveredCounts, Covered),
    sum_list(TotalCounts, Total),
    Total > 0,
    Percentage is Covered * 100 / Total.

application_source_file(ProjectRoot, File) :-
    source_file(File),
    relative_file_name(File, ProjectRoot, Relative),
    (   Relative == 'oca.pl'
    ;   sub_atom(Relative, 0, 4, _, 'src/')
    ).

file_coverage_counts(Succeeded, Failed, File, Covered, Total) :-
    prolog_coverage:cov_clause_sets(File, Succeeded, Failed, Sets0),
    prolog_coverage:deduplicate_clauses(File, Sets0, Sets),
    get_dict(clauses, Sets, Clauses),
    get_dict(uncovered, Sets, Uncovered),
    length(Clauses, Total),
    length(Uncovered, UncoveredCount),
    Covered is Total - UncoveredCount.
