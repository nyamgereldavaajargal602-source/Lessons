(clear)

(deffunction ask-question (?question $?allowed-values)
   (printout t ?question)
   (bind ?answer (read))
   (if (lexemep ?answer) then (bind ?answer (lowcase ?answer)))
   (while (not (member$ ?answer ?allowed-values)) do
      (printout t ?question)
      (bind ?answer (read))
      (if (lexemep ?answer) then (bind ?answer (lowcase ?answer))))
   ?answer)

(deffunction max2 (?a ?b)
   (if (> ?a ?b) then ?a else ?b))

; *** НЭМЭЛТ: явцын хувь тооцоолох функц ***
(deffunction pct (?done ?total)
   (if (> ?total 0)
      then (integer (* 100.0 (/ ?done ?total)))
      else 0))

(deftemplate program
   (slot p_code)
   (slot p_level)
   (slot p_credit)
   (slot p_type)
   (slot p_name)
   (slot r_gen_c)
   (slot r_gen_e)
   (slot r_core_c)
   (slot r_core_e)
   (slot r_pro_c)
   (slot r_pro_e)
   (slot r_intern)
   (slot r_prj))

(deftemplate course
   (slot code)
   (slot prev)
   (slot level)
   (slot type)
   (slot credit)
   (slot sem)
   (slot name)
   (slot grade (default 0.0)))

(deftemplate learned-course
   (slot code)
   (slot grade)
   (slot sem)
   (slot year))

(deftemplate req-state
   (slot gen-c  (default 0))
   (slot gen-e  (default 0))
   (slot core-c (default 0))
   (slot core-e (default 0))
   (slot pro-c  (default 0))
   (slot pro-e  (default 0))
   (slot intern (default 0))
   (slot prj    (default 0)))

(deftemplate learned-state
   (slot count   (default 0))
   (slot credits (default 0))
   (slot gpa     (default 0.0))
   (multislot codes))

(deftemplate selected-state
   (slot max-credit)
   (slot cur-credit (default 0))
   (multislot codes))

(deftemplate candidate
   (slot code)
   (slot rank)
   (slot level)
   (slot type)
   (slot credit)
   (slot sem)
   (slot name)
   (slot reason))

(deftemplate unavailable
   (slot code)
   (slot name)
   (slot reason))

(deftemplate semester-choice
   (slot value))

(deftemplate phase
   (slot value))

(defglobal
   ?*sum-grade* = 0.0
   ?*sum-credit* = 0
   ?*count-learned* = 0)

(deffacts boot
   (phase start)
   (learned-state)
   (req-state))

(deffacts program-data
   (program
      (p_code DS061201)
      (p_level BS)
      (p_credit 125)
      (p_type day)
      (p_name "Software engineering")
      (r_gen_c 29)
      (r_gen_e 6)
      (r_core_c 30)
      (r_core_e 6)
      (r_pro_c 30)
      (r_pro_e 16)
      (r_intern 4)
      (r_prj 5)))

