/* TODO: Use this more liberally */
.macro fdef name:req, label, rest:vararg
  entry \name, \label
  fw forth_interpreter
  fw \rest
.endm

fdef "1-", DECR, LIT, 1, SUB, EXIT
fdef "1+", INCR, LIT, 1, ADD, EXIT
fdef "2DUP", TWO_DUP, OVER, OVER, EXIT
fdef "2DROP", TWO_DROP, DROP, DROP, EXIT
fdef "-ROT", NROT, ROT, ROT, EXIT
fdef "2>R", TWO_TO_R, R_FROM, NROT, SWAP
fw TO_R, TO_R, TO_R, EXIT
fdef "2R>", TWO_R_FROM, R_FROM, R_FROM
fw R_FROM, ROT, TO_R, SWAP, EXIT
fdef "2RDROP", TWO_R_DROP, R_FROM, R_FROM
fw R_FROM, TWO_DROP, TO_R, EXIT
fdef "2R\x40", TWO_R_FETCH, R_FROM
fw TWO_R_FROM, TWO_DUP, TWO_TO_R, ROT
fw TO_R, EXIT
fdef "TRUE", _, LIT, -1, EXIT
fdef "FALSE", _, LIT, 0, EXIT
fdef "HERE_VAR", _, LIT, HERE_LOC, EXIT
fdef "LATEST", _, LIT, LATEST_LOC, EXIT
fdef "STATE", _, LIT, STATE_LOC, EXIT
fdef "HERE", _, HERE_VAR, FETCH, EXIT
fdef "CHAR+", CHAR_ADD, CHAR_SIZE, ADD, EXIT
fdef "CELL+", CELL_ADD, CELL_SIZE, ADD, EXIT
fdef "CHARS", _, CHAR_SIZE, STAR, EXIT
fdef "CELLS", _, CELL_SIZE, STAR, EXIT
fdef "C\x2c", C_COMMA, HERE, C_STORE, HERE
fw CHAR_ADD, HERE_VAR, STORE, EXIT
fdef "\x2c", COMMA, HERE, STORE, HERE
fw CELL_ADD, HERE_VAR, STORE, EXIT

entry "ALLOT", ALLOT
  fw forth_interpreter
  fw HERE, ADD, HERE_VAR, STORE, EXIT

entry "ALIGN", ALIGN
  fw forth_interpreter
  fw HERE, CELL_SIZE, DECR, ADD
  fw CELL_SIZE, DECR, INVERT, AND
  fw HERE_VAR, STORE, EXIT

entry "CREATE", CREATE
  fw forth_interpreter
  fw HERE, LATEST, FETCH
  fw COMMA, LATEST, STORE
  fw LIT, 0, C_COMMA, LIT, 0, C_COMMA
  fw ALIGN, HERE, CELL_SIZE, ALLOT
  fw BL, WORD_NEW, NIP
  fw TWO_DUP, SWAP, STORE
  fw NIP, LIT, 1, ADD, ALLOT
  fw ALIGN
  fw LATEST, FETCH, COMMA, EXIT

fdef "BALIGN", BALIGN, DECR, SWAP, OVER
fw ADD, SWAP, INVERT, AND, EXIT
fdef "ENTRY-NEXT", ENTRY_NEXT, EXIT
fdef "ENTRY-FLAGS", ENTRY_FLAGS, CELL_ADD, EXIT
fdef "ENTRY-LEN", ENTRY_LEN, LIT, 2
fw CELLS, ADD, EXIT
fdef "ENTRY-CHARS", ENTRY_CHARS, LIT, 3
fw CELLS, ADD, EXIT
fdef "ENTRY-PREV", ENTRY_PREV, DUP
fw ENTRY_LEN, FETCH, LIT, 1, ADD, SWAP
fw ENTRY_CHARS, ADD, LIT, 4, BALIGN, EXIT
fdef "ENTRY-XT", ENTRY_XT, ENTRY_PREV
fw CELL_ADD, EXIT

entry "HIDDEN?", HIDDENP
  fw forth_interpreter
  fw ENTRY_FLAGS, C_FETCH, EXIT

entry "IMMEDIATE?", IMMEDIATEP
  fw forth_interpreter
  fw ENTRY_FLAGS, CHAR_ADD, C_FETCH, EXIT

entry "HIDE", HIDE
  fw forth_interpreter
  fw CELL_ADD, DUP, C_FETCH
  fw INVERT, SWAP, C_STORE, EXIT

