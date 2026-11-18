const assert = require('node:assert/strict');
const {chromium} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const path = require('node:path');
const output = path.join(__dirname, '../docs/screenshots');
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.CHROME_PATH || (process.platform === 'darwin' ? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' : undefined),headless:true});
 try {
 const page=await browser.newPage({viewport:{width:1440,height:1450},deviceScaleFactor:1});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 async function enable(){await page.waitForTimeout(2000);const p=page.locator('flt-semantics-placeholder');if(await p.count())await p.evaluate(el=>el.click());await page.waitForTimeout(1000);}
 await page.goto(process.env.APP_URL || 'http://127.0.0.1:8387');await enable();
 await page.getByRole('button',{name:'Carregar 3 exemplos fictícios'}).click();
 await page.waitForTimeout(500);
 await page.screenshot({path:path.join(output,'desktop.png')});
 await page.reload();await enable();
 assert.equal(await page.getByRole('button',{name:/Chaves com chaveiro azul/}).count(),1);
 let data=await page.evaluate(()=>JSON.parse(localStorage.getItem('flutter.reencontra.v1')));assert.equal(JSON.parse(data).length,3);
 await page.getByRole('button',{name:'Registrar objeto',exact:true}).click();
 await page.getByRole('textbox',{name:'Nome do objeto'}).click();await page.waitForTimeout(250);await page.getByRole('textbox',{name:'Nome do objeto'}).pressSequentially('Guarda-chuva amarelo',{delay:40});
 await page.getByRole('textbox',{name:'Descrição pública'}).click();await page.waitForTimeout(250);await page.getByRole('textbox',{name:'Descrição pública'}).pressSequentially('Um exemplo fictício encontrado na biblioteca',{delay:40});
 await page.getByRole('textbox',{name:'Bairro ou espaço público'}).click();await page.waitForTimeout(250);await page.getByRole('textbox',{name:'Bairro ou espaço público'}).pressSequentially('Centro',{delay:40});
 const chooser=page.waitForEvent('filechooser');
 await page.getByRole('button',{name:'Escolher foto'}).click();
 await (await chooser).setFiles({name:'synthetic.png',mimeType:'image/png',buffer:Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAIAAAD/gAIDAAAAtUlEQVR4nO3QQQkAIADAQCOb0UJWsIIfGcLBAowbe01dNvKDj4IFC1YeLFiw8mDBgpUHCxasPFiwYOXBggUrDxYsWHmwYMHKgwULVh4sWLDyYMGClQcLFqw8WLBg5cGCBSsPFixYebBgwcqDBQtWHixYsPJgwYKVBwsWrDxYsGDlwYIFKw8WLFh5sGDByoMFC1YeLFiw8mDBgpUHCxasPFiwYOXBggUrDxYsWHmwYMHKgwXrTQdk5i3uXwA+aQAAAABJRU5ErkJggg==','base64')});
 await page.getByRole('button',{name:'Remover foto'}).waitFor();
 await page.getByRole('button',{name:'Salvar neste navegador'}).click();await page.waitForTimeout(1500);
 await page.reload();await enable();
 data=JSON.parse(await page.evaluate(()=>JSON.parse(localStorage.getItem('flutter.reencontra.v1'))));
 assert.equal(data.length,4);assert.ok(data[0].photo);
 const search=page.getByRole('textbox',{name:'Buscar objeto ou região'});
 await search.click();await page.waitForTimeout(250);await search.pressSequentially('GUARDA',{delay:40});await page.waitForTimeout(300);
 assert.equal(await page.getByRole('button',{name:/Guarda-chuva amarelo/}).count(),1);
 await page.getByRole('button',{name:/Guarda-chuva amarelo/}).click();
 await page.getByRole('button',{name:'Simular resolução'}).click();
 await page.getByRole('textbox',{name:'Nota da simulação'}).click();await page.waitForTimeout(250);await page.getByRole('textbox',{name:'Nota da simulação'}).pressSequentially('Simulação validada na biblioteca',{delay:40});
 await page.getByRole('checkbox').click();await page.waitForTimeout(500);assert.equal(await page.getByRole('checkbox').getAttribute('aria-checked'),'true');
 await page.getByRole('button',{name:'Concluir simulação'}).click();await page.waitForTimeout(300);
 data=JSON.parse(await page.evaluate(()=>JSON.parse(localStorage.getItem('flutter.reencontra.v1'))));
 assert.equal(data[0].status,'resolved');assert.equal(data[0].kind,'found');
 await page.reload();await enable();
 data=JSON.parse(await page.evaluate(()=>JSON.parse(localStorage.getItem('flutter.reencontra.v1'))));assert.equal(data[0].status,'resolved');
 await page.setViewportSize({width:390,height:844});await page.waitForTimeout(500);
 await page.screenshot({path:path.join(output,'mobile.png')});
 await page.mouse.move(190,700);await page.mouse.wheel(0,900);await page.waitForTimeout(500);
 await page.screenshot({path:path.join(output,'mobile-listings.png')});
 assert.deepEqual(errors,[]);console.log('Browser checks passed: opt-in fixtures, reload, create with photo, photo persistence, accent/case search, simulated resolution, resolved state reload; no page errors.');
 } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
