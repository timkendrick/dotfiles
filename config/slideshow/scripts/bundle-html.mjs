// Bundles an HTML file with its external resources (fonts, images, CSS) into a self-contained HTML file.

import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const [entryHtmlPath, outputPath] = process.argv.slice(2);

// Google Fonts serves woff2 only to user agents it recognizes as supporting it.
const BROWSER_USER_AGENT =
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36';

// Subsets of remote font stylesheets to keep; Google Fonts labels each @font-face with a `/* <subset> */` comment.
const REMOTE_FONT_SUBSETS = new Set(['latin']);

const FONT_FORMAT_PREFERENCE = ['woff2', 'woff', 'truetype', 'opentype'];

const MIME_TYPES = {
  '.woff2': 'font/woff2',
  '.woff': 'font/woff',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.webp': 'image/webp',
};

const isInlineReference = (reference) => reference.startsWith('data:') || reference.startsWith('#');

const isRemote = (url) => url.protocol === 'http:' || url.protocol === 'https:';

const fetchRemote = async (url) => {
  const response = await fetch(url, { headers: { 'User-Agent': BROWSER_USER_AGENT } });
  if (!response.ok) {
    throw new Error(`HTTP ${response.status} fetching ${url}`);
  }
  return response;
};

const readText = async (url) =>
  isRemote(url) ? (await fetchRemote(url)).text() : readFile(fileURLToPath(url), 'utf8');

const readBinary = async (url) => {
  if (isRemote(url)) {
    const response = await fetchRemote(url);
    return { bytes: Buffer.from(await response.arrayBuffer()), contentType: response.headers.get('content-type') };
  }
  return { bytes: await readFile(fileURLToPath(url)), contentType: null };
};

const toDataUri = async (url) => {
  const { bytes, contentType } = await readBinary(url);
  const mimeType =
    MIME_TYPES[path.extname(url.pathname).toLowerCase()] ?? contentType?.split(';')[0] ?? 'application/octet-stream';
  return `data:${mimeType};base64,${bytes.toString('base64')}`;
};

