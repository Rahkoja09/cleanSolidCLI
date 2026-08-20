# CSCM - Clean Solid CLI Mobile

Outil CLI pour générer des modules Flutter en Clean Architecture.
Moins de boilerplate, plus de métier.

---

## Table des matières

- [Pourquoi CSCM](#pourquoi-cscm)
- [Installation](#installation)
- [Commandes](#commandes)
  - [init](#cscm-init)
  - [create](#cscm-create)
  - [generate:all](#cscm-generateall)
  - [auth](#cscm-auth)
  - [implemente](#cscm-implemente)
  - [add:widget](#cscm-addwidget)
  - [list](#cscm-list)
  - [status](#cscm-status)
  - [history](#cscm-history)
  - [undo](#cscm-undo)
  - [commit](#cscm-commit)
  - [test](#cscm-test)
  - [config](#cscm-config)
- [Architecture générée](#architecture-generee)
- [Guide : projet complet en 5 minutes](#guide--projet-complet-en-5-minutes)
- [Format YAML pour generate:all](#format-yaml-pour-generateall)
- [Fichiers de suivi](#fichiers-de-suivi)
- [Remarques et bonnes pratiques](#remarques-et-bonnes-pratiques)

---

## Pourquoi CSCM

Créer une app Flutter en Clean Architecture, c'est bien. Mais à chaque nouvelle feature, tu répètes la même gymnastique : créer 12 fichiers (entity, model, repository, usecase, controller, states, actions), les relier entre eux, les injecter dans le container, les brancher dans le listener d'erreurs. C'est long, c'est répétitif, et une seule erreur d'import casse tout le montage.

CSCM automatises cette mécanique :

- Tu décris ta feature (nom + champs optionnels), CSCM génère les 12 fichiers avec les bons imports, les bonnes références, les bons appels.
- L'arborescence est standardisée : chaque feature suit exactement la même structure, ton équipe ne perd plus de temps à chercher "où est le usecase".
- Le container d'injection (GetIt), le ErrorListener, et les imports sont mis à jour automatiquement -- pas un seul oubli.
- Tu peux générer 15 features d'un coup depuis un fichier YAML avec tri topologique des dépendances.

En résumé : CSCM fait la plomberie, tu fais le métier.

---

## Installation

```bash
# 1. Cloner
git clone https://github.com/Rahkoja09/cleanSolidCLI.git
cd cleanSolidCLI/clean_solid_cli_mobile

# 2. Dépendances
dart pub get

# 3. Activation globale
dart pub global activate --source path .

# 4. Vérifier
cscm --help
```

### Problèmes courants d'installation

**`cscm: command not found`** -- Le cache pub n'est pas dans ton PATH. Ajoute cette ligne à ton `.bashrc` ou `.zshrc` :

```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

Puis `source ~/.bashrc` (ou ferme et rouvre le terminal).

**`Could not find a command named "cscm"`** -- Vérifie que `dart pub global list` contient bien `clean_solid_cli_mobile`. Si oui, c'est un problème de PATH (voir ci-dessus).

---

## Commandes

### `cscm init`

Crée un projet Flutter complet en Clean Architecture depuis zéro. Exécute `flutter create` en interne, puis superpose la structure Clean Architecture, configure les dépendances, initialise git.

```bash
cscm init mon_app
cscm init mon_app --backend supabase
cscm init mon_app -b firebase
cscm init mon_app -b none --no-git
cscm init mon_app --org fr.maboite
```

**Options :**

| Option      | Court | Défaut        | Description                                           |
| ----------- | ----- | ------------- | ----------------------------------------------------- |
| `--backend` | `-b`  | `supabase`    | Backend à configurer (`supabase`, `firebase`, `none`) |
| `--org`     | `-o`  | `com.example` | Package bundle ID                                     |
| `--no-git`  |       | `false`       | Ne pas initialiser git                                |

**Ce qui est généré :**

```
mon_app/
  lib/
    config/constants/     # AppConst, SupabaseApiConstants
    config/theme/         # ThemeProvider
    core/
      actions/            # AppAction (interface de base)
      di/                 # injection_container.dart (GetIt)
      error/              # Exceptions, Failures, ErrorManager
      network/            # NetworkInfo
      router/             # GoRouter
      utils/              # Typedefs
      mainErrorListener/  # SuccessErrorListener
    shared/widgets/       # Toast, Snackbar, LoadingWidget
    features/             # Tes features vont ici
  assets/
    medias/icons/
    medias/animations/
    theme/
  .env                   # Variables d'environnement
  .cscm.yaml             # Config CSCM
  .cscm-state.yaml       # État du projet (auto-généré)
```

**Après `cscm init` :**

```bash
cd mon_app
flutter pub get
# Configurer .env avec tes clés Supabase/Firebase
cscm create ma_premiere_feature -i "nom:string, prix:double"
```

---

### `cscm create`

Crée une feature complète en Clean Architecture. C'est la commande principale.

```bash
cscm create produit
cscm create produit -i "nom:string, prix:double, categorie:reference(Categorie)"
cscm create produit --impl "nom:string, prix:double, stock:int"
```

**Options :**

| Option          | Court | Description                                                      |
| --------------- | ----- | ---------------------------------------------------------------- |
| `--impl` / `-i` | `-i`  | Liste de champs pour générer l'implémentation CRUD immédiatement |

**Champs générés (automatiques, ne pas les inclure) :** `id`, `createdAt`, `updatedAt`

**Syntaxe des champs :** `nom:type`, séparés par des virgules

**Types disponibles :**

| Type YAML           | Type Dart    | Note                                 |
| ------------------- | ------------ | ------------------------------------ |
| `string`            | `String`     |                                      |
| `int`               | `int`        |                                      |
| `double`            | `double`     | `decimal` accepté aussi              |
| `bool`              | `bool`       | `boolean` accepté aussi              |
| `datetime`          | `DateTime`   | `date` accepté aussi                 |
| `num`               | `num`        |                                      |
| `enum(v1,v2)`       | Sealed Class | Génère une enum Dart                 |
| `reference(Entity)` | `String`     | Clé étrangère vers une autre feature |

**Exemple concret :**

```bash
cscm create commande -i "reference:string, montant:double, statut:enum(en_attente,confirmee,expediee,livree,annulee), client:reference(Client)"
```

Cela génère 12 fichiers avec l'entity `Commande` et tous ses champs typés, l'enum `StatutCommande` en sealed class, et la référence vers `Client`.

---

### `cscm generate:all`

Génère plusieurs features d'un coup depuis un fichier YAML. Gère les dépendances entre features (tri topologique) : si `produit` référence `categorie`, alors `categorie` est générée en premier.

```bash
cscm generate:all
cscm generate:all -f mes-features.yaml
```

Le fichier par défaut est `.cscm-features.yaml` à la racine du projet.

Voir la section [Format YAML pour generate:all](#format-yaml-pour-generateall) pour le détail du format.

---

### `cscm auth`

Configure l'authentification (Email, Google, etc.). Génère les services, repositories et écrans de login/register adaptés au backend choisi.

```bash
cscm auth email
cscm auth google
```

**Remarque :** `cscm auth` gère l'authentification (connexion, inscription, session). Pour les données métier de l'utilisateur (nom, rôle, téléphone), crée une feature `profil` séparée avec un champ `userId:string` comme liaison avec `auth.users.id`.

---

### `cscm implemente`

Ajoute ou met à jour l'implémentation CRUD d'une feature existante. Pratique si tu as créé une feature sans champs et que tu veux les ajouter plus tard.

```bash
cscm implemente produit -i "nom:string, prix:double"
```

---

### `cscm add:widget`

Génère un widget partagé réutilisable dans `lib/shared/widgets/`.

```bash
cscm add:widget app_button
cscm add:widget custom_card
```

---

### `cscm list`

Liste toutes les features du projet avec leurs détails.

```bash
cscm list
```

---

### `cscm status`

Affiche la progression du projet et des suggestions.

```bash
cscm status
```

---

### `cscm history`

Affiche l'historique de toutes les actions CSCM sur le projet.

```bash
cscm history
```

---

### `cscm undo`

Annule une feature : supprime les fichiers créés, nettoie l'injection de dépendances et le ErrorListener.

```bash
cscm undo produit
```

**Attention :** Cette commande est irréversible. Elle supprime tous les fichiers générés par `cscm create produit` et retire les références dans le container d'injection et le ErrorListener.

---

### `cscm commit`

Commit intelligent des fichiers modifiés par CSCM. Uniquement les fichiers touchés par CSCM sont inclus dans le commit.

```bash
cscm commit
```

---

### `cscm test`

Lance les tests.

```bash
cscm test              # Tous les tests
cscm test produit      # Tests d'une feature spécifique
```

---

### `cscm config`

Crée ou met à jour le fichier de configuration `.cscm.yaml`. Utilise cette commande si tu as un projet existant et que tu veux y ajouter CSCM.

```bash
cscm config -n mon_app
cscm config -n mon_app --backend supabase
```

---

## Architecture générée

Chaque feature suit cette arborescence :

```
lib/features/produit/
  data/
    datasources/
      produit_remote_source.dart    # Appels API/Supabase
    models/
      produit_model.dart            # DTO (fromJSON/toJSON)
    repositories/
      produit_repository_impl.dart  # Implémentation du repository
  domain/
    entities/
      produit_entity.dart           # Entité pure (pas de JSON)
    repositories/
      produit_repository.dart       # Interface abstraite
    usecases/
      get_produit_usecase.dart
      create_produit_usecase.dart
      update_produit_usecase.dart
      delete_produit_usecase.dart
  presentation/
    controllers/
      produit_controller.dart       # Riverpod notifier
    states/
      produit_states.dart           # Sealed class (loading, loaded, error...)
    actions/
      produit_actions.dart          # Sealed class (create, update, delete...)
```

**Principe de Clean Architecture respecté :**

- **Domain** ne dépend de rien (ni Flutter, ni packages externes)
- **Data** dépend de Domain (et de packages comme Supabase)
- **Presentation** dépend de Domain (via usecases)
- Les dépendances pointent toujours vers l'intérieur, jamais vers l'extérieur

**Points d'extension automatiques :**

CSCM utilise des ancres (`[ANCHOR]`) dans les fichiers de base pour pouvoir y injecter du code automatiquement quand de nouvelles features sont créées :

- `[IMPORT_ANCHOR]` -- dans `injection_container.dart`
- `[INIT_ANCHOR]` -- dans `injection_container.dart`
- `[INIT_METHOD_ANCHOR]` -- dans `injection_container.dart`
- `[LISTENERS_ANCHOR]` -- dans `success_error_listener.dart`
- `[ROUTES_ANCHOR]` -- dans `app_router.dart`

---

## Guide : projet complet en 5 minutes

```bash
# 1. Créer le projet
cscm init livreo --org fr.livreo --backend supabase
cd livreo
flutter pub get

# 2. Configurer le backend
# Éditer .env avec tes clés Supabase

# 3. Initialiser l'authentification
cscm auth email

# 4. Créer le profil utilisateur
cscm create profil -i "userId:string, telephone:string, nom:string, prenom:string, role:enum(client,sender,livreur), avatar:string, fcmToken:string, estActif:bool, estVerifie:bool"

# 5. Créer les features métier
cscm create categorie -i "nom:string, description:string"
cscm create produit -i "nom:string, description:string, prix:double, categorie:reference(Categorie)"
cscm create commande -i "reference:string, montant:double, statut:enum(en_attente,confirmee,expediee,livree,annulee)"

# 6. Vérifier
cscm list
cscm status

# 7. Commiter
cscm commit

# 8. Commencer à coder le métier
# Les fichiers sont prêts, les imports sont en place,
# l'injection est configurée. Tu n'as plus qu'à implémenter
# la logique dans les usecases et les appels API dans les datasources.
```

### Alternative : tout générer depuis un YAML

Si tu préfères décrire toutes tes features dans un fichier et tout générer en une commande :

```bash
# 1-3. Même début que ci-dessus

# 4. Créer le fichier .cscm-features.yaml (voir section suivante)

# 5. Tout générer d'un coup
cscm generate:all

# 6. Vérifier et commiter
cscm list
cscm commit
```

---

## Format YAML pour generate:all

### 3 formats acceptés

**Format map (compact) :**

```yaml
features:
  categorie:
    fields: "nom:string, description:string"
  produit:
    fields: "nom:string, prix:double, categorie:reference(Categorie)"
```

**Format liste :**

```yaml
features:
  - name: categorie
    fields: "nom:string, description:string"
  - name: produit
    fields: "nom:string, prix:double, categorie:reference(Categorie)"
```

**Format liste avec fields en array :**

```yaml
features:
  - name: produit
    fields:
      - "nom:string"
      - "prix:double"
      - "categorie:reference(Categorie)"
```

### Gestion des dépendances

Si `produit` a un champ `categorie:reference(Categorie)`, CSCM détecte la dépendance et génère `categorie` avant `produit` (tri topologique, algorithme de Kahn).

Si un cycle de dépendances est détecté, la commande s'arrête avec une erreur.

### Champs réservés (auto-générés, ne pas les inclure)

`id`, `createdAt`, `updatedAt` -- CSCM les ajoute automatiquement. Si tu les mets dans le YAML, ils seront ignorés.

---

## Fichiers de suivi

CSCM utilise deux fichiers de configuration à la racine de ton projet :

### `.cscm.yaml` -- Configuration du projet

```yaml
project_name: mon_app
backend: supabase
```

Ce fichier est créé par `cscm init` ou `cscm config`. Tu peux le modifier manuellement si besoin.

### `.cscm-state.yaml` -- État du projet (auto-généré)

Ce fichier est généré et mis à jour automatiquement par CSCM. Il contient :

- La liste des features créées et leurs fichiers
- L'historique des actions (create, undo, auth, etc.)
- L'état de l'authentification
- Les migrations SQL liées aux implémentations

**Ne pas éditer ce fichier manuellement.** Si tu le supprimes, CSCM ne pourra plus faire de `undo` ni de `status` fiable.

---

## Remarques et bonnes pratiques

### Workflow recommandé

1. **`cscm init`** une seule fois au début du projet
2. **`cscm auth`** si ton app a de l'authentification
3. **`cscm create`** ou **`cscm generate:all`** pour chaque feature métier
4. **Coder le métier** dans les usecases et datasources générés
5. **`cscm commit`** régulièrement pour ne committer que les fichiers CSCM
6. **`cscm undo`** si une feature doit être supprimée (avant de committer)

### Quand utiliser `create` vs `generate:all`

- **`cscm create`** -- Pour ajouter une feature à la volée pendant le développement
- **`cscm generate:all`** -- Au démarrage du projet quand tu connais toutes tes features, ou quand tu veux régénérer plusieurs features d'un coup

### Gestion des références entre features

Quand tu utilises `reference(AutreFeature)`, CSCM s'attend à ce que la feature `AutreFeature` existe (ou soit dans le même YAML pour `generate:all`). Le tri topologique de `generate:all` gère l'ordre de génération. Pour `cscm create`, crée les features référencées en premier.

### Enum et sealed classes

Le champ `statut:enum(en_attente,confirmee,livree)` génère :

- En **entity** : un type `enum` Dart
- En **model** : une conversion string vers enum et inverse
- Dans les **states/actions** : les sealed classes appropriées

### Fichiers générés par feature

Chaque `cscm create` génère **12 fichiers** :

| Couche                    | Fichiers                                                             |
| ------------------------- | -------------------------------------------------------------------- |
| Domain (entity)           | `produit_entity.dart`                                                |
| Domain (repository)       | `produit_repository.dart` (interface)                                |
| Domain (usecases)         | `get_produit_usecase.dart`, `create_...`, `update_...`, `delete_...` |
| Data (model)              | `produit_model.dart`                                                 |
| Data (datasource)         | `produit_remote_source.dart`                                         |
| Data (repository impl)    | `produit_repository_impl.dart`                                       |
| Presentation (controller) | `produit_controller.dart`                                            |
| Presentation (states)     | `produit_states.dart`                                                |
| Presentation (actions)    | `produit_actions.dart`                                               |
| Mise à jour               | `injection_container.dart`, `success_error_listener.dart`            |

### Désinstaller

```bash
dart pub global deactivate clean_solid_cli_mobile
```

### Stack technique

- **Langage** : Dart SDK (CLI pur, pas de dépendance Flutter)
- **Architecture** : Clean Architecture (Data, Domain, Presentation)
- **State management** : Riverpod (Notifiers + Sealed Classes)
- **Injection** : GetIt
- **Navigation** : GoRouter
- **Backend** : Supabase ou Firebase (optionnel)
- **Fonctionnel** : Dartz (Either pour la gestion d'erreurs)
- **Templates** : Système de remplacement dynamique de balises (`{{name}}`, `{{snakeName}}`, `[ANCHOR]`)

---

## Licence

MIT
