SECTIONS
{ _stack_min = 0x1000;
  _stack_max = 0x2000;
  _hold_min  = 0x2000;
  _hold_max  = 0x3000;
  _block_min = 0x3000;
  _block_max = 0x4000;
  . = 0x8000;
  .text :
  { KEEP(*(.text.init))
    *(.text)
    KEEP(*(.text.symtab))
    KEEP(*(.text.stage1))
  }
  text_size = SIZEOF(.text);
  DATA = .;
  .data :
  { *(.data)
  }
}
