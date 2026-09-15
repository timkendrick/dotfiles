import {
  DynamicBorder,
  type ExtensionAPI,
  type ExtensionContext,
  type SessionEntry,
} from "@earendil-works/pi-coding-agent";
import { Container, type SelectItem, SelectList, Text } from "@earendil-works/pi-tui";
import { realpathSync } from "node:fs";
import { isAbsolute, relative, resolve } from "node:path";

const MAX_VISIBLE_ROWS = 10;
/**
 * Value carried by the placeholder row shown when no files have been touched.
 * Selecting that row must not insert anything, so the picker resolves to `null`
 * whenever the confirmed item carries this value. No real path can be empty, so
 * it cannot collide with a selectable file.
 */
const EMPTY_STATE_VALUE = "";
const EDIT_TOOL_NAME = "edit";
const WRITE_TOOL_NAME = "write";
const PICKER_DESCRIPTION = "Pick a file edited in this session and insert its path";
const MIN_PATH_COLUMN_WIDTH = 32;
const MAX_PATH_COLUMN_WIDTH = 128;

type FileToolName = typeof EDIT_TOOL_NAME | typeof WRITE_TOOL_NAME;

interface FileTouch {
  readonly absolutePath: string;
  readonly editCount: number;
  readonly writeCount: number;
  readonly lastTouched: number;
}

interface PendingToolCall {
  readonly absolutePath: string;
  readonly toolName: FileToolName;
}

/**
 * The chosen path, alongside a repaint request bound to the running TUI.
 *
 * Inserting into the editor mutates it outside the terminal input pipeline, so
 * nothing schedules a frame afterwards and the insertion stays invisible until
 * the next keypress. The TUI is only reachable from inside the component
 * factory, so the picker hands a repaint callback back with its result.
 */
interface PickerResult {
  readonly path: string | null;
  readonly requestRender: () => void;
}

export default function (pi: ExtensionAPI): void {
  pi.registerCommand("files", {
    description: PICKER_DESCRIPTION,
    handler: async (_args, ctx): Promise<void> => {
      await showFilePicker(ctx);
    },
  });

  pi.registerShortcut("ctrl+r", {
    description: PICKER_DESCRIPTION,
    handler: async (ctx): Promise<void> => {
      await showFilePicker(ctx);
    },
  });
}

/**
 * Presents the files touched by `edit` and `write` on the current session
 * branch, then inserts the chosen path at the chat editor's cursor.
 */
async function showFilePicker(ctx: ExtensionContext): Promise<void> {
  if (ctx.mode !== "tui") {
    ctx.ui.notify("The file picker requires interactive mode", "warning");
    return;
  }

  const cwd = canonicalPath(ctx.cwd);
  const touches = collectFileTouches(ctx.sessionManager.getBranch(), cwd);
  const items = buildSelectItems(touches, cwd, Date.now());

  const selection = await ctx.ui.custom<PickerResult>((tui, theme, _keybindings, done) => {
    const container = new Container();
    const borderColor = (text: string): string => theme.fg("border", text);
    const requestRender = (): void => tui.requestRender();

    container.addChild(new DynamicBorder(borderColor));
    container.addChild(new Text(theme.fg("accent", theme.bold("Session file edits")), 1, 0));

    const selectList = new SelectList(
      items,
      Math.min(items.length, MAX_VISIBLE_ROWS),
      {
        selectedPrefix: (text: string): string => theme.fg("accent", text),
        selectedText: (text: string): string => theme.fg("accent", text),
        description: (text: string): string => theme.fg("muted", text),
        scrollInfo: (text: string): string => theme.fg("dim", text),
        noMatch: (text: string): string => theme.fg("warning", text),
      },
      {
        minPrimaryColumnWidth: MIN_PATH_COLUMN_WIDTH,
        maxPrimaryColumnWidth: MAX_PATH_COLUMN_WIDTH,
      },
    );
    selectList.onSelect = (item: SelectItem): void => {
      done({
        path: item.value === EMPTY_STATE_VALUE ? null : item.value,
        requestRender,
      });
    };
    selectList.onCancel = (): void => done({ path: null, requestRender });
    container.addChild(selectList);

    container.addChild(
      new Text(theme.fg("dim", "↑↓ navigate • enter select • esc cancel"), 1, 0),
    );
    container.addChild(new DynamicBorder(borderColor));

    return {
      render: (width: number): Array<string> => container.render(width),
      invalidate: (): void => container.invalidate(),
      handleInput: (data: string): void => {
        selectList.handleInput(data);
        requestRender();
      },
    };
  });

  if (selection.path !== null) {
    ctx.ui.pasteToEditor(`${selection.path} `);
    selection.requestRender();
  }
}

