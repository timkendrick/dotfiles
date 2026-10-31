/**
 * Sandbox Status Extension
 *
 * Publishes the `sandbox` extension status for the powerline footer.
 * A non-empty SANDBOX environment variable shows a lock icon.
 * Otherwise the status shows a warning icon.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const STATUS_KEY = "sandbox";
const SANDBOX_ENV_VAR = "SANDBOX";
const LOCK_ICON = "\uF023";
const WARNING_ICON = "\uF071";

export default function sandboxStatus(pi: ExtensionAPI): void {
  pi.on("session_start", (_event, ctx): void => {
    publishSandboxStatus(ctx);
  });
}

function publishSandboxStatus(ctx: ExtensionContext): void {
  const theme = ctx.ui.theme;
  const status = isSandboxed()
    ? theme.fg("success", LOCK_ICON)
    : theme.fg("warning", `${WARNING_ICON} ${theme.bold("UNSANDBOXED")}`);
  ctx.ui.setStatus(STATUS_KEY, status);
}

function isSandboxed(): boolean {
  const value = process.env[SANDBOX_ENV_VAR];
  return value !== undefined && value !== "";
}
