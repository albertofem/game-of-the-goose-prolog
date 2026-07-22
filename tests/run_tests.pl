:- encoding(utf8).

:- use_module(library(plunit)).
:- use_module(library(ordsets), [ord_intersection/3, ord_subtract/3]).
:- ensure_loaded('oca_tests.pl').

:- multifile prolog_cover:report_hook/2.

:- prolog_load_context(directory, TestsDirectory),
   directory_file_path(TestsDirectory, '..', ProjectRoot0),
   absolute_file_name(ProjectRoot0, ProjectRoot,
                      [file_type(directory), access(read)]),
   nb_setval(oca_test_project_root, ProjectRoot).

:- initialization(run_all_tests, main).

run_all_tests :-
    current_prolog_flag(argv, Arguments),
    (   memberchk('--coverage', Arguments)
    ->  nb_getval(oca_test_project_root, ProjectRoot),
        coverage_backend(Backend),
        load_coverage_backend(Backend),
        TestGoal = run_with_coverage(Backend, ProjectRoot)
    ;   TestGoal = run_tests
    ),
    (   call(TestGoal)
    ->  halt(0)
    ;   halt(1)
    ).

coverage_backend(modern) :-
    exists_source(library(prolog_coverage)),
    !.
coverage_backend(legacy) :-
    exists_source(library(test_cover)),
    !.
coverage_backend(_) :-
    existence_error(source_sink, coverage_library).

load_coverage_backend(modern) :-
    use_module(library(prolog_coverage)).
load_coverage_backend(legacy) :-
    use_module(library(test_cover)).

run_with_coverage(modern, ProjectRoot) :-
    setup_call_cleanup(
        true,
        ( coverage(run_tests, [show(false)]),
          show_coverage([roots([ProjectRoot]), width(120)]),
          application_coverage(ProjectRoot, Covered, Total, Percentage),
          coverage_result(Covered, Total, Percentage, true)
        ),
        cov_reset).
run_with_coverage(legacy, ProjectRoot) :-
    nb_setval(oca_legacy_coverage_root, ProjectRoot),
    nb_setval(oca_legacy_coverage_passed, false),
    prolog_cover:show_coverage(user:run_tests),
    nb_getval(oca_legacy_coverage_passed, true).

coverage_result(Covered, Total, Percentage, Passed) :-
    format('Application coverage: ~d/~d clauses (~1f%)~n',
           [Covered, Total, Percentage]),
    CoverageFloor = 85.0,
    (   Percentage >= CoverageFloor
    ->  Passed = true
    ;   format(user_error,
               'Coverage ~1f% is below the required ~1f%.~n',
               [Percentage, CoverageFloor]),
        Passed = false
    ).

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

prolog_cover:report_hook(Succeeded, Failed) :-
    user:legacy_coverage_report(Succeeded, Failed).

legacy_coverage_report(Succeeded, Failed) :-
    prolog_cover:file_coverage(Succeeded, Failed, []),
    nb_getval(oca_legacy_coverage_root, ProjectRoot),
    legacy_application_coverage(ProjectRoot, Succeeded, Failed,
                                Covered, Total, Percentage),
    coverage_result(Covered, Total, Percentage, Passed),
    nb_setval(oca_legacy_coverage_passed, Passed).

legacy_application_coverage(ProjectRoot, Succeeded, Failed,
                            Covered, Total, Percentage) :-
    findall(File,
            application_source_file(ProjectRoot, File),
            Files0),
    sort(Files0, Files),
    maplist(legacy_file_coverage_counts(Succeeded, Failed),
            Files, CoveredCounts, TotalCounts),
    sum_list(CoveredCounts, Covered),
    sum_list(TotalCounts, Total),
    Total > 0,
    Percentage is Covered * 100 / Total.

legacy_file_coverage_counts(Succeeded, Failed, File, Covered, Total) :-
    findall(Clause,
            prolog_cover:clause_source(Clause, File, _),
            Clauses0),
    sort(Clauses0, AllClauses),
    ord_intersection(AllClauses, Succeeded, SucceededInFile),
    ord_intersection(AllClauses, Failed, FailedInFile),
    ord_subtract(AllClauses, SucceededInFile, Uncovered0),
    ord_subtract(Uncovered0, FailedInFile, Uncovered1),
    prolog_cover:clean_set(AllClauses, Clauses),
    prolog_cover:clean_set(Uncovered1, Uncovered),
    length(Clauses, Total),
    length(Uncovered, UncoveredCount),
    Covered is Total - UncoveredCount.
