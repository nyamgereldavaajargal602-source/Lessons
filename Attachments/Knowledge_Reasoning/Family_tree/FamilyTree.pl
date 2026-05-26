% ===== Minii urgiin mod =====

% ---------- FACT ----------

male(gombosuren, 1954, gerlesen).
female(oyunchimeg, 1955, gerlesen).

male(nyamgerel, 1983, salsan).
female(giimaa, 1984, salsan).

female(byambasuren, 1989, gerlesen).
male(galaa, 1988, gerlesen).

male(renjindorj, 1990, gerlesen).
female(unenbat, 1991, gerlesen).

male(davaajargal, 2006, gerleegui).

female(uudam, 2012, gerleegui).
male(tushig, 2014, gerleegui).

male(erhembayar, 2012, gerleegui).
male(tegshbayar, 2014, gerleegui).


male(puntsag, 1928, gerlesen).
female(lkhamtseren, 1931, gerlesen).

male(dorjsuren, 1952, gerlesen).
female(lkhamsuren, 1953, gerlesen).

female(tungalag, 1958, gerlesen).
male(battulga, 1957, gerlesen).

% Dorjsuren-ii huuhdvvd
female(enkhjargal, 1978, gerlesen).
male(boldbaatar, 1980, gerlesen).
male(sukhbaatar, 1983, gerleegui).

% Enkhjargal-iin gerleg
male(ganzorig, 1976, gerlesen).

% Boldbaatar-iin gergii
female(solongo, 1981, gerlesen).

% Dorjsuren-ii ach zee
male(ankhbayar, 2005, gerleegui).
female(narantsetseg_j, 2008, gerleegui).
female(munkhzul, 2007, gerleegui).
male(erdenebold, 2010, gerleegui).

% Tungalag-iin huuhdvvd
female(nominchimeg, 1983, gerlesen).
male(munkhbayar, 1986, gerleegui).

% Nominchimeg-iin gergii
male(gantulga, 1981, gerlesen).

% Tungalag-iin ach zeree
male(altangerel, 2009, gerleegui).
female(enkhmaa, 2012, gerleegui).

% ---------- PARENT ----------

parent(puntsag, oyunchimeg).
parent(lkhamtseren, oyunchimeg).
parent(puntsag, dorjsuren).
parent(lkhamtseren, dorjsuren).
parent(puntsag, tungalag).
parent(lkhamtseren, tungalag).

parent(gombosuren, giimaa).
parent(oyunchimeg, giimaa).

parent(gombosuren, byambasuren).
parent(oyunchimeg, byambasuren).

parent(gombosuren, renjindorj).
parent(oyunchimeg, renjindorj).

parent(nyamgerel, davaajargal).
parent(giimaa, davaajargal).

parent(byambasuren, uudam).
parent(galaa, uudam).
parent(byambasuren, tushig).
parent(galaa, tushig).

parent(renjindorj, erhembayar).
parent(unenbat, erhembayar).
parent(renjindorj, tegshbayar).
parent(unenbat, tegshbayar).

% Dorjsuren-ii huuhdvvd
parent(dorjsuren, enkhjargal).
parent(lkhamsuren, enkhjargal).
parent(dorjsuren, boldbaatar).
parent(lkhamsuren, boldbaatar).
parent(dorjsuren, sukhbaatar).
parent(lkhamsuren, sukhbaatar).

% Enkhjargal-ii huuhdvvd
parent(enkhjargal, ankhbayar).
parent(ganzorig, ankhbayar).
parent(enkhjargal, narantsetseg_j).
parent(ganzorig, narantsetseg_j).

% Boldbaatar-ii huuhdvvd
parent(boldbaatar, munkhzul).
parent(solongo, munkhzul).
parent(boldbaatar, erdenebold).
parent(solongo, erdenebold).

% Tungalag-iin huuhdvvd
parent(tungalag, nominchimeg).
parent(battulga, nominchimeg).
parent(tungalag, munkhbayar).
parent(battulga, munkhbayar).

% Nominchimeg-ii huuhdvvd
parent(nominchimeg, altangerel).
parent(gantulga, altangerel).
parent(nominchimeg, enkhmaa).
parent(gantulga, enkhmaa).

% ---------- MARRIED ----------

married(gombosuren, oyunchimeg).
married(nyamgerel, giimaa).
married(byambasuren, galaa).
married(renjindorj, unenbat).

married(puntsag, lkhamtseren).
married(dorjsuren, lkhamsuren).
married(tungalag, battulga).
married(enkhjargal, ganzorig).
married(boldbaatar, solongo).
married(nominchimeg, gantulga).

% ---------- BASIC RULES ----------

male_person(X) :- male(X, _, _).
female_person(X) :- female(X, _, _).

born(X, Y) :- male(X, Y, _).
born(X, Y) :- female(X, Y, _).

status(X, S) :- male(X, _, S).
status(X, S) :- female(X, _, S).

aaw(X, Y) :- parent(X, Y), male_person(X).
eej(X, Y) :- parent(X, Y), female_person(X).

sibling(X, Y) :-
    parent(P1, X), parent(P1, Y),
    parent(P2, X), parent(P2, Y),
    P1 \== P2,
    X \== Y.