/**
 * Walks the current session branch and aggregates every successful `edit` and
 * `write` tool call by target file, most recently touched first.
 */
function collectFileTouches(entries: Array<SessionEntry>, cwd: string): Array<FileTouch> {
  const pendingCalls = new Map<string, PendingToolCall>();
  const touchesByPath = new Map<string, FileTouch>();

  for (const entry of entries) {
    if (entry.type !== "message") continue;
    const message = entry.message;

    if (message.role === "assistant") {
      for (const part of message.content) {
        if (part.type !== "toolCall") continue;
        const toolName = readFileToolName(part.name);
        if (toolName === null) continue;
        const requestedPath = readPathArgument(part.arguments);
        if (requestedPath === null) continue;
        pendingCalls.set(part.id, {
          absolutePath: resolvePath(requestedPath, cwd),
          toolName,
        });
      }
      continue;
    }

    if (message.role === "toolResult") {
      if (message.isError) continue;
      const call = pendingCalls.get(message.toolCallId);
      if (call === undefined) continue;
      const previous = touchesByPath.get(call.absolutePath);
      touchesByPath.set(call.absolutePath, {
        absolutePath: call.absolutePath,
        editCount: (previous?.editCount ?? 0) + (call.toolName === EDIT_TOOL_NAME ? 1 : 0),
        writeCount: (previous?.writeCount ?? 0) + (call.toolName === WRITE_TOOL_NAME ? 1 : 0),
        lastTouched: message.timestamp,
      });
    }
  }

  return [...touchesByPath.values()].sort((left, right) => right.lastTouched - left.lastTouched);
}

/** Identifies tool calls that mutate a file, discarding every other tool. */
function readFileToolName(toolName: string): FileToolName | null {
  if (toolName === EDIT_TOOL_NAME) return EDIT_TOOL_NAME;
  if (toolName === WRITE_TOOL_NAME) return WRITE_TOOL_NAME;
  return null;
}

/** Extracts the `path` argument from stored tool call arguments. */
function readPathArgument(toolArguments: Record<string, unknown>): string | null {
  const requestedPath = toolArguments.path;
  if (typeof requestedPath !== "string") return null;
  const trimmed = requestedPath.trim();
  if (trimmed === "") return null;
  return trimmed.startsWith("@") ? trimmed.slice(1) : trimmed;
}

/**
 * Resolves a tool call path argument to a canonical absolute path, so that
 * symlinked aliases of one file collapse to a single entry.
 */
function resolvePath(requestedPath: string, cwd: string): string {
  return canonicalPath(isAbsolute(requestedPath) ? requestedPath : resolve(cwd, requestedPath));
}

/**
 * Canonicalises a path through the filesystem. Paths that cannot be resolved,
 * such as files deleted since they were touched, are returned unchanged.
 *
 * The session working directory is canonicalised alongside touched files so that
 * both sides agree when the working directory is itself reached through a
 * symlink, which would otherwise force every path to render as absolute.
 */
function canonicalPath(path: string): string {
  try {
    return realpathSync(path);
  } catch {
    return path;
  }
}

function buildSelectItems(
  touches: Array<FileTouch>,
  cwd: string,
  now: number,
): Array<SelectItem> {
  if (touches.length === 0) {
    return [{ value: EMPTY_STATE_VALUE, label: "(no file edits in this session)" }];
  }

  return touches.map((touch) => {
    const path = displayPath(touch.absolutePath, cwd);
    return {
      value: path,
      label: path,
      description: `${describeCounts(touch)} · ${describeAge(now - touch.lastTouched)}`,
    };
  });
}

/** Renders a path relative to the session cwd, falling back to absolute. */
function displayPath(absolutePath: string, cwd: string): string {
  const relativePath = relative(cwd, absolutePath);
  if (relativePath === "" || relativePath.startsWith("..") || isAbsolute(relativePath)) {
    return absolutePath;
  }
  return relativePath;
}

/** Renders the per-tool touch breakdown, e.g. `1 write, 3 edits`. */
function describeCounts(touch: FileTouch): string {
  const parts: Array<string> = [];
  if (touch.writeCount > 0) {
    parts.push(`${touch.writeCount} ${touch.writeCount === 1 ? "write" : "writes"}`);
  }
  if (touch.editCount > 0) {
    parts.push(`${touch.editCount} ${touch.editCount === 1 ? "edit" : "edits"}`);
  }
  return parts.join(", ");
}

/** Renders an elapsed duration in milliseconds as a compact relative time. */
function describeAge(elapsedMilliseconds: number): string {
  const seconds = Math.max(0, Math.floor(elapsedMilliseconds / 1000));
  if (seconds < 60) return `${seconds}s ago`;
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  return `${Math.floor(hours / 24)}d ago`;
}
