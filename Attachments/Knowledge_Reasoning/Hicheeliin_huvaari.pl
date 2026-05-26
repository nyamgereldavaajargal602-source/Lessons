day(mon). day(tue). day(wed). day(thu). day(fri).

day_order(mon, 1). day_order(tue, 2). day_order(wed, 3).
day_order(thu, 4). day_order(fri, 5).

slot(s1). slot(s2). slot(s3). slot(s4). slot(s5).

slot_order(s1, 1). slot_order(s2, 2). slot_order(s3, 3).
slot_order(s4, 4). slot_order(s5, 5).

room(r113, lecture). room(r229, lecture).
room(r201, lab). room(r202, lab). room(r203, lab). room(r204, lab).

course(ai, 3). course(tamir, 3). course(suljee, 3).
course(math, 3). course(physics, 3). course(programming, 3).
course(english, 2).

teacher(battsetseg). teacher(saraa). teacher(undral).
teacher(uugantuya). teacher(suh). teacher(alimaa). teacher(oyun).

teaches(oyun, english).
teaches(battsetseg, ai).
teaches(saraa, tamir).
teaches(undral, suljee).
teaches(uugantuya, math).
teaches(suh, physics).
teaches(alimaa, programming).

room_capacity(r113, 35).  room_capacity(r229, 120).
room_capacity(r201, 30).  room_capacity(r202, 25).
room_capacity(r203, 25).  room_capacity(r204, 20).

course_students(ai, 70).       course_students(tamir, 20).
course_students(suljee, 95).   course_students(math, 78).
course_students(physics, 105). course_students(programming, 88).
course_students(english, 30).

schedule(ai,          lecture, r229, mon, s2).
schedule(ai,          lab,     r201, wed, s3).
schedule(tamir,       lecture, r113, mon, s3).
schedule(tamir,       lab,     r202, thu, s2).
schedule(suljee,      lecture, r229, tue, s1).
schedule(suljee,      lab,     r203, thu, s3).
schedule(math,        lecture, r229, tue, s2).
schedule(math,        lab,     r204, fri, s1).
schedule(physics,     lecture, r229, wed, s1).
schedule(physics,     lab,     r202, fri, s2).
schedule(programming, lecture, r229, wed, s4).
schedule(programming, lab,     r201, fri, s3).
schedule(english,     lecture, r113, thu, s4).

student_group(g1). student_group(g2). student_group(g3).

takes(g1, ai). takes(g1, math). takes(g1, english).
takes(g2, suljee). takes(g2, physics). takes(g2, programming).
takes(g3, tamir). takes(g3, english).


lecture_in_valid_room :-
    \+ (schedule(_, lecture, Room, _, _), \+ room(Room, lecture)).

lab_in_valid_room :-
    \+ (schedule(_, lab, Room, _, _), \+ room(Room, lab)).

valid_days :-
    \+ (schedule(_, _, _, Day, _), \+ day(Day)).

valid_slots :-
    \+ (schedule(_, _, _, _, Slot), \+ slot(Slot)).

exactly_one_lecture_and_lab :-
    \+ (course(C, 3), findall(_, schedule(C, lecture, _, _, _), L), length(L, N), N \= 1),
    \+ (course(C, 3), findall(_, schedule(C, lab, _, _, _), L), length(L, N), N \= 1),
    \+ (course(C, 2), findall(_, schedule(C, lecture, _, _, _), L), length(L, N), N \= 1),
    \+ (course(C, 2), schedule(C, lab, _, _, _)).

teacher_conflict :-
    schedule(C1, _, _, D, S), schedule(C2, _, _, D, S), C1 \= C2,
    teaches(T, C1), teaches(T, C2).

room_conflict :-
    schedule(C1, T1, R, D, S), schedule(C2, T2, R, D, S),
    (C1 \= C2 ; T1 \= T2).

student_conflict :-
    student_group(G), takes(G, C1), takes(G, C2), C1 \= C2,
    schedule(C1, _, _, D, S), schedule(C2, _, _, D, S).

same_course_no_overlap :-
    \+ (schedule(C, lecture, _, D, S), schedule(C, lab, _, D, S)).

lecture_before_lab(C) :-
    schedule(C, lecture, _, D1, S1),
    schedule(C, lab, _, D2, S2),
    (   D1 = D2, slot_order(S1, N1), slot_order(S2, N2), N1 < N2
    ;   D1 \= D2, day_order(D1, X1), day_order(D2, X2), X1 < X2
    ).

all_lectures_before_lab :-
    \+ (course(C, 3), \+ lecture_before_lab(C)).

teacher_daily_count(T, D, Count) :-
    findall(_, (schedule(C, _, _, D, _), teaches(T, C)), L),
    length(L, Count).

