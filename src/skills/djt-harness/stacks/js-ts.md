# Stack: JavaScript and TypeScript

## Detect

- `package.json`, `tsconfig.json`, or `jsconfig.json`.
- `.js`, `.mjs`, `.cjs`, `.ts`, `.mts` files.
- The lockfile names the package manager: `package-lock.json` npm, `yarn.lock` yarn, `pnpm-lock.yaml` pnpm, `bun.lock` or `bun.lockb` bun. Use that one. Never mix.
- Node version: `.nvmrc`, `.node-version`, `.tool-versions`, or `engines` in `package.json`.

## Lint discovery

The repo's config is the authority. Never add a linter. Look in this order:

1. `package.json` `scripts`: `lint`, `typecheck`, `format`, `check`, `test`. Run these as written: `npm run lint`.
2. ESLint: `eslint.config.*` or `.eslintrc*`, or `eslintConfig` in `package.json`.
3. TypeScript: `tsconfig*.json`. Note `strict` and the `noUnchecked*` flags. Type check with the repo's script, else `npx tsc --noEmit`.
4. Format: `.prettierrc*`, `prettier` in `package.json`, `biome.json`, `.editorconfig`.
5. Hooks and CI: `.husky/`, `lint-staged`, `.pre-commit-config.yaml`, `Makefile`, `.github/workflows/*.yml`. CI shows the commands that gate a merge.

No config at all: follow tier 1 docs only. Do not install anything.

## Tier 1 docs

- JavaScript and Web APIs: MDN. `docs-mcp mdn call search '{"query":"Array.prototype.toSorted"}'`, then `docs-mcp mdn call get-doc '{"path":"<path>"}'`. Cite `https://developer.mozilla.org<path>`.
- TypeScript: `https://www.typescriptlang.org/docs/handbook/intro.html`. Compiler flags: `https://www.typescriptlang.org/tsconfig/`.
- Node APIs: `https://nodejs.org/api/`. Match the repo's Node version.
- Lint rules: `https://eslint.org/docs/latest/rules/<rule-id>`, `https://typescript-eslint.io/rules/<rule-id>/`.
- Other libraries: the vendor `llms.txt`, then `https://gitmcp.io/<owner>/<repo>`.

## Rule packs

| Change | Load |
|---|---|
| Hot loops, lookups, data transforms | `$DJAUNT_SRC_DIR/agent-skills/skills/react-best-practices/rules/js-*.md`. The rules apply outside React too. |
| Coercion, regex, eval, JSON parsing, async pitfalls | `$DJAUNT_SRC_DIR/skills/plugins/sharp-edges/skills/sharp-edges/references/lang-javascript.md` |
| Parsers, serializers, invariants worth a property test | `$DJAUNT_SRC_DIR/skills/plugins/property-based-testing/skills/property-based-testing/SKILL.md`. Adding fast-check needs Tory's OK. |
