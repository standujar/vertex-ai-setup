# Contributing

Thanks for your interest in contributing!

## How to contribute

1. Fork the repo
2. Create a branch (`git checkout -b feat/my-feature`)
3. Make your changes
4. Run `terraform fmt -recursive` and `terraform validate`
5. Open a PR

## Requirements

- Terraform >= 1.6
- [tflint](https://github.com/terraform-linters/tflint) (optional but recommended)

## Code style

- Run `terraform fmt -recursive` before committing
- Use descriptive resource names
- Add comments only when the "why" isn't obvious
- Keep variables documented with `description`

## Adding examples

Put new examples in `examples/<name>/main.tf`. Each example should be self-contained and copy-pasteable.

## Reporting issues

Open a GitHub issue with:
- What you tried
- What happened
- What you expected