entry "IMMEDIATE", IMMEDIATE, -1
  fw forth_interpreter
  fw LATEST, FETCH
  fw TRUE, SWAP, CELL_ADD, CHAR_ADD, C_STORE, EXIT

entry "FIND'", FIND_NEW
  fw forth_interpreter
  fw LATEST, FETCH

FIND_LOOP: /* ( c-addr u entry ) */
  fw DUP, LIT, 0, EQUAL, ZBRANCH, (FIND_NON_END-.)
  fw DROP, DROP, LIT, 0, EXIT

FIND_NON_END:
  fw DUP, HIDDENP, INVERT
  fw ZBRANCH, (FIND_NEXT_ENTRY-.)

  fw TWO_DUP, ENTRY_LEN, FETCH, EQUAL
  fw ZBRANCH, (FIND_NEXT_ENTRY-.)
  /* c-addr u entry */
  fw TWO_DUP, ENTRY_CHARS
  fw LIT, 4, PICK
  /* c-addr u entry u entry-str c-addr */
  fw MEMCMP, ZBRANCH, (FIND_NEXT_ENTRY-.)

  fw NIP, NIP
  fw DUP, ENTRY_XT
  fw SWAP, IMMEDIATEP
  fw ZBRANCH, (NON_IMM-.), LIT, 1, BRANCH, (IMM_END-.)
NON_IMM:
  fw LIT, -1
IMM_END:
  fw EXIT

FIND_NEXT_ENTRY:
  fw FETCH
  fw BRANCH, (FIND_LOOP-.)

entry "MEMCMP", MEMCMP
  fw forth_interpreter
  fw ROT, LIT, 0
  fw TWO_TO_R
MEMCMP_LOOP:
  fw TWO_DUP, R_FETCH, ADD, C_FETCH
  fw SWAP, R_FETCH, ADD, C_FETCH

  fw CHAR_EQUAL, INVERT, ZBRANCH, (MEMCMP_NEXT-.)
  fw TWO_R_DROP, TWO_DROP, FALSE, EXIT
MEMCMP_NEXT:
  fw R_FROM, LIT, 1, ADD, TO_R
  fw TWO_R_FETCH, EQUAL
  fw ZBRANCH, (MEMCMP_LOOP-.)
  fw TWO_R_DROP

  fw TWO_DROP, TRUE, EXIT

entry "LOWER", LOWER
  fw forth_interpreter
  fw DUP, LIT, 'A', U_LESS_THAN
  fw OVER, LIT, 'Z', U_GREATER_THAN
  fw OR, INVERT, ZBRANCH, (1f-.)
  fw LIT, 32, ADD
1:fw EXIT

entry "CHAR=", CHAR_EQUAL
  fw forth_interpreter
  fw TWO_DUP, EQUAL, ZBRANCH, (1f-.)
  fw TWO_DROP, TRUE, EXIT
1:fw OVER, LIT, 33, U_LESS_THAN
  fw OVER, LIT, 33, U_LESS_THAN
  fw AND, ZBRANCH, (2f-.)
  fw TWO_DROP, TRUE, EXIT
2:fw LOWER, SWAP, LOWER, EQUAL
  fw ZBRANCH, (3f-.)
  fw TRUE, EXIT
3:fw FALSE, EXIT

entry "WORD'", WORD_NEW
  fw forth_interpreter
  fw HERE, SWAP, LIT, 0
WORD_SKIP:
  fw DROP, KEY, TWO_DUP, CHAR_EQUAL
  fw INVERT, ZBRANCH, (WORD_SKIP-.)
WORD_LOOP:
  fw DUP, C_COMMA, OVER, CHAR_EQUAL
  fw ZBRANCH, (WORD_CONT-.)
  fw DROP, CHAR_SIZE, NEGATE, ALLOT
  fw HERE, OVER, SUB, LIT, 0, C_COMMA
  fw LIT, -1, OVER, SUB, ALLOT, EXIT
WORD_CONT:
  fw KEY, BRANCH, (WORD_LOOP-.)

entry "CHAR->DIGIT", CHAR_TO_DIGIT
  fw forth_interpreter
  fw LIT, '0', SUB
  fw DUP, LIT, 9, U_GREATER_THAN, ZBRANCH, (C_TO_D_END-.)
  fw LIT, ('A'-'9'-1), SUB
  fw DUP, LIT, 10, U_LESS_THAN, ZBRANCH, (C_TO_D_A-.)
  fw LIT, 10, SUB
