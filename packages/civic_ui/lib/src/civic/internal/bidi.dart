/// [value] set apart from the words round it (U+2068 first strong isolate
/// … U+2069 pop directional isolate): a figure or an amount composed into
/// a sentence keeps its own order whichever way the sentence reads, so
/// "£20 to £60" never reads "to £60 £20" right to left.
String civicIsolate(String value) => '\u2068$value\u2069';