teacher_daily_limit :-
    \+ (teacher(T), day(D), teacher_daily_count(T, D, C), C > 3).

capacity_ok :-
    \+ (schedule(C, _, R, _, _), course_students(C, N), room_capacity(R, Cap), N > Cap).

valid_schedule :-
    lecture_in_valid_room, lab_in_valid_room, valid_days, valid_slots,
    exactly_one_lecture_and_lab, same_course_no_overlap, all_lectures_before_lab,
    teacher_daily_limit, capacity_ok,
    \+ teacher_conflict, \+ room_conflict, \+ student_conflict.

% ============================================================
% НЭМЭЛТs 1: ОНОШИЛГООНЫ ТАЙЛАГНАГЧ
% Зөрчил яг хаана байгааг хэлдэг predicates
% ============================================================

%% Багшийн зөрчил: аль хоёр хичээл, аль өдөр, аль цагт давхарласан
report_teacher_conflicts :-
    format("~n=== БАГШИЙН ЗӨРЧИЛ ===~n"),
    (   bagof(f(T,C1,C2,D,S),
              (schedule(C1,_,_,D,S), schedule(C2,_,_,D,S), C1 @< C2,
               teaches(T,C1), teaches(T,C2)),
              Conflicts)
    ->  forall(member(f(T,C1,C2,D,S), Conflicts),
               format("  [!] ~w: ~w болон ~w хичээл ~w өдрийн ~w цагт давхарлав~n",
                      [T,C1,C2,D,S]))
    ;   format("  [ok] Байхгүй~n")
    ).

%% Өрөөний зөрчил: аль өрөө, аль хоёр хичээл давхарласан
report_room_conflicts :-
    format("~n=== ӨРӨӨНИЙ ЗӨРЧИЛ ===~n"),
    (   bagof(f(R,C1,T1,C2,T2,D,S),
              (schedule(C1,T1,R,D,S), schedule(C2,T2,R,D,S),
               (C1 @< C2 ; (C1=C2, T1 @< T2))),
              Conflicts)
    ->  forall(member(f(R,C1,T1,C2,T2,D,S), Conflicts),
               format("  [!] ~w өрөө: ~w(~w) болон ~w(~w) ~w өдрийн ~w цагт давхарлав~n",
                      [R,C1,T1,C2,T2,D,S]))
    ;   format("  [ok] Байхгүй~n")
    ).

%% Оюутны бүлгийн зөрчил
report_student_conflicts :-
    format("~n=== ОЮУТНЫ БҮЛГИЙН ЗӨРЧИЛ ===~n"),
    (   bagof(f(G,C1,C2,D,S),
              (student_group(G), takes(G,C1), takes(G,C2), C1 @< C2,
               schedule(C1,_,_,D,S), schedule(C2,_,_,D,S)),
              Conflicts)
    ->  forall(member(f(G,C1,C2,D,S), Conflicts),
               format("  [!] ~w бүлэг: ~w болон ~w хичээл ~w өдрийн ~w цагт давхарлав~n",
                      [G,C1,C2,D,S]))
    ;   format("  [ok] Байхгүй~n")
    ).

%% Багтаамжийн зөрчил
report_capacity_conflicts :-
    format("~n=== БАГТААМЖИЙН ЗӨРЧИЛ ===~n"),
    (   bagof(f(C,R,N,Cap),
              (schedule(C,_,R,_,_), course_students(C,N), room_capacity(R,Cap), N > Cap),
              Conflicts)
    ->  forall(member(f(C,R,N,Cap), Conflicts),
               format("  [!] ~w хичээл (~w оюутан) -> ~w өрөө (багтаамж ~w)~n",
                      [C,N,R,Cap]))
    ;   format("  [ok] Байхгүй~n")
    ).

%% Бүх оношилгоог нэг дор гаргах
full_report :-
    format("~n╔══════════════════════════════════════╗~n"),
    format("║       ХУВААРИЙН ОНОШИЛГОО           ║~n"),
    format("╚══════════════════════════════════════╝~n"),
    report_teacher_conflicts,
    report_room_conflicts,
    report_student_conflicts,
    report_capacity_conflicts,
    format("~n--- Ерөнхий дүгнэлт ---~n"),
    (valid_schedule -> format("  [✓] Хуваарь хүчинтэй~n") ; format("  [✗] Хуваарьт зөрчил байна~n")),
    nl.

% ============================================================
% НЭМЭЛТs 2: ХУВААРИЙН АСУУЛГЫН ТУСЛАХ PREDICATES
% ============================================================

