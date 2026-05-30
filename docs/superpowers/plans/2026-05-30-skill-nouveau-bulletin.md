# Skill `/nouveau-bulletin` — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construire un skill `/nouveau-bulletin` qui, à partir du PDF source du curé, génère la page HTML du nouveau numéro (format identique à mai) puis publie tout automatiquement sur GitHub Pages.

**Architecture:** Skill (`SKILL.md`) = orchestration suivie par Claude, qui fait la partie créative/multimodale (lire le PDF → écrire le HTML). Un script PowerShell `publier-numero.ps1` fait la plomberie déterministe (poppler, copie PDF, git, vérif). Un `templates/bulletin.html` fige le CSS + sections stables ; les sections variables sont régénérées.

**Tech Stack:** Claude Code skill (Markdown), PowerShell 7, GitHub CLI (`gh`), poppler (`pdftoppm`), HTML/CSS statique, GitHub Pages.

Spec de référence : `docs/superpowers/specs/2026-05-30-skill-nouveau-bulletin-design.md`.

---

## File Structure

| Fichier | Responsabilité |
|---|---|
| `.gitignore` (modifié) | Ignorer les PDF sources bruts et `_input.pdf` |
| `templates/bulletin.html` (créé) | Gabarit hybride figé (CSS + en-tête + footer + horaires + contacts ; variables vidées) |
| `scripts/publier-numero.ps1` (créé) | Plomberie : phases `prepare` et `publish` |
| `.claude/skills/nouveau-bulletin/SKILL.md` (créé) | Orchestration + cookbook des composants HTML |

---

## Task 1 : Nettoyage et `.gitignore`

**Files:**
- Modify: `.gitignore`
- Delete: `_source-mai-2026.pdf` (fichier temporaire du design)

- [ ] **Step 1 : Supprimer le fichier temporaire de design**

```powershell
Remove-Item "C:\Projets GitHub\bulletin-icrsp-dijon\_source-mai-2026.pdf" -ErrorAction SilentlyContinue
```

- [ ] **Step 2 : Lire le `.gitignore` actuel**

Run: `Get-Content "C:\Projets GitHub\bulletin-icrsp-dijon\.gitignore"`
Expected: 3 lignes existantes (`.DS_Store`, `*.log`, `node_modules/` — ou similaire).

- [ ] **Step 3 : Ajouter les règles d'ignore**

Ajouter ces lignes à la fin de `.gitignore` :

```gitignore

# PDF sources bruts du curé (seule la copie ASCII dans bulletins/ est versionnée)
_input.pdf
Dijon Précurseur *.pdf
```

- [ ] **Step 4 : Vérifier que le PDF source racine est bien ignoré**

Run: `cd "C:\Projets GitHub\bulletin-icrsp-dijon"; git status --short`
Expected: ni `Dijon Précurseur 1.pdf` ni `_source-mai-2026.pdf` n'apparaissent ; seul `.gitignore` est modifié.

- [ ] **Step 5 : Commit**

```powershell
cd "C:\Projets GitHub\bulletin-icrsp-dijon"
git add .gitignore
git commit -m "Ignore les PDF sources bruts (skill nouveau-bulletin)"
```

---

## Task 2 : Le gabarit `templates/bulletin.html`

On part d'une copie **exacte** de `index.html` (CSS verbatim), puis on (a) remplace l'en-tête de numéro et le lien PDF par des marqueurs, et (b) vide les 5 sections variables en gardant un commentaire repère.

**Files:**
- Create: `templates/bulletin.html` (copie de `index.html` modifiée)

- [ ] **Step 1 : Copier `index.html` vers le template**

```powershell
cd "C:\Projets GitHub\bulletin-icrsp-dijon"
New-Item -ItemType Directory -Force templates | Out-Null
Copy-Item index.html templates\bulletin.html -Force
```

- [ ] **Step 2 : Marqueur de numéro dans l'en-tête**

