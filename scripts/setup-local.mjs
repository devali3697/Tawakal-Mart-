import {readFileSync,writeFileSync,mkdirSync,existsSync,readdirSync} from 'node:fs';
import {resolve} from 'node:path';import {spawnSync} from 'node:child_process';
function run(args){const r=spawnSync(process.execPath,args,{stdio:'inherit',env:{...process.env,CI:'1'}});if(r.status!==0)process.exit(r.status||1)}
if(!existsSync('dist/server/wrangler.json'))run(['scripts/run-framework.mjs','build']);
mkdirSync('.sites-runtime',{recursive:true});const cfg=JSON.parse(readFileSync('dist/server/wrangler.json','utf8'));const dbConfig={name:'tawakal-local-db',compatibility_date:'2026-05-15',d1_databases:cfg.d1_databases.map(d=>({...d,migrations_dir:resolve('drizzle')}))};writeFileSync('.sites-runtime/db-config.json',JSON.stringify(dbConfig,null,2));
run(['--import','./scripts/sites-env.mjs','node_modules/wrangler/bin/wrangler.js','d1','migrations','apply','DB','--local','--config','.sites-runtime/db-config.json','--persist-to','.wrangler/state']);
if(process.argv.includes('--sample')){run(['scripts/seed-local.mjs']);}
console.log('Local database ready. Run npm run dev. No site has been published.');
