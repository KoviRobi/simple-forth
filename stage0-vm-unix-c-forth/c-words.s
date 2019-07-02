.macro .fw word:req, rest:vararg
  .ifnc "\word","L"
    .4byte \word /* FWSIZE */
  .endif
  .ifnb \rest
    .fw \rest
  .endif
.endm

.macro .cell init=0
  .4byte \init
.endm

.set previous_entry, 0
.macro .entry name:req, label, imm=0, hid=0
  .ifc _,\label
    .entry \name, \name, \imm, \hid
  .else
    .balign 4 /* Align to power of 2 */
    .globl FHDR_\label
    FHDR_\label :
    1:.cell previous_entry
    .set previous_entry, 1b
    .byte \hid, \imm
    .balign 4
    .cell 2f-3f
    3:.ascii "\name"
    2:.byte 0
    .balign 4 /* Align to power of 2 */
    .globl \label
    \label :
  .endif
.endm

.macro .forth_interpreter
  .cell forth_interpreter
.endm

.macro fromC name, label, rest:vararg
  .ifc _,\label
    fromC \name, \name
  .else
    .entry \name, \label
    .fw F\label, 0
  .endif
  .ifnb \rest
    fromC \rest
  .endif
.endm

fromC KEY, _, EMIT, _
fromC BYE, _, EXIT, _, EXECUTE, _
fromC "[']", LIT

fromC "+", ADD, "-", SUB, "*", STAR, "/", SLASH
fromC "<", LESS_THAN, ">", GREATER_THAN
fromC "U<", U_LESS_THAN, "U>", U_GREATER_THAN
fromC "<>", NOT_EQUAL, "\x3d", EQUAL
fromC OR, _, AND, _, LSHIFT, _, RSHIFT, _, INVERT, _, NEGATE, _
fromC "C!", C_STORE, "C@", C_FETCH, "!", STORE, "@", FETCH
fromC "CELL-SIZE", CELL_SIZE, "CHAR-SIZE", CHAR_SIZE

fromC DUP, _, DROP, _, NIP, _, OVER, _, PICK, _, ROT, _, SWAP, _
fromC "R@", R_FETCH, "R>", R_FROM, ">R", TO_R

fromC BRANCH, _, "?BRANCH", ZBRANCH;

.entry "<FORTH_MAIN>", forth_main, 0, -1
.fw QUIT
.fw BYE