C_TO_D_A:
  fw DUP, LIT, 35, U_GREATER_THAN, ZBRANCH, (C_TO_D_END-.)
  fw LIT, 32, SUB
  fw DUP, LIT, 10, U_LESS_THAN, ZBRANCH, (C_TO_D_END-.)
  fw LIT, 10, SUB
C_TO_D_END:
  fw EXIT

.data
BASE_LOC: fw 10
.text
entry "BASE", BASE
  fw forth_interpreter
  fw LIT, BASE_LOC, EXIT
entry "DECIMAL", DECIMAL
  fw forth_interpreter
  fw LIT, 10, BASE, STORE, EXIT
entry ">NUMBER", TO_NUMBER
  fw forth_interpreter
  fw OVER, ADD, DUP, TO_R, SWAP
  fw TWO_TO_R
TO_NUM_LOOP:
  fw R_FETCH, C_FETCH, CHAR_TO_DIGIT, DUP
  fw BASE, FETCH, U_LESS_THAN
  fw ZBRANCH, (TO_NUM_ELSE-.)
  fw SWAP, BASE, FETCH, STAR, ADD
  fw BRANCH, (TO_NUM_NEXT-.)
TO_NUM_ELSE:
  fw DROP, R_FETCH, TWO_R_DROP, R_FROM
  fw OVER, SUB,  EXIT
TO_NUM_NEXT:
  fw R_FROM, LIT, 1, ADD, TO_R
  fw TWO_R_FETCH, EQUAL
  fw ZBRANCH, (TO_NUM_LOOP-.)
  fw TWO_R_DROP
  fw R_FROM, LIT, 0
  fw EXIT

entry "BL", BL
  fw forth_interpreter
  fw LIT, ' ', EXIT

entry "'", TICK
  fw forth_interpreter
  fw BL, WORD_NEW, FIND_NEW, DROP, EXIT

entry "OK", OK
  fw forth_interpreter
  fw LIT, 'O', EMIT, LIT, 'k'
  fw EMIT, BL, EMIT, EXIT

entry "ERROR", ERROR
  fw forth_interpreter
  fw LIT, 'E', EMIT, LIT, 'r', EMIT
  fw LIT, 'r', EMIT, BL, EMIT, EXIT

entry "COMPILE,", COMPILE_COMMA
  fw forth_interpreter
  fw COMMA, EXIT

entry "QUIT-FOUND", QUIT_FOUND
  fw forth_interpreter
  fw NIP, LIT, -1, EQUAL, STATE
  fw FETCH, AND, ZBRANCH, (Q_F_EX-.)
  fw COMPILE_COMMA, BRANCH, (Q_F_END-.)
Q_F_EX:
  fw EXECUTE
Q_F_END:
  fw OK, EXIT

entry "LITERAL", LITERAL, -1 /* immediate */
  fw forth_interpreter
  fw LIT, LIT, COMMA
  fw COMMA, EXIT

entry "QUIT-NOT-FOUND", QUIT_NOT_FOUND
  fw forth_interpreter
  fw NROT, TO_NUMBER, LIT, 0
  fw EQUAL, ZBRANCH, (Q_N_F_ELSE-.)
  fw DROP, STATE, FETCH, ZBRANCH, (Q_N_F_END-.)
  fw LITERAL
  fw BRANCH, (Q_N_F_END-.)
Q_N_F_ELSE:
  fw TWO_DROP, ERROR, EXIT
Q_N_F_END:
  fw OK, EXIT

entry "QUIT", QUIT
  fw forth_interpreter
QUIT_LOOP:
  fw BL, WORD_NEW, DUP, NROT
  fw FIND_NEW, ROT, SWAP
  fw DUP, ZBRANCH, (QUIT_N_F-.)
  fw QUIT_FOUND, BRANCH, (QUIT_LOOP-.)
QUIT_N_F:
  fw QUIT_NOT_FOUND, BRANCH, (QUIT_LOOP-.)
  fw EXIT

entry "[", LBRAC,-1
  fw forth_interpreter
  fw LIT, 0, STATE, STORE, EXIT

entry "]", RBRAC
  fw forth_interpreter
  fw LIT, -1, STATE, STORE, EXIT

entry ":", COLON
  fw forth_interpreter
  fw CREATE
  fw LIT, forth_interpreter, COMMA
  fw LATEST, FETCH, HIDE
  fw RBRAC, EXIT
  # TODO

entry ";", SEMICOLON, -1 /* immediate */
  fw forth_interpreter
  fw LIT, EXIT, COMMA
  fw LATEST, FETCH, HIDE, LBRAC, EXIT
