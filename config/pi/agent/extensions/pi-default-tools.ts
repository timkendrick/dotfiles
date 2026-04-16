import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    const tools = process.env.PI_DEFAULT_TOOLS;
    if (!tools) return;
    const toolNames = tools.split(",").map((value) => value.trim()).filter(Boolean);
    const allToolNames = pi.getAllTools().map((tool) => tool.name);
    const validToolNames = toolNames.filter((toolName) => allToolNames.includes(toolName));
    const invalidToolNames = toolNames.filter((toolName) => !allToolNames.includes(toolName));
    if (invalidToolNames.length > 0) {
      ctx.ui.notify(`PI_DEFAULT_TOOLS: skipping unknown tools: ${invalidToolNames.join(", ")}`, "warning");
    }
    if (validToolNames.length === 0) return;
    const previousActiveToolNames = pi.getActiveTools();
    const nextActiveToolNames = [...new Set([...previousActiveToolNames, ...validToolNames])];
    if (nextActiveToolNames.length === previousActiveToolNames.length) return;
    pi.setActiveTools(nextActiveToolNames);
  });
}  
