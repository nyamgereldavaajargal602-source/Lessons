connected(ulaanbaatar, uvurkhangai, 498, 5 ).
connected(ulaanbaatar, khentii,  278, 3).
connected(ulaanbaatar, selenge, 289, 3 ).
connected(ulaanbaatar, dundgovi, 320, 3 ).
connected(ulaanbaatar, govisvmber, 241, 3 ).
connected(ulaanbaatar, bulgan, 447, 4 ).
connected(dornod, svkhbaatar,282, 2).
connected(dornod, khentii, 593, 5).
connected(khentii, svkhbaatar, 351, 4).
connected(svkhbaatar, dornogovi, 720, 6).
connected(dornogovi, khentii, 796, 5).
connected(dornogovi, govisvmber, 373, 4).
connected(govisvmber, khentii, 461, 2).
connected(govisvmber, dundgovi, 210, 2).
connected(selenge, darkhan-uul, 86, 1).
connected(dundgovi, umnugovi, 363, 4).
connected(dundgovi, uvurkhangai, 397, 4).
connected(uvurkhangai, bulgan, 453, 5).
connected(uvurkhangai, umnugovi, 402, 3).
connected(orkhon, selenge, 248, 2).
connected(orkhon, bulgan, 135, 1).
connected(bulgan, arhkangai, 255, 3).
connected(bulgan, selenge, 358, 4).
connected(bulgan, khuvsgul, 373, 3).
connected(uvurkhangai, baynkhongor, 398, 3).
connected(baynkhongor, arkhangai, 452, 4).
connected(arkhangai, khuvsgul, 628, 3).
connected(arkhangai, uvurkhangai, 402, 4).
connected(baynkhongor, umnugovi, 780, 5).
connected(baynkhongor, uvurkhangai, 398, 3).
connected(khuvsgul, zawhan, 500, 5).
connected(zawhan, arkhangai, 471, 4).
connected(zawhan,govi-altai, 449, 4).
connected(zawhan, baynkhongor, 787, 6).
connected(govi_altai, baynkhongor, 402, 4).
connected(zawhan, uws, 406,3).
connected(zawhan, khovd, 683, 4).
connected(khovd, uws,367, 4).
connected(khovd, bayn_ulgii, 371, 3).
connected(bayn_ulgii, uws, 481, 4).

route(X,Y,D,C):-connected(X,Y,D,C).
route(X,Y,D,C):-connected(Y,X,D,C).

path(Start, End, Visited, Path, Dist, Time):-
     route(Start, Next, D, C),
	 \+member(Next, Visited),
	 (Next=End-> Path=[Start, End], Dist=D, Time=C;
	     path(Next, End, [Next|Visited], SubPath, SubDist, SubTime),
		 Path=[Start|SubPath],
		 Dist is D+SubDist,
		 Time is C+SubTime). 
all_paths(Start, End, Paths) :-
    findall([Path,Dist,Time], path(Start, End, [Start], Path, Dist, Time), Paths).


shortest_path(Start, End, ShortestPath, MinDist, Time) :-
    all_paths(Start, End, Paths),
    sort(2, @=<, Paths, Sorted), 
    Sorted = [[ShortestPath,MinDist,Time]|_].
print_path([City]) :-
    write(City).

print_path([City1, City2|Rest]) :-
    write(City1),
    write(' -> '),
    print_path([City2|Rest]).
ywah(Start, End) :-
    shortest_path(Start, End, Path, Dist, Time),
    nl,
    write(Start), write(' hotoos '),
    write(End), write(' hvrtel ywah hamgyn bogino zam bol:'), nl,
    print_path(Path), nl,
    write('niit '), write(Dist), write(' km zam tuulj, '),
    write(Time), write(' tsag zartsuulna.'), nl.
