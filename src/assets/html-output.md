# HTML Output Convention — Reference

Read before writing the first HTML output file in a session.

### Stylesheet Bootstrap

Before writing the first HTML output file in a project, ensure the stylesheet exists:

```bash
mkdir -p .agents/output/assets
[ -f .agents/output/assets/style.css ] || cp ~/.agents/assets/style.css .agents/output/assets/style.css
```

### Relative Path to Stylesheet

Use a relative path from the HTML file to `.agents/output/assets/style.css`:

- File at `.agents/output/<type>/<file>.html` (one level deep) → `../assets/style.css`
- File at `.agents/output/<type>/<name>/<file>.html` (two levels deep) → `../../assets/style.css`

### Standard HTML Shell

Every output HTML file uses this base structure:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{{Title}} — {{type}}</title>
  <link rel="stylesheet" href="{{relative-path}}/assets/style.css">
</head>
<body data-type="{{type}}">
  <div class="container">
    <header class="doc-header">
      <div class="doc-meta">
        <span class="badge badge-{{type}}">{{TYPE}}</span>
        <span class="doc-date">{{YYYY-MM-DD}}</span>
      </div>
      <h1>{{Title}}</h1>
    </header>
    <main>
      {{sections}}
    </main>
  </div>
</body>
</html>
```

### Theme — Djaunt Hoard

The stylesheet follows the Djaunt brand (`github.com/tory37/djaunt-branding`, `BRANDING.md`). It vendors the brand `tokens.css` and loads Archivo, IBM Plex Sans, and IBM Plex Mono.

- Every doc uses the default `hoard` (gold) theme. No per-type colors.
- Use `--dj-*` role tokens for any inline styling (`--dj-accent`, `--dj-text-muted`, `--dj-surface`, `--dj-border`). Never hardcode a hex.
- Keep `data-type` on `<body>`. It no longer changes color.
- No emoji, no gradients, no left-accent-stripe cards. Radii stay 2/4/8px.

### Type Badges

Use `badge-feature`, `badge-bug`, `badge-research`, `badge-review`, or `badge-techdebt` on `.badge` elements in `.doc-meta`. All render in the gold accent; the label carries the type.

### Severity / Status Badges

Use `badge-critical`, `badge-warning`, `badge-suggestion`, `badge-complete`, `badge-pending`, or `badge-in-progress`.

### Key Component Classes

| Class | Use for |
|---|---|
| `.phase-card` | Each implementation phase (feature/techdebt plans) |
| `.phase-number`, `.phase-title`, `.phase-header` | Phase card header |
| `.phase-steps` | Ordered list of steps inside a phase |
| `.test-criteria` | Verification criteria block inside a phase |
| `.finding-card` + `.critical/.warning/.suggestion/.positive` | Review findings |
| `.finding-header`, `.finding-title`, `.finding-body`, `.finding-file` | Finding card anatomy |
| `.checklist` | Unordered list with checkbox-style bullets |
| `.test-steps` + `.test-step` | Numbered manual test steps (doer plans) |
| `.test-step .checkpoint` | Expected outcome inside a test step |
| `.meta-block` + `.meta-item` | Key/value metadata grid |
| `.section` + `.accent/.success/.warning/.danger` | Left-bordered content block |
| `.files-list` + `.file-chip` | Inline file path chips |
| `.bibliography` | Numbered sources list |
| `.callout` + `.info/.success/.warning/.danger` | Semantic note box |
| `table` | Data table with mono header row |