older(X, Y) :-
    born(X, BX), born(Y, BY),
    BX < BY,
    X \== Y.

younger(X, Y) :-
    born(X, BX), born(Y, BY),
    BX > BY,
    X \== Y.

egc(X, Y) :-
    sibling(X, Y),
    older(X, Y),
    female_person(X).

ah(X, Y) :-
    sibling(X, Y),
    older(X, Y),
    male_person(X).

eregtei_dvv(X, Y) :-
    sibling(X, Y),
    younger(X, Y),
    male_person(X).

emegtei_dvv(X, Y) :-
    sibling(X, Y),
    younger(X, Y),
    female_person(X).

avga_ah(X, Z) :-
    ah(X, Y),
    aaw(Y, Z).

avga_egc(X, Z) :-
    egc(X, Y),
    aaw(Y, Z).

nagats_ah(X, Z) :-
    ah(X, Y),
    eej(Y, Z).

nagats_egc(X, Z) :-
    egc(X, Y),
    eej(Y, Z).

grandparent(X, Y) :-
    parent(X, Z),
    parent(Z, Y).

uwuu(X, Z) :-
    aaw(X, Y),
    parent(Y, Z).

emee_rule(X, Z) :-
    eej(X, Y),
    parent(Y, Z).

elents(X, Z) :-
    parent(X, Y),
    parent(Y, W),
    parent(W, Z).

hulants(X, Z) :-
    parent(X, Y),
    parent(Y, W),
    parent(W, A),
    parent(A, Z).

% ---------- HTML FAMILY TREE ----------

:- use_module(library(www_browser)).

spouse(X, Y) :- married(X, Y).
spouse(X, Y) :- married(Y, X).

person(X) :- male_person(X).
person(X) :- female_person(X).

children(X, Kids) :-
    setof(Y, parent(X, Y), Kids), !.
children(_, []).

has_child(X) :-
    parent(X, _).

root_person(X) :-
    person(X),
    has_child(X),
    \+ parent(_, X),
    \+ (spouse(X, S), parent(_, S)),
    (
        \+ spouse(X, _)
        ;
        (spouse(X, S), X @< S)
    ).

root_people(Roots) :-
    setof(X, root_person(X), Roots), !.
root_people([]).

label(X, Label) :-
    spouse(X, S), !,
    ( X @< S ->
        A = X, B = S
    ;
        A = S, B = X
    ),
    format(atom(Label), '~w -- ~w', [A, B]).

label(X, Label) :-
    format(atom(Label), '~w', [X]).

write_person_tree(X) :-
    label(X, Label),
    format('<li><span>~w</span>', [Label]),
    children(X, Kids),
    ( Kids \= [] ->
        write('<ul>'),
        write_children(Kids),
        write('</ul>')
    ; true
    ),
    write('</li>').

write_children([]).
write_children([H|T]) :-
    write_person_tree(H),
    write_children(T).

write_roots([]).
write_roots([H|T]) :-
    write_person_tree(H),
    write_roots(T).

generate_family_html(File) :-
    open(File, write, Stream, [encoding(utf8)]),
    current_output(Old),
    set_output(Stream),

    write('<!DOCTYPE html>'), nl,
    write('<html>'), nl,
    write('<head>'), nl,
    write('<meta charset="UTF-8">'), nl,
    write('<title>Minii urgiin mod</title>'), nl,
    write('<style>
body {
    font-family: Arial, sans-serif;
    background: #f6f8fb;
    padding: 30px;
}
h1 {
    text-align: center;
    color: #222;
}
.tree ul {
    padding-top: 20px;
    position: relative;
    padding-left: 40px;
    margin: 0;
}
.tree li {
    list-style-type: none;
    position: relative;
    padding: 12px 0 0 20px;
}
.tree li::before {
    content: "";
    position: absolute;
    top: 0;
    left: 0;
    border-left: 2px solid #999;
    height: 100%;
}
.tree li::after {
    content: "";
    position: absolute;
    top: 24px;
    left: 0;
    width: 20px;
    border-top: 2px solid #999;
}
.tree li:last-child::before {
    height: 24px;
}
.tree span {
    display: inline-block;
    padding: 8px 14px;
    background: white;
    border: 1px solid #ccc;
    border-radius: 10px;
    box-shadow: 0 2px 6px rgba(0,0,0,0.08);
    color: #222;
    font-weight: normal;
}
</style>'), nl,
    write('</head>'), nl,
    write('<body>'), nl,
    write('<h1>Urgiin mod</h1>'), nl,
    write('<div class="tree">'), nl,
    write('<ul>'), nl,

    root_people(Roots),
    write_roots(Roots),

    write('</ul>'), nl,
    write('</div>'), nl,
    write('</body>'), nl,
    write('</html>'), nl,

    set_output(Old),
    close(Stream).

show_family_tree :-
    File = 'FamilyTree.html',
    generate_family_html(File),
    absolute_file_name(File, AbsPath),
    catch(www_open_url(AbsPath), _, true),
    format('Family tree HTML uuslee: ~w~n', [AbsPath]).