(deffacts course-data
   (course (code U.MT101) (prev none)      (level gen)    (type comp) (credit 3) (sem fall)   (name "Math 1"))
   (course (code U.MT102) (prev U.MT101)   (level gen)    (type comp) (credit 3) (sem spring) (name "Math 2"))
   (course (code U.PH101) (prev none)      (level gen)    (type comp) (credit 3) (sem fall)   (name "Physics 1"))
   (course (code U.CE102) (prev none)      (level gen)    (type comp) (credit 3) (sem spring) (name "Communication english"))
   (course (code U.SS102) (prev none)      (level gen)    (type comp) (credit 3) (sem spring) (name "History of Mongolia"))
   (course (code U.ML103) (prev none)      (level gen)    (type comp) (credit 3) (sem fall)   (name "Mongolia language culture"))
   (course (code F.CS101) (prev none)      (level gen)    (type comp) (credit 3) (sem fall)   (name "Introduction to programming"))
   (course (code F.CS102) (prev none)      (level gen)    (type comp) (credit 2) (sem any)    (name "Major orientation"))
   (course (code F.CN104) (prev none)      (level gen)    (type comp) (credit 3) (sem fall)   (name "Engineering economics"))
   (course (code F.EE101) (prev none)      (level gen)    (type comp) (credit 3) (sem spring) (name "Introduction to electronics"))
   (course (code U.SS101) (prev none)      (level gen)    (type elec) (credit 3) (sem any)    (name "Philosophy"))
   (course (code U.SS103) (prev none)      (level gen)    (type elec) (credit 2) (sem any)    (name "Fundamentals of political science"))
   (course (code U.SS113) (prev none)      (level gen)    (type elec) (credit 3) (sem any)    (name "Basics of psychology"))
   (course (code U.SS114) (prev none)      (level gen)    (type elec) (credit 3) (sem any)    (name "Basics of sociology"))
   (course (code U.CD101) (prev none)      (level gen)    (type elec) (credit 1) (sem any)    (name "Disaster management"))
   (course (code U.EG101) (prev none)      (level gen)    (type elec) (credit 3) (sem any)    (name "Ecological and environmental protection"))
   (course (code U.SS109) (prev none)      (level gen)    (type elec) (credit 2) (sem any)    (name "Basics of cultural studies"))
   (course (code U.SS115) (prev none)      (level gen)    (type elec) (credit 3) (sem any)    (name "Human development"))
   (course (code U.PT101) (prev none)      (level gen)    (type elec) (credit 2) (sem fall)   (name "Physical education"))
   (course (code U.FL171) (prev none)      (level gen)    (type elec) (credit 3) (sem any)    (name "Japanese"))
   (course (code U.RL101) (prev none)      (level gen)    (type elec) (credit 3) (sem any)    (name "Russian language I"))
   (course (code U.CT101) (prev none)      (level gen)    (type elec) (credit 3) (sem any)    (name "General chemistry"))
   (course (code U.ED101) (prev none)      (level gen)    (type elec) (credit 3) (sem any)    (name "Descriptive Geometry"))
   (course (code U.PH102) (prev U.PH101)   (level gen)    (type elec) (credit 3) (sem any)    (name "Physics 2"))
   (course (code U.PH104) (prev none)      (level gen)    (type elec) (credit 3) (sem any)    (name "Fundamentals of nanoscience"))
   (course (code F.CS100) (prev none)      (level gen)    (type elec) (credit 3) (sem any)    (name "Basics of algorithms"))
   (course (code F.IT103) (prev none)      (level gen)    (type elec) (credit 3) (sem any)    (name "Basics of programming language"))
   (course (code F.NS102) (prev none)      (level gen)    (type elec) (credit 3) (sem any)    (name "Basics of computer networking and security"))
   (course (code F.CS202) (prev F.CS101)   (level core)   (type comp) (credit 3) (sem spring) (name "Object-oriented programming"))
   (course (code F.CS203) (prev F.CS202)   (level core)   (type comp) (credit 3) (sem fall)   (name "Data structure and algorithms"))
   (course (code F.CS204) (prev U.MT101)   (level core)   (type comp) (credit 3) (sem spring) (name "Discrete structure"))
   (course (code F.CS211) (prev F.CS202)   (level core)   (type comp) (credit 3) (sem fall)   (name "Basics of software engineering"))
   (course (code F.EE202) (prev none)      (level core)   (type comp) (credit 3) (sem spring) (name "Digital electronics"))
   (course (code F.EE281) (prev F.EE202)   (level core)   (type comp) (credit 3) (sem fall)   (name "Microprocessor system"))
   (course (code F.IT202) (prev none)      (level core)   (type comp) (credit 3) (sem fall)   (name "Web design"))
   (course (code F.IT207) (prev F.CS202)   (level core)   (type comp) (credit 3) (sem spring) (name "Human-computer interaction"))
   (course (code F.IT231) (prev F.CS202)   (level core)   (type comp) (credit 3) (sem spring) (name "Database design"))
   (course (code U.MT201) (prev U.MT102)   (level core)   (type comp) (credit 3) (sem spring) (name "Probability theory and mathematical statistics"))
   (course (code F.CS209) (prev F.CS202)   (level core)   (type elec) (credit 3) (sem fall)   (name "Computer graphics"))
   (course (code F.IT203) (prev F.CS202)   (level core)   (type elec) (credit 3) (sem spring) (name "Visual programming"))
   (course (code F.NS204) (prev U.CE102)   (level core)   (type elec) (credit 3) (sem any)    (name "Computer networks 1"))
   (course (code F.NS205) (prev F.NS204)   (level core)   (type elec) (credit 3) (sem any)    (name "Computer networks 2"))
   (course (code U.ED203) (prev none)      (level core)   (type elec) (credit 3) (sem any)    (name "Engineering drawing"))
   (course (code U.ES210) (prev none)      (level core)   (type elec) (credit 3) (sem any)    (name "Science and Technology English"))
   (course (code U.MT202) (prev U.MT102)   (level core)   (type elec) (credit 3) (sem any)    (name "Ordinary differential equations"))
   (course (code U.MT210) (prev U.MT102)   (level core)   (type elec) (credit 3) (sem any)    (name "Theory of optimization"))
   (course (code F.CS301) (prev F.CS202)   (level pro)    (type comp) (credit 3) (sem fall)   (name "Operating system"))
   (course (code F.CS306) (prev F.CS301)   (level pro)    (type comp) (credit 3) (sem spring) (name "Parallel programming"))
   (course (code F.CS311) (prev F.CS211)   (level pro)    (type comp) (credit 3) (sem any)    (name "Software development"))
   (course (code F.CS312) (prev F.CS211)   (level pro)    (type comp) (credit 3) (sem fall)   (name "Software requirements and analysis"))
   (course (code F.CS313) (prev F.CS211)   (level pro)    (type comp) (credit 3) (sem fall)   (name "Software quality assurance and testing"))
   (course (code F.CS314) (prev F.CS211)   (level pro)    (type comp) (credit 3) (sem spring) (name "Software design and architecture"))
   (course (code F.CS315) (prev F.CS313)   (level pro)    (type comp) (credit 3) (sem spring) (name "Software project management"))
   (course (code F.CS316) (prev F.CS311)   (level pro)    (type comp) (credit 3) (sem fall)   (name "Software development process"))
   (course (code F.CS319) (prev F.CS314)   (level pro)    (type comp) (credit 3) (sem any)    (name "Software engineering project"))
   (course (code F.IT237) (prev F.IT231)   (level pro)    (type comp) (credit 3) (sem fall)   (name "Database management"))
   (course (code F.CS303) (prev F.CS202)   (level pro)    (type elec) (credit 3) (sem spring) (name "Introduction to AI"))
   (course (code F.CS305) (prev F.CS202)   (level pro)    (type elec) (credit 3) (sem spring) (name "Principles of programming language"))
   (course (code F.CS317) (prev F.CS202)   (level pro)    (type elec) (credit 3) (sem fall)   (name "Mobile programming"))
   (course (code F.CS322) (prev F.CS209)   (level pro)    (type elec) (credit 3) (sem fall)   (name "Computer vision"))
   (course (code F.CS329) (prev F.IT231)   (level pro)    (type elec) (credit 3) (sem fall)   (name "GIS programming"))
   (course (code F.IT301) (prev F.CS202)   (level pro)    (type elec) (credit 3) (sem any)    (name "Web system's technology"))
   (course (code F.IT302) (prev F.NS204)   (level pro)    (type elec) (credit 3) (sem spring) (name "System and network management"))
   (course (code F.IT312) (prev none)      (level pro)    (type elec) (credit 2) (sem any)    (name "Computer ethics and law"))
   (course (code F.IT336) (prev F.CS312)   (level pro)    (type elec) (credit 3) (sem spring) (name "Enterprise architecture"))
   (course (code F.EE312) (prev F.CS101)   (level pro)    (type elec) (credit 2) (sem any)    (name "Embedded C programming"))
   (course (code F.EE304) (prev F.EE202)   (level pro)    (type elec) (credit 3) (sem any)    (name "Computer architecture and assembly language"))
   (course (code U.EP310) (prev U.ES210)   (level pro)    (type elec) (credit 2) (sem any)    (name "Professional English"))
   (course (code F.NS305) (prev F.CS202)   (level pro)    (type elec) (credit 3) (sem spring) (name "Network programming"))
   (course (code F.NS356) (prev F.CS203)   (level pro)    (type elec) (credit 2) (sem spring) (name "Database security"))
   (course (code F.CS210) (prev F.CS202)   (level intern) (type comp) (credit 2) (sem summer) (name "Programming practice"))
   (course (code F.CS310) (prev F.CS314)   (level intern) (type comp) (credit 2) (sem summer) (name "Software engineering internship"))
   (course (code F.CS330) (prev F.CS319)   (level project)(type comp) (credit 5) (sem any)    (name "Bachelor's thesis"))
)

