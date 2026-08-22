import { access, readFile } from "node:fs/promises";

const requiredFiles = [
  "dist/index.html",
  "dist/privacy/index.html",
  "dist/support/index.html",
  "dist/terms/index.html",
  "dist/accessibility/index.html",
  "dist/testflight/index.html",
  "dist/index.md",
  "dist/llms.txt",
  "dist/api/ai",
  "dist/openapi.json",
  "dist/robots.txt",
  "dist/sitemap.xml"
];

await Promise.all(requiredFiles.map((file) => access(file)));

const home = await readFile("dist/index.html", "utf8");
const requiredHomeCopy = ["Enjoy on", "Life", "Trade", "History", "private", "TestFlight"];
for (const fragment of requiredHomeCopy) {
  if (!home.includes(fragment))
    throw new Error(`Landing page is missing required copy: ${fragment}`);
}

for (const fragment of [
  '<link rel="canonical" href="https://indulge.significanthobbies.com/">',
  'property="og:image"',
  'name="twitter:card" content="summary_large_image"',
  "See TestFlight status"
]) {
  if (!home.includes(fragment))
    throw new Error(`Landing metadata or fallback is missing: ${fragment}`);
}

if (home.includes("testflight.apple.com")) {
  throw new Error("A public TestFlight URL appeared without a verified build-time configuration.");
}

for (const prohibitedClaim of [
  "cure addiction",
  "treat addiction",
  "guaranteed recovery",
  "blocks every app"
]) {
  if (home.toLowerCase().includes(prohibitedClaim))
    throw new Error(`Prohibited product claim found: ${prohibitedClaim}`);
}

if (!home.includes("SoftwareApplication")) {
  throw new Error("Landing is missing SoftwareApplication structured data.");
}

if (!home.includes("look-inside")) {
  throw new Error("Landing is missing the screenshot gallery.");
}

if (home.includes("Download on the App Store") && !home.includes("https://apps.apple.com/")) {
  throw new Error("App Store badge copy appeared without a verified apps.apple.com URL.");
}

const localHrefs = [...home.matchAll(/href="(\/[^"]*)"/g)]
  .map((match) => match[1].split("#")[0])
  .filter((href, index, all) => href && all.indexOf(href) === index);

for (const href of localHrefs) {
  const outputPath =
    href === "/" ? "dist/index.html" : href.endsWith("/") ? `dist${href}index.html` : `dist${href}`;
  await access(outputPath);
}

const ai = JSON.parse(await readFile("dist/api/ai", "utf8"));
if (ai.product?.name !== "Indulge")
  throw new Error("AI product surface does not identify Indulge.");
if (ai.markdown?.negotiation !== true)
  throw new Error("AI product surface must have markdown.negotiation set to true.");
if (!ai.openapi) throw new Error("AI product surface must include an openapi field.");

console.log(
  `Checked ${requiredFiles.length} built public surfaces and ${localHrefs.length} internal links.`
);
