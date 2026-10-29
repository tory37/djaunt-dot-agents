# Stack: HTML and CSS

## Detect

- `.html`, `.css`, `.scss`, `.less`, or `*.module.css` files.
- `tailwind.config.*`, `postcss.config.*`, or a CSS-in-JS dependency: `styled-components`, `@emotion/*`.
- Target browsers: `browserslist` in `package.json`, or `.browserslistrc`.

## Lint discovery

The repo's config is the authority. Never add a linter. Look for:

1. `package.json` `scripts` that run `stylelint`, `html-validate`, or `prettier`.
2. `.stylelintrc*` or `stylelint.config.*`. Rule docs: `https://stylelint.io/user-guide/rules`.
3. `.htmlvalidate.json`. Rule docs: `https://html-validate.org/rules/`.
4. `eslint-plugin-jsx-a11y` in the ESLint config, for JSX markup.
5. `.pre-commit-config.yaml`, `Makefile`, `.github/workflows/*.yml`.

No config at all: follow tier 1 docs only. Do not install anything.

## Tier 1 docs

- MDN for HTML, CSS, and ARIA:
  - `docs-mcp mdn call search '{"query":"css container queries"}'`
  - `docs-mcp mdn call get-doc '{"path":"<path>"}'`
  - Cite `https://developer.mozilla.org<path>`.
- Browser support: `docs-mcp mdn call get-compat '{"key":"<compat-key>"}'`. `search` returns the `compat-key`. Check it against the repo's browserslist.
- Accessibility criteria: `https://www.w3.org/WAI/WCAG22/quickref/`. Cite the success criterion number.
- HTML semantics: `https://html.spec.whatwg.org/multipage/`.

## Rule packs

The rules: `$DJAUNT_SRC_DIR/web-interface-guidelines/command.md`. Read only the sections the change needs.

| Change | Section |
|---|---|
| Buttons, links, labels, alt text, ARIA | Accessibility |
| Keyboard, focus rings | Focus States |
| Inputs, validation, submit | Forms |
| Transitions, motion | Animation |
| Fonts, numbers, text | Typography, Content Handling |
| Images, media | Images |
| Layout, notches, overflow | Safe Areas & Layout |
| Themes, color schemes | Dark Mode & Theming |
| Dates, numbers, languages | Locale & i18n |
| Hover, touch | Hover & Interactive States, Touch & Interaction |
| UI copy, labels, errors | Content & Copy |

Review process: `$DJAUNT_SRC_DIR/agent-skills/skills/web-design-guidelines/SKILL.md`. Skip its fetch from GitHub. Use the local `command.md` above.
