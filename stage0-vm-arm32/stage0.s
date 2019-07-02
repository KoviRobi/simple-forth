/* TODO: Use this more liberally */
.macro .fdef1 name:req, label, imm, hidden, rest:vararg
  .entry \name, \label, \imm, \hidden
  .forth_interpreter
  .ifnb \rest ; .fw \rest ; .endif
.endm
.macro .fdef name:req, label, rest:vararg
  .fdef1 \name, \label, 0, 0, \rest
.endm

.fdef "1-", DECR, LIT, L,1, SUB, EXIT
.fdef "1+", INCR, LIT, L,1, ADD, EXIT
.fdef "2DUP", TWO_DUP, OVER, OVER, EXIT
.fdef "2DROP", TWO_DROP, DROP, DROP, EXIT
.fdef "-ROT", NROT, ROT, ROT, EXIT
.fdef "2>R", TWO_TO_R, R_FROM, NROT, SWAP
.fw TO_R, TO_R, TO_R, EXIT
.fdef "2R>", TWO_R_FROM, R_FROM, R_FROM
.fw R_FROM, ROT, TO_R, SWAP, EXIT
.fdef "2RDROP", TWO_R_DROP, R_FROM, R_FROM
.fw R_FROM, TWO_DROP, TO_R, EXIT
.fdef "2R\x40", TWO_R_FETCH, R_FROM
.fw TWO_R_FROM, TWO_DUP, TWO_TO_R, ROT
.fw TO_R, EXIT
.fdef "TRUE", _, LIT, L,-1, EXIT
.fdef "FALSE", _, LIT, L,0, EXIT
.fdef "HERE_VAR", _, LIT, L,HERE_LOC, EXIT
.fdef "LATEST", _, LIT, L,LATEST_LOC, EXIT
.fdef "STATE", _, LIT, L,STATE_LOC, EXIT
.fdef "HERE", _, HERE_VAR, FETCH, EXIT
.fdef "CHAR+", CHAR_ADD, CHAR_SIZE, ADD, EXIT
.fdef "CELL+", CELL_ADD, CELL_SIZE, ADD, EXIT
.fdef "CHARS", _, CHAR_SIZE, STAR, EXIT
.fdef "CELLS", _, CELL_SIZE, STAR, EXIT
.fdef "C\x2c", C_COMMA, HERE, C_STORE, HERE
.fw CHAR_ADD, HERE_VAR, STORE, EXIT
.fdef "\x2c", COMMA, HERE, STORE, HERE
.fw CELL_ADD, HERE_VAR, STORE, EXIT

.fdef "ALLOT", _
  .fw HERE, ADD, HERE_VAR, STORE, EXIT

.fdef "ALIGN", _
  .fw HERE, CELL_SIZE, DECR, ADD
  .fw CELL_SIZE, DECR, INVERT, AND
  .fw HERE_VAR, STORE, EXIT

.fdef "CREATE", _
  .fw ALIGN
  .fw HERE, LATEST, FETCH
  .fw COMMA, LATEST, STORE
  .fw LIT, L,0, C_COMMA
  .fw LIT, L,0, C_COMMA, ALIGN
  .fw BL, WORD
  .fw CELL_SIZE, ALLOT
  .fw FETCH, CHARS, ALLOT
  .fw LIT, L,0, C_COMMA
  .fw EXIT

.fdef "BALIGN", BALIGN, DECR, SWAP, OVER
.fw ADD, SWAP, INVERT, AND, EXIT
.fdef "ENTRY-NEXT", ENTRY_NEXT, EXIT
.fdef "ENTRY-FLAGS", ENTRY_FLAGS, CELL_ADD, EXIT
.fdef "ENTRY-LEN", ENTRY_LEN, LIT, L,2
.fw CELLS, ADD, EXIT
.fdef "ENTRY-CHARS", ENTRY_CHARS, LIT, L,3
.fw CELLS, ADD, EXIT
.fdef "ENTRY-XT", ENTRY_XT, DUP
.fw ENTRY_LEN, FETCH, LIT, L,1, ADD, SWAP
.fw ENTRY_CHARS, ADD, LIT, L,4, BALIGN, EXIT

.fdef "HIDDEN?", HIDDENP
  .fw ENTRY_FLAGS, C_FETCH, EXIT

.fdef "IMMEDIATE?", IMMEDIATEP
  .fw ENTRY_FLAGS, CHAR_ADD, C_FETCH, EXIT

.fdef "HIDE", _, CELL_ADD, DUP, C_FETCH
  .fw INVERT, SWAP, C_STORE, EXIT

.fdef1 "IMMEDIATE", _, -1 /* immediate */
  .fw LATEST, FETCH
  .fw TRUE, SWAP, CELL_ADD, CHAR_ADD, C_STORE, EXIT