(deffacts learned-data
   (learned-course (code U.MT101) (grade 2.7) (sem fall)   (year 2021-2022))
   (learned-course (code U.PH101) (grade 3.0) (sem fall)   (year 2021-2022))
   (learned-course (code U.CE102) (grade 3.7) (sem fall)   (year 2021-2022))
   (learned-course (code F.CS101) (grade 2.4) (sem fall)   (year 2021-2022))
   (learned-course (code U.CD101) (grade 4.0) (sem fall)   (year 2021-2022))
   (learned-course (code U.SS109) (grade 3.7) (sem spring) (year 2021-2022))
   (learned-course (code U.MT102) (grade 3.0) (sem spring) (year 2021-2022))
   (learned-course (code F.CN104) (grade 3.4) (sem spring) (year 2021-2022))
   (learned-course (code F.CS102) (grade 2.7) (sem spring) (year 2021-2022))
)

(defrule startup
   ?f <- (phase start)
   =>
   (retract ?f)
   (printout t crlf "========================================" crlf)
   (printout t "HICHEEL SONGOLT SYSTEM" crlf)
   (printout t "Program: DS061201 Software engineering" crlf)
   (printout t "========================================" crlf crlf)
   (assert (semester-choice (value (ask-question "Semester (fall spring): " fall spring))))
   (printout t "Credit limit: ")
   (assert (selected-state (max-credit (read)) (cur-credit 0)))
   (assert (phase update-learned))
)

