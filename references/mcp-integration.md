# MCP Integration Guide

## What is MCP?

Model Context Protocol (MCP) lets Cline access external tools like web search, APIs, or databases via standardized servers. The MCP Marketplace (github.com/cline/mcp-marketplace) hosts curated tool servers.

## Using MCP with Sub-Agents

Sub-agents inherit MCP tools from their CLINE_DIR config. To give a sub-agent access to specific tools:

### 1. Install MCP tools in the main Cline config
```bash
cline  # Interactive mode
# Navigate to MCP Marketplace → Install desired tools
```

### 2. Copy MCP config to isolated CLINE_DIRs
```bash
# MCP config lives in the cline data directory
cp -r ~/.cline/data/mcp ~/.cline-configs/my-project/data/mcp 2>/dev/null || true
```

### 3. Auto-approve MCP tools for headless mode
```bash
cline -y --auto-approve-mcp "task that needs web search" --timeout 600
```

## Useful MCP Tools for Sub-Agents

| Tool | Purpose | Use Case |
|------|---------|----------|
| Web Search | Search the internet | Research API docs, find solutions |
| Fetch | HTTP requests | Download files, check endpoints |
| File System | Extended file ops | Cross-project file access (with approval) |
| Database | SQL queries | Schema inspection, data validation |
| GitHub | GitHub API | PR creation, issue management |

## Security Considerations

- MCP tools run with the same permissions as the Cline agent
- Review which MCP tools each sub-agent has access to
- Consider restricting MCP tools per project via separate CLINE_DIR configs
- Monitor MCP tool usage in task logs