.fdef "FIND\x27", FIND_NEW
  .fw LATEST, FETCH
FIND_LOOP: /* ( c-addr u entry ) */
  .fw DUP, LIT, L,0, EQUAL, ZBRANCH, L,(FIND_NON_END-.)
  .fw DROP, DROP, LIT, L,0, EXIT
FIND_NON_END:
  .fw DUP, HIDDENP, INVERT
  .fw ZBRANCH, L,(FIND_NEXT_ENTRY-.)

  .fw TWO_DUP, ENTRY_LEN, FETCH, EQUAL
  .fw ZBRANCH, L,(FIND_NEXT_ENTRY-.)
  /* c-addr u entry */
  .fw TWO_DUP, ENTRY_CHARS
  .fw LIT, L,4, PICK
  /* c-addr u entry u entry-str c-addr */
  .fw MEMCMP, ZBRANCH, L,(FIND_NEXT_ENTRY-.)

  .fw NIP, NIP
  .fw DUP, ENTRY_XT
  .fw SWAP, IMMEDIATEP
  .fw ZBRANCH, L,(NON_IMM-.), LIT, L,1, BRANCH, L,(IMM_END-.)
NON_IMM:
  .fw LIT, L,-1
IMM_END:
  .fw EXIT

FIND_NEXT_ENTRY:
  .fw FETCH
  .fw BRANCH, L,(FIND_LOOP-.)

.fdef "MEMCMP", _
  .fw ROT, LIT, L,0
  .fw TWO_TO_R
MEMCMP_LOOP:
  .fw TWO_DUP, R_FETCH, ADD, C_FETCH
  .fw SWAP, R_FETCH, ADD, C_FETCH

  .fw CHAR_EQUAL, INVERT, ZBRANCH, L,(MEMCMP_NEXT-.)
  .fw TWO_R_DROP, TWO_DROP, FALSE, EXIT
MEMCMP_NEXT:
  .fw R_FROM, LIT, L,1, ADD, TO_R
  .fw TWO_R_FETCH, EQUAL
  .fw ZBRANCH, L,(MEMCMP_LOOP-.)
  .fw TWO_R_DROP

  .fw TWO_DROP, TRUE, EXIT

.fdef "LOWER", _
  .fw DUP, LIT, L,'A', U_LESS_THAN
  .fw OVER, LIT, L,'Z', U_GREATER_THAN
  .fw OR, INVERT, ZBRANCH, L,(1f-.)
  .fw LIT, L,32, ADD
1:.fw EXIT

.fdef "CHAR\x3d", CHAR_EQUAL
  .fw TWO_DUP, EQUAL, ZBRANCH, L,(1f-.)
  .fw TWO_DROP, TRUE, EXIT
1:.fw OVER, LIT, L,33, U_LESS_THAN
  .fw OVER, LIT, L,33, U_LESS_THAN
  .fw AND, ZBRANCH, L,(2f-.)
  .fw TWO_DROP, TRUE, EXIT
2:.fw LOWER, SWAP, LOWER, EQUAL
  .fw ZBRANCH, L,(3f-.)
  .fw TRUE, EXIT
3:.fw FALSE, EXIT

.fdef "WORD\x27", WORD_NEW
  .fw HERE, SWAP, LIT, L,0
WORD_SKIP:
  .fw DROP, KEY, TWO_DUP, CHAR_EQUAL
  .fw INVERT, ZBRANCH, L,(WORD_SKIP-.)
WORD_LOOP:
  .fw DUP, C_COMMA, OVER, CHAR_EQUAL
  .fw ZBRANCH, L,(WORD_CONT-.)
  .fw DROP, CHAR_SIZE, NEGATE, ALLOT
  .fw HERE, OVER, SUB, LIT, L,0, C_COMMA
  .fw LIT, L,-1, OVER, SUB, ALLOT, EXIT
WORD_CONT:
  .fw KEY, BRANCH, L,(WORD_LOOP-.)

.fdef "WORD", WORD
  .fw HERE, SWAP, CELL_SIZE, ALLOT,
  .fw WORD_NEW, ROT, STORE
  .fw CELL_SIZE, NEGATE, ALLOT
  .fw CELL_SIZE, SUB, EXIT

.fdef "CHAR->DIGIT", CHAR_TO_DIGIT
  .fw LIT, L,'0', SUB
  .fw DUP, LIT, L,9, U_GREATER_THAN, ZBRANCH, L,(C_TO_D_END-.)
  .fw LIT, L,('A'-'9'-1), SUB
  .fw DUP, LIT, L,10, U_LESS_THAN, ZBRANCH, L,(C_TO_D_A-.)
  .fw LIT, L,10, SUB
C_TO_D_A:
  .fw DUP, LIT, L,35, U_GREATER_THAN, ZBRANCH, L,(C_TO_D_END-.)
  .fw LIT, L,32, SUB
  .fw DUP, LIT, L,10, U_LESS_THAN, ZBRANCH, L,(C_TO_D_END-.)
  .fw LIT, L,10, SUB
