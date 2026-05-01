/**
 * System Prompt Provider Rules Extension
 *
 * Performs regex-based find/replace on the system prompt based on the
 * current model provider. Rules are keyed by provider name and applied
 * sequentially via String.prototype.replaceAll.
 *
 * Usage:
 *   Edit the provider rules to add provider-specific replacements.
 *   Place the file in ~/.pi/agent/extensions/ for auto-discovery.
 */

import type { ExtensionAPI } from '@mariozechner/pi-coding-agent';

/**
 * Provider-specific regex replacement rules.
 *
 * Key:   provider name (e.g. "anthropic", "openai", "google")
 * Value: array of Replacement objects applied in order
 *
 * Each replacement is passed to String.prototype.replaceAll.
 * Replacer can be a static string or a function.
 */
const PROVIDER_REPLACEMENTS: Record<string, Array<Replacement>> = {
	'anthropic': [
		{ pattern: /pi, a coding agent harness/, replacement: 'a coding agent harness' },
		{ pattern: /\n\nPi documentation.*\n\n/s, replacement: "\n\n" },
	],
};

type Replacer = string | ((substring: string, ...groups: string[]) => string);

interface Replacement {
	pattern: RegExp;
	replacement: Replacer;
}

export default function systemPromptProviderRules(pi: ExtensionAPI) {
	pi.on('before_agent_start', async (event, ctx) => {
		const provider = ctx.model.provider;
		const providerRules = PROVIDER_REPLACEMENTS[provider];
		if (!providerRules || providerRules.length === 0) return;
		const systemPrompt = providerRules.reduce(
			(prompt, { pattern, replacement }) => prompt.replaceAll(createGlobalRegExp(pattern), replacement),
			event.systemPrompt,
		);
		return { systemPrompt };
	});
}

function createGlobalRegExp(pattern: RegExp): RegExp {
	const flags = pattern.flags.includes('g') ? pattern.flags : `${pattern.flags}g`;
	return new RegExp(pattern.source, flags);
}
