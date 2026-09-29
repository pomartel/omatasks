# OmaTasks en français

Fork de [crmne/omatasks](https://github.com/crmne/omatasks), conservant ses composants natifs pour les listes, les détails, l’ajout, la modification, les filtres et les actions groupées.

## Les trois vues

- **Aujourd’hui** : tâches principales prévues aujourd’hui ou en retard. Les tâches avec seulement une date limite sont également incluses selon cette date, comme dans OmaTasks.
- **Inbox** : tâches principales **sans date de planification, dans tous les projets**. Le nom reste Inbox ; le filtre ne se limite pas au projet Boîte de réception. Une date limite seule n’exclut pas la tâche.
- **Bientôt** : de demain au sixième jour inclus, sans les tâches d’aujourd’hui ou en retard. Les jours contenant des tâches sont regroupés sous **Demain**, puis les noms des jours en français. Les heures restent visibles sur les tâches, sans répéter leur date.

Seul l’onglet sélectionné a un fond rempli. Le survol éclaircit son texte et ses icônes ; le focus clavier est indiqué par un contour.

Les sous-tâches se consultent et se terminent dans les détails de leur parent. Elles ne figurent pas dans les listes principales ni dans le compteur. Aujourd’hui et Inbox n’ont pas de sous-titres avec le regroupement par défaut. Les options natives de regroupement, de tri et de filtrage restent disponibles ; Inbox inclut par défaut tous les responsables, les autres vues conservent le filtre natif « Moi et non attribuées ».

## Installation

```sh
omarchy plugin add https://github.com/pomartel/omatasks.git --enable --yes
```

Identifiant du plugin : `pomartel.omatasks`. Nécessite Omarchy Quattro, Quickshell et un compte Todoist. Aucun outil Todoist supplémentaire n’est requis. L’ancien plugin peut rester installé, mais désactivé, pour revenir en arrière.

Depuis un dépôt local, `./install` copie les composants et active le plugin. Après une modification, rechargez les plugins avec `omarchy restart shell`.

## Connexion et stockage

Ouvrez le panneau, puis les paramètres développeur de Todoist depuis le lien proposé. Collez le jeton API dans le champ protégé et cliquez sur **Se connecter**.

Le jeton reste dans `$XDG_CONFIG_HOME/omatasks-fr/token`, normalement `~/.config/omatasks-fr/token`, avec les permissions `0600` dans un dossier `0700`. Il passe par l’entrée standard pour son enregistrement et par un en-tête HTTPS pour les appels à Todoist. Les préférences sont stockées dans `views.json` au même endroit ; les tâches restent en mémoire. Aucun jeton ne doit être ajouté à ce dépôt ou à YADM.

Les erreurs de synchronisation transitoires déclenchent des essais espacés de 5 secondes jusqu’à 5 minutes. Les modifications échouées gardent leurs brouillons et permettent de réessayer. Les actions groupées vérifient chaque commande et ne renvoient que les modifications non confirmées.

## Raccourcis

| Touche | Action |
| --- | --- |
| Tab / Maj+Tab ou ← / → | Parcourir Aujourd’hui, Bientôt, Inbox |
| a / d / i | Ouvrir Aujourd’hui, Bientôt, Inbox |
| ↑ / ↓ ou k / j | Sélectionner une tâche |
| Entrée / e | Modifier la tâche sélectionnée |
| Espace | Terminer la tâche sélectionnée |
| o | Ouvrir la page de la tâche dans la fenêtre flottante Todoist |
| x | Supprimer, après confirmation |
| Ctrl+a / Ctrl+d / Ctrl+i | Planifier aujourd’hui, demain, ou retirer la date |
| Ctrl+a sans curseur de tâche | Sélectionner toutes les tâches visibles |
| q | Ouvrir le formulaire d’ajout dans la liste |
| r | Actualiser |
| p | Ouvrir ou fermer les réglages |
| ? | Afficher l’aide des raccourcis |
| Échap | Annuler le glissement, revenir ou fermer |

Les liens « Ouvrir dans Todoist » et le raccourci **o** lancent directement la page de la tâche avec `omarchy-launch-webapp`, puis ferment le panneau. La règle de fenêtre Todoist d’Omarchy détermine son affichage flottant.

Les champs de texte gardent leurs touches habituelles. **Alt+Space** ouvre l’ajout rapide global natif ; ce raccourci est configurable dans les réglages. Pour associer **Super+Maj+T** au panneau, utilisez la commande :

```sh
omarchy-shell pomartel.omatasks togglePanel
```

Le clic droit sur l’icône ouvre l’ajout rapide et le clic du milieu actualise. Les raccourcis globaux existants en conflit ne sont pas remplacés automatiquement.

## Tâches et formulaires

L’interface reprend celle d’OmaTasks : projets, sections, descriptions, dates, priorités, étiquettes, responsables, durées, dates limites et rappels. Les menus et messages sont en français. Les noms de projets, d’étiquettes et le contenu des tâches restent ceux du compte Todoist. Les icônes des onglets se masquent sur les panneaux étroits pour conserver les titres français complets.

L’ajout utilise le parseur Todoist. Les modifications reconnaissent aussi les dates françaises ou anglaises, les heures, `p1` à `p4` et `#Projet`, par exemple `Réviser demain à 17h p1 #Travail`. Les champs non modifiés restent inchangés. Les dates limites acceptent aujourd’hui, demain, la semaine prochaine ou `AAAA-MM-JJ`.

Ctrl+clic sélectionne plusieurs tâches, y compris sur leur cercle. Le menu contextuel conserve les actions natives : terminer, replanifier, changer la priorité, déplacer, dupliquer, copier les liens et supprimer avec confirmation. Les rappels dépendent des fonctionnalités disponibles sur le compte Todoist.

Le glissement conserve le fonctionnement natif d’OmaTasks : réorganisation dans le groupe affiché, et dans le même projet/section pour Inbox. Le tri manuel est synchronisé avec Todoist. Les raccourcis Ctrl+a/d/i servent à changer la date ; ce fork ne reprend pas le glissement entre onglets de l’ancien plugin.

## Vérification

```sh
node --test tests/*.test.cjs
./tests/check-drag
omarchy plugin validate .
```

Les tests utilisent des tâches synthétiques et des requêtes interceptées. Les contrôles visuels couvrent les thèmes clair et sombre à plusieurs largeurs. Le raccourci IPC `omarchy-shell pomartel.omatasks status` retourne uniquement un état agrégé, sans contenu de tâche ni identifiant de connexion.

## Origine et licence

Interface et implémentation d’origine : Carmine Paolino, [OmaTasks](https://github.com/crmne/omatasks), base `7cd8b201ce5e17ea57bcbc12c5d6f8f02b15acc1`. Adaptation française et préférences : [pomartel/omatasks](https://github.com/pomartel/omatasks). Le parseur de modification provient de [pomartel/omarchy-todoist](https://github.com/pomartel/omarchy-todoist).

Licence [MIT](LICENSE), avec la [notice du parseur importé](LICENSE.EditParser). Aucune publication de version ni aucun envoi de modifications au dépôt d’origine n’est effectué automatiquement.