%% Бүлгийн хуваарийг харах
%% Жишээ: group_schedule(g1).
group_schedule(G) :-
    student_group(G),
    format("~n=== ~w bulgiin huvaari ===~n", [G]),
    format("~`-t~50|~n"),
    format("~w~t~15|~w~t~25|~w~t~35|~w~t~45|~w~n",
           ['hicheel','torol','oroo','odr','tsag']),
    format("~`-t~50|~n"),
    forall(
        (takes(G, C), schedule(C, Type, Room, Day, Slot)),
        format("~w~t~15|~w~t~25|~w~t~35|~w~t~45|~w~n", [C,Type,Room,Day,Slot])
    ).

%% Багшийн хуваарийг харах
%% Жишээ: teacher_schedule(battsetseg).
teacher_schedule(T) :-
    teacher(T),
    format("~n=== ~w bagshiin huvaari  ===~n", [T]),
    format("~`-t~50|~n"),
    format("~w~t~15|~w~t~25|~w~t~35|~w~t~45|~w~n",
           ['hicheel','torol','oroo','odr','tsag']),
    format("~`-t~50|~n"),
    forall(
        (teaches(T, C), schedule(C, Type, Room, Day, Slot)),
        format("~w~t~15|~w~t~25|~w~t~35|~w~t~45|~w~n", [C,Type,Room,Day,Slot])
    ).

%% Тухайн өдрийн бүх хичээлийг харах
%% Жишээ: day_schedule(mon).
day_schedule(Day) :-
    day(Day),
    format("~n=== ~w odriin huvaari  ===~n", [Day]),
    format("~`-t~60|~n"),
    format("~w~t~15|~w~t~25|~w~t~35|~w~t~45|~w~n",
           ['hicheel','torol','oroo','tsag','bagsh']),
    format("~`-t~60|~n"),
    forall(
        (schedule(C, Type, Room, Day, Slot), teaches(T, C)),
        format("~w~t~15|~w~t~25|~w~t~35|~w~t~45|~w~n", [C,Type,Room,Slot,T])
    ).

%% Тухайн хичээлийн дэлгэрэнгүй мэдээлэл
%% Жишээ: course_info(ai).
course_info(C) :-
    course(C, Credits),
    teaches(T, C),
    course_students(C, Students),
    format("~n=== ~w hicheeliin medeelel ===~n", [C]),
    format("  credit:     ~w~n", [Credits]),
    format("  bagsh:       ~w~n", [T]),
    format("  oyutan:     ~w~n", [Students]),
    forall(
        schedule(C, Type, Room, Day, Slot),
        (   room_capacity(Room, Cap),
            format("  ~w: ~w oroo (~w tsag, ~w) | useage: ~w/~w~n",
                   [Type, Room, Day, Slot, Students, Cap])
        )
    ).

% ============================================================
% НЭМЭЛТs 3: БАГШИЙН АЧААЛЛЫН СТАТИСТИК
% ============================================================

%% Нэг багшийн нийт цагийн тоо
teacher_workload(T, Total) :-
    teacher(T),
    findall(_, (teaches(T, C), schedule(C, _, _, _, _)), L),
    length(L, Total).

%% Бүх багшийн ачааллын тайлан
workload_report :-
    format("~n=== Bagshiin achaallin tailan ===~n"),
    format("~`-t~35|~n"),
    format("~w~t~20|~w~n", ['Bagsh','total hour']),
    format("~`-t~35|~n"),
    forall(
        teacher(T),
        (   teacher_workload(T, Total),
            format("~w~t~20|~w~n", [T, Total])
        )
    ),
    format("~`-t~35|~n"),
    findall(N, (teacher(T), teacher_workload(T, N)), Loads),
    sum_list(Loads, Sum),
    length(Loads, Count),
    Avg is Sum / Count,
    format("  Niit: ~w tsag | dundaj: ~1f tsag/bagsh~n", [Sum, Avg]).

% ============================================================
% НЭМЭЛТs 4: ЧӨЛӨӨТ ЦАГ ХАЙХ
% ============================================================

%% Тухайн өрөөний чөлөөт цагуудыг олох
%% Жишээ: free_room_slots(r229, FreeList).
free_room_slots(Room, FreeSlots) :-
    room(Room, _),
    findall(d(Day,Slot),
            (day(Day), slot(Slot),
             \+ schedule(_, _, Room, Day, Slot)),
            FreeSlots).

%% Тухайн өрөөний чөлөөт цагийн тайлан
print_free_slots(Room) :-
    free_room_slots(Room, FreeSlots),
    length(FreeSlots, N),
    format("~n=== ~w oroonii choloot tsaguud (~w tsag) ===~n", [Room, N]),
    forall(
        member(d(Day,Slot), FreeSlots),
        format("  ~w - ~w~n", [Day, Slot])
    ).

%% Тухайн багшийн чөлөөт цагуудыг олох
free_teacher_slots(T, FreeSlots) :-
    teacher(T),
    findall(d(Day,Slot),
            (day(Day), slot(Slot),
             \+ (teaches(T, C), schedule(C, _, _, Day, Slot))),
            FreeSlots).

