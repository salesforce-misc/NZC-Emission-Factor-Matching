# Contributing to EmissionsMatching

Thank you for your interest in contributing to the EmissionsMatching project! This document provides guidelines and instructions for contributing.

## Code of Conduct

This project adheres to the Salesforce Open Source Community Code of Conduct. By participating, you are expected to uphold this code.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:
- A clear, descriptive title
- Steps to reproduce the issue
- Expected vs. actual behavior
- Salesforce org edition and API version
- Any relevant error messages or logs

### Suggesting Enhancements

We welcome suggestions for new features or improvements. Please open an issue with:
- A clear description of the enhancement
- Use case or problem it would solve
- Any examples or mockups if applicable

### Pull Requests

1. **Fork the repository** and create a new branch from `main` or `master`
2. **Make your changes** following our coding standards
3. **Write or update tests** to cover your changes
4. **Update documentation** if needed
5. **Ensure all tests pass** before submitting
6. **Submit a pull request** with a clear description of changes

### Coding Standards

- Follow Salesforce Apex and Lightning Web Component best practices
- Maintain test coverage above 75%
- Follow the existing code style and naming conventions
- Add comments for complex logic
- Update relevant documentation

### Development Setup

1. Clone the repository
2. Set up a Salesforce scratch org:
   ```bash
   sf org create scratch --definition-file config/project-scratch-def.json --alias MyScratchOrg --duration-days 30
   ```
3. Deploy the source:
   ```bash
   sf project deploy start
   ```
4. Run tests:
   ```bash
   sf apex run test --test-level RunLocalTests
   ```

### Testing Requirements

- All new code must include test classes
- Test classes should achieve at least 75% code coverage
- Tests should cover both positive and negative scenarios
- Bulk testing (200+ records) should be included where applicable

### Documentation

- Update `README.md` for user-facing changes
- Update `REPOSITORY_SUMMARY.md` for architectural changes
- Add inline comments for complex logic
- Update this `CONTRIBUTING.md` if contribution process changes

### Commit Messages

Use clear, descriptive commit messages:
- Start with a verb (Add, Fix, Update, Remove)
- Reference issue numbers when applicable
- Keep the first line under 72 characters
- Add detailed description if needed

Example:
```
Fix date matching logic for overlapping date ranges

Resolves issue #123 by updating the date comparison logic
to handle edge cases where emissions set date ranges overlap.
```

## Questions?

If you have questions about contributing, please:
- Open an issue with the `question` label
- Review existing documentation in the `docs/` directory
- Check the `REPOSITORY_SUMMARY.md` for architectural details

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.

