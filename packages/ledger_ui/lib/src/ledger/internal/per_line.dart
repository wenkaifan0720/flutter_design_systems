/// How many of [count] choices stand on a line that holds at most [most], so
/// that no line is left with one choice alone while another holds more:
/// every choice on one line when they fit; else the most per line that
/// leaves the last line full or at least two; else one per line. Three
/// choices two to a line on a phone stand one per line; from 600 they share
/// one line.
int ledgerPerLine(int count, int most) {
  if (count <= most) return count < 1 ? 1 : count;
  for (var n = most; n >= 2; n--) {
    final rest = count % n;
    if (rest == 0 || rest >= 2) return n;
  }
  return 1;
}
