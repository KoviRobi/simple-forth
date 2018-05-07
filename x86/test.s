.set previous_entry, 0
.macro fw word:req, rest:vararg
  .4byte \word
  .ifnb \rest
    fw \rest
  .endif
.endm

.macro entry_header name:req, label:req, immediate=0, hidden=0
.balign 4 /* Align to power of 2 */
1:fw previous_entry
.set previous_entry, 1b
.byte \hidden
.byte \immediate
.balign 4
fw 2f-3f
3: .ascii "\name"; 2: .byte 0
.balign 4 /* Align to power of 2 */
fw 1b
.globl \label
\label :
.endm

.macro fromCC name, label, rest:vararg
entry_header \name, \label
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
fromC LIT

fromCC "+", ADD, "-", SUB, "*", STAR, "/", SLASH
fromCC "<", LESS_THAN, ">", GREATER_THAN
fromCC "U<", U_LESS_THAN, "U>", U_GREATER_THAN
fromCC "<>", NOT_EQUAL, "\x3d", EQUAL
fromC FALSE, TRUE, OR, AND, LSHIFT, RSHIFT
fromCC "C\x2c", C_COMMA, "\x2c", COMMA
fromCC "C!", C_STORE, "C@", C_FETCH, "!", STORE, "@", FETCH
fromC INVERT, LATEST, HERE_VAR, NEGATE
fromC STATE, EXECUTE, DOCOL
fromCC "CELL-SIZE", CELL_SIZE, "CHAR-SIZE", CHAR_SIZE

fromC DUP, DROP, NIP, OVER
fromC PICK, ROT, SWAP
fromCC "2DUP", TWO_DUP, "2DROP", TWO_DROP

fromCC "R@", R_FETCH, "R>", R_FROM, ">R", TO_R, "2RDROP", TWO_R_DROP, "2R@", TWO_R_FETCH

fromC BRANCH
fromCC "0BRANCH", ZBRANCH;

fw ERROR, ERROR, ERROR, ERROR, ABORT
.globl forth_main; forth_main:
fw QUIT, ABORT
fw ABORT
