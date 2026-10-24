# MCP Architecture

MCP servers provide AI development agents with controlled access to external systems.

## Recommended server categories
- Business Central sandbox / metadata access
- Application Insights / telemetry queries
- Documentation search
- GitHub / source control

## Security rules
- Keep production access read-only by default.
- Never store credentials in `.mcp.json` or `.vscode/mcp.json`.
- Use environment variables or secure credential stores.
- Do not allow autonomous production publishing or destructive data operations.
