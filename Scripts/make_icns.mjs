import { readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const root = process.cwd();
const iconset = join(root, "Resources", "AppIcon.iconset");
const output = join(root, "Resources", "NextMeeting.icns");

const entries = [
  ["icp4", "icon_16x16.png"],
  ["icp5", "icon_32x32.png"],
  ["icp6", "icon_32x32@2x.png"],
  ["ic07", "icon_128x128.png"],
  ["ic08", "icon_256x256.png"],
  ["ic09", "icon_512x512.png"],
  ["ic10", "icon_512x512@2x.png"],
];

function chunk(type, payload) {
  const header = Buffer.alloc(8);
  header.write(type, 0, 4, "ascii");
  header.writeUInt32BE(payload.length + 8, 4);
  return Buffer.concat([header, payload]);
}

const chunks = entries.map(([type, file]) => chunk(type, readFileSync(join(iconset, file))));
const totalLength = chunks.reduce((sum, item) => sum + item.length, 8);
const header = Buffer.alloc(8);
header.write("icns", 0, 4, "ascii");
header.writeUInt32BE(totalLength, 4);

writeFileSync(output, Buffer.concat([header, ...chunks], totalLength));
