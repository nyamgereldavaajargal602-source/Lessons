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

(deffunction load-program-data (?filename)
   (if (not (open ?filename pfile "r")) then
      (printout t "ERROR: program file not found -> " ?filename crlf)
      (halt))

   (assert
      (program
         (p_code (read pfile))
         (p_level (read pfile))
         (p_credit (read pfile))
         (p_type (read pfile))
         (p_name (readline pfile))
         (r_gen_c (read pfile))
         (r_gen_e (read pfile))
         (r_core_c (read pfile))
         (r_core_e (read pfile))
         (r_pro_c (read pfile))
         (r_pro_e (read pfile))
         (r_intern (read pfile))
         (r_prj (read pfile))))

   (while (neq (bind ?code (read pfile)) EOF)
      (assert
         (course
            (code ?code)
            (prev (read pfile))
            (level (read pfile))
            (type (read pfile))
            (credit (read pfile))
            (sem (read pfile))
            (name (readline pfile)))))

   (close pfile))

(deffunction load-learned-data (?filename)
   (if (not (open ?filename lfile "r")) then
      (printout t "ERROR: learned file not found -> " ?filename crlf)
      (halt))

   (while (neq (bind ?code (read lfile)) EOF)
      (assert
         (learned-course
            (code ?code)
            (grade (read lfile))
            (sem (read lfile))
            (year (read lfile)))))

   (close lfile))

(defrule startup
   ?f <- (phase start)
   =>
   (retract ?f)
   (printout t crlf "========================================" crlf)
   (printout t "HICHEEL SONGOLT SYSTEM" crlf)
   (printout t "Program: DS061201 Software engineering" crlf)
   (printout t "========================================" crlf crlf)

   ; data-g file-uudiig unshina
   (load-program-data "program_data.txt")
   (load-learned-data "learned_data.txt")

   (assert (semester-choice (value (ask-question "Semester (fall spring): " fall spring))))
   (printout t "Credit limit: ")
   (assert (selected-state (max-credit (read)) (cur-credit 0)))
   (assert (phase update-learned)))

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
      (codes $?codes ?code)))

(defrule finish-update
   ?f <- (phase update-learned)
   =>
   (retract ?f)
   (assert (phase report-progress)))

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
   (assert (phase build-candidates)))

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
      (assert (candidate (code ?code) (rank ?rank) (level ?lv) (type ?tp) (credit ?cr) (sem ?sem) (name ?name) (reason ?reason)))))

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
      (assert (candidate (code ?code) (rank ?rank) (level ?lv) (type ?tp) (credit ?cr) (sem ?sem) (name ?name) (reason ?reason)))))

(defrule unavailable-by-semester
   (phase build-candidates)
   (semester-choice (value ?want))
   (course (code ?code) (grade 0.0) (sem ?sem&~any&~?want) (name ?name))
   (not (unavailable (code ?code)))
   =>
   (assert (unavailable (code ?code) (name ?name) (reason (str-cat "offered in " ?sem " only")))))

(defrule unavailable-by-prereq
   (phase build-candidates)
   (course (code ?code) (prev ?pre&~none) (grade 0.0) (name ?name))
   (not (course (code ?pre) (grade ?g&:(> ?g 0.0))))
   (not (unavailable (code ?code)))
   =>
   (assert (unavailable (code ?code) (name ?name) (reason (str-cat "missing prerequisite " ?pre)))))

(defrule finish-build
   ?f <- (phase build-candidates)
   =>
   (retract ?f)
   (assert (phase select-r3)))

(defrule select-r3
   ?f <- (phase select-r3)
   ?ss <- (selected-state (max-credit ?max) (cur-credit ?cur) (codes $?sel))
   ?c <- (candidate (code ?code) (rank 3.0) (credit ?cr))
   (test (not (member$ ?code $?sel)))
   (test (<= (+ ?cur ?cr) ?max))
   =>
   (modify ?ss (cur-credit (+ ?cur ?cr)) (codes $?sel ?code)))

(defrule next-r3
   ?f <- (phase select-r3)
   =>
   (retract ?f)
   (assert (phase select-r25)))

(defrule select-r25
   ?f <- (phase select-r25)
   ?ss <- (selected-state (max-credit ?max) (cur-credit ?cur) (codes $?sel))
   ?c <- (candidate (code ?code) (rank 2.5) (credit ?cr))
   (test (not (member$ ?code $?sel)))
   (test (<= (+ ?cur ?cr) ?max))
   =>
   (modify ?ss (cur-credit (+ ?cur ?cr)) (codes $?sel ?code)))