Dans `templates/bulletin.html`, remplacer :

```html
    <div class="header__issue">n°1 · mai 2026</div>
```

par :

```html
    <div class="header__issue">{{ISSUE}}</div>
```

- [ ] **Step 3 : Marqueur de lien PDF dans le footer**

Remplacer :

```html
      <a href="bulletins/bulletin-icrsp-dijon-mai-2026.pdf" download>Télécharger ce bulletin en PDF</a>
```

par :

```html
      <a href="bulletins/bulletin-icrsp-dijon-{{MOIS-SLUG}}.pdf" download>Télécharger ce bulletin en PDF</a>
```

- [ ] **Step 4 : Vider la section Éditorial**

Remplacer tout le bloc `<section id="editorial" class="section"> … </section>` par :

```html
  <section id="editorial" class="section">
    <h2 class="section-title">Éditorial</h2>
    <!-- ÉDITORIAL (variable) — cookbook §5.1 :
         h3.block-title (2e+ avec style="margin-top: 36px;"),
         1er <p> en class="lettrine", citations en div.citation,
         signature finale en p.auteur. -->
  </section>
```

- [ ] **Step 5 : Vider la section Événements**

Remplacer tout le bloc `<section id="evenements" class="section"> … </section>` par :

```html
  <section id="evenements" class="section">
    <h2 class="section-title">Événements</h2>
    <!-- ÉVÉNEMENTS (variable) — cookbook §5.2 :
         par événement, div.fiche-evenement > h3.block-title +
         div.fiche-meta (📅 fiche-meta__date, 📍 fiche-meta__lieu) +
         <p> + éventuel p.fiche-contact + éventuel a.btn.btn--primary. -->
  </section>
```

- [ ] **Step 6 : Vider la section Carnet familial**

Remplacer tout le bloc `<section id="carnet" class="section"> … </section>` par :

```html
  <section id="carnet" class="section">
    <h2 class="section-title">Carnet familial</h2>
    <!-- CARNET (variable) — cookbook §5.3 :
         div.carnet-familial > carnet-section (label + content) séparées
         par div.carnet-separator ✦. Rubriques : R.I.P. ✝, Mariages,
         Fiançailles, Baptêmes. Noms en <strong>. -->
  </section>
```

- [ ] **Step 7 : Vider la section Vie de l'ICRSP**

Remplacer tout le bloc `<section id="icrsp" class="section"> … </section>` par :

```html
  <section id="icrsp" class="section">
    <h2 class="section-title">Vie de l'ICRSP</h2>
    <!-- VIE DE L'ICRSP (variable) — cookbook §5.4 :
         div.fiche-evenement avec style="border-left-color: var(--color-accent);". -->
  </section>
```

- [ ] **Step 8 : Vider la section Textes et prières**

Remplacer tout le bloc `<section id="textes" class="section"> … </section>` par :

```html
  <section id="textes" class="section">
    <h2 class="section-title">Textes et prières</h2>
    <!-- TEXTES (variable) — cookbook §5.5 :
         par texte, div.depliant > details.depliant-details > summary
         (h3.block-title + p.block-subtitle + <p> d'amorce + div.depliant-toggle)
         puis div.depliant-content. -->
  </section>
```

- [ ] **Step 9 : Vérifier que les sections stables et le CSS sont intacts**

Run:
```powershell
cd "C:\Projets GitHub\bulletin-icrsp-dijon"
Select-String -Path templates\bulletin.html -Pattern 'id="apostolat"','id="contacts"','--color-primary','Sub Oculis','{{ISSUE}}','{{MOIS-SLUG}}' | ForEach-Object { $_.Pattern } | Sort-Object -Unique
```
Expected: les 6 motifs sont trouvés (sections stables présentes, design tokens présents, marqueurs présents).

- [ ] **Step 10 : Vérifier que les sections variables sont bien vidées**

