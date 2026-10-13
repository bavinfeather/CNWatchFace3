// Executes production control flow with mocked Garmin APIs. Not a latency benchmark.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const source = fs.readFileSync(process.argv[2] || path.join(__dirname, '../source/SolView.mc'), 'utf8');
function method(name) {
    const start = source.indexOf('function ' + name + '(');
    assert(start >= 0, name);
    const open = source.indexOf('{', start);
    let depth = 1, end = open + 1;
    while (depth && end < source.length) {
        if (source[end] === '{') depth++;
        if (source[end] === '}') depth--;
        end++;
    }
    return source.slice(start, end)
        .replace(/=>/g, ':')
        .replace(/\.size\(\)/g, '.length')
        .replace(/([\w.]+) has :(\w+)/g, '("$2" in $1)')
        .replace(/([\w.]+) instanceof (Number|Float)/g, '(typeof $1 === "number")');
}
const methods = ['onEnterSleep', 'onExitSleep', 'loadSettings', 'onUpdate', 'refresh',
    'refreshSun', 'refreshActivityDistances', 'needsActivity', 'needsBodyBattery',
    'needsStress', 'needsWeather', 'needsSun', 'needsActivityDistances'];
if (source.includes('function updateSunState(')) methods.push('updateSunState');
if (source.includes('function fittedDateFont(')) methods.push('fittedDateFont');
const solarSource = fs.readFileSync(path.join(__dirname, '../source/Solar.mc'), 'utf8');
const solarMethod = solarSource.slice(solarSource.indexOf('function nextEvent'), solarSource.lastIndexOf('}')).replace(/\.size\(\)/g, '.length');
const DAY = 86400;
const start = Date.UTC(2026, 9, 7, 12) / 1000;
function harness(amoled = true, now = start) {
    const calls = [];
    const state = { now, asleep: false, wakeFramePending: false, dataChecked: now - 1,
        activityDistanceChecked: now, sunChecked: now, saved: now, sunDateKey: 20261007,
        cache: { day: 20261007, month: 202610, week: 0, steps: [123, now] },
        options: { UpdateFrequency: 60, SolarDisplay: 2, ProgressMetric: 0,
            Field1: 1, Field2: 2, Field3: 3, Field4: 4 },
        selected: [1, 2, 3, 4], events: [], todayRise: null, todaySet: null,
        nextSun: null, night: false, location: { toDegrees: () => [30, 120] },
        battery: 80, weather: null, profile: null,
        width: 416, isFr255: false, isInstinct3: false, isInstinct3Large: false,
        dateFitText: null, dateFitFont: null, dateFitWidth: -1,
        fonts: Array(7).fill(1), dataCjkFont: null, dataLatinFont: null,
        timeCondensedFont: null, statusLatinFont: null, smallLatinFont: null,
        smallCjkFont: null, customTextLatinFont: null, customTextCjkFont: null,
        customTextIsLatin: true, COLOR_KEYS: [], DEFAULT_COLORS: [], colors: {},
        EN_LABELS: Array(56).fill('FIELD'), Graphics: {}, Math,
        isAmoled: () => amoled, cn: () => false, latin: () => true, p: v => v,
        property: (key, fallback) => fallback, palette: () => {},
        fieldSelected: id => state.selected.includes(id),
        complication: () => { calls.push('complication'); return 50; },
        validNonNegative: v => typeof v === 'number' && v >= 0,
        validPercent: v => typeof v === 'number' && v >= 0 && v <= 100,
        validHeartRate: v => typeof v === 'number' && v > 0,
        latestOptions: () => ({}), value: k => state.cache[k]?.[0] ?? null,
        keep: (k, v, t) => { if (typeof v === 'number') state.cache[k] = [v, t]; },
        keepText: () => {}, estimatedActiveCalories: () => null,
        saveCache: () => calls.push('save'), mergeWeather: () => calls.push('mergeWeather'),
        Complications: {},
        WatchUi: { requestUpdate: () => calls.push('request') },
        System: { DISPLAY_MODE_LOW_POWER: 1, getDisplayMode: () => state.displayMode || 0,
            getClockTime: () => ({ hour: 12, min: 0, sec: 0 }),
            getSystemStats: () => { calls.push('stats'); return { battery: 81 }; },
            getDeviceSettings: () => ({ is24Hour: true }) },
        Gregorian: { info: moment => {
            const d = new Date(moment.value() * 1000);
            return { year: d.getUTCFullYear(), month: d.getUTCMonth() + 1,
                day: d.getUTCDate(), day_of_week: d.getUTCDay() + 1 };
        } },
        ActivityMonitor: { getInfo: () => { calls.push('activity'); return { steps: 456, metersClimbed: 9 }; } },
        Activity: { SPORT_RUNNING: 1, SPORT_CYCLING: 2 },
        UserProfile: { getProfile: () => { calls.push('profile'); return {}; },
            getUserActivityHistory: () => { calls.push('history'); return { next: () => null }; } },
        SensorHistory: {}, Position: { getInfo: () => { calls.push('position'); return { position: state.location }; } },
        Weather: { getCurrentConditions: () => { calls.push('weather'); return {}; },
            getSunrise: () => { calls.push('rise'); return state.sunUnavailable ? null : { value: () => state.now + 100 }; },
            getSunset: () => { calls.push('set'); return state.sunUnavailable ? null : { value: () => state.now + 200 }; } },
        Application: { Storage: { setValue: () => calls.push('storage') } },
        Solar: { nextEvent: () => null },
        drawAod: () => calls.push('aod'), drawSkyRegion: () => calls.push('sky'),
        progressValue: () => 0, drawProgressValue: () => calls.push('progress'),
        dateLine: () => '10/07', timeString: () => '12:00', fitTag: (dc, t) => t,
        drawLandscape: () => calls.push('landscape'), fieldStart: () => 132,
        fieldLabel: () => 'FIELD', fieldText: () => 'VALUE',
        drawFieldValue: () => calls.push('field') };
    Object.defineProperty(state.cache, 'remove', { value: function (key) { delete this[key]; } });
    state.Time = { FORMAT_SHORT: 0, now: () => new state.Time.Moment(state.now),
        today: () => new state.Time.Moment(Math.floor(state.now / DAY) * DAY),
        Moment: function (n) { this.value = () => n; } };
    const context = vm.createContext(state);
    vm.runInContext('Number.prototype.toNumber=function(){return Math.trunc(this);}; String.prototype.equals=function(v){return String(this)===v;}; Array.prototype.add=function(v){this.push(v);}; Object.prototype.remove=function(k){delete this[k];};', context);
    for (const name of methods) vm.runInContext(method(name).replace(/:(face|size):/g, '$1:'), context);
    state.Solar.nextEvent = vm.runInContext('(' + solarMethod + ')', context);
    const dc = { setColor: () => {}, clear: () => calls.push('clear'), setPenWidth: () => {},
        drawArc: () => {}, drawText: () => calls.push('text'), getFontHeight: () => 12,
        getTextWidthInPixels: () => 40 };
    return { state, calls, frame: () => state.onUpdate(dc), wake: () => state.onExitSleep() };
}
function fullFrame(h) {
    assert(h.calls.includes('clear')); assert(h.calls.includes('landscape'));
    assert.equal(h.calls.filter(c => c === 'field').length, 4);
}
// Warm wake: even expired optional history/weather/sun/storage waits one frame.
for (const period of [30, 60, 300]) {
    const h = harness(); h.state.options.UpdateFrequency = period;
    h.state.selected.push(28, 20, 35); h.state.options.SolarDisplay = 0;
    h.state.dataChecked = start - period; h.state.activityDistanceChecked = start - 301;
    h.state.sunChecked = start - 301; h.state.saved = start - 901;
    h.state.onEnterSleep(); assert.equal(h.state.asleep, true);
    h.wake(); assert.equal(h.state.asleep, false);
    h.calls.length = 0; h.frame(); fullFrame(h);
    for (const api of ['stats', 'complication', 'activity', 'profile', 'history', 'weather', 'position', 'rise', 'set', 'save']) assert(!h.calls.includes(api), api);
    assert.equal(h.state.dataChecked, start - period);
    h.calls.length = 0; h.state.now++; h.frame(); fullFrame(h);
    for (const api of ['stats', 'activity', 'profile', 'history', 'weather', 'position', 'rise', 'set', 'save']) assert(h.calls.includes(api), api);
    assert.equal(h.calls.filter(c => c === 'rise').length, 3);
    assert.equal(h.calls.filter(c => c === 'set').length, 3);
    h.calls.length = 0; h.state.now++; h.frame(); fullFrame(h);
    assert(!h.calls.includes('stats')); assert(!h.calls.includes('rise')); assert(!h.calls.includes('history'));
}
// A quick wake preserves an unexpired data interval, then refreshes when due.
{
    const h = harness(); h.wake(); h.frame(); h.calls.length = 0;
    h.state.now++; h.frame(); fullFrame(h); assert(!h.calls.includes('stats'));
    h.state.now = start + 60; h.calls.length = 0; h.frame(); assert(h.calls.includes('stats'));
}
// Cached event selection and day/night still advance on the deferred frame.
{
    const h = harness(); h.state.options.SolarDisplay = 0;
    h.state.events = [[start - 200, true], [start - 100, false], [start + DAY, true]];
    h.state.nextSun = h.state.events[1];
    h.state.todayRise = { value: () => start - 200 };
    h.state.todaySet = { value: () => start - 100 };
    h.state.night = false; h.wake(); h.calls.length = 0; h.frame();
    assert.equal(h.state.nextSun[0], start + DAY); assert.equal(h.state.night, true);
    assert(!h.calls.includes('rise')); fullFrame(h);
}
for (const mode of ['cold', 'settings', 'midnight', 'clock-back', 'mip']) {
    const h = harness(mode !== 'mip'); h.wake();
    if (mode === 'cold') h.state.dataChecked = -1000;
    if (mode === 'settings') h.state.loadSettings();
    if (mode === 'midnight') h.state.cache.day--;
    if (mode === 'clock-back') h.state.dataChecked = start + 5;
    h.calls.length = 0; h.frame(); fullFrame(h); assert(h.calls.includes('stats'), mode);
    assert(h.calls.indexOf('stats') < h.calls.indexOf('clear'));
}
// Repeated low-power frames preserve the pending bright frame and existing AOD battery path.
{
    const h = harness(); h.wake(); h.state.displayMode = 1;
    for (let i = 0; i < 3; i++) { h.calls.length = 0; h.frame();
        assert.deepEqual(h.calls, ['stats', 'aod']); assert.equal(h.state.wakeFramePending, true); }
    assert.equal(h.state.battery, 81);
    h.state.displayMode = 0; h.calls.length = 0; h.frame(); fullFrame(h);
    assert(!h.calls.includes('stats')); assert.equal(h.state.wakeFramePending, false);
}
// A date change overrides unexpired health and sun intervals. Failed sun results clear yesterday.
for (const unavailable of [false, true]) {
    const h = harness(true, Math.floor(start / DAY) * DAY + DAY + 1);
    h.state.dataChecked = h.state.now - 2; h.state.sunChecked = h.state.now - 2;
    h.state.options.SolarDisplay = 0; h.state.sunUnavailable = unavailable;
    h.state.todayRise = { value: () => start }; h.state.todaySet = { value: () => start + 1 };
    h.state.events = [[start, true]];
    h.frame(); assert(h.calls.includes('stats')); assert(h.calls.includes('rise'));
    assert.equal(h.state.cache.day, 20261008); assert.equal(h.state.sunDateKey, 20261008);
    assert.equal(h.state.cache.steps[0], 456);
    if (unavailable) { assert.equal(h.state.todayRise, null); assert.equal(h.state.todaySet, null); assert.equal(h.state.events.length, 0); }
    h.calls.length = 0; h.state.now++; h.frame(); assert(!h.calls.includes('rise'));
}
console.log('PASS: production AMOLED/MIP wake, due and unexpired intervals, next frame, cold start, settings, midnight, clock rollback, AOD, history/weather/sun/save gating and full bright frames.');