(defrule apply-learned-grade
   (phase update-learned)
   ?ls <- (learned-state (count ?n) (credits ?c) (gpa ?g) (codes $?codes))
   ?rs <- (req-state (gen-c ?gc) (gen-e ?ge) (core-c ?cc) (core-e ?ce) (pro-c ?pc) (pro-e ?pe) (intern ?ic) (prj ?pj))
   (learned-course (code ?code) (grade ?gr))
   ?c1 <- (course (code ?code) (grade 0.0) (credit ?cr) (level ?lv) (type ?tp))
   =>
   (modify ?c1 (grade ?gr))
   (bind ?*sum-grade* (+ ?*sum-grade* (* ?cr ?gr)))
   (bind ?*sum-credit* (+ ?*sum-credit* ?cr))
   (bind ?*count-learned* (+ ?*count-learned* 1))
   (if (eq ?lv gen) then
      (if (eq ?tp comp) then (bind ?gc (+ ?gc ?cr)) else (bind ?ge (+ ?ge ?cr))))
   (if (eq ?lv core) then
      (if (eq ?tp comp) then (bind ?cc (+ ?cc ?cr)) else (bind ?ce (+ ?ce ?cr))))
   (if (eq ?lv pro) then
      (if (eq ?tp comp) then (bind ?pc (+ ?pc ?cr)) else (bind ?pe (+ ?pe ?cr))))
   (if (eq ?lv intern) then (bind ?ic (+ ?ic ?cr)))
   (if (eq ?lv project) then (bind ?pj (+ ?pj ?cr)))
   (modify ?rs
      (gen-c ?gc) (gen-e ?ge)
      (core-c ?cc) (core-e ?ce)
      (pro-c ?pc) (pro-e ?pe)
      (intern ?ic) (prj ?pj))
   (modify ?ls
      (count ?*count-learned*)
      (credits ?*sum-credit*)
      (gpa (/ ?*sum-grade* ?*sum-credit*))
      (codes $?codes ?code))
)

