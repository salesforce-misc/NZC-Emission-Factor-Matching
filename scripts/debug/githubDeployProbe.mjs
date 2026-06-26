import { existsSync } from 'node:fs';
import { readFile } from 'node:fs/promises';

const runId = process.argv[2] || 'pre-fix';
const deployUrl =
  'https://githubsfdeploy.herokuapp.com/app/githubdeploy/salesforce-misc/NZC-Emission-Factor-Matching?ref=main';

async function sendLog(location, hypothesisId, message, data) {
  await fetch('http://127.0.0.1:7512/ingest/cf52c871-8e14-429c-9383-eaddf956d6ee', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-Debug-Session-Id': 'a6a7e7' },
    body: JSON.stringify({
      sessionId: 'a6a7e7',
      runId,
      hypothesisId,
      location,
      message,
      data,
      timestamp: Date.now(),
    }),
  }).catch(() => {});
}

const rootPackageXmlExists = existsSync('package.xml');
const forceAppPackageXmlExists = existsSync('force-app/main/default/package.xml');
const rootMdapiDirExists = existsSync('mdapi');
const rootSrcDirExists = existsSync('src');
const forceAppDirExists = existsSync('force-app/main/default');

// #region agent log H1
await sendLog('scripts/debug/githubDeployProbe.mjs:30', 'H1', 'Root package.xml presence check', {
  rootPackageXmlExists,
});
// #endregion

// #region agent log H2
await sendLog('scripts/debug/githubDeployProbe.mjs:36', 'H2', 'Root mdapi/src directory presence check', {
  rootMdapiDirExists,
  rootSrcDirExists,
});
// #endregion

// #region agent log H3
await sendLog(
  'scripts/debug/githubDeployProbe.mjs:43',
  'H3',
  'SFDX source-layout directory/package.xml presence check',
  { forceAppDirExists, forceAppPackageXmlExists }
);
// #endregion

let deployPageHtml = '';
let deployPageStatus = -1;
try {
  const response = await fetch(deployUrl);
  deployPageStatus = response.status;
  deployPageHtml = await response.text();
} catch (error) {
  // #region agent log H4
  await sendLog('scripts/debug/githubDeployProbe.mjs:58', 'H4', 'Deploy page fetch failed', {
    error: String(error),
  });
  // #endregion
}

if (deployPageStatus !== -1) {
  const containsPackageXml = deployPageHtml.includes('package.xml');
  const containsApexClass = deployPageHtml.includes('ApexClass');
  const containsLwcBundle = deployPageHtml.includes('LightningComponentBundle');
  const containsTrigger = deployPageHtml.includes('ApexTrigger');
  const containsNzcClass = deployPageHtml.includes('NZC_EmissionsMatchingEngine');

  // #region agent log H4
  await sendLog('scripts/debug/githubDeployProbe.mjs:72', 'H4', 'Deploy page metadata token scan', {
    deployPageStatus,
    containsPackageXml,
    containsApexClass,
    containsLwcBundle,
    containsTrigger,
    containsNzcClass,
  });
  // #endregion

  // #region agent log H5
  await sendLog(
    'scripts/debug/githubDeployProbe.mjs:84',
    'H5',
    'Likely parser expectation mismatch (mdapi root vs SFDX force-app)',
    {
      parserShowsOnlyManifest:
        containsPackageXml && !containsApexClass && !containsLwcBundle && !containsTrigger,
      rootPackageXmlExists,
      forceAppPackageXmlExists,
      rootMdapiDirExists,
      forceAppDirExists,
    }
  );
  // #endregion
}

let defaultPackagePath = '';
let defaultPathHasClasses = false;
let defaultPathHasMainDefault = false;
try {
  const sfdxProject = JSON.parse(await readFile('sfdx-project.json', 'utf8'));
  const defaultPkg = (sfdxProject.packageDirectories || []).find((pkg) => pkg.default === true);
  defaultPackagePath = defaultPkg?.path || '';
  defaultPathHasClasses = !!defaultPackagePath && existsSync(`${defaultPackagePath}/classes`);
  defaultPathHasMainDefault = !!defaultPackagePath && existsSync(`${defaultPackagePath}/main/default`);
} catch {}

// #region agent log H6
await sendLog(
  'scripts/debug/githubDeployProbe.mjs:111',
  'H6',
  'Default SFDX package path compatibility check',
  {
    defaultPackagePath,
    defaultPathHasClasses,
    defaultPathHasMainDefault,
  }
);
// #endregion
