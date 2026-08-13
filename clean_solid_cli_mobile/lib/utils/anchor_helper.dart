/// Remplace la première occurrence d'une ancre par [replacement],
/// puis ré-insère l'ancre après le contenu inséré (pour empiler).
/// Affiche un warning si l'ancre est absente.
String replaceAnchor(String content, String anchor, String replacement, {String? context}) {
  if (!content.contains(anchor)) {
    print('  ⚠  Ancre "$anchor" introuvable${context != null ? " dans $context" : ""}. Injection ignorée.');
    return content;
  }
  return content.replaceFirst(anchor, '$replacement\n$anchor');
}
