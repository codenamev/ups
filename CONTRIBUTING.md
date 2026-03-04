# Contributing to ups

Thanks for considering a contribution. Here's what you need to know.

## The Basics

ups is maintained by a small team. We review PRs weekly. Please be patient — we'll get to yours.

## What We Welcome

- **Bug fixes** with a clear description of the problem and how your change fixes it
- **Documentation improvements** — typos, clarifications, better examples
- **Test coverage** for existing functionality
- **Small, focused PRs** — one concern per pull request

## What Needs Discussion First

Before spending time on a feature PR, **open an issue** describing what you want to build and why. We're selective about new features to keep the codebase focused. We'd rather discuss the approach before you write code.

## How to Contribute

1. Fork the repo
2. Create a feature branch (`git checkout -b fix/description`)
3. Make your changes
4. Run the test suite (`bin/rails test`)
5. Run the linter (`bin/rubocop`)
6. Commit with a clear message
7. Open a PR against `main`

## Code Style

We use [rubocop-rails-omakase](https://github.com/rails/rubocop-rails-omakase). Run `bin/rubocop` before submitting.

## Development Setup

```bash
git clone https://github.com/codenamev/ups.git
cd ups
bundle install
bin/rails db:create db:migrate
bin/rails server
```

## Tests

```bash
bin/rails test        # Unit and integration tests
bin/rails test:system # System tests (requires Chrome)
```

## License

By contributing, you agree that your contributions will be licensed under AGPL-3.0.
