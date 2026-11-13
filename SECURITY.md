# Security Guidelines

## Secrets and credentials
- Never hardcode API keys, tokens, passwords, or database URLs in code.
- Use environment variables (`.env`) and keep `.env` in `.gitignore`.
- Never print, log, or commit secrets. If you see one exposed, warn right away.
- Provide a `.env.example` file with placeholder values only.

## Input and data handling
- Treat all user input as untrusted. Validate type, length, and format.
- Use parameterized queries or an ORM. Never build SQL by string concatenation.
- Escape or sanitize output to prevent XSS.
- Don't collect or store personal data that wasn't asked for.
- Never log sensitive data (passwords, tokens, personal info).

## Authentication and access
- Never write your own crypto or password hashing. Use bcrypt/argon2 or the framework's built-in tools.
- Check authorization on the server, not only in the UI.
- Apply least privilege: users and API keys get only the access they need.
- Use HTTPS for all network requests.

## Dependencies
- Don't add a package without asking and explaining why.
- Prefer well-maintained, popular packages. Don't invent package names.
- Flag outdated or vulnerable dependencies.

## Error handling
- Use try/catch around risky operations (network, database, file access).
- Show users friendly error messages. Never expose stack traces or internal details.
- No silent failures: log the error safely and handle it.

## Destructive actions
- Never delete files, drop tables, reset databases, force-push, or run `rm -rf` / `sudo` commands without explicit approval.
- Before any migration or bulk data change, explain what will happen and suggest a backup.
- Don't touch files outside the project folder.

## Review habit
- After writing code, list any security risks or assumptions you made.
- If a request would create a security hole, say so and suggest a safer way.
- When unsure whether something is safe, ask instead of guessing.
