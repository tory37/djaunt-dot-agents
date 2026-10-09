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

### Rainbow Type System

The stylesheet maps each doc type to a bold `--primary` color via `data-type` on `<body>`. Every component (H1 gradient, H3, phase numbers, card accents, table headers, code tint, etc.) automatically inherits this color — no extra CSS needed per doc.

| Type | Color | Hex |
|---|---|---|
| `feature` | Electric blue | `#3b9eff` |
| `bug` | Hot red | `#ff4d4d` |
| `research` | Vivid purple | `#b060ff` |
| `review` | Neon green | `#22d167` |
| `techdebt` | Vivid amber | `#f5a623` |

### Type Badges

Use `badge-feature`, `badge-bug`, `badge-research`, `badge-review`, or `badge-techdebt` on `.badge` elements in `.doc-meta`.

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
| `table` | Standard dark-styled data table |
