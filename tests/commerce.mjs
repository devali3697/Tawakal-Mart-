import assert from 'node:assert/strict';import ts from 'typescript';import {readFileSync,mkdirSync,writeFileSync} from 'node:fs';import {pathToFileURL} from 'node:url';import {resolve} from 'node:path';
mkdirSync('.sites-runtime/tests',{recursive:true});for(const f of ['commerce','defaults','csv'])writeFileSync(`.sites-runtime/tests/${f}.mjs`,ts.transpileModule(readFileSync(`lib/${f}.ts`,'utf8'),{compilerOptions:{target:ts.ScriptTarget.ES2022,module:ts.ModuleKind.ESNext}}).outputText);
const {calculate,phone,customer,transition}=await import(pathToFileURL(resolve('.sites-runtime/tests/commerce.mjs')));const {defaults,sampleProducts}=await import(pathToFileURL(resolve('.sites-runtime/tests/defaults.mjs')));const {csv,parseCSV}=await import(pathToFileURL(resolve('.sites-runtime/tests/csv.mjs')));
const data={...structuredClone(defaults),products:structuredClone(sampleProducts)};const id=data.products[0].variants[0].id;let checks=0;function test(name,fn){fn();checks++;console.log('PASS '+name)}
test('Pakistani phone normalization',()=>assert.equal(phone('+92 300 1234567'),'03001234567'));
test('Invalid phone rejected',()=>assert.throws(()=>phone('12345')));
test('Empty cart rejected',()=>assert.throws(()=>calculate(data,[])));
test('Duplicate variants aggregate before stock validation',()=>assert.throws(()=>calculate(data,[{variantId:id,quantity:8},{variantId:id,quantity:8}])));
test('Fractions and negative quantities rejected',()=>{assert.throws(()=>calculate(data,[{variantId:id,quantity:1.5}]));assert.throws(()=>calculate(data,[{variantId:id,quantity:-1}]))});
test('Authoritative variant prices used',()=>assert.equal(calculate(data,[{variantId:id,quantity:1,price:1}]).subtotal,4490));
test('Shipping threshold uses discount-adjusted total',()=>{data.coupons=[{id:'c',code:'TEN',type:'percent',value:10,minimum:0,limit:1,used:0,expires:'',starts:'',categories:[],products:[],active:true}];const q=calculate(data,[{variantId:id,quantity:1}],'TEN');assert.equal(q.discount,449);assert.equal(q.shipping,250);assert.equal(q.total,4291)});
test('Restricted coupon rejects ineligible cart',()=>{data.coupons[0].categories=['bags'];assert.throws(()=>calculate(data,[{variantId:id,quantity:1}],'TEN'));data.coupons[0].categories=[]});
test('Expired, future and exhausted coupons rejected',()=>{const c=data.coupons[0];c.used=1;assert.throws(()=>calculate(data,[{variantId:id,quantity:1}],'TEN'));c.used=0;c.expires='2000-01-01';assert.throws(()=>calculate(data,[{variantId:id,quantity:1}],'TEN'));c.expires='';c.starts='2100-01-01';assert.throws(()=>calculate(data,[{variantId:id,quantity:1}],'TEN'));c.starts=''});
test('Specific city shipping rule takes precedence',()=>{data.shipping.push({id:'city',name:'City',province:'Punjab',city:'Lahore',fee:150,freeAbove:0,estimate:'2 days'});assert.equal(calculate(data,[{variantId:id,quantity:1}],'','Punjab','Lahore').shipping,150)});
test('Live mode rejects sample inventory',()=>{data.settings.mode='live';assert.throws(()=>calculate(data,[{variantId:id,quantity:1}]));data.settings.mode='preview'});
test('Invalid state transitions rejected',()=>{transition('Pending','Confirmed');assert.throws(()=>transition('Pending','Delivered'));assert.throws(()=>transition('Cancelled','Pending'))});
test('CSV quoted commas and line breaks round-trip',()=>{const rows=[{name:'Lovely, linen',description:'Two\nlines "here"'}];assert.deepEqual(parseCSV(csv(rows)),rows)});
test('CSV formula injection neutralized',()=>assert.equal(parseCSV(csv([{name:'=HYPERLINK("bad")'}]))[0].name[0],"'"));
console.log(`${checks} commerce checks passed.`);
