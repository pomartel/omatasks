# Particularités du fork OmaTasks

Base intégrée : [crmne/omatasks](https://github.com/crmne/omatasks), révision
`a20f58c5a3c986e2b144ee155ac0fefa078f669b` (1.4.0).
Le [README](README.md) reprend sa documentation, sans maintenir une seconde copie.
Cette fiche prévaut pour les différences ci-dessous.

## Installation et stockage

```sh
omarchy plugin add https://github.com/pomartel/omatasks.git --enable --yes
```

L’identifiant est `pomartel.omatasks` ; les commandes IPC du README utilisent
cet identifiant dans le fork. `togglePanel` reste aussi disponible.
Le jeton et `views.json` sont dans `$XDG_CONFIG_HOME/omatasks-fr`
(sinon `~/.config/omatasks-fr`), avec un jeton privé, jamais suivi par Git/YADM.
Le transport curl crée une connexion par requête, avec un délai de 20 secondes,
pour supporter les changements de réseau et les reprises de veille. Les
écritures ne sont pas rejouées automatiquement par curl.

## Comportements conservés

- **Aujourd’hui** : tâches principales du jour ou en retard.
- **Prochainement** : demain jusqu’au sixième jour inclus, regroupés en français.
- **Inbox** : tâches principales sans date de planification, dans tous les
  projets. Une date limite seule ne les exclut pas. Les sous-tâches restent
  dans les détails du parent, hors des listes principales et du compteur.
- Dernier onglet restauré après fermeture ou redémarrage.
- Interface française, dates françaises et anglaises lors des modifications,
  champs Qt natifs pour les accents, touches mortes, Compose et annulation.
  La restriction upstream de lecture du presse-papiers ne s’applique donc pas.
- Clic simple pour ouvrir les détails ; survol pour le focus clavier ;
  `Ctrl` + clic pour sélectionner plusieurs tâches. Suppression immédiate.
- Liens HTTP/HTTPS et Markdown cliquables ; ouverture des tâches dans la
  fenêtre webapp Todoist. Les champs non modifiés restent inchangés.
- Compteur dans la barre par défaut, taille d’icône accordée à qs-yadm.
  Les nouveaux modes de barre et notifications upstream restent disponibles.

## Raccourcis propres au fork

| Touche | Action |
| --- | --- |
| Tab / Maj+Tab ou ← / → | Parcourir les vues |
| a / d / i | Planifier aujourd’hui, demain, ou retirer la date |
| ↑ / ↓ ou k / j | Sélectionner une tâche ou l’ajout |
| Entrée / e / Espace | Détails / modification / terminer |
| u | Annuler la dernière complétion dans la session |
| o / x | Ouvrir dans Todoist / supprimer immédiatement |
| Ctrl+a | Sélectionner toutes les tâches visibles |
| q / r / p / ? | Ajouter / actualiser / réglages / aide |

`Alt+Space` ouvre l’ajout rapide ; son raccourci reste configurable sans
écraser une autre liaison. Les champs de saisie gardent leurs touches natives.

## Entretien

Garder les comportements locaux et leurs tests séparés autant que possible
des évolutions upstream. `EditParser.js` porte le parseur de modification,
`HttpRequest.qml` le transport curl, et `Service.qml` les préférences durables.

```sh
node --test tests/*.test.cjs
tests/check-composer
tests/check-french-input
omarchy plugin validate "$PWD"
```

Les tests utilisent des données synthétiques. Le test de saisie nécessite
Qt 6 et un compilateur C++ ; il ne remplace pas un essai physique du clavier.
La suite supplémentaire `tests/check-drag` contient un échec connu du scénario
de date personnalisée groupée, reproduit avant l’intégration upstream.
Conserver [LICENSE](LICENSE) et [LICENSE.EditParser](LICENSE.EditParser).