(defrule finish-update
   ?f <- (phase update-learned)
   =>
   (retract ?f)
   (assert (phase report-progress))
)

; *** ӨӨРЧЛӨГДСӨН ДҮРЭМ: % нэмсэн ***
(defrule print-summary
   ?f <- (phase report-progress)
   (learned-state (count ?cnt) (credits ?cr) (gpa ?gpa))
   (req-state (gen-c ?gc1) (gen-e ?ge1) (core-c ?cc1) (core-e ?ce1) (pro-c ?pc1) (pro-e ?pe1) (intern ?int1) (prj ?prj1))
   (program (p_credit ?total) (r_gen_c ?gc) (r_gen_e ?ge) (r_core_c ?cc) (r_core_e ?ce) (r_pro_c ?pc) (r_pro_e ?pe) (r_intern ?int) (r_prj ?prj))
   =>
   (printout t crlf "--------------- SUMMARY ---------------" crlf)
   (format t "Learned courses : %d%n" ?cnt)
   (format t "Earned credits  : %d / %d (%d%%)%n" ?cr ?total (pct ?cr ?total))
   (format t "GPA             : %.2f%n" ?gpa)
   (printout t "---------------------------------------" crlf)
   (format t "Gen comp   : %d / %d   left %d  (%d%%)%n" ?gc1 ?gc (max2 0 (- ?gc ?gc1))    (pct ?gc1 ?gc))
   (format t "Gen elec   : %d / %d   left %d  (%d%%)%n" ?ge1 ?ge (max2 0 (- ?ge ?ge1))    (pct ?ge1 ?ge))
   (format t "Core comp  : %d / %d   left %d  (%d%%)%n" ?cc1 ?cc (max2 0 (- ?cc ?cc1))    (pct ?cc1 ?cc))
   (format t "Core elec  : %d / %d   left %d  (%d%%)%n" ?ce1 ?ce (max2 0 (- ?ce ?ce1))    (pct ?ce1 ?ce))
   (format t "Pro comp   : %d / %d   left %d  (%d%%)%n" ?pc1 ?pc (max2 0 (- ?pc ?pc1))    (pct ?pc1 ?pc))
   (format t "Pro elec   : %d / %d   left %d  (%d%%)%n" ?pe1 ?pe (max2 0 (- ?pe ?pe1))    (pct ?pe1 ?pe))
   (format t "Internship : %d / %d   left %d  (%d%%)%n" ?int1 ?int (max2 0 (- ?int ?int1)) (pct ?int1 ?int))
   (format t "Project    : %d / %d   left %d  (%d%%)%n" ?prj1 ?prj (max2 0 (- ?prj ?prj1)) (pct ?prj1 ?prj))
   (printout t "---------------------------------------" crlf crlf)
   (retract ?f)
   (assert (phase build-candidates))
)

