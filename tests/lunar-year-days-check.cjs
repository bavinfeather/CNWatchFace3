const fs = require('node:fs');
const assert = require('node:assert/strict');
const source = fs.readFileSync(`${__dirname}/../source/SolView.mc`, 'utf8');
const table = new Function(`return ${source.match(/LUNAR_YEARS[^=]*=\s*(\[[\s\S]*?\]);/)[1]};`)();
const body = source.split('function lunarYearDays(')[1].split('function lunarDate(')[0];
const code = body.slice(body.indexOf('{') + 1, body.lastIndexOf('}'));
const yearDays = new Function('LUNAR_YEARS', 'year', code);
assert.equal(table.length, 201);
for (let year = 1900; year <= 2100; year++) {
    const info = table[year - 1900];
    let expected = 0;
    for (let month = 1; month <= 12; month++) expected += (info & (0x10000 >> month)) ? 30 : 29;
    if ((info & 15) !== 0) expected += (info & 0x10000) ? 30 : 29;
    assert.equal(yearDays(table, year), expected, `lunar year ${year}`);
}
console.log('PASS: lunar year lengths preserved for all 201 supported years');
