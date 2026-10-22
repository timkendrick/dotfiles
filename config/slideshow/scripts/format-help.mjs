// Adapts existing command help text (read from stdin) to describe additional command-line arguments.
//
// Arguments:
//   <name>                                         Command name shown in the usage line
//   --usage "<example>|<description>"              Usage example, appended below the usage line
//   --arg="<option>|<description>|<before-option>"  Option inserted before the line listing <before-option>
//
// Fields are separated by the ASCII unit separator (0x1F), shown above as |.

import { readFileSync } from 'node:fs';
import { parseArgs } from 'node:util';

const FIELD_SEPARATOR = '\x1f';

const fail = (message) => {
  process.stderr.write(`format-help: ${message}\n`);
  process.exit(1);
};

const splitFields = (value, count, flag) => {
  const fields = value.split(FIELD_SEPARATOR);
  if (fields.length !== count) {
    fail(`${flag} expects ${count} fields separated by 0x1F: ${JSON.stringify(value)}`);
  }
  return fields;
};

const escapeRegExp = (text) => text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const { values, positionals } = parseArgs({
  allowPositionals: true,
  options: {
    usage: { type: 'string', multiple: true, default: [] },
    arg: { type: 'string', multiple: true, default: [] },
  },
});

const [name] = positionals;
if (name === undefined) {
  fail('missing command name');
}

const examples = values.usage.map((value) => splitFields(value, 2, '--usage'));
const options = values.arg.map((value) => splitFields(value, 3, '--arg'));

const usageBlock = (rest) => {
  const exampleWidth = Math.max(0, ...examples.map(([example]) => example.length)) + 3;
  return [
    `Usage: ${name} ${rest}`,
    ...examples.map(([example, description]) => `       ${example.padEnd(exampleWidth)}${description}`),
  ].join('\n');
};

const insertOption = (help, [option, description, beforeOption]) => {
  const pattern = new RegExp(`^( *)${escapeRegExp(beforeOption)}(?![\\w-]).*?  +`, 'm');
  const match = pattern.exec(help);
  if (match === null) {
    fail(`option not found in help text: ${beforeOption}`);
  }
  const [prefix, indent] = match;
  const longFlagColumn = indent.length + Math.max(0, beforeOption.indexOf('--'));
  const optionColumn = option.startsWith('--') ? longFlagColumn : indent.length;
  const line = `${' '.repeat(optionColumn)}${option}`.padEnd(prefix.length) + description;
  return `${help.slice(0, match.index)}${line}\n${help.slice(match.index)}`;
};

const help = readFileSync(process.stdin.fd, 'utf8').replace(/^Usage: cli (.*)$/m, (_, rest) => usageBlock(rest));

process.stdout.write(options.reduce(insertOption, help));
