# Design — Skill `/nouveau-bulletin`

Date : 2026-05-30
Auteur : Benoist + Claude
Statut : validé (design)

## 1. Objectif

Automatiser, mois après mois, la publication d'un nouveau numéro du bulletin
« ICRSP Dijon » sur GitHub Pages, à partir du PDF source fourni par le curé
(`Dijon Précurseur N.pdf`). Le skill doit :

1. **Créer la page HTML** du nouveau numéro en respectant **scrupuleusement** le
   format actuel (celui de `index.html` / mai 2026) ;
2. **Enchaîner toute la routine** de publication (archivage, archives.html,
   commit, push, vérification en ligne) **automatiquement**.

Le contenu est extrait du PDF par **analyse multimodale** (texte **et** images :
une affiche d'événement peut porter une date/lieu/contact à retranscrire).

## 2. Décisions de cadrage

| Sujet | Décision |
|---|---|
| Images du PDF | **Non intégrées** au HTML (sortie texte seul, comme mai). Mais **analysées** pour en extraire les infos (événements, dates…). |
| Publication | **Tout automatique**, sans point d'arrêt de relecture. Vérification finale (HTML + liens 200). Revert git comme filet de sécurité. |
| Entrée / identification | **Auto-détection** : n° via le nom de fichier (`Dijon Précurseur N.pdf`) + historique git ; **mois** lu dans le contenu du PDF (en-tête). |
| Gabarit | **Hybride** : template figé (CSS + en-tête + footer + sections stables horaires/contacts) ; sections variables vidées et régénérées. À mettre à jour manuellement si une section stable change. |
| Architecture d'exécution | **Skill + script déterministe** : Claude fait le créatif/multimodal (HTML) ; un script PowerShell fait la plomberie (OS/git/réseau). |
| PDF téléchargeable | **PDF source du curé** réutilisé tel quel (zéro rendu). Copié sous un nom ASCII conventionnel. |

## 3. Architecture

Séparation des responsabilités :

- **Claude (créatif + multimodal)** : lit le PDF, comprend le contenu, **écrit** le
  HTML (`index.html`, la copie archivée, la carte dans `archives.html`).
- **Script `publier-numero.ps1` (déterministe, aucune connaissance du HTML)** :
  prépare l'environnement (poppler), copie le PDF, fait git, vérifie les liens.

### Fichiers créés

| Fichier | Rôle |
|---|---|
| `.claude/skills/nouveau-bulletin/SKILL.md` | Instructions d'orchestration + cookbook des composants HTML |
| `templates/bulletin.html` | Gabarit hybride figé |
| `scripts/publier-numero.ps1` | Plomberie (poppler, copie PDF, commit, push, vérif) |

## 4. Le template hybride (`templates/bulletin.html`)

Copie exacte de `index.html` (CSS inclus, **verbatim**), avec :

**Sections FIGÉES (conservées remplies) :**
- `<head>` complet + tout le bloc `<style>` (design tokens, composants) — **jamais modifié par le skill**.
- `header.header` : titre « Bulletin ICRSP — Dijon » et devise « Sub Oculis Christi Regis » figés ; **`header__issue` = marqueur `{{ISSUE}}`** (ex. « n°2 · juin 2026 »).
- `nav.nav` (sommaire) : conservé ; le skill retire les `nav__item` dont la section variable est vide ce mois-ci.
- `section#apostolat` (horaires Basilique + Chapelle Saint-André) : **conservé tel quel**.
- `section#contacts` (annuaire) : **conservé tel quel**.
- `footer.footer` : conservé ; **lien PDF = marqueur** vers `bulletins/bulletin-icrsp-dijon-{{MOIS-SLUG}}.pdf`.

**Sections VIDÉES (régénérées chaque mois depuis le PDF) :**
- `section#editorial`
- `section#evenements`
- `section#carnet`
- `section#icrsp`
- `section#textes`

Chaque section vidée contient un commentaire repère, p.ex.
`<!-- ÉDITORIAL : voir cookbook §5.1 -->`.

**Règle « section vide » :** si le PDF ne fournit rien pour une section variable
(ex. pas de carnet ce mois-ci), le skill **supprime la section ET son entrée de
sommaire** plutôt que de laisser un bloc vide.

## 5. Cookbook des composants HTML (référence de format)

Le SKILL.md documente les motifs exacts à réutiliser. Classes CSS de référence
issues de `index.html` (à respecter à l'identique) :

### 5.1 Éditorial (`#editorial`)
- `h2.section-title` « Éditorial ».
- Un ou plusieurs `h3.block-title` (sous-titres ; à partir du 2e, `style="margin-top: 36px;"`).
- **Premier paragraphe** de l'édito : `<p class="lettrine">` (lettrine).
- Citations : `<div class="citation"><p>« … »</p><span class="citation-source">Auteur</span></div>`.
- Signature finale : `<p class="auteur">Chanoine …</p>`.

### 5.2 Événements (`#evenements`)
- `h2.section-title` « Événements ».
- Par événement : `<div class="fiche-evenement">` avec
  - `h3.block-title` ;
  - `<div class="fiche-meta">` → lignes `fiche-meta__row` avec icône 📅 (`fiche-meta__date`) et 📍 (`fiche-meta__lieu`, lien Google Maps si adresse) ;
  - `<p>` descriptif ; éventuel `<p class="fiche-contact">` (tél en `<a href="tel:…">`) ;
  - bouton optionnel `<a class="btn btn--primary">…→</a>` (lien d'inscription).
- Variante « note » : `style="border-left-color: var(--color-primary);"` + `btn--secondary`.

### 5.3 Carnet familial (`#carnet`)
- `h2.section-title` « Carnet familial ».
- `<div class="carnet-familial">` avec des `carnet-section` (label `carnet-section__label`,
  contenu `carnet-section__content`) séparées par `<div class="carnet-separator">✦</div>`.
- Rubriques possibles : R.I.P. (✝), Mariages, Fiançailles, Baptêmes. Noms en `<strong>`.

### 5.4 Vie de l'ICRSP (`#icrsp`)
- `h2.section-title` « Vie de l'ICRSP ».
- `fiche-evenement` avec `style="border-left-color: var(--color-accent);"`.

### 5.5 Textes et prières (`#textes`)
- `h2.section-title` « Textes et prières ».
- Par texte : `<div class="depliant"><details class="depliant-details"><summary>…</summary>
  <div class="depliant-content">…</div></details></div>`.
- Le `<summary>` contient : `h3.block-title`, éventuel `p.block-subtitle` (source/auteur),
  un `<p>` d'amorce, puis `<div class="depliant-toggle">Lire la suite <span class="depliant-toggle__chevron">▾</span></div>`.

## 6. Le script `scripts/publier-numero.ps1`

Deux phases (paramètre `-Phase prepare|publish`). Aucune connaissance du HTML.

### Phase `prepare`
Paramètre : `-SourcePdfPath <chemin>`.
1. Vérifie que `pdftoppm` (poppler) est disponible (PATH machine+user). Sinon, installe
   via `winget install --id oschwartz10612.Poppler` (ou équivalent) ; si échec → **stop** message clair.
2. Copie le PDF source vers `_input.pdf` à la racine (nom ASCII lisible par l'outil de lecture
   de Claude, contournant l'encodage NFD de « Dijon Précurseur N.pdf »).
3. Affiche le n° candidat déduit du nom de fichier et le dernier n° publié (via git).

### Phase `publish`
Paramètres : `-Numero <int> -MoisSlug <slug> -SourcePdfPath <chemin>`
(ex. `-Numero 2 -MoisSlug "juin-2026"`).
1. Copie le PDF source → `bulletins/bulletin-icrsp-dijon-<MoisSlug>.pdf`.
2. Supprime `_input.pdf`.
3. `git add -A` ; `git commit` (message « Bulletin n°N — <Mois Année> ») ; `git push`.
4. Attend le build Pages (`gh api repos/<repo>/pages --jq .status` jusqu'à `built`).
5. Vérifie en HEAD (200) : `/`, `/archives.html`, `/bulletins/…<MoisSlug>.html`,
   `/bulletins/…<MoisSlug>.pdf`. Rapport final avec l'URL ; si un 200 manque → signale (revert possible).

## 7. Le skill `.claude/skills/nouveau-bulletin/SKILL.md`

Orchestration suivie par Claude lors de `/nouveau-bulletin` :

1. **Localiser le PDF source** : le plus récent `*.pdf` à la racine correspondant à
   « Dijon Précurseur N.pdf ». Aucun → **stop** (demander le chemin).
2. Lancer `publier-numero.ps1 -Phase prepare -SourcePdfPath <pdf>`.
3. **Lire `_input.pdf`** (toutes les pages, images comprises) via l'outil Read.
4. **Déduire** : n° (nom de fichier, recoupé avec git = dernier + 1) ; **mois/année**
   (en-tête du PDF). Mois introuvable → **demander à l'utilisateur** (seul arrêt prévu).
   Calculer `MoisSlug` (ex. `juin-2026`) et `ISSUE` (ex. `n°2 · juin 2026`).
5. **Générer le HTML** depuis `templates/bulletin.html` :
   - remplacer `{{ISSUE}}` et `{{MOIS-SLUG}}` ;
   - remplir les sections variables avec le contenu extrait, selon le cookbook (§5) ;
   - supprimer toute section variable vide + son entrée de sommaire ;
   - écrire **`index.html`** (racine) ;
   - écrire **`bulletins/bulletin-icrsp-dijon-<MoisSlug>.html`** = même contenu mais
     blason en `../image.png` et lien PDF en `bulletin-icrsp-dijon-<MoisSlug>.pdf`
     (même dossier).
6. **Mettre à jour `archives.html`** : insérer en tête de `section.archives-list` une
   `<article class="bulletin-card">` (n°, mois, titre de l'éditorial, liens HTML + PDF).
7. Lancer `publier-numero.ps1 -Phase publish -Numero N -MoisSlug <slug> -SourcePdfPath <pdf>`.
8. Restituer le **rapport final** (URL en ligne, statut des liens).

## 8. Gestion d'erreurs

| Cas | Comportement |
|---|---|
| Aucun PDF à la racine | Stop : demander le chemin du PDF. |
| Mois illisible dans le PDF | Demander le mois à l'utilisateur (seul arrêt « normal »). |
| Poppler non installable | Stop net avec instructions. |
| Échec push | Stop : afficher l'erreur git. |
| Vérif 200 en échec | Signaler clairement ; rappeler la commande de revert. |

## 9. `.gitignore`

Ajouter : `_input.pdf` et `Dijon Précurseur *.pdf` (les sources brutes restent locales ;
seule la copie ASCII dans `bulletins/` est versionnée). Nettoyer le fichier temporaire
`_source-mai-2026.pdf` créé pendant le design.

## 10. Critère d'acceptation (test)

**Reproduction de mai** : exécuter le skill sur `Dijon Précurseur 1.pdf` doit produire
un HTML très proche de l'actuel `index.html` (mêmes sections, mêmes classes, contenu
fidèle). On compare visuellement et structurellement. C'est le test de non-régression
du format.

Sur le script : vérifier que la phase `publish` archive, commit, push et obtient des 200
sur toutes les URLs.

## 11. Hors-scope (YAGNI)

- Pas d'extraction/intégration d'images dans le HTML.
- Pas de rendu HTML→PDF (on réutilise le PDF source).
- Pas de domaine personnalisé, pas de multilingue, pas de CMS.
- Mai n'est pas retouché (garde son PDF rendu actuel) ; la convention « PDF source »
  s'applique à partir du n°2.
