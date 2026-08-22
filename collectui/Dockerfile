FROM node:22-bookworm-slim

ARG COLLECTUI_MCP_VERSION=1.0.0

# Community package: install exact version and never execute lifecycle scripts.
RUN npm install --global --ignore-scripts --omit=dev "collectui-mcp@${COLLECTUI_MCP_VERSION}" \
    && npm cache clean --force

USER node

ENTRYPOINT ["collectui-mcp"]
