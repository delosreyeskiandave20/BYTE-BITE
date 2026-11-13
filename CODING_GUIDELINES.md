# Coding Guidelines

## Readability
- Write simple, readable code. Clarity over cleverness.
- Use descriptive names for variables, functions, classes, and files. Avoid vague names like `data`, `temp`, or `stuff`.
- Use consistent naming conventions (`camelCase`, `snake_case`, etc.) based on the project's language.
- Avoid deep nesting. Use early returns instead.
- No magic numbers or strings. Use named constants.

## Structure
- Keep functions short and single-purpose (one function, one job).
- Keep files focused. Split large files into smaller modules.
- Follow the existing folder structure. Ask before creating new folders.
- Separate concerns: UI, business logic, and data access stay apart.

## Don't Repeat Yourself (DRY)
- Reuse existing functions and components before writing new ones.
- If the same code appears 3 or more times, extract it into a helper.
- Don't over-engineer. No abstractions "just in case."

## Consistency
- Match the existing code style, formatting, and patterns.
- Use the project's linter and formatter (ESLint, Prettier, `dart format`, etc.).
- Don't mix different approaches for the same problem.

## Comments and documentation
- Comment the "why," not the "what."
- Add comments only where the logic isn't obvious.
- Don't leave commented-out code, debug logs, or unused imports.
- Mark unfinished work with a `TODO` and communicate it.

## Clean code
- Remove dead code and unused variables.
- Handle edge cases (null, empty, invalid values).
- Avoid global state and side effects where possible.
- Don't leave `console.log` or `print` statements in final code.

## Simplicity
- Choose the simplest solution that works.
- Prefer built-in language and framework features over extra libraries.
- If the code feels too complex to explain in plain words, simplify it.
