# OmaTasks en français

Fork de [crmne/omatasks](https://github.com/crmne/omatasks), conservant ses composants natifs pour les listes, les détails, l’ajout, la modification, les filtres et les actions groupées.

## Les trois vues

- **Aujourd’hui** : tâches principales prévues aujourd’hui ou en retard. Les tâches avec seulement une date limite sont également incluses selon cette date, comme dans OmaTasks.
- **Inbox** : tâches principales **sans date de planification, dans tous les projets**. Le nom reste Inbox ; le filtre ne se limite pas au projet Boîte de réception. Une date limite seule n’exclut pas la tâche.
- **Prochainement** : de demain au sixième jour inclus, sans les tâches d’aujourd’hui ou en retard. Les jours contenant des tâches sont regroupés sous **Demain**, puis les noms des jours en français. Les heures restent visibles sur les tâches, sans répéter leur date.

Seul l’onglet sélectionné a un fond rempli. Le survol éclaircit son texte et ses icônes ; le focus clavier est indiqué par un contour. Le dernier onglet utilisé est enregistré dans les préférences et restauré à chaque réouverture, même après un redémarrage du shell ou un rechargement du plugin.

Les sous-tâches se consultent et se terminent dans les détails de leur parent. Elles ne figurent pas dans les listes principales ni dans le compteur. Aujourd’hui et Inbox n’ont pas de sous-titres avec le regroupement par défaut. Les options natives de regroupement, de tri et de filtrage restent disponibles ; Inbox inclut par défaut tous les responsables, les autres vues conservent le filtre natif « Moi et non attribuées ».

L’icône de la barre dépasse légèrement la hauteur visible du « Y » de qs-yadm ; le compteur utilise la même taille de texte que son compteur.

## Installation

```sh
omarchy plugin add https://github.com/pomartel/omatasks.git --enable --yes
```

Identifiant du plugin : `pomartel.omatasks`. Nécessite Omarchy Quattro, Quickshell, curl (7.84 ou plus récent) et un compte Todoist. Aucun outil Todoist supplémentaire n’est requis. L’ancien plugin peut rester installé, mais désactivé, pour revenir en arrière.

Depuis un dépôt local, `./install` copie les composants et active le plugin. Après une modification, rechargez les plugins avec `omarchy restart shell`.

## Connexion et stockage

Ouvrez le panneau, puis les paramètres développeur de Todoist depuis le lien proposé. Collez le jeton API dans le champ protégé et cliquez sur **Se connecter**.

Le jeton reste dans `$XDG_CONFIG_HOME/omatasks-fr/token`, normalement `~/.config/omatasks-fr/token`, avec les permissions `0600` dans un dossier `0700`. Il passe par l’entrée standard pour son enregistrement et par un en-tête HTTPS pour les appels à Todoist. Les préférences sont stockées dans `views.json` au même endroit ; les tâches restent en mémoire. Aucun jeton ne doit être ajouté à ce dépôt ou à YADM.

Chaque requête utilise un processus curl indépendant, avec une nouvelle connexion réseau et un délai maximal de 20 secondes. Cela évite de réutiliser une connexion bloquée après une veille ou un passage entre Wi-Fi et Ethernet. Le jeton et le contenu passent par l’entrée standard de curl, jamais par les arguments du processus. Les écritures ne sont pas rejouées automatiquement par curl.

Les erreurs de synchronisation transitoires déclenchent des essais espacés de 5 secondes jusqu’à 5 minutes. Les modifications échouées gardent leurs brouillons et permettent de réessayer. Les actions groupées vérifient chaque commande et ne renvoient que les modifications non confirmées.

## Raccourcis

| Touche | Action |
| --- | --- |
| Tab / Maj+Tab ou ← / → | Parcourir Aujourd’hui, Prochainement, Inbox |
| a / d / i | Planifier la tâche sélectionnée aujourd’hui, demain, ou retirer la date |
| ↑ / ↓ ou k / j | Sélectionner une tâche ou « Ajouter une tâche » |
| Entrée | Ouvrir les détails de la tâche sélectionnée |
| e | Modifier la tâche sélectionnée |
| Espace | Terminer la tâche sélectionnée |
| u | Annuler la dernière tâche terminée dans le plugin (session courante) |
| o | Ouvrir la page de la tâche dans la fenêtre flottante Todoist |
| x | Supprimer immédiatement |
| Ctrl+a | Sélectionner toutes les tâches visibles |
| q | Ouvrir le formulaire d’ajout dans la liste |
| r | Actualiser |
| p | Ouvrir ou fermer les réglages |
| ? | Afficher l’aide des raccourcis |
| Échap | Annuler le glissement, revenir ou fermer |

Les liens « Ouvrir dans Todoist » et le raccourci **o** lancent directement la page de la tâche avec `omarchy-launch-webapp`, puis ferment le panneau. La règle de fenêtre Todoist d’Omarchy détermine son affichage flottant.

Le raccourci **u** peut être pressé immédiatement après la complétion : si Todoist n’a pas encore répondu, l’annulation attend sa confirmation.

Entrée ou Espace sur « Ajouter une tâche » ouvre le formulaire. Dans la description, Tab passe au champ suivant et Maj+Tab au précédent.

Le lien d’ajout utilise la couleur du texte du panneau pour rester lisible en thème clair comme sombre. L’aide (`?`), son texte et ses contrôles suivent également les couleurs du panneau.

Après avoir terminé une tâche dans la liste avec sa case ou Espace, le focus clavier passe à la tâche suivante, ou à la précédente s’il n’y a pas de suivante. Il reste sur la tâche en cas d’échec et aucune tâche n’est sélectionnée si la liste devient vide.

Les champs de texte gardent leurs touches habituelles. **Alt+Space** ouvre l’ajout rapide global natif ; ce raccourci est configurable dans les réglages. Pour associer **Super+Maj+T** au panneau, utilisez la commande :

```sh
omarchy-shell pomartel.omatasks togglePanel
```

Dans le titre et la description des tâches, les liens HTTP/HTTPS et les liens nommés Markdown sont soulignés et s’ouvrent dans le navigateur par défaut. Un clic sur un lien n’ouvre pas les détails de la tâche ; Ctrl+clic conserve la sélection multiple dans la liste.

Le clic droit sur l’icône ouvre l’ajout rapide et le clic du milieu actualise. Les raccourcis globaux existants en conflit ne sont pas remplacés automatiquement.

## Tâches et formulaires

L’interface reprend celle d’OmaTasks : projets, sections, descriptions, dates, priorités, étiquettes, responsables, durées, dates limites et rappels. Les menus et messages sont en français. Les noms de projets, d’étiquettes et le contenu des tâches restent ceux du compte Todoist. Les icônes des onglets se masquent sur les panneaux étroits pour conserver les titres français complets.

L’ajout utilise le parseur Todoist. Les modifications reconnaissent aussi les dates françaises ou anglaises, les heures, `p1` à `p4` et `#Projet`, par exemple `Réviser demain à 17h p1 #Travail`. Les champs non modifiés restent inchangés. Les dates limites acceptent aujourd’hui, demain, la semaine prochaine ou `AAAA-MM-JJ`.

Un clic simple sélectionne uniquement la tâche cliquée, avec la même couleur que le survol, efface la sélection multiple éventuelle et ouvre ses détails. Le clic sur le cercle termine la tâche. Le survol sélectionne la tâche pour les raccourcis clavier. Cette sélection simple utilise la couleur du survol. Ctrl+clic sélectionne plusieurs tâches, y compris sur leur cercle, avec une couleur distincte qui reste visible lors du survol d’une autre tâche. Le menu contextuel conserve les actions natives : terminer, replanifier, changer la priorité, déplacer, dupliquer, copier les liens et supprimer sans confirmation. Les rappels dépendent des fonctionnalités disponibles sur le compte Todoist.

Le glissement conserve le fonctionnement natif d’OmaTasks : réorganisation dans le groupe affiché, et dans le même projet/section pour Inbox. Le tri manuel est synchronisé avec Todoist. Les raccourcis a/d/i servent à changer la date ; ce fork ne reprend pas le glissement entre onglets de l’ancien plugin.

## Vérification

```sh
node --test tests/*.test.cjs
./tests/check-drag
./tests/check-composer
omarchy plugin validate .
```

Les tests utilisent des tâches synthétiques et des requêtes interceptées. Les contrôles visuels couvrent les thèmes clair et sombre à plusieurs largeurs. Le raccourci IPC `omarchy-shell pomartel.omatasks status` retourne uniquement un état agrégé, sans contenu de tâche ni identifiant de connexion, avec le transport, le dernier statut HTTP, la dernière synchronisation réussie et le nombre d’échecs consécutifs. Les tests du transport utilisent uniquement un serveur local et des données synthétiques ; le test QML est exécuté lorsque Quickshell est disponible.

## Origine et licence

Interface et implémentation d’origine : Carmine Paolino, [OmaTasks](https://github.com/crmne/omatasks), base `7cd8b201ce5e17ea57bcbc12c5d6f8f02b15acc1`. Adaptation française et préférences : [pomartel/omatasks](https://github.com/pomartel/omatasks). Le parseur de modification provient de [pomartel/omarchy-todoist](https://github.com/pomartel/omarchy-todoist).

Licence [MIT](LICENSE), avec la [notice du parseur importé](LICENSE.EditParser). Aucune publication de version ni aucun envoi de modifications au dépôt d’origine n’est effectué automatiquement.

## Intégration upstream du 3 octobre 2026

Reconnaissance et surlignage des propriétés Quick Add dans les deux éditeurs, police native du bureau et correction des dates relatives anciennes. Les dates françaises, filtres locaux et détails par clic simple sont conservés. Source upstream : `55b6b631f2d6294f3466f589d30eccb35e1df46f`.

## Intégration upstream du 21 octobre 2026

Révision intégrée : `a20f58c5a3c986e2b144ee155ac0fefa078f669b`. Intégration en un commit linéaire, conformément aux règles du dépôt ; les commits du fork ne sont pas réécrits.

Notifications Todoist, récapitulatif du matin, mode « Prochaine tâche » dans la barre et commandes de panneau intégrés. Le mode de barre reste sur le compteur par défaut. Les vues françaises, les raccourcis, les liens, la sélection persistante, l’annulation et le transport curl sont conservés.

Les champs natifs Qt sont conservés pour les accents, les touches mortes, Compose, les méthodes de saisie, la sélection et l’annulation. Le remplacement upstream par un éditeur de touches personnalisé est volontairement écarté. Les champs natifs gardent donc le comportement Qt de lecture du presse-papiers ; la protection upstream qui supprime ces lectures automatiques n’est pas applicable à cette variante.

`tests/check-french-input` vérifie la préédition et la validation de `ê`, `é` et `à` dans les vrais composants, avec des données synthétiques. Ce test requiert les outils de développement Qt 6 et un compilateur C++. Il ne remplace pas un essai physique du clavier.

La documentation upstream est conservée dans [UPSTREAM.md](UPSTREAM.md) ; ses limitations de saisie ne concernent pas cette variante native.
