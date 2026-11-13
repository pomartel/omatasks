const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const model = vm.createContext({ Fr: require("../i18n/Fr.js"),});
vm.runInContext(fs.readFileSync('Model.js', 'utf8').replace(/^\.import.*$/gm, ''), model);

test('named links and bare URLs are underlined with escaped attributes', () => {
    assert.equal(model.linkText('[Site](https://example.com/?a=1&b=2)'), '<a href="https://example.com/?a=1&amp;b=2"><u>Site</u></a>');
    assert.equal(model.linkText('Voir https://example.com.'), 'Voir <a href="https://example.com"><u>https://example.com</u></a>.');
    assert.match(model.linkText('[Article](https://example.com/wiki/Test_(one))'), /href="https:\/\/example.com\/wiki\/Test_\(one\)"/);
});
test('named links retain brackets in their labels', () => {
    const title = 'Le siècle de notre métamorphose [French Edition] eBook';
    const url = 'https://www.amazon.ca/dp/B0HJW46BV9?a=1&b=2';
    const input = `[${title}](${url})`;
    assert.equal(model.linkText(input), `<a href="https://www.amazon.ca/dp/B0HJW46BV9?a=1&amp;b=2"><u>${title}</u></a>`);
    assert.equal(model.firstTaskLink({content: input}), url);
    assert.equal(model.plain(input), title);
    assert.equal(model.linkText('[A [B [C]]](https://example.com)'), '<a href="https://example.com"><u>A [B [C]]</u></a>');
    assert.equal(model.linkText('[<img> [x]](https://example.com)'), '<a href="https://example.com"><u>&lt;img&gt; [x]</u></a>');
    assert.equal(model.linkText('[unfinished [label] https://example.com'), '[unfinished [label] <a href="https://example.com"><u>https://example.com</u></a>');
});
test('task content cannot inject markup or non-web links', () => {
    assert.equal(model.linkText('<img src="file:///secret">'), '&lt;img src=&quot;file:///secret&quot;&gt;');
    assert.equal(model.linkText('[Run](javascript:alert(1))'), '[Run](javascript:alert(1))');
    assert.equal(model.linkText('one\ntwo'), 'one<br>two');
});
test('first task link follows the same rules as displayed links', () => {
    assert.equal(model.firstTaskLink({content: '[Site](https://example.com/wiki/Test_(one)) then https://other.test', description: 'https://description.test'}), 'https://example.com/wiki/Test_(one)');
    assert.equal(model.firstTaskLink({content: 'No link', description: 'See https://example.com/path).'}), 'https://example.com/path');
    assert.equal(model.firstTaskLink({content: '[Run](javascript:alert(1))'}), '');
});