const stripSourceMaps = (source) => source.replace(/\n?\/[/*][#@] sourceMappingURL=[^\n]*/g, '');

const replaceAsync = async (source, pattern, replacer) => {
  const matches = [...source.matchAll(pattern)];
  const replacements = await Promise.all(matches.map((match) => replacer(...match)));
  let result = '';
  let cursor = 0;
  matches.forEach((match, index) => {
    result += source.slice(cursor, match.index) + replacements[index];
    cursor = match.index + match[0].length;
  });
  return result + source.slice(cursor);
};

const unquote = (value) => value.trim().replace(/^(['"])(.*)\1$/, '$2');

const FONT_FACE_PATTERN = /@font-face\s*\{[^}]*\}/g;

const filterRemoteFontSubsets = (css) =>
  css.replace(/\/\*\s*([\w-]+)\s*\*\/\s*(@font-face\s*\{[^}]*\})/g, (_, subset, rule) =>
    REMOTE_FONT_SUBSETS.has(subset) ? rule : '',
  );

const formatOf = (source) => {
  const declared = source.match(/format\(\s*['"]?([\w-]+)['"]?\s*\)/);
  if (declared) {
    return declared[1];
  }
  const extension = source.match(/url\(\s*['"]?[^'")?#]*\.(\w+)/)?.[1];
  return { woff2: 'woff2', woff: 'woff', ttf: 'truetype', otf: 'opentype' }[extension] ?? 'unknown';
};

// Embed only the most compact supported format of each font face, rather than every legacy fallback.
const selectPreferredFontSource = (rule) => {
  const declarations = [...rule.matchAll(/(?:^|[{;])\s*src\s*:([^;}]*)/g)];
  if (declarations.length === 0) {
    return rule;
  }
  const sources = declarations.at(-1)[1].split(/,(?=\s*(?:url|local)\()/).map((source) => source.trim());
  const ranked = sources
    .filter((source) => source.startsWith('url('))
    .map((source) => ({ source, rank: FONT_FORMAT_PREFERENCE.indexOf(formatOf(source)) }))
    .filter(({ rank }) => rank !== -1)
    .sort((a, b) => a.rank - b.rank);
  if (ranked.length === 0) {
    return rule;
  }
  const withoutSources = rule.replace(/(^|[{;])\s*src\s*:[^;}]*;?/g, '$1');
  return withoutSources.replace(/\}\s*$/, `  src: ${ranked[0].source};\n}`);
};

const inlineCss = async (css, baseUrl, { remote }) => {
  let result = stripSourceMaps(css);
  if (remote) {
    result = filterRemoteFontSubsets(result);
  }
  result = result.replace(FONT_FACE_PATTERN, selectPreferredFontSource);

  result = await replaceAsync(
    result,
    /@import\s+(?:url\(\s*([^)]*?)\s*\)|(['"][^'"]*['"]))[^;]*;/g,
    async (statement, urlArgument, stringArgument) => {
      const importUrl = new URL(unquote(urlArgument ?? stringArgument), baseUrl);
      try {
        return await inlineCss(await readText(importUrl), importUrl, { remote: isRemote(importUrl) });
      } catch (error) {
        console.warn(`warning: dropping ${statement.trim()} (${error.message}); system fallback fonts will be used`);
        return '';
      }
    },
  );

  return replaceAsync(result, /url\(\s*([^)]*?)\s*\)/g, async (expression, argument) => {
    const reference = unquote(argument);
    if (isInlineReference(reference)) {
      return expression;
    }
    const assetUrl = new URL(reference, baseUrl);
    try {
      return `url("${await toDataUri(assetUrl)}")`;
    } catch (error) {
      console.warn(`warning: dropping ${expression} (${error.message})`);
      return 'url("data:,")';
    }
  });
};

const usedFontFamilies = (css) => {
  const declarationsOutsideFontFaces = css.replace(FONT_FACE_PATTERN, '');
  const finalCustomProperties = new Map();
  for (const [, name, value] of declarationsOutsideFontFaces.matchAll(/(--[\w-]+)\s*:([^;}]*)/g)) {
    finalCustomProperties.set(name, value);
  }
  const fontDeclarations = [...declarationsOutsideFontFaces.matchAll(/(?:^|[{;\s])font(?:-family)?\s*:([^;}]*)/g)].map(
    ([, value]) => value,
  );
  const families = new Set();
  for (const value of [...finalCustomProperties.values(), ...fontDeclarations]) {
    for (const family of value.matchAll(/['"]([^'"]+)['"]/g)) {
      families.add(family[1].toLowerCase());
    }
  }
  return families;
};

// Reveal themes bundle fonts that custom stylesheets may override; drop faces no surviving declaration refers to.
const pruneUnusedFontFaces = (styleBlocks) => {
  const families = usedFontFamilies(styleBlocks.join('\n'));
  return styleBlocks.map((css) =>
    css.replace(FONT_FACE_PATTERN, (rule) => {
      const family = rule.match(/font-family\s*:\s*([^;}]*)/)?.[1];
      return family !== undefined && !families.has(unquote(family).toLowerCase()) ? '' : rule;
    }),
  );
};

const fontFaceDescriptor = (rule, name) => rule.match(new RegExp(`(?:^|[{;\\s])${name}\\s*:\\s*([^;}]*)`))?.[1]?.trim();

// Variable fonts are served as a single file for every requested weight; embed it once with a weight range.
const mergeVariableFontFaces = (css) => {
  const groups = new Map();
  for (const [rule] of css.matchAll(FONT_FACE_PATTERN)) {
    const key = ['font-family', 'font-style', 'src', 'unicode-range']
      .map((name) => fontFaceDescriptor(rule, name) ?? '')
      .join('\u0000');
    const weights = (fontFaceDescriptor(rule, 'font-weight') ?? '').split(/\s+/).map(Number);
    const group = groups.get(key);
    if (group === undefined) {
      groups.set(key, { rule, weights });
    } else {
      group.weights.push(...weights);
    }
  }
  const emitted = new Set();
  return css.replace(FONT_FACE_PATTERN, (rule) => {
    const key = ['font-family', 'font-style', 'src', 'unicode-range']
      .map((name) => fontFaceDescriptor(rule, name) ?? '')
      .join('\u0000');
    if (emitted.has(key)) {
      return '';
    }
    emitted.add(key);
    const { weights } = groups.get(key);
    if (weights.some(Number.isNaN)) {
      return rule;
    }
    const range = `${Math.min(...weights)} ${Math.max(...weights)}`;
    return rule.replace(/(font-weight\s*:\s*)[^;}]*/, `$1${range}`);
  });
};

const entryUrl = pathToFileURL(entryHtmlPath);
let html = await readFile(entryHtmlPath, 'utf8');

html = html.replace(/<link\b[^>]*\brel=["'](?:shortcut )?icon["'][^>]*>\s*/gi, '');

const stylesheetPattern = /<link\b[^>]*\brel=["']stylesheet["'][^>]*>/gi;
const stylesheets = await Promise.all(
  [...html.matchAll(stylesheetPattern)].map(async ([tag]) => {
    const href = tag.match(/\bhref=["']([^"']+)["']/i)?.[1];
    if (href === undefined) {
      throw new Error(`stylesheet link without href: ${tag}`);
    }
    const stylesheetUrl = new URL(href, entryUrl);
    return inlineCss(await readText(stylesheetUrl), stylesheetUrl, { remote: isRemote(stylesheetUrl) });
  }),
);
const prunedStylesheets = pruneUnusedFontFaces(stylesheets).map(mergeVariableFontFaces);
let stylesheetIndex = 0;
html = html.replace(stylesheetPattern, () => {
  const css = prunedStylesheets[stylesheetIndex++].replace(/<\/style/gi, '<\\/style');
  return `<style>\n${css}\n</style>`;
});

html = await replaceAsync(
  html,
  /<script\b([^>]*)\bsrc=["']([^"']+)["']([^>]*)>\s*<\/script>/gi,
  async (_, before, src, after) => {
    const scriptUrl = new URL(src, entryUrl);
    const source = stripSourceMaps(await readText(scriptUrl)).replace(/<\/script/gi, '<\\/script');
    return `<script${before}${after}>\n${source}\n</script>`;
  },
);

const markup = html.replace(/<textarea\b[\s\S]*?<\/textarea>/gi, '').replace(/<script\b[\s\S]*?<\/script>/gi, '');
const styles = [...html.matchAll(/<style>([\s\S]*?)<\/style>/g)].map(([, css]) => css).join('\n');
const externalReferences = [
  ...[...markup.matchAll(/\b(?:src|href)=["']([^"']+)["']/gi)].map(([, reference]) => reference),
  ...[...styles.matchAll(/url\(\s*([^)]*?)\s*\)/g)].map(([, reference]) => unquote(reference)),
].filter((reference) => !isInlineReference(reference));

if (externalReferences.length > 0) {
  console.error(`error: unresolved external references:\n${externalReferences.map((r) => `  ${r}`).join('\n')}`);
  process.exit(1);
}

if (outputPath === '-') {
  process.stdout.write(html);
} else {
  await writeFile(outputPath, html);
}
console.error(`wrote ${outputPath === '-' ? '<stdout>' : outputPath} (${(Buffer.byteLength(html) / 1024).toFixed(0)} KiB)`);