C_TO_D_END:
  .fw EXIT

.data
BASE_LOC: .cell 10
.text
.fdef "BASE", BASE
  .fw LIT, L,BASE_LOC, EXIT
.fdef "DECIMAL", DECIMAL
  .fw LIT, L,10, BASE, STORE, EXIT
.fdef ">NUMBER", TO_NUMBER
  .fw OVER, ADD, DUP, TO_R, SWAP
  .fw TWO_TO_R
TO_NUM_LOOP:
  .fw R_FETCH, C_FETCH, CHAR_TO_DIGIT, DUP
  .fw BASE, FETCH, U_LESS_THAN
  .fw ZBRANCH, L,(TO_NUM_ELSE-.)
  .fw SWAP, BASE, FETCH, STAR, ADD
  .fw BRANCH, L,(TO_NUM_NEXT-.)
TO_NUM_ELSE:
  .fw DROP, R_FETCH, TWO_R_DROP, R_FROM
  .fw OVER, SUB,  EXIT
TO_NUM_NEXT:
  .fw R_FROM, LIT, L,1, ADD, TO_R
  .fw TWO_R_FETCH, EQUAL
  .fw ZBRANCH, L,(TO_NUM_LOOP-.)
  .fw TWO_R_DROP
  .fw R_FROM, LIT, L,0
  .fw EXIT

.fdef "BL", BL
  .fw LIT, L,' ', EXIT

.fdef "\x27", TICK
  .fw BL, WORD_NEW, FIND_NEW, DROP, EXIT

.fdef "OK", OK
  .fw LIT, L,'O', EMIT, LIT, L,'k'
  .fw EMIT, BL, EMIT, EXIT

.fdef "ERROR", ERROR
  .fw LIT, L,'E', EMIT, LIT, L,'r', EMIT
  .fw LIT, L,'r', EMIT, BL, EMIT, EXIT

// TODO: Different interpretation modes
.fdef "COMPILE\x2c", COMPILE_COMMA
  .fw COMMA, EXIT

.fdef "QUIT-FOUND", QUIT_FOUND
  .fw NIP, LIT, L,-1, EQUAL, STATE
  .fw FETCH, AND, ZBRANCH, L,(Q_F_EX-.)
  .fw COMPILE_COMMA, BRANCH, L,(Q_F_END-.)
Q_F_EX:
  .fw EXECUTE
Q_F_END:
  .fw OK, EXIT

.fdef1 "LITERAL", LITERAL, -1 /* immediate */
  .fw LIT, LIT, COMMA
  .fw COMMA, EXIT

.fdef "QUIT-NOT-FOUND", QUIT_NOT_FOUND
  .fw NROT, TO_NUMBER, LIT, L,0 /* TODO: http://forth-standard.org/standard/usage#subsection.3.4.1.3 */
  .fw EQUAL, ZBRANCH, L,(Q_N_F_ELSE-.)
  .fw DROP, STATE, FETCH, ZBRANCH, L,(Q_N_F_END-.)
  .fw LITERAL
  .fw BRANCH, L,(Q_N_F_END-.)
Q_N_F_ELSE:
  .fw TWO_DROP, ERROR, EXIT
Q_N_F_END:
  .fw OK, EXIT

.fdef "QUIT", QUIT
QUIT_LOOP:
  .fw BL, WORD_NEW, DUP, NROT
  .fw FIND_NEW, ROT, SWAP
  .fw DUP, ZBRANCH, L,(QUIT_N_F-.)
  .fw QUIT_FOUND, BRANCH, L,(QUIT_LOOP-.)
QUIT_N_F:
  .fw QUIT_NOT_FOUND, BRANCH, L,(QUIT_LOOP-.)
  .fw EXIT

.fdef1 "[", LBRAC,-1 /* immediate */
  .fw LIT, L,0, STATE, STORE, EXIT

.fdef "]", RBRAC
  .fw LIT, L,-1, STATE, STORE, EXIT

// TODO: SUBROUTINE .fdef "\x3a", COLON
// TODO: SUBROUTINE   .fw CREATE
// TODO: SUBROUTINE   .fw LIT, forth_interpreter, COMMA
// TODO: SUBROUTINE   .fw LATEST, FETCH, HIDE
// TODO: SUBROUTINE   .fw RBRAC, EXIT
.fdef "\x3a", COLON
  .fw CREATE
  .fw LATEST, FETCH, HIDE
  .fw RBRAC, EXIT
  # TODO

.fdef1 "\x3b", SEMICOLON, -1 /* immediate */
  .fw LIT, L,EXIT, COMMA
  .fw LATEST, FETCH, HIDE, LBRAC, EXIT
