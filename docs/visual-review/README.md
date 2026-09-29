# Vérification visuelle

Captures synthétiques hors écran, sans connexion à Todoist, aux largeurs de 400 et 600 pixels. Les thèmes clair et sombre sont injectés uniquement dans le processus de prévisualisation.

| Version | Sombre | Clair |
| --- | --- | --- |
| Source, 400 px | [Avant](upstream-dark-400.png) | [Avant](upstream-light-400.png) |
| Fork français, 400 px | [Après](fr-dark-400.png) | [Après](fr-light-400.png) |
| Fork français, 600 px | [Après](fr-dark-600.png) | [Après](fr-light-600.png) |

Points vérifiés : titres français complets, conservation des composants natifs, titres Demain/Jeudi sans dates répétées, Inbox sans sous-titre, absence de sous-tâches dans la liste principale, adaptation des onglets aux petites largeurs. Les tests QtTest vérifient séparément les formulaires, les menus, la sélection, les raccourcis et le glissement.
