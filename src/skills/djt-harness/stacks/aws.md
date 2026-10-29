# Stack: AWS

Covers Lambda, AppSync, DynamoDB, CloudWatch, and CloudFormation or SAM. Load the handler language's stack file too: `python.md` or `js-ts.md`.

## Detect

- SAM: `template.yaml` or `template.yml` with `Transform: AWS::Serverless-2016-10-31`, or `samconfig.toml`.
- CloudFormation: a template with `AWSTemplateFormatVersion` or `Resources:` of type `AWS::*`.
- AppSync: `*.graphql` schemas, resolver files (`.js` with `@aws-appsync/utils`, or `.vtl`).
- SDK use: `boto3` in Python deps, `@aws-sdk/*` in `package.json`.

## Lint discovery

The repo's config is the authority. Never add a linter. Run only what the repo configures:

1. `cfn-lint`: `.cfnlintrc`, `.cfnlintrc.yaml`, or a hook in `.pre-commit-config.yaml`. Rule docs: `https://github.com/aws-cloudformation/cfn-lint/blob/main/docs/rules.md`.
2. `sam validate --lint`: only if a script, `Makefile`, or CI runs it. Docs: `https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-cli-command-reference-sam-validate.html`.
3. `Makefile`, `.github/workflows/*.yml`, `buildspec.yml`.

Never deploy or call a live AWS account to verify a change.

## Tier 1 docs

AWS Knowledge MCP through `docs-mcp`:

```
docs-mcp aws call aws___search_documentation '{"search_phrase":"Lambda reserved concurrency","limit":5}'
```

- Each result has `title`, `url`, and `context`. `context` is page text. Cite the `url`.
- Optional `topics`, for example `["reference_documentation"]`. Run `docs-mcp aws tools` for the rest.
- Full page: `aws___read_documentation`.
- Fallback when the MCP fails: `https://docs.aws.amazon.com/`.

## Rule packs

Base: `$DJAUNT_SRC_DIR/trailofbits-skills/plugins/sharp-edges/skills/sharp-edges/references/`. Read locally. CC-BY-SA: never copy the text.

| Change | Load |
|---|---|
| IAM policies, resource config, defaults | `config-patterns.md` |
| Cognito, tokens, authorizers, AppSync auth | `auth-patterns.md` |
| KMS, signing, hashing | `crypto-apis.md` |
| Handler code | the handler language's rows in `python.md` or `js-ts.md` |
