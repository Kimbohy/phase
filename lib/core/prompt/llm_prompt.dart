/// Prompt à copier dans un LLM en ligne pour obtenir le format d'import.
const String llmPrompt = r'''
Tu es un convertisseur d'emploi du temps. Je te donne mon planning en texte libre,
et tu le convertis EXACTEMENT dans le format ci-dessous. Réponds uniquement avec le
texte converti, dans un bloc de code, sans aucune explication.

FORMAT
- Une ligne optionnelle au début : "# Nom du planning"
- Un en-tête de jours sur sa propre ligne : [Lun-Ven] ou [Lun, Mer, Ven] ou [Sam] ou [Tous]
  (jours possibles : Lun Mar Mer Jeu Ven Sam Dim)
- Puis une ligne par bloc : HH:MM-HH:MM | Nom du bloc | option
- Heures au format 24h (07:00, 14:30). Si un bloc passe minuit, mets par exemple 22:30-07:00.
- Option possible : pomodoro=F/P (F minutes de focus, P minutes de pause).
  À utiliser seulement pour les blocs de travail long que je veux découper.
- Noms de blocs : 40 caractères maximum.
- Pas de chevauchement entre blocs d'un même jour.
- Si plusieurs jours ont exactement le même planning, regroupe-les sous un seul en-tête.

EXEMPLE
# Ma semaine
[Lun-Ven]
07:00-07:45 | Réveil
08:15-10:00 | Deep Work 1 | pomodoro=25/5
10:00-10:15 | Ménage
[Sam]
09:00-12:00 | Projets libres | pomodoro=50/10

MON PLANNING
[COLLE ICI TON EMPLOI DU TEMPS — tu peux aussi préciser ce que tu veux changer,
par exemple "ajoute 30 min de lecture à 21h"]
''';
