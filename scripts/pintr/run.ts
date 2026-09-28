// Draw a single-line "plotter" illustration from a raw RGBA dump, using the
// PINTR core (https://github.com/javierbyte/pintr, BSD-3-Clause; see LICENSE).
//
// Usage: node --experimental-strip-types scripts/pintr/run.ts IN.rgba W H OUT.svg \
//          [--lines 6000] [--contrast 50] [--definition 50] [--stroke 1.5] [--seed 1] [--color "#e8e8ee"]
//
// IN.rgba is width*height*4 bytes, row-major, unpremultiplied. scripts/pintr.py
// produces it and calls this script for you.
import { readFileSync, writeFileSync } from 'node:fs';

import { createPintr } from './createPintr.ts';
import { preparePintrImage } from './preparePintrImage.ts';

const [, , input, w, h, output, ...rest] = process.argv;
if (!input || !w || !h || !output) {
  console.error('usage: run.ts IN.rgba W H OUT.svg [--lines N] [--contrast N] [--definition N] [--stroke N] [--seed N] [--color C]');
  process.exit(2);
}
const opt = (name: string, fallback: string) => {
  const i = rest.indexOf(`--${name}`);
  return i >= 0 && rest[i + 1] !== undefined ? rest[i + 1] : fallback;
};

const width = Number(w);
const height = Number(h);
const lines = Number(opt('lines', '6000'));
const strokeWidth = Number(opt('stroke', '1.5'));
const color = opt('color', '#e8e8ee');
const rgba = new Uint8Array(readFileSync(input));

const image = preparePintrImage({ width, height, rgba });
const pintr = createPintr({
  image,
  config: {
    contrast: Number(opt('contrast', '50')),
    definition: Number(opt('definition', '50')),
    singleLine: true,
    strokeWidth,
  },
  seed: Number(opt('seed', '1')),
});

const points: string[] = [];
while (pintr.lineCount < lines) {
  const batch = pintr.next(Math.min(1000, lines - pintr.lineCount));
  for (const line of batch.lines) points.push(line[0].join(','));
}

const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${width} ${height}" width="${width}" height="${height}" role="img" aria-label="Line drawing portrait">
<polyline points="${points.join(' ')}" fill="none" stroke="${color}" stroke-width="${strokeWidth}" stroke-linejoin="round" stroke-linecap="round"/>
</svg>
`;
writeFileSync(output, svg);
console.log(`wrote ${output} (${width}x${height}, ${points.length} lines)`);
