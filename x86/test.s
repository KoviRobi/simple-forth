.macro fw word:req, rest:vararg
  .4byte \word /* FWSIZE */
  .ifnb \rest ; fw \rest ; .endif
.endm

.set previous_entry, 0
.macro entry name:req, label, imm=0, hid=0
.balign 4 /* Align to power of 2 */
1:fw previous_entry ; .set previous_entry, 1b
.byte \hid, \imm ; .balign 4
fw 2f-3f ; 3:.ascii "\name" ; 2: .byte 0
.balign 4 /* Align to power of 2 */
fw 1b
.ifc _,\label
.globl \name ; \name :
.else
.globl \label ; \label :
.endif
.endm

.macro fromCC name, label, rest:vararg
entry \name, \label
  fw F\label, 0
.ifnb \rest
fromCC \rest
.endif
.endm
.macro fromC name, rest:vararg
fromCC "\name" \name
.ifnb \rest
fromC \rest
.endif
.endm

fromC KEY, EMIT
fromC ABORT, EXIT
fromCC "[']", LIT

fromCC "+", ADD, "-", SUB, "*", STAR, "/", SLASH
fromCC "<", LESS_THAN, ">", GREATER_THAN
fromCC "U<", U_LESS_THAN, "U>", U_GREATER_THAN
fromCC "<>", NOT_EQUAL, "\x3d", EQUAL
fromC OR, AND, LSHIFT, RSHIFT
fromCC "C!", C_STORE, "C@", C_FETCH, "!", STORE, "@", FETCH
fromC INVERT, LATEST, HERE_VAR, NEGATE
fromC STATE, EXECUTE_INTERPRETER, DOCOL
fromCC "CELL-SIZE", CELL_SIZE, "CHAR-SIZE", CHAR_SIZE

fromC DUP, DROP, NIP, OVER
fromC PICK, ROT, SWAP

fromCC "R@", R_FETCH, "R>", R_FROM, ">R", TO_R

fromC BRANCH
fromCC "0BRANCH", ZBRANCH;

fw ERROR, ERROR, ERROR, ERROR, ABORT
.globl forth_main; forth_main:
fw BL, WORD_NEW, ABORT
fw QUIT, ABORT
fw ABORT
