/**
 * System Prompt Replacer Extension
 *
 * Loads regex-based find/replace rules from JSON files and applies them to
 * the system prompt based on the current model provider.
 *
 * Rule files (applied in order: global then project):
 *   ~/.pi/agent/system-prompt-replacements.json  (or PI_CODING_AGENT_DIR)
 *   .pi/system-prompt-replacements.json          (relative to cwd)
 *
 * File format: array of { provider, pattern, replacement } where
 *   provider    – provider name string (e.g. "anthropic")
 *   pattern     – regex literal string including delimiters (e.g. "/foo/gi")
 *   replacement – raw replacement string
 *
 * A missing file is silently ignored. A malformed file throws immediately.
 */

import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import * as fs from 'node:fs';
import * as os from 'node:os';
import * as path from 'node:path';

const ERROR_PREFIX = '[system-prompt-replacer]';

const REPLACEMENTS_CONFIG_FILENAME = 'system-prompt-replacements.json';

type ReplacementDefinitionsConfigFile = ReplacementDefinitionConfigEntry[];

interface ReplacementDefinitionConfigEntry {
	provider?: string;
	pattern: string;
	replacement: string;
}

interface ParsedReplacementDefinition {
	provider: string | undefined;
	pattern: RegExp;
	replacement: string;
}

export default function systemPromptReplacer(pi: ExtensionAPI) {
	pi.on('before_agent_start', async (event, ctx) => {
		const provider = ctx.model.provider;
		const entries = loadReplacementsConfig().filter(e => e.provider === undefined || e.provider === provider);
		if (entries.length === 0) return;
		const systemPrompt = entries.reduce(
			(prompt, { pattern, replacement }) => prompt.replaceAll(createGlobalRegExp(pattern), replacement),
			event.systemPrompt,
		);
		return { systemPrompt };
	});
}

function loadReplacementsConfig(): ParsedReplacementDefinition[] {
	const globalFile = path.join(getGlobalConfigDir(), REPLACEMENTS_CONFIG_FILENAME);
	const projectFile = path.join(getProjectConfigDir(), REPLACEMENTS_CONFIG_FILENAME);
	return [...loadReplacementsConfigFile(globalFile), ...loadReplacementsConfigFile(projectFile)];
}

function loadReplacementsConfigFile(filePath: string): ParsedReplacementDefinition[] {
	const errorPrefix = `${ERROR_PREFIX} ${filePath}`;
	let text: string;
	try {
		text = fs.readFileSync(filePath, 'utf-8');
	} catch (err: unknown) {
		if ((err as NodeJS.ErrnoException).code === 'ENOENT') return [];
		throw new Error(`${errorPrefix}: failed to read config file: ${err}`);
	}

	let parsed: unknown;
	try {
		parsed = JSON.parse(text);
	} catch (err) {
		throw new Error(`${errorPrefix}: invalid JSON: ${err}`);
	}

	try {
		return parseValidReplacements(parsed);
	} catch (err: unknown) {
		throw new Error(`${errorPrefix}: ${err instanceof Error ? err.message : err}`);
	}
}

function parseValidReplacements(value: unknown): ParsedReplacementDefinition[] {
	// Pass 1: Parse and validate raw JSON structure into ReplacementDefinitionsConfigFile
	const configFile = parseReplacementsConfigFile(value);
	// Pass 2: Parse validated payloads into ParsedReplacementDefinition objects
	return parseConfigFileDefinitions(configFile);
}

function parseReplacementsConfigFile(value: unknown): ReplacementDefinitionsConfigFile {
	if (!Array.isArray(value)) {
		throw new Error(`expected an array at the top level`);
	}
	return value.map((item: unknown, i: number) => {
		try {
			return parseReplacementConfigEntry(item);
		} catch (err: unknown) {
			throw new Error(`invalid entry [${i}]: ${err instanceof Error ? err.message : err}`);
		}
	});
}

function parseReplacementConfigEntry(item: unknown): ReplacementDefinitionConfigEntry {
	if (typeof item !== 'object' || item === null || Array.isArray(item)) {
		throw new Error(`must be an object`);
	}
	const { provider, pattern, replacement } = item as Record<string, unknown>;
	if (provider !== undefined && (typeof provider !== 'string' || provider.length === 0)) {
		throw new Error(`provider must be a non-empty string when specified`);
	}
	if (typeof pattern !== 'string' || pattern.length === 0) {
		throw new Error(`pattern must be a non-empty string`);
	}
	if (typeof replacement !== 'string') {
		throw new Error(`replacement must be a string`);
	}
	return { provider, pattern, replacement };
}

function parseConfigFileDefinitions(configFile: ReplacementDefinitionsConfigFile): ParsedReplacementDefinition[] {
	return configFile.map((payload: ReplacementDefinitionConfigEntry, i: number) => {
		try {
			return {
				provider: payload.provider,
				pattern: parseRegExp(payload.pattern),
				replacement: payload.replacement,
			};
		} catch (err: unknown) {
			throw new Error(`invalid entry [${i}]: ${err instanceof Error ? err.message : err}`);
		}
	});
}

function getGlobalConfigDir(): string {
	const envDir = process.env['PI_CODING_AGENT_DIR'];
	if (envDir) return envDir.replace(/^~/, os.homedir());
	return path.join(os.homedir(), '.pi', 'agent');
}

function getProjectConfigDir(): string {
	return path.join(process.cwd(), '.pi');
}

function parseRegExp(raw: string): RegExp {
	if (!raw.startsWith('/')) {
		throw new Error(`pattern must start with '/': ${JSON.stringify(raw)}`);
	}
	const lastSlash = raw.lastIndexOf('/');
	if (lastSlash === 0) {
		throw new Error(`pattern must have a closing '/': ${JSON.stringify(raw)}`);
	}
	const source = raw.slice(1, lastSlash);
	const flags = raw.slice(lastSlash + 1);
	try {
		return new RegExp(source, flags);
	} catch (err) {
		throw new Error(`invalid pattern ${JSON.stringify(raw)}: ${err}`);
	}
}

function createGlobalRegExp(pattern: RegExp): RegExp {
	const flags = pattern.flags.includes('g') ? pattern.flags : `${pattern.flags}g`;
	return new RegExp(pattern.source, flags);
}
