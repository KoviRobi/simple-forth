BEGIN {
  i = 0;
  while ((getline l <"labels") == 1) {
    labels[i] = l
    i++;
  }
}

{
  addr = strtonum($(NF));
  lastlabel = 0;
  name = "";
  offset = 0;
  for (i in labels) {
    split(labels[i], ls)
    label = strtonum("0x" ls[1]);
    if (lastlabel < label && label <= addr) {
      lastlabel = label;
      name = ls[5];
      offset = addr-label;
    }
  }
  print($0 ": " name "+" offset)
}
