const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
test('French task entry keeps native input-method handling', () => {
 const composer = fs.readFileSync('ui/Composer.qml', 'utf8');
 assert.match(composer, /C\.TextArea\s*\{/);
 assert.match(composer, /input\.inputMethodComposing/);
 assert.doesNotMatch(composer, /KeyField\s*\{/);
 for (const file of ['ui/Settings.qml', 'ui/Setup.qml', 'ui/TaskMenu.qml']) {
   const source = fs.readFileSync(file, 'utf8');
   assert.match(source, /UI\.TextField\s*\{/);
   assert.doesNotMatch(source, /KeyField\s*\{/);
 }
});