(defrule make-candidate-no-prereq
   (phase build-candidates)
   (semester-choice (value ?want))
   (req-state (gen-c ?gc1) (gen-e ?ge1) (core-c ?cc1) (core-e ?ce1) (pro-c ?pc1) (pro-e ?pe1) (intern ?int1) (prj ?prj1))
   (program (r_gen_c ?gc) (r_gen_e ?ge) (r_core_c ?cc) (r_core_e ?ce) (r_pro_c ?pc) (r_pro_e ?pe) (r_intern ?int) (r_prj ?prj))
   (course (code ?code) (prev none) (grade 0.0) (level ?lv) (type ?tp) (credit ?cr) (sem ?sem) (name ?name))
   (test (or (eq ?sem any) (eq ?sem ?want)))
   (not (candidate (code ?code)))
   =>
   (bind ?rank -1.0)
   (bind ?reason "")
   (if (and (eq ?lv gen) (eq ?tp comp) (< ?gc1 ?gc)) then
      (bind ?rank 3.0)
      (bind ?reason "gen comp, no prerequisite, semester ok"))
   (if (and (eq ?lv gen) (eq ?tp elec) (< ?ge1 ?ge)) then
      (bind ?rank 2.5)
      (bind ?reason "gen elec, no prerequisite, semester ok"))
   (if (and (eq ?lv core) (eq ?tp comp) (< ?cc1 ?cc)) then
      (bind ?rank 2.0)
      (bind ?reason "core comp, no prerequisite, semester ok"))
   (if (and (eq ?lv core) (eq ?tp elec) (< ?ce1 ?ce)) then
      (bind ?rank 1.5)
      (bind ?reason "core elec, no prerequisite, semester ok"))
   (if (and (eq ?lv pro) (eq ?tp comp) (< ?pc1 ?pc)) then
      (bind ?rank 1.0)
      (bind ?reason "pro comp, no prerequisite, semester ok"))
   (if (and (eq ?lv pro) (eq ?tp elec) (< ?pe1 ?pe)) then
      (bind ?rank 0.5)
      (bind ?reason "pro elec, no prerequisite, semester ok"))
   (if (and (eq ?lv intern) (< ?int1 ?int)) then
      (bind ?rank 0.5)
      (bind ?reason "internship requirement, semester ok"))
   (if (and (eq ?lv project) (< ?prj1 ?prj)) then
      (bind ?rank 0.5)
      (bind ?reason "project requirement, semester ok"))
   (if (>= ?rank 0.0) then
      (assert (candidate (code ?code) (rank ?rank) (level ?lv) (type ?tp) (credit ?cr) (sem ?sem) (name ?name) (reason ?reason))))
)

(defrule make-candidate-with-prereq
   (phase build-candidates)
   (semester-choice (value ?want))
   (req-state (gen-c ?gc1) (gen-e ?ge1) (core-c ?cc1) (core-e ?ce1) (pro-c ?pc1) (pro-e ?pe1) (intern ?int1) (prj ?prj1))
   (program (r_gen_c ?gc) (r_gen_e ?ge) (r_core_c ?cc) (r_core_e ?ce) (r_pro_c ?pc) (r_pro_e ?pe) (r_intern ?int) (r_prj ?prj))
   (course (code ?pre) (grade ?g&:(> ?g 0.0)))
   (course (code ?code) (prev ?pre) (grade 0.0) (level ?lv) (type ?tp) (credit ?cr) (sem ?sem) (name ?name))
   (test (or (eq ?sem any) (eq ?sem ?want)))
   (not (candidate (code ?code)))
   =>
   (bind ?rank -1.0)
   (bind ?reason "")
   (if (and (eq ?lv gen) (eq ?tp comp) (< ?gc1 ?gc)) then
      (bind ?rank 3.0)
      (bind ?reason (str-cat "gen comp, prerequisite " ?pre " done, semester ok")))
   (if (and (eq ?lv gen) (eq ?tp elec) (< ?ge1 ?ge)) then
      (bind ?rank 2.5)
      (bind ?reason (str-cat "gen elec, prerequisite " ?pre " done, semester ok")))
   (if (and (eq ?lv core) (eq ?tp comp) (< ?cc1 ?cc)) then
      (bind ?rank 2.0)
      (bind ?reason (str-cat "core comp, prerequisite " ?pre " done, semester ok")))
   (if (and (eq ?lv core) (eq ?tp elec) (< ?ce1 ?ce)) then
      (bind ?rank 1.5)
      (bind ?reason (str-cat "core elec, prerequisite " ?pre " done, semester ok")))
   (if (and (eq ?lv pro) (eq ?tp comp) (< ?pc1 ?pc)) then
      (bind ?rank 1.0)
      (bind ?reason (str-cat "pro comp, prerequisite " ?pre " done, semester ok")))
   (if (and (eq ?lv pro) (eq ?tp elec) (< ?pe1 ?pe)) then
      (bind ?rank 0.5)
      (bind ?reason (str-cat "pro elec, prerequisite " ?pre " done, semester ok")))
   (if (and (eq ?lv intern) (< ?int1 ?int)) then
      (bind ?rank 0.5)
      (bind ?reason (str-cat "internship requirement, prerequisite " ?pre " done")))
   (if (and (eq ?lv project) (< ?prj1 ?prj)) then
      (bind ?rank 0.5)
      (bind ?reason (str-cat "project requirement, prerequisite " ?pre " done")))
   (if (>= ?rank 0.0) then
      (assert (candidate (code ?code) (rank ?rank) (level ?lv) (type ?tp) (credit ?cr) (sem ?sem) (name ?name) (reason ?reason))))
)