Run:
```powershell
Select-String -Path templates\bulletin.html -Pattern 'lettrine','fiche-evenement','carnet-familial','depliant-details'
```
Expected: **aucun résultat** (les composants variables n'existent plus dans le template — ils ne vivent que dans le cookbook).

- [ ] **Step 11 : Commit**

```powershell
git add templates/bulletin.html
git commit -m "Ajoute le gabarit hybride templates/bulletin.html"
```

---

## Task 3 : Le script `scripts/publier-numero.ps1`

**Files:**
- Create: `scripts/publier-numero.ps1`

- [ ] **Step 1 : Écrire le script**

Créer `scripts/publier-numero.ps1` avec ce contenu exact :

```powershell
<#
.SYNOPSIS
  Plomberie de publication d'un numéro du bulletin ICRSP Dijon.
.DESCRIPTION
  Phase 'prepare' : installe poppler si besoin, copie le PDF source vers _input.pdf.
  Phase 'publish' : copie le PDF sous le nom conventionnel, commit, push, vérifie les liens.
#>
param(
  [Parameter(Mandatory)][ValidateSet('prepare','publish')][string]$Phase,
  [string]$SourcePdfPath,
  [int]$Numero,
  [string]$MoisSlug
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

function Sync-Path {
  $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' +
              [Environment]::GetEnvironmentVariable('Path','User')
}

function Ensure-Poppler {
  Sync-Path
  if (Get-Command pdftoppm -ErrorAction SilentlyContinue) { return }
  Write-Host "Installation de poppler (pdftoppm) via winget..."
  winget install --id oschwartz10612.Poppler -e --accept-source-agreements --accept-package-agreements | Out-Null
  Sync-Path
  if (-not (Get-Command pdftoppm -ErrorAction SilentlyContinue)) {
    throw "pdftoppm introuvable apres installation. Installe poppler manuellement puis relance."
  }
}

if ($Phase -eq 'prepare') {
  if (-not $SourcePdfPath -or -not (Test-Path -LiteralPath $SourcePdfPath)) {
    throw "PDF source introuvable: $SourcePdfPath"
  }
  Ensure-Poppler
  Copy-Item -LiteralPath $SourcePdfPath -Destination (Join-Path $RepoRoot '_input.pdf') -Force
  $name = Split-Path $SourcePdfPath -Leaf
  $cand = if ($name -match '(\d+)') { $Matches[1] } else { '?' }
  $last = git log --oneline 2>$null | Select-String -Pattern 'Bulletin n.(\d+)' | Select-Object -First 1
  Write-Host "OK: _input.pdf prêt."
  Write-Host "Numéro candidat (nom de fichier): $cand"
  Write-Host "Dernier commit bulletin: $last"
  exit 0
}

# Phase publish
if (-not $Numero)    { throw "-Numero requis en phase publish" }
if (-not $MoisSlug)  { throw "-MoisSlug requis en phase publish" }
if (-not $SourcePdfPath -or -not (Test-Path -LiteralPath $SourcePdfPath)) {
  throw "PDF source introuvable: $SourcePdfPath"
}

$targetPdf = Join-Path $RepoRoot "bulletins/bulletin-icrsp-dijon-$MoisSlug.pdf"
Copy-Item -LiteralPath $SourcePdfPath -Destination $targetPdf -Force
Remove-Item (Join-Path $RepoRoot '_input.pdf') -ErrorAction SilentlyContinue

Sync-Path
git add -A
git commit -q -m "Bulletin n°$Numero — $MoisSlug"
git push -q

# Dépôt au format owner/name
$remote = git remote get-url origin
$repo = ($remote -replace '.*github\.com[:/]','') -replace '\.git$',''
$owner = ($repo -split '/')[0].ToLower()
$name  = ($repo -split '/')[1]
$base  = "https://$owner.github.io/$name"

Write-Host "Attente du build GitHub Pages..."
for ($i = 0; $i -lt 20; $i++) {
  $s = gh api "repos/$repo/pages" --jq '.status' 2>$null
  Write-Host "  build: $s"
  if ($s -eq 'built') { break }
  Start-Sleep -Seconds 15
}

$urls = @('/', '/archives.html',
          "/bulletins/bulletin-icrsp-dijon-$MoisSlug.html",
          "/bulletins/bulletin-icrsp-dijon-$MoisSlug.pdf")
$allOk = $true
foreach ($u in $urls) {
  try {
    $r = Invoke-WebRequest -Uri "$base$u" -Method Head -TimeoutSec 20
    Write-Host ("  {0,-50} {1}" -f $u, $r.StatusCode)
  } catch {
    $allOk = $false
    Write-Host ("  {0,-50} ERREUR {1}" -f $u, $_.Exception.Response.StatusCode.value__)
  }
}

if ($allOk) {
  Write-Host "`nPublié et vérifié : $base/"
} else {
  Write-Host "`nATTENTION: au moins un lien ne répond pas 200."
  Write-Host "Revert possible: git revert HEAD  (puis git push)"
  exit 1
}
```

- [ ] **Step 2 : Vérifier la syntaxe du script (parse sans exécuter)**

Run:
```powershell
$null = [System.Management.Automation.Language.Parser]::ParseFile("C:\Projets GitHub\bulletin-icrsp-dijon\scripts\publier-numero.ps1", [ref]$null, [ref]$null); "Parse OK"
```
Expected: `Parse OK` sans erreur de parsing.

- [ ] **Step 3 : Vérifier le rejet des paramètres manquants**

Run:
```powershell
cd "C:\Projets GitHub\bulletin-icrsp-dijon"
try { ./scripts/publier-numero.ps1 -Phase publish } catch { "Rejet attendu: $($_.Exception.Message)" }
```
Expected: message « -Numero requis en phase publish » (ou « PDF source introuvable » selon l'ordre des contrôles).

- [ ] **Step 4 : Commit**

```powershell
git add scripts/publier-numero.ps1
git commit -m "Ajoute scripts/publier-numero.ps1 (plomberie de publication)"
```

---

## Task 4 : Vérifier la phase `prepare` de bout en bout

Test d'intégration léger : la phase `prepare` doit installer poppler (si absent) et produire `_input.pdf`.

**Files:** (aucun ; vérification du comportement)

- [ ] **Step 1 : Lancer la phase prepare sur le PDF de mai**

Run:
```powershell
cd "C:\Projets GitHub\bulletin-icrsp-dijon"
$pdf = (Get-ChildItem "Dijon Précurseur*.pdf" | Select-Object -First 1).FullName
./scripts/publier-numero.ps1 -Phase prepare -SourcePdfPath $pdf
```
Expected: installation de poppler si nécessaire, puis « OK: _input.pdf prêt. » + numéro candidat « 1 ».

- [ ] **Step 2 : Vérifier que `pdftoppm` est maintenant disponible**

Run:
```powershell
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
(Get-Command pdftoppm).Source
```
Expected: un chemin vers `pdftoppm.exe`.

- [ ] **Step 3 : Vérifier que Claude peut lire `_input.pdf`**

Lire `C:\Projets GitHub\bulletin-icrsp-dijon\_input.pdf` (pages 1-5) avec l'outil Read.
Expected: les pages s'affichent en images (rendu multimodal fonctionnel). Si « pdftoppm failed », poppler n'est pas correctement sur le PATH de l'outil — résoudre avant de continuer.

- [ ] **Step 4 : Nettoyer le `_input.pdf` de test**

```powershell
Remove-Item "C:\Projets GitHub\bulletin-icrsp-dijon\_input.pdf" -ErrorAction SilentlyContinue
```

(Pas de commit : `_input.pdf` est gitignoré.)

---

## Task 5 : Le skill `.claude/skills/nouveau-bulletin/SKILL.md`

**Files:**
- Create: `.claude/skills/nouveau-bulletin/SKILL.md`

- [ ] **Step 1 : Écrire le SKILL.md**

Créer `.claude/skills/nouveau-bulletin/SKILL.md` avec ce contenu exact :

````markdown
---
name: nouveau-bulletin
description: Publier un nouveau numéro du bulletin ICRSP Dijon à partir du PDF source du curé. Use when l'utilisateur veut générer/publier un nouveau bulletin mensuel, ou lance /nouveau-bulletin.
---

# Nouveau bulletin ICRSP Dijon

Génère la page HTML d'un nouveau numéro à partir du PDF source (« Dijon Précurseur N.pdf »)
en respectant SCRUPULEUSEMENT le format de `index.html`, puis publie tout automatiquement.

Architecture : tu (Claude) fais le créatif (lecture multimodale du PDF → écriture du HTML).
Le script `scripts/publier-numero.ps1` fait la plomberie (poppler, copie PDF, git, vérif).

## Procédure

### 1. Localiser le PDF source
Cherche à la racine du dépôt le PDF « Dijon Précurseur N.pdf » le plus récent.
Aucun PDF → STOP, demande son chemin à l'utilisateur.

### 2. Préparer la lecture
Lance :
`./scripts/publier-numero.ps1 -Phase prepare -SourcePdfPath "<chemin du PDF>"`
Cela installe poppler si besoin et copie le PDF vers `_input.pdf`.

### 3. Lire le PDF (multimodal)
Lis `_input.pdf` avec l'outil Read, TOUTES les pages, images comprises.
Les images (affiches d'événements) peuvent porter des dates/lieux/contacts : extrais-les.

### 4. Déduire numéro et mois
- **Numéro** : depuis le nom de fichier (« Dijon Précurseur 2.pdf » → 2), recoupé avec
  l'historique git (`git log` ; dernier « Bulletin n°N » + 1).
- **Mois / année** : lus dans l'en-tête du PDF. Introuvables → demande à l'utilisateur
  (seul arrêt prévu).
- Calcule :
  - `MOIS-SLUG` = mois en minuscules + année, ex. `juin-2026`.
  - `ISSUE` = `n°<N> · <mois> <année>`, ex. `n°2 · juin 2026`.

### 5. Générer le HTML
Pars de `templates/bulletin.html`. NE TOUCHE PAS au `<style>`, à l'en-tête fixe, au
sommaire (hors retraits), aux sections `#apostolat` et `#contacts`, ni au footer (hors lien PDF).
- Remplace `{{ISSUE}}` par la valeur calculée.
- Remplace `{{MOIS-SLUG}}` par le slug.
- Remplis les 5 sections variables (`#editorial`, `#evenements`, `#carnet`, `#icrsp`,
  `#textes`) avec le contenu extrait, en suivant le **cookbook** ci-dessous à la lettre.