(defrule next-r25
   ?f <- (phase select-r25)
   =>
   (retract ?f)
   (assert (phase select-r2)))

(defrule select-r2
   ?f <- (phase select-r2)
   ?ss <- (selected-state (max-credit ?max) (cur-credit ?cur) (codes $?sel))
   ?c <- (candidate (code ?code) (rank 2.0) (credit ?cr))
   (test (not (member$ ?code $?sel)))
   (test (<= (+ ?cur ?cr) ?max))
   =>
   (modify ?ss (cur-credit (+ ?cur ?cr)) (codes $?sel ?code)))

(defrule next-r2
   ?f <- (phase select-r2)
   =>
   (retract ?f)
   (assert (phase select-r15)))

(defrule select-r15
   ?f <- (phase select-r15)
   ?ss <- (selected-state (max-credit ?max) (cur-credit ?cur) (codes $?sel))
   ?c <- (candidate (code ?code) (rank 1.5) (credit ?cr))
   (test (not (member$ ?code $?sel)))
   (test (<= (+ ?cur ?cr) ?max))
   =>
   (modify ?ss (cur-credit (+ ?cur ?cr)) (codes $?sel ?code)))

(defrule next-r15
   ?f <- (phase select-r15)
   =>
   (retract ?f)
   (assert (phase select-r1)))

(defrule select-r1
   ?f <- (phase select-r1)
   ?ss <- (selected-state (max-credit ?max) (cur-credit ?cur) (codes $?sel))
   ?c <- (candidate (code ?code) (rank 1.0) (credit ?cr))
   (test (not (member$ ?code $?sel)))
   (test (<= (+ ?cur ?cr) ?max))
   =>
   (modify ?ss (cur-credit (+ ?cur ?cr)) (codes $?sel ?code)))

(defrule next-r1
   ?f <- (phase select-r1)
   =>
   (retract ?f)
   (assert (phase select-r05)))

(defrule select-r05
   ?f <- (phase select-r05)
   ?ss <- (selected-state (max-credit ?max) (cur-credit ?cur) (codes $?sel))
   ?c <- (candidate (code ?code) (rank 0.5) (credit ?cr))
   (test (not (member$ ?code $?sel)))
   (test (<= (+ ?cur ?cr) ?max))
   =>
   (modify ?ss (cur-credit (+ ?cur ?cr)) (codes $?sel ?code)))

(defrule finish-selection
   ?f <- (phase select-r05)
   =>
   (retract ?f)
   (assert (phase print-selected)))

(defrule print-selected-header
   ?f <- (phase print-selected)
   =>
   (printout t crlf "----------- RECOMMENDED COURSES -----------" crlf)
   (printout t "Code       Cr  Sem      Level      Type      Reason" crlf)
   (printout t "-------------------------------------------" crlf))

(defrule print-selected-item
   (phase print-selected)
   ?ss <- (selected-state (max-credit ?m) (cur-credit ?cur) (codes ?code $?rest))
   (candidate (code ?code) (credit ?cr) (sem ?sem) (level ?lv) (type ?tp) (reason ?reason))
   =>
   (format t "%-10s %-3d %-8s %-10s %-9s %s%n" ?code ?cr ?sem ?lv ?tp ?reason)
   (modify ?ss (max-credit ?m) (cur-credit ?cur) (codes $?rest)))

(defrule print-selected-footer
   ?f <- (phase print-selected)
   (selected-state (max-credit ?m) (cur-credit ?cur) (codes))
   =>
   (printout t "-------------------------------------------" crlf)
   (format t "Selected credits: %d / %d%n" ?cur ?m)
   (printout t "-------------------------------------------" crlf)
   (retract ?f)
   (assert (phase print-unavailable)))

(defrule print-unavailable-header
   ?f <- (phase print-unavailable)
   =>
   (printout t crlf "----------- NOT AVAILABLE NOW ------------" crlf)
   (printout t "Code       Name                                Reason" crlf)
   (printout t "-------------------------------------------" crlf))

(defrule print-unavailable-item
   (phase print-unavailable)
   ?u <- (unavailable (code ?code) (name ?name) (reason ?reason))
   =>
   (format t "%-10s %-35s %s%n" ?code ?name ?reason)
   (retract ?u))

(defrule print-unavailable-footer
   ?f <- (phase print-unavailable)
   =>
   (printout t "-------------------------------------------" crlf)
   (retract ?f))

(reset)
(run)