(defrule unavailable-by-semester
   (phase build-candidates)
   (semester-choice (value ?want))
   (course (code ?code) (grade 0.0) (sem ?sem&~any&~?want) (name ?name))
   (not (unavailable (code ?code)))
   =>
   (assert (unavailable (code ?code) (name ?name) (reason (str-cat "offered in " ?sem " only"))))
)

(defrule unavailable-by-prereq
   (phase build-candidates)
   (course (code ?code) (prev ?pre&~none) (grade 0.0) (name ?name))
   (not (course (code ?pre) (grade ?g&:(> ?g 0.0))))
   (not (unavailable (code ?code)))
   =>
   (assert (unavailable (code ?code) (name ?name) (reason (str-cat "missing prerequisite " ?pre))))
)

(defrule finish-build
   ?f <- (phase build-candidates)
   =>
   (retract ?f)
   (assert (phase select-r3))
)

(defrule select-r3
   ?f <- (phase select-r3)
   ?ss <- (selected-state (max-credit ?max) (cur-credit ?cur) (codes $?sel))
   ?c <- (candidate (code ?code) (rank 3.0) (credit ?cr))
   (test (not (member$ ?code $?sel)))
   (test (<= (+ ?cur ?cr) ?max))
   =>
   (modify ?ss (cur-credit (+ ?cur ?cr)) (codes $?sel ?code))
)

(defrule next-r3
   ?f <- (phase select-r3)
   =>
   (retract ?f)
   (assert (phase select-r25))
)

(defrule select-r25
   ?f <- (phase select-r25)
   ?ss <- (selected-state (max-credit ?max) (cur-credit ?cur) (codes $?sel))
   ?c <- (candidate (code ?code) (rank 2.5) (credit ?cr))
   (test (not (member$ ?code $?sel)))
   (test (<= (+ ?cur ?cr) ?max))
   =>
   (modify ?ss (cur-credit (+ ?cur ?cr)) (codes $?sel ?code))
)

(defrule next-r25
   ?f <- (phase select-r25)
   =>
   (retract ?f)
   (assert (phase select-r2))
)

(defrule select-r2
   ?f <- (phase select-r2)
   ?ss <- (selected-state (max-credit ?max) (cur-credit ?cur) (codes $?sel))
   ?c <- (candidate (code ?code) (rank 2.0) (credit ?cr))
   (test (not (member$ ?code $?sel)))
   (test (<= (+ ?cur ?cr) ?max))
   =>
   (modify ?ss (cur-credit (+ ?cur ?cr)) (codes $?sel ?code))
)