- Si une section variable n'a aucun contenu ce mois-ci, supprime la section ENTIÈRE
  ainsi que son `<li class="nav__item">` dans le sommaire.
- Écris le résultat dans :
  - `index.html` (racine) — blason `image.png`, lien PDF `bulletins/bulletin-icrsp-dijon-<slug>.pdf` ;
  - `bulletins/bulletin-icrsp-dijon-<slug>.html` — IDENTIQUE mais blason `../image.png`
    et lien PDF `bulletin-icrsp-dijon-<slug>.pdf` (même dossier).

### 6. Mettre à jour archives.html
Insère, en TÊTE de `<section class="archives-list">`, cette carte (titre = titre de l'éditorial) :

```html
    <article class="bulletin-card">
      <div class="bulletin-card__issue">n°<N> · <Mois Année></div>
      <h3 class="bulletin-card__title"><titre de l'éditorial></h3>
      <div class="bulletin-card__actions">
        <a href="bulletins/bulletin-icrsp-dijon-<slug>.html" class="btn btn--primary">Lire en ligne →</a>
        <a href="bulletins/bulletin-icrsp-dijon-<slug>.pdf" class="btn btn--secondary" download>Télécharger le PDF</a>
      </div>
    </article>
```

### 7. Publier
Lance :
`./scripts/publier-numero.ps1 -Phase publish -Numero <N> -MoisSlug "<slug>" -SourcePdfPath "<chemin du PDF>"`
Le script copie le PDF, commit, push, attend le build Pages et vérifie les liens (200).

### 8. Restituer
Donne le rapport final : URL en ligne, statut des liens. Si un lien échoue, indique la
commande de revert (`git revert HEAD` puis `git push`).

## Cookbook des composants (format à respecter à l'identique)

### §5.1 Éditorial (#editorial)
- `<h2 class="section-title">Éditorial</h2>`.
- `<h3 class="block-title">…</h3>` par sujet (à partir du 2e : `style="margin-top: 36px;"`).
- Premier paragraphe : `<p class="lettrine">…</p>`.
- Citation : `<div class="citation"><p>« … »</p><span class="citation-source">Auteur</span></div>`.
- Signature : `<p class="auteur">Chanoine …</p>`.

### §5.2 Événements (#evenements)
```html
<div class="fiche-evenement">
  <h3 class="block-title">Titre</h3>
  <div class="fiche-meta">
    <div class="fiche-meta__row"><span class="fiche-meta__icon">📅</span><span class="fiche-meta__date">Date</span></div>
    <div class="fiche-meta__row"><span class="fiche-meta__icon">📍</span><span class="fiche-meta__lieu"><a href="https://maps.google.com/?q=...">Lieu</a></span></div>
  </div>
  <p>Description.</p>
  <p class="fiche-contact">Contact : <a href="tel:+33...">Nom — 06 ...</a></p>
  <a href="https://..." target="_blank" class="btn btn--primary">S'inscrire →</a>
</div>
```
Variante note : `style="border-left-color: var(--color-primary);"` + `btn--secondary`.

### §5.3 Carnet familial (#carnet)
```html
<div class="carnet-familial">
  <div class="carnet-section">
    <div class="carnet-section__label">✝ R.I.P.</div>
    <div class="carnet-section__content"><p>… <strong>Nom</strong> …</p></div>
  </div>
  <div class="carnet-separator">✦</div>
  <div class="carnet-section">
    <div class="carnet-section__label">Mariages</div>
    <div class="carnet-section__content"><p><strong>X</strong> avec <strong>Y</strong>, le … en l'église …</p></div>
  </div>
</div>
```
Rubriques selon le PDF : R.I.P., Mariages, Fiançailles, Baptêmes. Une `carnet-separator` ✦ entre chaque.

### §5.4 Vie de l'ICRSP (#icrsp)
Comme §5.2 mais `<div class="fiche-evenement" style="border-left-color: var(--color-accent);">`.

### §5.5 Textes et prières (#textes)
```html
<div class="depliant">
  <details class="depliant-details">
    <summary>
      <h3 class="block-title">Titre du texte</h3>
      <p class="block-subtitle">Source / auteur</p>
      <p>Phrase d'amorce…</p>
      <div class="depliant-toggle">Lire la suite <span class="depliant-toggle__chevron">▾</span></div>
    </summary>
    <div class="depliant-content">
      <p>Texte complet…</p>
    </div>
  </details>
</div>
```

## Règles de fidélité
- Ne modifie JAMAIS le bloc `<style>` ni les sections stables (#apostolat, #contacts, footer).
- Utilise les espaces insécables `&nbsp;` avant `: ; ! ?` comme dans index.html.
- Liens téléphone en `<a href="tel:+33...">`, adresses en liens Google Maps.
- N'intègre AUCUNE image du PDF dans le HTML (texte seul, sauf le blason).
````

- [ ] **Step 2 : Vérifier la présence et le frontmatter du skill**

Run:
```powershell
Get-Content "C:\Projets GitHub\bulletin-icrsp-dijon\.claude\skills\nouveau-bulletin\SKILL.md" -TotalCount 4
```
Expected: les lignes de frontmatter `---`, `name: nouveau-bulletin`, `description: …`.

- [ ] **Step 3 : Commit**

```powershell
cd "C:\Projets GitHub\bulletin-icrsp-dijon"
git add .claude/skills/nouveau-bulletin/SKILL.md
git commit -m "Ajoute le skill /nouveau-bulletin"
```

---

## Task 6 : Test d'acceptation — reproduire mai depuis le PDF source

C'est le test de non-régression du format : générer le HTML depuis `Dijon Précurseur 1.pdf`
doit redonner une page très proche de l'actuel `index.html`. On NE publie PAS (test à blanc).

**Files:** (génération dans un fichier de travail jetable, non commité)

- [ ] **Step 1 : Préparer la lecture du PDF de mai**

Run:
```powershell
cd "C:\Projets GitHub\bulletin-icrsp-dijon"
$pdf = (Get-ChildItem "Dijon Précurseur*.pdf" | Select-Object -First 1).FullName
./scripts/publier-numero.ps1 -Phase prepare -SourcePdfPath $pdf
```
Expected: `_input.pdf` prêt, numéro candidat « 1 ».

- [ ] **Step 2 : Lire le PDF et générer le HTML dans un fichier de test**

Suivre les étapes 3-5 du SKILL.md mais écrire la sortie dans `_test-mai.html`
(au lieu de `index.html`), avec `ISSUE = n°1 · mai 2026` et `MOIS-SLUG = mai-2026`.

- [ ] **Step 3 : Comparer la structure au mai de référence**

Run:
```powershell
cd "C:\Projets GitHub\bulletin-icrsp-dijon"
$ref  = (Select-String -Path index.html      -Pattern 'class="[a-z-]+"' -AllMatches).Matches.Value | Sort-Object -Unique
$test = (Select-String -Path _test-mai.html  -Pattern 'class="[a-z-]+"' -AllMatches).Matches.Value | Sort-Object -Unique
"Classes manquantes dans le test:"; Compare-Object $ref $test | Where-Object SideIndicator -eq '<=' | ForEach-Object { $_.InputObject }
```
Expected: aucune (ou très peu de) classe structurelle manquante. Toute classe de composant
absente signale une infidélité de format à corriger dans le SKILL.md/cookbook.

- [ ] **Step 4 : Revue visuelle**

Ouvrir `_test-mai.html` dans le navigateur et comparer à `index.html` : mêmes sections,
même allure, contenu fidèle au PDF. Noter tout écart de contenu (édito, événements, carnet).

- [ ] **Step 5 : Nettoyer les fichiers de test**

```powershell
Remove-Item "C:\Projets GitHub\bulletin-icrsp-dijon\_test-mai.html","C:\Projets GitHub\bulletin-icrsp-dijon\_input.pdf" -ErrorAction SilentlyContinue
```

- [ ] **Step 6 : Mettre à jour la mémoire projet**

Ajouter une mémoire `skill-nouveau-bulletin` notant l'existence du skill, du template et du
script, et le workflow mensuel (déposer le PDF → `/nouveau-bulletin`). Lier à
`[[deploiement-github-pages]]`.

---

## Notes d'exécution

- **Pas de vraie publication pendant l'implémentation** : seul le Task 6 fait une génération,
  et à blanc (`_test-mai.html`, non commité). La première vraie publication aura lieu quand
  le curé fournira « Dijon Précurseur 2.pdf ».
- **Dépendance poppler** : installée à la première phase `prepare`. Si le PATH ne se rafraîchit
  pas dans la session courante, rouvrir le terminal ou re-synchroniser le PATH.
- **Filet de sécurité** : tout est versionné ; un mauvais numéro se corrige par
  `git revert HEAD && git push`.