%% Хоёр багшийн нийтлэг чөлөөт цагийг олох (уулзалт товлоход хэрэгтэй)
%% Жишээ: common_free_slots(battsetseg, saraa, Common).
common_free_slots(T1, T2, CommonSlots) :-
    free_teacher_slots(T1, Free1),
    free_teacher_slots(T2, Free2),
    intersection(Free1, Free2, CommonSlots).

%% Хуваарилахад тохиромжтой өрөө, цаг хосыг хайх
%% (Өгөгдсөн оюутны тооноос их багтаамжтай чөлөөт өрөөг олох)
%% Жишээ: suggest_slot(lecture, 80, Suggestions).
suggest_slot(Type, NStudents, Suggestions) :-
    findall(s(Room,Day,Slot),
            (   room(Room, Type),
                room_capacity(Room, Cap),
                Cap >= NStudents,
                day(Day), slot(Slot),
                \+ schedule(_, _, Room, Day, Slot)
            ),
            Suggestions).

print_suggestions(Type, NStudents) :-
    suggest_slot(Type, NStudents, Sugg),
    length(Sugg, N),
    format("~n=== ~w хичээл (~w оюутан) зохиомжтой цаг/өрөө (~w сонголт) ===~n",
           [Type, NStudents, N]),
    forall(
        member(s(Room,Day,Slot), Sugg),
        format("  ~w өрөө | ~w | ~w~n", [Room, Day, Slot])
    ).

% ============================================================
% НЭМЭЛТs 5: ӨРӨӨНИЙ АШИГЛАЛТЫН СТАТИСТИК
% ============================================================

%% Тухайн өрөөний ашиглалтын хувь (5 өдөр x 5 цаг = 25 боломжит цаг)
room_utilization(Room, UsedCount, TotalSlots, Pct) :-
    room(Room, _),
    TotalSlots is 5 * 5,
    findall(_, schedule(_, _, Room, _, _), Used),
    length(Used, UsedCount),
    Pct is round(UsedCount * 100 / TotalSlots).

%% Бүх өрөөний ашиглалтын тайлан
utilization_report :-
    format("~n=== oroonii ashiglaltiin tailan ===~n"),
    format("~`-t~55|~n"),
    format("~w~t~10|~w~t~20|~w~t~30|~w~t~40|~w~n",
           ['oroo','torol','ashiglasan','niit','huvi']),
    format("~`-t~55|~n"),
    forall(
        room(Room, Type),
        (   room_utilization(Room, Used, Total, Pct),
            format("~w~t~10|~w~t~20|~w~t~30|~w~t~40|~w%~n",
                   [Room, Type, Used, Total, Pct])
        )
    ).

%% Хамгийн их болон хамгийн бага ашиглалттай өрөөг олох
most_used_room(Room, Pct) :-
    findall(p(P,R), (room(R,_), room_utilization(R,_,_,P)), Pairs),
    max_member(p(Pct,Room), Pairs).

least_used_room(Room, Pct) :-
    findall(p(P,R), (room(R,_), room_utilization(R,_,_,P)), Pairs),
    min_member(p(Pct,Room), Pairs).

% ============================================================
% НЭМЭЛТs 6: ДОЛОО ХОНОГИЙН НЭГТГЭСЭН ТАЙЛАН
% ============================================================

weekly_summary :-
    format("~n╔══════════════════════════════════════════════╗~n"),
    format("║          ДОЛОО ХОНОГИЙН НЭГТГЭСЭН ТАЙЛАН    ║~n"),
    format("╚══════════════════════════════════════════════╝~n"),

    format("~n--- Хичээлийн тоо ---~n"),
    findall(C, course(C,_), Courses), length(Courses, NC),
    findall(_, schedule(_,_,_,_,_), Sched), length(Sched, NS),
    format("  Нийт хичээл: ~w | Нийт цагийн тооллого: ~w~n", [NC, NS]),

    format("~n--- Өдрийн ачаалал ---~n"),
    forall(
        day(D),
        (   findall(_, schedule(_,_,_,D,_), DL), length(DL, DN),
            format("  ~w: ~w цаг~n", [D, DN])
        )
    ),

    workload_report,
    utilization_report,

    format("~n--- hamgiin ih/baga ashiglalt ---~n"),
    (most_used_room(MostR, MostP) ->
        format("  Hamgiin ih: ~w (~w%)~n", [MostR, MostP]) ; true),
    (least_used_room(LeastR, LeastP) ->
        format("  hamgiin baga: ~w (~w%)~n", [LeastR, LeastP]) ; true),

    format("~n--- onoshilgoo ---~n"),
    (valid_schedule -> format("  [✓] huvaari huchintei~n") ; format("  [✗] zorchil ilerlee	~n")),
    nl.