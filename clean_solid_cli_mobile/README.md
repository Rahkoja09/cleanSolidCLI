# CSCM (Clean Solid CLI Mobile)

CSCM est un outil d'interface en ligne de commande (CLI) dédié à la génération automatisée de modules Flutter.

## Objectif

L'enjeu principal de cet outil est l'industrialisation de la Clean Architecture au sein d"un écosystème flutter, permettant de supprimer le boilerplate et de garantir la cohérence technique et de focaliser plus sur les metiers et expériences utilisateurs que de passer trop de temps sur la structuration des dossiers  et/ou fichiers.

## Aperçu de la structure

lib/features/nom_feature/
├── data/
│   ├── model/           # Mapping de données (Supabase/JSON)
│   ├── repository/      # Implementation des contrats
│   └── source/          # Sources de données Remote et Local
├── domain/
│   ├── actions/         # Classes scellées pour la gestion d'intentions
│   ├── entity/          # Classes métiers immuables avec copyWith
│   ├── repository/      # Interfaces et contrats de données
│   └── usecases/        # Logique métier (Insert, Delete, Search)
└── presentation/
    ├── controller/      # Riverpod StateNotifiers
    ├── pages/           # Vues Flutter (ConsumerStatefulWidget)
    ├── states/          # Gestion d'états immuables
    └── widgets/         # Composants d'interface locaux

## Stack Technique

- **Langage :** Dart SDK.
- **Architecture :** Clean Architecture (Data, Domain, Presentation).
- **Gestion de fichiers :** Dart IO & Path package.
- **Templates :** Système de remplacement dynamique de balises.
- **Injection :** Mise à jour automatique via Get_It.

## Caractéristiques

- Génération complète de l'arborescence par feature (Data, Domain, Presentation).
- Support natif des Sealed Classes pour les actions d'états.
- Contrôleurs Riverpod pré-configurés avec pagination et lazy loading.
- Standardisation des imports via le préfixe package.
- Automatisation du câblage dans le container d'injection de dépendances.

## Installation rapide

1. Cloner le projet : `git clone https://github.com/votre-compte/clean_solid_cli_mobile.git`
2. Installer les dépendances : `dart pub get`
3. Activer le CLI globalement : `dart pub global activate --source path .`
4. Configurer le PATH (dans Bash/Zsh) : `export PATH="$PATH":"$HOME/.pub-cache/bin"`
5. Exécuter la commande : `cscm create nom_feature`

---

Coming push...