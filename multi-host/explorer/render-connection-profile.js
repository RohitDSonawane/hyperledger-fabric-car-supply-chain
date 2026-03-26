const fs = require('fs');

const templatePath = '/opt/explorer/app/platform/fabric/connection-profile/test-network.json';
const outputDir = '/opt/explorer/runtime-connection-profile';
const outputPath = `${outputDir}/test-network.json`;

const required = [
    'EXPLORER_ADMIN_ID',
    'EXPLORER_ADMIN_PASSWORD'
];

for (const key of required) {
    if (!process.env[key] || process.env[key].trim() === '') {
        console.error(`[render-connection-profile] Missing required env var: ${key}`);
        process.exit(1);
    }
}

if (!fs.existsSync(templatePath)) {
    console.error(`[render-connection-profile] Template not found: ${templatePath}`);
    process.exit(1);
}

const template = fs.readFileSync(templatePath, 'utf8');
const rendered = template
    .replace(/\$\{EXPLORER_ADMIN_ID\}/g, process.env.EXPLORER_ADMIN_ID)
    .replace(/\$\{EXPLORER_ADMIN_PASSWORD\}/g, process.env.EXPLORER_ADMIN_PASSWORD);

fs.mkdirSync(outputDir, { recursive: true });
fs.writeFileSync(outputPath, rendered, 'utf8');

console.log(`[render-connection-profile] Wrote runtime profile: ${outputPath}`);