(defrule next-r2
   ?f <- (phase select-r2)
   =>
   (retract ?f)
   (assert (phase select-r15))
)

(defrule select-r15
   ?f <- (phase select-r15)
   ?ss <- (selected-state (max-credit ?max) (cur-credit ?cur) (codes $?sel))
   ?c <- (candidate (code ?code) (rank 1.5) (credit ?cr))
   (test (not (member$ ?code $?sel)))
   (test (<= (+ ?cur ?cr) ?max))
   =>
   (modify ?ss (cur-credit (+ ?cur ?cr)) (codes $?sel ?code))
)

(defrule next-r15
   ?f <- (phase select-r15)
   =>
   (retract ?f)
   (assert (phase select-r1))
)

(defrule select-r1
   ?f <- (phase select-r1)
   ?ss <- (selected-state (max-credit ?max) (cur-credit ?cur) (codes $?sel))
   ?c <- (candidate (code ?code) (rank 1.0) (credit ?cr))
   (test (not (member$ ?code $?sel)))
   (test (<= (+ ?cur ?cr) ?max))
   =>
   (modify ?ss (cur-credit (+ ?cur ?cr)) (codes $?sel ?code))
)

(defrule next-r1
   ?f <- (phase select-r1)
   =>
   (retract ?f)
   (assert (phase select-r05))
)

(defrule select-r05
   ?f <- (phase select-r05)
   ?ss <- (selected-state (max-credit ?max) (cur-credit ?cur) (codes $?sel))
   ?c <- (candidate (code ?code) (rank 0.5) (credit ?cr))
   (test (not (member$ ?code $?sel)))
   (test (<= (+ ?cur ?cr) ?max))
   =>
   (modify ?ss (cur-credit (+ ?cur ?cr)) (codes $?sel ?code))
)

(defrule finish-selection
   ?f <- (phase select-r05)
   =>
   (retract ?f)
   (assert (phase print-selected))
)

(defrule print-selected-header
   ?f <- (phase print-selected)
   =>
   (printout t crlf "----------- RECOMMENDED COURSES -----------" crlf)
   (printout t "Code       Cr  Sem      Level      Type      Reason" crlf)
   (printout t "-------------------------------------------" crlf)
)

(defrule print-selected-item
   (phase print-selected)
   ?ss <- (selected-state (max-credit ?m) (cur-credit ?cur) (codes ?code $?rest))
   (candidate (code ?code) (credit ?cr) (sem ?sem) (level ?lv) (type ?tp) (reason ?reason))
   =>
   (format t "%-10s %-3d %-8s %-10s %-9s %s%n" ?code ?cr ?sem ?lv ?tp ?reason)
   (modify ?ss (max-credit ?m) (cur-credit ?cur) (codes $?rest))
)

(defrule print-selected-footer
   ?f <- (phase print-selected)
   (selected-state (max-credit ?m) (cur-credit ?cur) (codes))
   =>
   (printout t "-------------------------------------------" crlf)
   (format t "Selected credits: %d / %d%n" ?cur ?m)
   (printout t "-------------------------------------------" crlf)
   (retract ?f)
   (assert (phase print-unavailable))
)

(defrule print-unavailable-header
   ?f <- (phase print-unavailable)
   =>
   (printout t crlf "----------- NOT AVAILABLE NOW ------------" crlf)
   (printout t "Code       Name                                Reason" crlf)
   (printout t "-------------------------------------------" crlf)
)

(defrule print-unavailable-item
   (phase print-unavailable)
   ?u <- (unavailable (code ?code) (name ?name) (reason ?reason))
   =>
   (format t "%-10s %-35s %s%n" ?code ?name ?reason)
   (retract ?u)
)

(defrule print-unavailable-footer
   ?f <- (phase print-unavailable)
   =>
   (printout t "-------------------------------------------" crlf)
   (retract ?f)
)

(reset)
(run)
