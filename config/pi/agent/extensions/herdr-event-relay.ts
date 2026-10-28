/* See https://github.com/juicesharp/rpiv-mono/pull/165 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/** Map 3rd-party extension lifecycle events to well-known herdr event names */
export default function herdrEventRelay(pi: ExtensionAPI): void {
  rpivHerdrBridge(pi);
}

interface RpivAskUserBlockedPayload {
  active?: boolean;
}

/** Map @rpiv/ask-user-question lifecycle events to well-known herdr event names */
function rpivHerdrBridge(pi: ExtensionAPI): void {
  pi.events.on(
    "rpiv:ask-user:blocked",
    (payload: RpivAskUserBlockedPayload | undefined): void => {
      pi.events.emit(
        "herdr:blocked",
        payload?.active
          ? { active: true, label: "Waiting for ask_user_question" }
          : { active: false },
      );
    },
  );
}
