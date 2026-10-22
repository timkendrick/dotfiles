// Computes the relative path from one file or directory to another.

import path from 'node:path';

const [from, to] = process.argv.slice(2);

console.log(path.relative(from, to));
