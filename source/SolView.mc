import Toybox.Application;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Math;
import Toybox.Lang;
import Toybox.ActivityMonitor;
import Toybox.Activity;
import Toybox.Complications;
import Toybox.SensorHistory;
import Toybox.Position;
import Toybox.Weather;
import Toybox.UserProfile;

class SolView extends WatchUi.WatchFace {
    var scale = 1.0;
    var width = 280;
    var isFr255 = false;
    var isInstinct3 = false;
    var isInstinct3Large = false;
    var asleep = false;
    var wakeFramePending = false;
    var sharedAod;
    var fonts as Array = [];
    var customTextIsLatin = true;
    var timeCondensedFont;
    var customTextLatinFont;
    var customTextCjkFont;
    var dataLatinFont;
    var smallLatinFont;
    var statusLatinFont;
    var dataCjkFont;
    var smallCjkFont;
    var nativeFieldFont;
    var dateFitText;
    var dateFitFont;
    var dateFitWidth = -1;
    var options as Dictionary = {};
    var colors as Dictionary = {};
    var cache as Dictionary = {};
    var dataChecked = -1000;
    var activityDistanceChecked = -1000;
    var saved = 0;
    var sunChecked = -1000;
    var sunDateKey = -1;
    var events = [];
    var nextSun;
    var location;
    var night = false;
    var todayRise;
    var todaySet;
    var battery = null;
    var weather;
    var weatherSaved = -1000;
    var weatherUpdated = 0;
    var weatherDateKey = -1;
    var profile;
    var progressBatteryIcon;
    var progressBodyBatteryIcon;
    var progressStressIcon;
    const COLOR_KEYS = ["Background","Sky","Sun","TimeColor","SecondsColor","DateColor","LabelColor","ValueColor","CustomColor","ArcColor","ProgressValueColor","EventColor","Dots","Ridge","Foreground","SkyThird"];
    const DEFAULT_COLORS = [0xA63E32,0xA63E32,0xFF5500,0xF5E6D3,0xFF6633,0xFFFFFF,0xFFFFFF,0xF5E6D3,0xFF6633,0xFF5500,0xC7CBCB,0xFF6633,0xC7CBCB,0x4A6A7A,0x243747,0xA63E32];
    // Solid geometric layers in the shared 280px layout.
    const LANDSCAPE_FAR = [[0,247],[43,223],[86,234],[130,211],[176,230],[216,219],[280,241],[280,280],[0,280]];
    const LANDSCAPE_NEAR = [[0,266],[39,249],[91,225],[129,246],[190,205],[229,235],[280,248],[280,280],[0,280]];
    const LANDSCAPE_FACE = [[190,205],[204,244],[244,268],[280,280],[280,248],[229,235]];
    const LANDSCAPE_TREES = [[0,280],[0,268],[28,262],[39,237],[47,257],[57,218],[69,260],[80,242],[88,263],[122,266],[133,242],[140,257],[149,228],[160,263],[178,269],[192,254],[202,274],[280,280]];
    const EN_LABELS = ["","WEEKLY RUN","ELEV. GAIN","BODY BATT","STRESS","STEPS","HEART RATE","ALTITUDE","BATTERY","DISTANCE","FLOORS","ACT. CAL","TOTAL CAL","ACTIVE MIN","SECONDS","DATE","WEEKDAY","SUNRISE","SUNSET","NEXT SUN EVENT","TEMP","HI TEMP","LO TEMP","FEELS LIKE","HUMIDITY","PRECIP %","RECOVERY","WEATHER","RUN DAY","RUN MONTH","RIDE DAY","RIDE WEEK","RIDE MONTH","WEEKLY MIN","STEP GOAL","RESTING HR","PULSE OX","RESPIRATION","RUN VO2 MAX","BIKE VO2 MAX","NOTIFICATIONS","SLEEP SCORE","FLOORS DOWN","BATTERY DAYS","SEA PRESSURE","SOLAR","7-DAY DIST","WEEKLY GOAL","RESTING CAL","TRAINING","WEATHER +1","WEATHER +2","WEATHER +3","CALENDAR","LAST GOLF","LOCATION"];
    const CN_LABELS = ["","本周跑步","今日爬升","身体电量","压力","步数","心率","海拔","电量","今日距离","楼层","活动热量","总热量","活动分钟","秒","日期","星期","日出","日落","下次日出/日落","温度","最高温","最低温","体感温","湿度","降水概率","恢复时间","天气描述","今日跑步","本月跑步","今日骑行","本周骑行","本月骑行","本周活动分钟","步数目标","静息心率","血氧","呼吸频率","跑步最大摄氧量","骑行最大摄氧量","通知","睡眠评分","下楼层数","剩余电量天数","海平面气压","太阳能强度","近7日距离","活动分钟目标","静息热量","训练状态","明天天气","后天天气","三天天气","日历时间","高尔夫成绩","天气地点"];
    const WEATHER_EN = ["CLEAR","P.CLOUD","M.CLOUD","RAIN","SNOW","WINDY","STORMS","MIX","FOG","HAZE","HAIL","SHOWERS","T-STORM","PRECIP","L.RAIN","H.RAIN","L.SNOW","H.SNOW","L.MIX","H.MIX","CLOUDY","W.MIX","M.SUNNY","P.SUNNY","L.SHOWER","SHOWERS","H.SHOWER","SHOWER?","STORM?","MIST","DUST","DRIZZLE","TORNADO","SMOKE","ICE","SAND","HIGH WIND","SANDSTORM","ASH","HAZE","FAIR","HURRICANE","TROP.STM","SNOW?","MIX?","RAIN/CLD","SNOW/CLD","MIX/CLD","FLURRY","FRZ.RAIN","SLEET","ICE PEL.","THIN CLD","UNKNOWN"];
    const WEATHER_CN = ["晴","少云","多云","雨","雪","风","雷暴","雨雪","雾","霾","冰雹","零星阵雨","零星雷暴","未知降水","小雨","大雨","小雪","大雪","小雨雪","大雨雪","阴","雨雪","局部晴","大部晴","小阵雨","阵雨","大阵雨","可能阵雨","可能雷暴","薄雾","沙尘","毛毛雨","龙卷风","烟雾","冰","沙","大风","沙尘暴","火山灰","霾","晴好","飓风","热带风暴","可能下雪","可能雨雪","多云有雨","多云有雪","多云雨雪","小雪","冻雨","雨夹雪","冰雪","薄云","未知"];
    const DOW = ["SUN","MON","TUE","WED","THU","FRI","SAT"];
    const CNDOW = ["周日","周一","周二","周三","周四","周五","周六"];
    const MONTH_DAYS = [31,28,31,30,31,30,31,31,30,31,30,31];
    const LUNAR_YEARS = [
        0x04bd8,0x04ae0,0x0a570,0x054d5,0x0d260,0x0d950,0x16554,0x056a0,0x09ad0,0x055d2,
        0x04ae0,0x0a5b6,0x0a4d0,0x0d250,0x1d255,0x0b540,0x0d6a0,0x0ada2,0x095b0,0x14977,
        0x04970,0x0a4b0,0x0b4b5,0x06a50,0x06d40,0x1ab54,0x02b60,0x09570,0x052f2,0x04970,
        0x06566,0x0d4a0,0x0ea50,0x06e95,0x05ad0,0x02b60,0x186e3,0x092e0,0x1c8d7,0x0c950,
        0x0d4a0,0x1d8a6,0x0b550,0x056a0,0x1a5b4,0x025d0,0x092d0,0x0d2b2,0x0a950,0x0b557,
        0x06ca0,0x0b550,0x15355,0x04da0,0x0a5b0,0x14573,0x052b0,0x0a9a8,0x0e950,0x06aa0,
        0x0aea6,0x0ab50,0x04b60,0x0aae4,0x0a570,0x05260,0x0f263,0x0d950,0x05b57,0x056a0,
        0x096d0,0x04dd5,0x04ad0,0x0a4d0,0x0d4d4,0x0d250,0x0d558,0x0b540,0x0b5a0,0x195a6,
        0x095b0,0x049b0,0x0a974,0x0a4b0,0x0b27a,0x06a50,0x06d40,0x0af46,0x0ab60,0x09570,
        0x04af5,0x04970,0x064b0,0x074a3,0x0ea50,0x06b58,0x05ac0,0x0ab60,0x096d5,0x092e0,
        0x0c960,0x0d954,0x0d4a0,0x0da50,0x07552,0x056a0,0x0abb7,0x025d0,0x092d0,0x0cab5,
        0x0a950,0x0b4a0,0x0baa4,0x0ad50,0x055d9,0x04ba0,0x0a5b0,0x15176,0x052b0,0x0a930,
        0x07954,0x06aa0,0x0ad50,0x05b52,0x04b60,0x0a6e6,0x0a4e0,0x0d260,0x0ea65,0x0d530,
        0x05aa0,0x076a3,0x096d0,0x04afb,0x04ad0,0x0a4d0,0x1d0b6,0x0d250,0x0d520,0x0dd45,
        0x0b5a0,0x056d0,0x055b2,0x049b0,0x0a577,0x0a4b0,0x0aa50,0x1b255,0x06d20,0x0ada0,
        0x14b63,0x09370,0x049f8,0x04970,0x064b0,0x168a6,0x0ea50,0x06aa0,0x1a6c4,0x0aae0,
        0x0a2e0,0x0d2e3,0x0c960,0x0d557,0x0d4a0,0x0da50,0x05d55,0x056a0,0x0a6d0,0x055d4,
        0x052d0,0x0a9b8,0x0a950,0x0b4a0,0x0b6a6,0x0ad50,0x055a0,0x0aba4,0x0a5b0,0x052b0,
        0x0b273,0x06930,0x07337,0x06aa0,0x0ad50,0x14b55,0x04b60,0x0a570,0x054e4,0x0d160,
        0x0e968,0x0d520,0x0daa0,0x06aa6,0x056d0,0x04ae0,0x0a9d4,0x0a2d0,0x0d150,0x0f252,
        0x0d520
    ];
    const SOLAR_TERM_CN = ["小寒","大寒","立春","雨水","惊蛰","春分","清明","谷雨","立夏","小满","芒种","夏至","小暑","大暑","立秋","处暑","白露","秋分","寒露","霜降","立冬","小雪","大雪","冬至"];
    const SOLAR_TERM_EN = ["MinCold","MajCold","Spring","Rain","Insects","SpringEq","Clear","GrainRain","Summer","GrainFull","GrainEar","SummerSol","MinHeat","MajHeat","Autumn","EndHeat","WhiteDew","AutumnEq","ColdDew","Frost","Winter","MinSnow","MajSnow","WinterSol"];
    const SOLAR_TERM_C = [5.4055,20.12,3.87,18.73,5.63,20.646,4.81,20.1,5.52,20.888,5.678,21.37,7.108,22.83,7.5,23.13,7.646,23.042,8.318,23.438,7.438,22.36,7.18,21.94];

    (:amoled) function isAmoled() { return true; }
    (:mip) function isAmoled() { return false; }
    function initialize() {
        WatchFace.initialize();
        try {
            var stored = Application.Storage.getValue("SolCacheV1");
            if (stored instanceof Dictionary) { cache = stored; }
            var loc = Application.Storage.getValue("SolLocationV1");
            if (loc instanceof Array && loc.size() == 2) {
                location = new Position.Location({:latitude=>loc[0], :longitude=>loc[1], :format=>:degrees});
            }
            weather = loadWeatherCache();
        } catch(e) {}
        loadSettings();
    }
    function property(key, fallback) {
        var v = Application.Properties.getValue(key);
        if(fallback instanceof String) { return v instanceof String?v:fallback; }
        if(fallback instanceof Boolean) { return v instanceof Boolean?v:fallback; }
        if(fallback instanceof Number) { return v instanceof Number?v:fallback; }
        return v == null ? fallback : v;
    }
    function loadSettings() {
        dateFitText=null;
        // Older builds could cache total calories under the active-calorie key.
        cache.remove("activeCal");
        options = {"Language"=>property("Language",0),"CustomText"=>property("CustomText","SOL"),"TimeStyle"=>property("TimeStyle",0),"ShowSecondsActive"=>property("ShowSecondsActive",false),"UpdateFrequency"=>property("UpdateFrequency",60),"SolarDisplay"=>property("SolarDisplay",2),"TemperatureUnit"=>property("TemperatureUnit",0),"Units"=>property("Units",0),"ProgressMetric"=>property("ProgressMetric",0),"ShowWeekday"=>property("ShowWeekday",true),"ShowMonthDay"=>property("ShowMonthDay",true),"ShowLunar"=>property("ShowLunar",false),"ShowSolarTerm"=>property("ShowSolarTerm",false)};
        for (var i=1; i<=4; i++) { options["Field"+i] = property("Field"+i,i); }
        for (var j=0; j<COLOR_KEYS.size(); j++) { options[COLOR_KEYS[j]] = property(COLOR_KEYS[j],DEFAULT_COLORS[j]); }
        options["SkyColorCount"]=property("SkyColorCount",1);
        options["SkyBoundary1"]=property("SkyBoundary1",0);
        options["SkyBoundary2"]=property("SkyBoundary2",85);
        customTextIsLatin=latin(options["CustomText"]);
        dataChecked=-1000;activityDistanceChecked=-1000;sunChecked=-1000;
        wakeFramePending=false;
        palette();
    }
    function palette() {
        for(var i=0;i<COLOR_KEYS.size();i++) {
            var key=COLOR_KEYS[i];var v=options[key];
            // Migrate the old follow-theme sentinel to an independent concrete value.
            if(v==-1) { v=DEFAULT_COLORS[i];Application.Properties.setValue(key,v);options[key]=v; }
            colors[key]=displayColor(v);
            // Default orange solar accents need stronger contrast on a MIP sky.
            if(!isAmoled() && (key.equals("Sun") || key.equals("EventColor")) && v==DEFAULT_COLORS[i]) { colors[key]=0xFFFFAA; }
        }
    }
    function mipChannel(channel) {
        if(channel<0x2B) { return 0x00; }
        if(channel<0x80) { return 0x55; }
        if(channel<0xD5) { return 0xAA; }
        return 0xFF;
    }
    function displayColor(color) {
        if(isAmoled()) { return color; }
        // Keep the face's warm gray, warm white, and orange accents legible on RGB222 MIP screens.
        if(color==0xF5E6D3) { return 0xFFFFAA; }
        if(color==0xC7CBCB) { return 0xAAAAAA; }
        if(color==0xFF6633 || color==0xFF5500) { return 0xFF5500; }
        if(color==0x4A6A7A) { return 0x5555AA; }
        var r=mipChannel((color>>16)&0xFF);var g=mipChannel((color>>8)&0xFF);var b=mipChannel(color&0xFF);
        return (r<<16)|(g<<8)|b;
    }
    function p(v) { return (v * scale).toNumber(); }
    function onLayout(dc) {
        dateFitText=null;
        width = dc.getWidth(); scale = width / 280.0;
        var part=System.getDeviceSettings().partNumber;
        isFr255=part.find("006-B3992")==0 || part.find("006-B3990")==0;
        isInstinct3=part.find("006-B4586")==0 || part.find("006-B4587")==0;
        isInstinct3Large=part.find("006-B4587")==0;
        fonts = [WatchUi.loadResource(Rez.Fonts.Time),WatchUi.loadResource(Rez.Fonts.Data),WatchUi.loadResource(Rez.Fonts.Small),WatchUi.loadResource(Rez.Fonts.Aod),WatchUi.loadResource(Rez.Fonts.CjkData),WatchUi.loadResource(Rez.Fonts.CjkSmall),WatchUi.loadResource(Rez.Fonts.Status)];
        // Fixed Chinese labels, dates and units fall back to the bundled atlas.
        // Prefer Garmin's hinted Noto Sans SC when the device publishes it.
        dataCjkFont=fonts[4];
        smallCjkFont=fonts[5];
        try {
            progressBatteryIcon=WatchUi.loadResource(Rez.Drawables.MdiBattery);
            progressBodyBatteryIcon=WatchUi.loadResource(Rez.Drawables.BodyBatteryIcon);
            progressStressIcon=WatchUi.loadResource(Rez.Drawables.MdiBrain);
        } catch(e) {}
        if (Graphics has :getVectorFont) {
            try {
                var nativeCjkData = Graphics.getVectorFont({:face=>"NotoSansSCMedium",:size=>p(isAmoled()?(isInstinct3?18:24):19)});
                if(nativeCjkData!=null) { dataCjkFont=nativeCjkData; }
                var nativeCjkSmall = Graphics.getVectorFont({:face=>"NotoSansSCMedium",:size=>p(isAmoled()?15:14)});
                if(nativeCjkSmall!=null) { smallCjkFont=nativeCjkSmall;nativeFieldFont=nativeCjkSmall; }
            } catch(e) {}
            try {
                var timeFaces=["BionicBold","BionicSemiBold","RobotoCondensedBold","RobotoMonoBold"];
                if(isInstinct3) { timeFaces=["RobotoCondensedBold","BionicBold","BionicSemiBold","RobotoMonoBold"]; }
                timeCondensedFont = Graphics.getVectorFont({:face=>timeFaces,:size=>p(isAmoled()?(isInstinct3?64:78):76)});
            } catch(e) {}
            try {
                customTextLatinFont = Graphics.getVectorFont({:face=>["RobotoCondensedBold"],:size=>p(isAmoled()?28:26)});
            } catch(e) {}
            try {
                customTextCjkFont = Graphics.getVectorFont({:face=>"NotoSansSCMedium",:size=>p(isAmoled()?(isInstinct3?15:18):16)});
            } catch(e) {}
            try { dataLatinFont = Graphics.getVectorFont({:face=>["RobotoCondensedBold"],:size=>p(isInstinct3?18:22)}); } catch(e) {}
            try { smallLatinFont = Graphics.getVectorFont({:face=>["RobotoCondensedBold"],:size=>p(15)}); } catch(e) {}
            try { statusLatinFont = Graphics.getVectorFont({:face=>["RobotoCondensedBold"],:size=>p(18)}); } catch(e) {}
        }
        if(isInstinct3) { dataCjkFont=fonts[4]; }
        // Custom text may contain any Chinese character. Use the device's Unicode
        // system font when scalable CJK fonts are unavailable, instead of the
        // fixed face atlas that only contains the watch face's built-in labels.
        if(customTextCjkFont==null) { customTextCjkFont=Graphics.FONT_SYSTEM_SMALL; }
        if(isFr255) { dataCjkFont=fonts[4];smallCjkFont=fonts[5]; }
    }
    function onEnterSleep() { asleep=true; }
    function onExitSleep() {
        asleep=false;
        if(isAmoled()) { wakeFramePending=true; }
        else { dataChecked=-1000; }
        WatchUi.requestUpdate();
    }
    function saveCache() {
        try { Application.Storage.setValue("SolCacheV1",cache); } catch(e) {}
    }
    function keep(k,v,stamp) {
        if (v instanceof Number || v instanceof Float) { cache[k]=[v,stamp]; }
    }
    function keepText(k,v,stamp) {
        if(v instanceof String && v.length()>0) { cache[k]=[v,stamp]; }
        else { cache.remove(k); }
    }
    function textValue(k,now,age) {
        var record=cache[k];
        if(!(record instanceof Array) || record.size()!=2 || !(record[0] instanceof String) ||
            !(record[1] instanceof Number) || now<record[1] || now-record[1]>age) { return "--"; }
        return record[0];
    }
    function value(k,now,age) {
        var v=cache[k];
        if (!(v instanceof Array) || v.size()!=2 ||
            !(v[0] instanceof Number || v[0] instanceof Float) ||
            !(v[1] instanceof Number || v[1] instanceof Float) ||
            now<v[1] || now-v[1]>age) { return null; }
        return v[0];
    }
    function complication(t) {
        try {
            var item=Complications.getComplication(new Complications.Id(t));
            return item==null?null:item.value;
        } catch(e) { return null; }
    }
    function loadWeatherCache() {
        try {
            var data=Application.Storage.getValue("SolWeatherV1");
            if(data instanceof Dictionary && data["temperature"]!=null) {
                var stored=new SolStoredWeather();
                stored.temperature=data["temperature"];stored.condition=data["condition"];
                stored.highTemperature=data["highTemperature"];stored.lowTemperature=data["lowTemperature"];
                stored.feelsLikeTemperature=data["feelsLikeTemperature"];stored.relativeHumidity=data["relativeHumidity"];
                stored.observationLocationName=data["locationName"];
                stored.precipitationChance=data["precipitationChance"];
                var loc=data["location"];
                if(loc instanceof Array && loc.size()>=2) {
                    stored.observationLocationPosition=new Position.Location({:latitude=>loc[0],:longitude=>loc[1],:format=>:degrees});
                }
                var updated=data["updatedAt"];
                if(updated instanceof Number || updated instanceof Float) { weatherUpdated=updated; }
                var weatherDay=data["dayKey"];
                if(weatherDay instanceof Number) { weatherDateKey=weatherDay; }
                return stored;
            }
        } catch(e) {}
        return null;
    }
    function saveWeatherCache(now) {
        if(weather==null || !(weather has :temperature) || weather.temperature==null) { return; }
        if(now-weatherSaved<900 && now>=weatherSaved) { return; }
        var data={};data["temperature"]=weather.temperature;data["updatedAt"]=weatherUpdated;data["dayKey"]=weatherDateKey;
        if(weather has :condition && weather.condition!=null) { data["condition"]=weather.condition; }
        if(weather has :highTemperature && weather.highTemperature!=null) { data["highTemperature"]=weather.highTemperature; }
        if(weather has :lowTemperature && weather.lowTemperature!=null) { data["lowTemperature"]=weather.lowTemperature; }
        if(weather has :feelsLikeTemperature && weather.feelsLikeTemperature!=null) { data["feelsLikeTemperature"]=weather.feelsLikeTemperature; }
        if(weather has :relativeHumidity && weather.relativeHumidity!=null) { data["relativeHumidity"]=weather.relativeHumidity; }
        if(weather has :precipitationChance && weather.precipitationChance!=null) { data["precipitationChance"]=weather.precipitationChance; }
        if(weather has :observationLocationName && weather.observationLocationName instanceof String) { data["locationName"]=weather.observationLocationName; }
        if(weather has :observationLocationPosition && weather.observationLocationPosition!=null) { data["location"]=weather.observationLocationPosition.toDegrees(); }
        try { Application.Storage.setValue("SolWeatherV1",data);weatherSaved=now; } catch(e) {}
    }
    function mergeWeather(latest,now) {
        if(latest==null) { return; }
        var merged=new SolStoredWeather();
        var date=Gregorian.info(new Time.Moment(now),Time.FORMAT_SHORT);
        var currentDay=date.year*10000+date.month*100+date.day;
        var observedDay=-1;
        if(latest has :observationTime && latest.observationTime!=null) {
            var observed=Gregorian.info(latest.observationTime,Time.FORMAT_SHORT);
            observedDay=observed.year*10000+observed.month*100+observed.day;
        }
        var cachedDay=-1;
        if(weatherUpdated>0) {
            var cached=Gregorian.info(new Time.Moment(weatherUpdated),Time.FORMAT_SHORT);
            cachedDay=cached.year*10000+cached.month*100+cached.day;
        }
        if(weather!=null && weatherUpdated>0 && now>=weatherUpdated && now-weatherUpdated<=21600) {
            if(weather has :temperature) { merged.temperature=weather.temperature; }
            if(weather has :condition) { merged.condition=weather.condition; }
            if(weatherDateKey==currentDay && cachedDay==currentDay && weather has :highTemperature) { merged.highTemperature=weather.highTemperature; }
            if(weatherDateKey==currentDay && cachedDay==currentDay && weather has :lowTemperature) { merged.lowTemperature=weather.lowTemperature; }
            if(weather has :feelsLikeTemperature) { merged.feelsLikeTemperature=weather.feelsLikeTemperature; }
            if(weather has :relativeHumidity) { merged.relativeHumidity=weather.relativeHumidity; }
            if(weather has :observationLocationName) { merged.observationLocationName=weather.observationLocationName; }
            if(weather has :precipitationChance) { merged.precipitationChance=weather.precipitationChance; }
            if(weather has :observationLocationPosition) { merged.observationLocationPosition=weather.observationLocationPosition; }
        }
        if(latest has :temperature && latest.temperature!=null) { merged.temperature=latest.temperature; }
        if(latest has :condition && latest.condition!=null) { merged.condition=latest.condition; }
        if(observedDay==currentDay && latest has :highTemperature && latest.highTemperature!=null) { merged.highTemperature=latest.highTemperature; }
        if(observedDay==currentDay && latest has :lowTemperature && latest.lowTemperature!=null) { merged.lowTemperature=latest.lowTemperature; }
        if(latest has :feelsLikeTemperature && latest.feelsLikeTemperature!=null) { merged.feelsLikeTemperature=latest.feelsLikeTemperature; }
        if(latest has :relativeHumidity && latest.relativeHumidity!=null) { merged.relativeHumidity=latest.relativeHumidity; }
        if(latest has :observationLocationName && latest.observationLocationName instanceof String) { merged.observationLocationName=latest.observationLocationName; }
        if(latest has :precipitationChance && latest.precipitationChance!=null) { merged.precipitationChance=latest.precipitationChance; }
        if(latest has :observationLocationPosition && latest.observationLocationPosition!=null) { merged.observationLocationPosition=latest.observationLocationPosition; }
        if(merged.temperature!=null || merged.observationLocationPosition!=null) {
            weather=merged;weatherDateKey=currentDay;
            if((latest has :temperature && latest.temperature!=null) || (latest has :condition && latest.condition!=null)) {
                weatherUpdated=now;
                if(latest has :observationTime && latest.observationTime!=null) { weatherUpdated=latest.observationTime.value(); }
            }
            saveWeatherCache(now);
        }
    }
    function validPercent(v) {
        return (v instanceof Number || v instanceof Float) && v>=0 && v<=100;
    }
    function validNonNegative(v) {
        return (v instanceof Number || v instanceof Float) && v>=0;
    }
    function validHeartRate(v) {
        return (v instanceof Number || v instanceof Float) && v>0 && v<255;
    }
    function estimateBmr() {
        try {
            if(profile==null || !(profile has :weight) || !(profile has :height) || !(profile has :birthYear) ||
                profile.weight==null || profile.height==null || profile.birthYear==null || profile.weight<=0 || profile.height<=0) { return null; }
            var age=Gregorian.info(Time.now(),Time.FORMAT_SHORT).year-profile.birthYear;
            if(age<10 || age>100) { return null; }
            var bmr=5.2-6.116*age+7.628*profile.height+12.2*(profile.weight/1000.0);
            if((profile has :gender) && profile.gender==UserProfile.GENDER_FEMALE) { bmr-=202.8; }
            return bmr;
        } catch(e) { return null; }
    }
    function estimatedActiveCalories(total) {
        if(!validNonNegative(total)) { return null; }
        var bmr=estimateBmr();
        if(bmr==null || bmr<=0) { return null; }
        var clock=System.getClockTime();
        var active=total-((bmr*(clock.hour*60+clock.min)/1440.0)+0.5).toNumber();
        return active<0?0:active.toNumber();
    }
    function recoveryHours(now) {
        var record=cache["recoveryEnd"];
        if(record instanceof Array && record.size()==2 &&
            (record[0] instanceof Number || record[0] instanceof Float) &&
            (record[1] instanceof Number || record[1] instanceof Float) &&
            now>=record[1] && now-record[1]<=172800) {
            if(record[0]>now) { return (record[0]-now)/3600.0; }
            if(now-record[0]<=3600) { return 0; }
        }
        return value("recovery",now,21600);
    }
    function latestOptions() { return {:period=>1,:order=>SensorHistory.ORDER_NEWEST_FIRST}; }
    function fieldSelected(id) {
        for(var i=1;i<=4;i++) { if(options["Field"+i]==id) { return true; } }
        return false;
    }
    function needsActivity() {
        return fieldSelected(2)||fieldSelected(5)||fieldSelected(9)||fieldSelected(10)||fieldSelected(11)||fieldSelected(12)||fieldSelected(13)||fieldSelected(26)||fieldSelected(33)||fieldSelected(34)||fieldSelected(37)||fieldSelected(42)||fieldSelected(47)||fieldSelected(48);
    }
    function needsBodyBattery() { return options["ProgressMetric"]==1||fieldSelected(3); }
    function needsStress() { return options["ProgressMetric"]==2||fieldSelected(4); }
    function needsWeather() {
        return fieldSelected(20)||fieldSelected(21)||fieldSelected(22)||fieldSelected(23)||fieldSelected(24)||fieldSelected(25)||fieldSelected(27)||fieldSelected(55);
    }
    function needsSun() { return options["SolarDisplay"]!=2||fieldSelected(17)||fieldSelected(18)||fieldSelected(19); }
    function needsActivityDistances() {
        return fieldSelected(28)||fieldSelected(29)||fieldSelected(30)||fieldSelected(32)||fieldSelected(46);
    }
    function refreshActivityDistances(now,date) {
        if(now-activityDistanceChecked<300 && now>=activityDistanceChecked) { return; }
        activityDistanceChecked=now;
        try {
            var runDay=0.0;var runMonth=0.0;var rideDay=0.0;var rideMonth=0.0;var distance7=0.0;
            var iterator=UserProfile.getUserActivityHistory();
            var activity=iterator.next();
            while(activity!=null) {
                if(activity.startTime!=null && activity.startTime.value()<=now && validNonNegative(activity.distance)) {
                    if(activity.startTime.value()>=now-7*86400) { distance7+=activity.distance; }
                    var activityDate=Gregorian.info(activity.startTime,Time.FORMAT_SHORT);
                    if((activity.type==Activity.SPORT_RUNNING || activity.type==Activity.SPORT_CYCLING) && activityDate.year==date.year && activityDate.month==date.month) {
                        if(activity.type==Activity.SPORT_RUNNING) {
                            runMonth+=activity.distance;
                            if(activityDate.day==date.day) { runDay+=activity.distance; }
                        } else {
                            rideMonth+=activity.distance;
                            if(activityDate.day==date.day) { rideDay+=activity.distance; }
                        }
                    }
                }
                activity=iterator.next();
            }
            keep("runDay",runDay,now);keep("runMonth",runMonth,now);
            keep("rideDay",rideDay,now);keep("rideMonth",rideMonth,now);keep("distance7",distance7,now);
        } catch(e) {}
    }
    function refresh(now) {
        var refreshPeriod=options["UpdateFrequency"];
        if(!(refreshPeriod instanceof Number) || refreshPeriod<30) { refreshPeriod=60; }
        var date=Gregorian.info(new Time.Moment(now),Time.FORMAT_SHORT);
        var dayKey=date.year*10000+date.month*100+date.day;
        if(cache["day"]!=dayKey || now-dataChecked>=refreshPeriod || now<dataChecked) {
            dataChecked=now;
            try {
                var stats=System.getSystemStats();if(stats.battery!=null) { battery=stats.battery; }
                if(fieldSelected(43) && stats has :batteryInDays) { keep("batteryDays",stats.batteryInDays,now); }
                if(fieldSelected(45) && stats has :solarIntensity && validNonNegative(stats.solarIntensity)) { keep("solar",stats.solarIntensity,now); }
            } catch(e) {}
            var useBody=needsBodyBattery();var useStress=needsStress();var useRecovery=fieldSelected(26);
            var body=useBody?complication(Complications.COMPLICATION_TYPE_BODY_BATTERY):null;
            var stress=useStress?complication(Complications.COMPLICATION_TYPE_STRESS):null;
            var recoveryMinutes=useRecovery?complication(Complications.COMPLICATION_TYPE_RECOVERY_TIME):null;
            if(fieldSelected(49)) { keepText("trainingStatus",complication(Complications.COMPLICATION_TYPE_TRAINING_STATUS),now); }
            if(fieldSelected(53)) { keepText("calendarTime",complication(Complications.COMPLICATION_TYPE_CALENDAR_EVENTS),now); }
            if(fieldSelected(54)) { keepText("lastGolf",complication(41),now); }
            for(var forecastField=50;forecastField<=52;forecastField++) {
                if(fieldSelected(forecastField)) { cache.remove("forecast"+forecastField);keep("forecast"+forecastField,complication(9+forecastField-50),now); }
            }
            if (cache["day"] != dayKey) {
                cache.remove("climb");cache.remove("steps");cache.remove("distance");cache.remove("floors");
                cache.remove("activeCal");cache.remove("totalCal");cache.remove("restingCal");cache.remove("activeMin");
                cache.remove("stepGoal");cache.remove("floorsDown");cache.remove("runDay");cache.remove("rideDay");cache.remove("distance7");cache["day"]=dayKey;activityDistanceChecked=-1000;
            }
            var monthKey=date.year*100+date.month;
            if(cache["month"]!=monthKey) { cache.remove("runMonth");cache.remove("rideMonth");cache["month"]=monthKey;activityDistanceChecked=-1000; }
            // A Monday change invalidates last week's value before accepting fresh data.
            var weekStart = Time.today().value()-((date.day_of_week+5)%7)*86400;
            if (cache["week"] != weekStart) { cache.remove("run");cache.remove("rideWeek");cache.remove("activeWeek");cache.remove("activeWeekGoal");cache["week"]=weekStart; }
            if(fieldSelected(1)) { keep("run",complication(Complications.COMPLICATION_TYPE_WEEKLY_RUN_DISTANCE),now); }
            if(fieldSelected(31)) { keep("rideWeek",complication(Complications.COMPLICATION_TYPE_WEEKLY_BIKE_DISTANCE),now); }
            if(needsActivityDistances()) { refreshActivityDistances(now,date); }
            if(fieldSelected(11)||fieldSelected(35)||fieldSelected(38)||fieldSelected(39)||fieldSelected(48)) { try { profile=UserProfile.getProfile(); } catch(e) {} }
            var am=null;
            if(needsActivity()||useStress||useRecovery) { try { am=ActivityMonitor.getInfo(); } catch(e) {} }
            if(am!=null) {
                if(needsActivity()) {
                    keep("steps",am.steps,now);if(am has :metersClimbed) { keep("climb",am.metersClimbed,now); }
                    if(am has :distance) { keep("distance",am.distance,now); }
                    if(am has :floorsClimbed) { keep("floors",am.floorsClimbed,now); }
                    if(am has :calories) {
                        keep("totalCal",am.calories,now);
                        var estimatedActive=estimatedActiveCalories(am.calories);
                        if(validNonNegative(estimatedActive)) {
                            keep("activeCal",estimatedActive,now);
                            keep("restingCal",am.calories-estimatedActive,now);
                        } else {
                            cache.remove("activeCal");cache.remove("restingCal");
                        }
                    }
                    if(am has :activeMinutesDay && am.activeMinutesDay!=null && am.activeMinutesDay has :total) { keep("activeMin",am.activeMinutesDay.total,now); }
                    if(am has :activeMinutesWeek && am.activeMinutesWeek!=null && am.activeMinutesWeek has :total) { keep("activeWeek",am.activeMinutesWeek.total,now); }
                    if(am has :activeMinutesWeekGoal) { keep("activeWeekGoal",am.activeMinutesWeekGoal,now); }
                    if(am has :stepGoal) { keep("stepGoal",am.stepGoal,now); }
                    if(am has :floorsDescended) { keep("floorsDown",am.floorsDescended,now); }
                    if(am has :respirationRate) { keep("respiration",am.respirationRate,now); }
                }
                if(useStress && !validPercent(stress) && am has :stressScore) { stress=am.stressScore; }
                if(useRecovery && !validNonNegative(recoveryMinutes) && am has :timeToRecovery) { recoveryMinutes=am.timeToRecovery*60.0; }
            }
            if((fieldSelected(33)||fieldSelected(47)) && value("activeWeek",now,21600)==null) { keep("activeWeek",complication(Complications.COMPLICATION_TYPE_INTENSITY_MINUTES),now); }
            var heart=fieldSelected(6)?complication(Complications.COMPLICATION_TYPE_HEART_RATE):null;
            var altitude=fieldSelected(7)?complication(Complications.COMPLICATION_TYPE_ALTITUDE):null;
            if((fieldSelected(6) && !validHeartRate(heart)) || (fieldSelected(7) && !(altitude instanceof Number || altitude instanceof Float))) { try {
                var ai=Activity.getActivityInfo();
                if(!validHeartRate(heart)) { heart=ai.currentHeartRate; }
                if(!(altitude instanceof Number || altitude instanceof Float)) { altitude=ai.altitude; }
            } catch(e) {} }
            if(validHeartRate(heart)) { keep("hr",heart,now); }
            if(altitude instanceof Number || altitude instanceof Float) { keep("alt",altitude,now); }
            if(fieldSelected(35) && profile!=null) {
                if(profile has :averageRestingHeartRate && validHeartRate(profile.averageRestingHeartRate)) { keep("restingHr",profile.averageRestingHeartRate,now); }
                else if(profile has :restingHeartRate && validHeartRate(profile.restingHeartRate)) { keep("restingHr",profile.restingHeartRate,now); }
            }
            if(fieldSelected(36)) { keep("pulseOx",complication(Complications.COMPLICATION_TYPE_PULSE_OX),now); }
            if(fieldSelected(37) && value("respiration",now,600)==null) { keep("respiration",complication(Complications.COMPLICATION_TYPE_RESPIRATION_RATE),now); }
            if(fieldSelected(38)) { var runVo2=complication(Complications.COMPLICATION_TYPE_VO2MAX_RUN);if(!validNonNegative(runVo2) && profile!=null && profile has :vo2maxRunning) { runVo2=profile.vo2maxRunning; }keep("runVo2",runVo2,now); }
            if(fieldSelected(39)) { var bikeVo2=complication(Complications.COMPLICATION_TYPE_VO2MAX_BIKE);if(!validNonNegative(bikeVo2) && profile!=null && profile has :vo2maxCycling) { bikeVo2=profile.vo2maxCycling; }keep("bikeVo2",bikeVo2,now); }
            if(fieldSelected(40)) { keep("notifications",complication(Complications.COMPLICATION_TYPE_NOTIFICATION_COUNT),now); }
            if(fieldSelected(41)) { keep("sleepScore",complication(42),now); }
            if(fieldSelected(44)) { keep("seaPressure",complication(Complications.COMPLICATION_TYPE_SEA_LEVEL_PRESSURE),now); }
            if(fieldSelected(6) && value("hr",now,300)==null) { try {
                var sample=SensorHistory.getHeartRateHistory(latestOptions()).next();
                if(sample!=null && validHeartRate(sample.data)) { keep("hr",sample.data,sample.when.value()); }
            } catch(e) {} }
            var bodyStamp=now;var stressStamp=now;
            if(useBody && !validPercent(body)) { try {
                if(SensorHistory has :getBodyBatteryHistory) {
                    var bodySample=SensorHistory.getBodyBatteryHistory(latestOptions()).next();
                    if(bodySample!=null) { body=bodySample.data;bodyStamp=bodySample.when.value(); }
                }
            } catch(e) {} }
            if(useStress && !validPercent(stress)) { try {
                if(SensorHistory has :getStressHistory) {
                    var stressSample=SensorHistory.getStressHistory(latestOptions()).next();
                    if(stressSample!=null) { stress=stressSample.data;stressStamp=stressSample.when.value(); }
                }
            } catch(e) {} }
            if(validPercent(body)) { keep("bb",body,bodyStamp); }
            if(validPercent(stress)) { keep("stress",stress,stressStamp); }
            if(validNonNegative(recoveryMinutes)) {
                keep("recovery",recoveryMinutes/60.0,now);
                cache["recoveryEnd"]=[now+recoveryMinutes*60.0,now];
            }
            if(needsWeather()) { try {
                var latestWeather=Weather.getCurrentConditions();
                mergeWeather(latestWeather,now);
            } catch(e) {} }
        }
        if(needsSun()) { refreshSun(now); } else { nextSun=null;night=false; }
        if(now-saved>=900 || now<saved) { saved=now;saveCache(); }
    }
    function refreshSun(now) {
        var currentDate=Gregorian.info(new Time.Moment(now),Time.FORMAT_SHORT);
        var currentSunDay=currentDate.year*10000+currentDate.month*100+currentDate.day;
        if (sunDateKey!=currentSunDay || now-sunChecked>=300 || now<sunChecked) {
            sunChecked=now;
            if(sunDateKey!=currentSunDay) {
                sunDateKey=currentSunDay;events=[];todayRise=null;todaySet=null;nextSun=null;
            }
            var resolvedLocation=location;
            try {
                resolvedLocation=Position.getInfo().position;
                if(resolvedLocation==null && weather!=null && weather has :observationLocationPosition) {
                    resolvedLocation=weather.observationLocationPosition;
                }
            } catch(e) {}
            if(resolvedLocation==null) { try {
                var latestWeather=Weather.getCurrentConditions();
                if(latestWeather!=null && latestWeather has :observationLocationPosition && latestWeather.observationLocationPosition!=null) {
                    resolvedLocation=latestWeather.observationLocationPosition;
                    mergeWeather(latestWeather,now);
                }
            } catch(e) {} }
            if(resolvedLocation!=null) { try {
                var coordinates=resolvedLocation.toDegrees();
                var previous=location==null?null:location.toDegrees();
                if(previous==null || previous[0]!=coordinates[0] || previous[1]!=coordinates[1]) {
                    Application.Storage.setValue("SolLocationV1",coordinates);
                }
                location=resolvedLocation;
            } catch(e) {} }
            if (location!=null) {
                // Local noon avoids carrying the current late-night hour across DST.
                var clock=System.getClockTime();
                var noon=now+(12-clock.hour)*3600-clock.min*60-clock.sec;
                var refreshedEvents=[];var refreshedRise=null;var refreshedSet=null;
                for(var i=0;i<3;i++) {
                    try {
                        var date=new Time.Moment(noon+i*86400);
                        var rise=Weather.getSunrise(location,date);
                        var set=Weather.getSunset(location,date);
                        if(rise!=null) { refreshedEvents.add([rise.value(),true]); }
                        if(set!=null) { refreshedEvents.add([set.value(),false]); }
                        if(i==0) { refreshedRise=rise;refreshedSet=set; }
                    } catch(e) {}
                }
                // Keep the current day's last successful values when a weather call is temporarily unavailable.
                if(refreshedEvents.size()>0) { events=refreshedEvents; }
                if(refreshedRise!=null) { todayRise=refreshedRise; }
                if(refreshedSet!=null) { todaySet=refreshedSet; }
            }
        }
        updateSunState(now);
    }
    function updateSunState(now) {
        nextSun=Solar.nextEvent(now,events);
        night=todayRise!=null && todaySet!=null && (now<todayRise.value() || now>=todaySet.value());
    }
    function cn() { return options["Language"]==1; }
    function latin(s) {
        var chars=s.toCharArray();
        for(var i=0;i<chars.size();i++) { var n=chars[i].toNumber();if(n<32 || n>126) { return false; } }
        return true;
    }
    function drawText(dc,x,y,s,color,small,maxWidth,align) {
        var isLatin=latin(s);
        var f=isLatin?(small?(smallLatinFont!=null?smallLatinFont:fonts[2]):(dataLatinFont!=null?dataLatinFont:fonts[1])):(small?(smallCjkFont!=null?smallCjkFont:fonts[5]):(dataCjkFont!=null?dataCjkFont:fonts[4]));
        // Fit by actual font metrics; truncation respects Unicode characters.
        if(dc.getTextWidthInPixels(s,f)>p(maxWidth)) {
            f=isLatin?(smallLatinFont!=null?smallLatinFont:fonts[2]):(smallCjkFont!=null?smallCjkFont:fonts[5]);
            var chars=s.toCharArray();
            var count=chars.size();
            while(count>0 && dc.getTextWidthInPixels(s,f)>p(maxWidth)) {
                count--;s="";
                for(var i=0;i<count;i++) { s+=chars[i].toString(); }
            }
        }
        dc.setColor(color,Graphics.COLOR_TRANSPARENT);
        dc.drawText(p(x),p(y),f,s,align);
    }
    function fieldStart() { return isFr255?124:(isInstinct3?(isInstinct3Large?132:137):132); }
    function solarPanelBounds(y,height) {
        var radius=width/2.0;
        var top=y-height/2.0;var bottom=y+height/2.0;
        var dy=top<radius?radius-top:top-radius;
        var lower=bottom<radius?radius-bottom:bottom-radius;
        if(lower>dy) { dy=lower; }
        var half=dy>=radius?0:Math.sqrt(radius*radius-dy*dy);
        var left=Math.ceil(radius-half+p(8)).toNumber();
        if(left<p(24)) { left=p(24); }
        return [left,Math.floor(radius+half-p(8)).toNumber()];
    }
    function fieldLabel(id,now) {
        if(id==19 && nextSun!=null) { return cn()?(nextSun[1]?"下次日出":"下次日落"):(nextSun[1]?"NEXT SUNRISE":"NEXT SUNSET"); }
        return (cn()?CN_LABELS:EN_LABELS)[id];
    }
    function fieldValueParts(s,id) {
        // Dates, weather and native text retain their punctuation and wording.
        if(s.equals("--") || (id>=15 && id<=19) || id==27 || id>=49) { return [s,""]; }
        var chars=s.toCharArray();var count=0;
        while(count<chars.size()) {
            var code=chars[count].toNumber();
            if((code>=48 && code<=57) || code==46 || (count==0 && code==45)) { count++; } else { break; }
        }
        if(count==0) { return [s,""]; }
        return [s.substring(0,count),s.substring(count,s.length())];
    }
    function drawFieldValue(dc,y,s,id,bounds) {
        // Keep all values in the original language-specific font, including units.
        var f=(cn() || !latin(s))?(dataCjkFont!=null?dataCjkFont:fonts[4]):(dataLatinFont!=null?dataLatinFont:fonts[1]);
        var fieldOffset=bounds[0]-p(24);
        var valueLeft=p(186)+fieldOffset-3;
        var valueRight=p(272)+fieldOffset;
        var content=fitTag(dc,s,f,valueRight-valueLeft);
        var center=p(y+10);
        dc.setClip(bounds[0],0,valueRight-bounds[0],width);
        dc.setColor(colors["ValueColor"],Graphics.COLOR_TRANSPARENT);
        dc.drawText(valueLeft,center,f,content,Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.clearClip();
    }
    function fitTag(dc,s,f,maxWidth) {
        if(dc.getTextWidthInPixels(s,f)<=maxWidth) { return s; }
        var suffix="...";
        var chars=s.toCharArray();
        for(var count=chars.size()-1;count>=0;count--) {
            var clipped="";
            for(var i=0;i<count;i++) { clipped+=chars[i].toString(); }
            clipped+=suffix;
            if(dc.getTextWidthInPixels(clipped,f)<=maxWidth) { return clipped; }
        }
        return suffix;
    }
    function fieldText(id,now) {
        var keys=["","run","climb","bb","stress","steps","hr","alt","","distance","floors","activeCal","totalCal","activeMin"];
        if(id==8) { return battery==null?"--":battery.toNumber().format("%d")+"%"; }
        var clock=System.getClockTime(); var date=Gregorian.info(Time.now(),Time.FORMAT_SHORT);
        if(id==14) { return clock.sec.format("%02d")+(cn()?"秒":"SEC"); }
        if(id==15) { return date.month.format("%02d")+"/"+date.day.format("%02d"); }
        if(id==16) { return cn()?CNDOW[date.day_of_week-1]:DOW[date.day_of_week-1]; }
        if(id==17) { return sunText(todayRise); }
        if(id==18) { return sunText(todaySet); }
        if(id==19) { return nextSun==null?"--":sunText(new Time.Moment(nextSun[0])); }
        if((id>=20 && id<=25) || id==27) { return weatherText(id); }
        if(id==26) {
            var recovery=recoveryHours(now);
            if(recovery==null) { return "--"; }
            var recoveryText=(recovery<9.9 && recovery!=0)?recovery.format("%.1f"):recovery.format("%.0f");
            return recoveryText+(cn()?"小时":"H");
        }
        if(id>=28 && id<=32) {
            var distanceKey=id==28?"runDay":(id==29?"runMonth":(id==30?"rideDay":(id==31?"rideWeek":"rideMonth")));
            return distanceText(value(distanceKey,now,21600));
        }
        if(id==33) { var weeklyMinutes=value("activeWeek",now,21600);return weeklyMinutes==null?"--":weeklyMinutes.format("%.0f")+(cn()?"分":"MIN"); }
        if(id==34) { var steps=value("steps",now,21600);var stepGoal=value("stepGoal",now,21600);if(steps==null||stepGoal==null||stepGoal<=0) { return "--"; }var stepPct=(steps*100/stepGoal).toNumber();if(stepPct>999) { stepPct=999; }return stepPct.format("%d")+"%"; }
        if(id==35) { var restingHr=value("restingHr",now,21600);return restingHr==null?"--":restingHr.format("%.0f")+(cn()?"次/分":"BPM"); }
        if(id==36) { var pulseOx=value("pulseOx",now,900);return pulseOx==null?"--":pulseOx.format("%.0f")+"%"; }
        if(id==37) { var respiration=value("respiration",now,600);return respiration==null?"--":respiration.format("%.0f")+(cn()?"次/分":"BRPM"); }
        if(id==38 || id==39) { var vo2=value(id==38?"runVo2":"bikeVo2",now,21600);return vo2==null?"--":vo2.format("%.0f"); }
        if(id==40) { var notifications=value("notifications",now,600);return notifications==null?"--":notifications.format("%.0f"); }
        if(id==41) { var sleepScore=value("sleepScore",now,21600);return sleepScore==null?"--":sleepScore.format("%.0f"); }
        if(id==42) { var floorsDown=value("floorsDown",now,21600);return floorsDown==null?"--":floorsDown.format("%.0f")+(cn()?"层":"FLR"); }
        if(id==43) { var batteryDays=value("batteryDays",now,600);return batteryDays==null?"--":batteryDays.format("%.1f")+(cn()?"天":"D"); }
        if(id==44) { var seaPressure=value("seaPressure",now,600);return seaPressure==null?"--":(seaPressure/100.0).format("%.0f")+"hPa"; }
        if(id==45) { var solar=value("solar",now,600);return solar==null?"--":solar.format("%.0f")+"%"; }
        if(id==46) { return distanceText(value("distance7",now,21600)); }
        if(id==47) { var weekMinutes=value("activeWeek",now,21600);var weekGoal=value("activeWeekGoal",now,21600);if(weekMinutes==null||weekGoal==null||weekGoal<=0) { return "--"; }var weekPct=(weekMinutes*100/weekGoal).toNumber();if(weekPct>999) { weekPct=999; }return weekPct.format("%d")+"%"; }
        if(id==48) { var restingCal=value("restingCal",now,21600);return restingCal==null?"--":restingCal.format("%.0f")+(cn()?"千卡":"KCAL"); }
        if(id==49) { return textValue("trainingStatus",now,600); }
        if(id>=50 && id<=52) { return conditionText(value("forecast"+id,now,21600)); }
        if(id==53) { return textValue("calendarTime",now,600); }
        if(id==54) { return textValue("lastGolf",now,21600); }
        if(id==55) {
            if(weather!=null && weatherUpdated>0 && now>=weatherUpdated && now-weatherUpdated<=21600 && weather has :observationLocationName && weather.observationLocationName instanceof String && weather.observationLocationName.length()>0) { return weather.observationLocationName; }
            return "--";
        }
        if(id<1 || id>13) { return ""; }
        var v=value(keys[id],now,id==4?600:(id==6?900:21600));
        if(v==null) { return "--"; }
        var metric=metricUnits();
        if(id==1) { return (v/(metric?1000.0:1609.344)).format("%.1f")+(cn()?(metric?"公里":"英里"):(metric?"KM":"MI")); }
        if(id==9) { return (v/(metric?100000.0:160934.4)).format("%.1f")+(cn()?(metric?"公里":"英里"):(metric?"KM":"MI")); }
        if(id==2 || id==7) { return (v*(metric?1.0:3.28084)).format("%.0f")+(cn()?(metric?"米":"英尺"):(metric?"M":"FT")); }
        if(id==5) { return v.format("%.0f")+(cn()?"步":"STP"); }
        if(id==6) { return v.format("%.0f")+(cn()?"次/分":"BPM"); }
        if(id==10) { return v.format("%.0f")+(cn()?"层":"FLR"); }
        if(id==11 || id==12) { return v.format("%.0f")+(cn()?"千卡":"KCAL"); }
        if(id==13) { return v.format("%.0f")+(cn()?"分":"MIN"); }
        return v.format("%.0f");
    }
    function sunText(moment) {
        if(moment==null) { return "--"; }
        var t=Gregorian.info(moment,Time.FORMAT_SHORT);
        return t.hour.format("%02d")+":"+t.min.format("%02d");
    }
    function conditionText(condition) {
        if(!(condition instanceof Number || condition instanceof Float)) { return "--"; }
        var index=condition.toNumber();
        if(index<0 || index>=WEATHER_EN.size()) { return "--"; }
        return (cn()?WEATHER_CN:WEATHER_EN)[index];
    }
    function weatherText(id) {
        var now=Time.now().value();
        if(weather==null || weatherUpdated<=0 || now<weatherUpdated || now-weatherUpdated>21600) { return "--"; }
        if((id==21 || id==22)) {
            var date=Gregorian.info(Time.now(),Time.FORMAT_SHORT);
            var updated=Gregorian.info(new Time.Moment(weatherUpdated),Time.FORMAT_SHORT);
            var today=date.year*10000+date.month*100+date.day;
            if(weatherDateKey!=today || updated.year*10000+updated.month*100+updated.day!=today) { return "--"; }
        }
        if(id==20 && weather has :temperature && weather.temperature!=null) { return temperatureText(weather.temperature); }
        if(id==21 && weather has :highTemperature && weather.highTemperature!=null) { return temperatureText(weather.highTemperature); }
        if(id==22 && weather has :lowTemperature && weather.lowTemperature!=null) { return temperatureText(weather.lowTemperature); }
        if(id==23 && weather has :feelsLikeTemperature && weather.feelsLikeTemperature!=null) { return temperatureText(weather.feelsLikeTemperature); }
        if(id==24 && weather has :relativeHumidity && weather.relativeHumidity!=null) { return weather.relativeHumidity.format("%.0f")+"%"; }
        if(id==25 && weather has :precipitationChance && weather.precipitationChance!=null) { return weather.precipitationChance.format("%.0f")+"%"; }
        if(id==27 && weather has :condition && weather.condition!=null) {
            var condition=weather.condition.toNumber();
            if(condition>=0 && condition<WEATHER_EN.size()) { return (cn()?WEATHER_CN:WEATHER_EN)[condition]; }
        }
        return "--";
    }
    function temperatureText(value) {
        var temp=value.toFloat();
        if(options["TemperatureUnit"]==1) { temp=temp*9.0/5.0+32.0; }
        if(cn()) { return temp.format("%.0f")+(options["TemperatureUnit"]==1?"华氏":"度"); }
        return temp.format("%.0f")+(options["TemperatureUnit"]==1?"F":"C");
    }
    function metricUnits() {
        var unit=options["Units"];
        if(unit==1) { return true; }
        if(unit==2) { return false; }
        return System.getDeviceSettings().distanceUnits==System.UNIT_METRIC;
    }
    function distanceText(v) {
        if(v==null) { return "--"; }
        var metric=metricUnits();
        return (v/(metric?1000.0:1609.344)).format("%.1f")+(cn()?(metric?"公里":"英里"):(metric?"KM":"MI"));
    }
    function leapYear(year) { return (year%4==0 && year%100!=0) || year%400==0; }
    function lunarYearInfo(year) { return LUNAR_YEARS[year-1900]; }
    function lunarLeapMonth(year) { return lunarYearInfo(year)&0x0f; }
    function lunarLeapDays(year) { return lunarLeapMonth(year)==0?0:((lunarYearInfo(year)&0x10000)!=0?30:29); }
    function lunarMonthDays(year,month) { return (lunarYearInfo(year)&(0x10000>>month))!=0?30:29; }
    function lunarYearDays(year) {
        // Avoid nested leap-day helpers in the calendar drawing path.
        var info=LUNAR_YEARS[year-1900];
        var days=348;
        for(var mask=0x8000;mask>0x8;mask>>=1) { if((info&mask)!=0) { days+=1; } }
        if((info&0x0f)!=0) { days+=(info&0x10000)!=0?30:29; }
        return days;
    }
    function lunarDate(date) {
        var year=date.year;
        if(year<1900 || year>2100 || (year==1900 && date.month==1 && date.day<31)) { return cn()?"--":"L--"; }
        var offset=date.day-31;
        for(var y=1900;y<year;y++) { offset+=leapYear(y)?366:365; }
        for(var m=1;m<date.month;m++) { offset+=MONTH_DAYS[m-1];if(m==2 && leapYear(year)) { offset+=1; } }
        var lunarYear=1900;var yearDays=lunarYearDays(lunarYear);
        while(offset>=yearDays && lunarYear<2100) { offset-=yearDays;lunarYear+=1;yearDays=lunarYearDays(lunarYear); }
        var leap=lunarLeapMonth(lunarYear);var lunarMonth=1;var isLeap=false;var monthDays=lunarMonthDays(lunarYear,lunarMonth);
        while(offset>=monthDays) {
            offset-=monthDays;
            if(leap!=0 && lunarMonth==leap && !isLeap) { isLeap=true;monthDays=lunarLeapDays(lunarYear); }
            else { if(isLeap) { isLeap=false; } lunarMonth+=1;monthDays=lunarMonthDays(lunarYear,lunarMonth); }
        }
        if(!cn()) { return (isLeap?"R":"L")+lunarMonth.format("%02d")+"/"+(offset+1).format("%02d"); }
        var months=["正","二","三","四","五","六","七","八","九","十","冬","腊"];
        var days=["初一","初二","初三","初四","初五","初六","初七","初八","初九","初十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十","廿一","廿二","廿三","廿四","廿五","廿六","廿七","廿八","廿九","三十"];
        return (isLeap?"闰":"")+months[lunarMonth-1]+"月"+days[offset];
    }
    function dayOfYear(month,day,year) {
        var result=day;
        for(var m=1;m<month;m++) { result+=MONTH_DAYS[m-1]; }
        return month>2 && leapYear(year)?result+1:result;
    }
    function solarTermDay(year,index) { var y=year%100;return (y*0.2422+SOLAR_TERM_C[index]).toNumber()-((y-1)/4).toNumber(); }
    function nextSolarTerm(date) {
        var today=dayOfYear(date.month,date.day,date.year);
        for(var i=0;i<24;i++) {
            var month=(i/2).toNumber()+1;var day=solarTermDay(date.year,i);
            var term=dayOfYear(month,day,date.year);
            if(term>=today) { return [term-today,i]; }
        }
        var nextDay=solarTermDay(date.year+1,0);
        return [(leapYear(date.year)?366:365)-today+dayOfYear(1,nextDay,date.year+1),0];
    }
    function solarTermText(date) {
        var term=nextSolarTerm(date);var name=(cn()?SOLAR_TERM_CN:SOLAR_TERM_EN)[term[1]];
        return term[0]==0?name:name+term[0].format("%d")+(cn()?"日":"D");
    }
    function fittedDateFont(dc,text,maxWidth) {
        if(dateFitText!=null && dateFitText.equals(text) && dateFitWidth==maxWidth) { return dateFitFont; }
        var f=cn()?(dataCjkFont!=null?dataCjkFont:fonts[4]):(dataLatinFont!=null?dataLatinFont:fonts[1]);
        var measured=dc.getTextWidthInPixels(text,f);
        if(measured>maxWidth && (Graphics has :getVectorFont)) {
            var normalSize=p(cn()?(isAmoled()?(isInstinct3?18:24):19):(isInstinct3?18:22));
            var size=Math.floor(normalSize*maxWidth/measured).toNumber();
            if(size>=normalSize) { size=normalSize-1; }
            var minimum=p(8);if(minimum<1) { minimum=1; }
            for(;size>=minimum;size--) {
                try {
                    var candidate=Graphics.getVectorFont({:face=>cn()?"NotoSansSCMedium":"RobotoCondensedBold",:size=>size});
                    if(candidate==null) { break; }
                    if(dc.getTextWidthInPixels(text,candidate)<=maxWidth && dc.getFontHeight(candidate)<=dc.getFontHeight(f)) { f=candidate;break; }
                } catch(e) { break; }
            }
        }
        if(dc.getTextWidthInPixels(text,f)>maxWidth) {
            // Non-scalable devices reuse the smaller bundled/system fonts.
            var candidates=cn()?[fonts[5],Graphics.FONT_SYSTEM_XTINY]:[fonts[2],fonts[6],Graphics.FONT_XTINY];
            for(var i=0;i<candidates.size();i++) {
                if(dc.getTextWidthInPixels(text,candidates[i])<dc.getTextWidthInPixels(text,f)) { f=candidates[i]; }
                if(dc.getTextWidthInPixels(text,f)<=maxWidth) { break; }
            }
        }
        dateFitText=text;dateFitFont=f;dateFitWidth=maxWidth;
        return f;
    }
    function dateLine(date) {
        var result="";
        if(options["ShowWeekday"]) { result+=cn()?CNDOW[date.day_of_week-1]:DOW[date.day_of_week-1]+"."; }
        if(options["ShowMonthDay"]) { if(result.length()>0) { result+=" "; } result+=cn()?date.month+"月"+date.day+"日":date.day.format("%02d")+"."+date.month.format("%02d"); }
        if(options["ShowLunar"]) { if(result.length()>0) { result+=" "; } result+=lunarDate(date); }
        if(options["ShowSolarTerm"]) { if(result.length()>0) { result+=" "; } result+=solarTermText(date); }
        return result;
    }
    function timeString(clock) {
        var h=clock.hour;
        if(!System.getDeviceSettings().is24Hour) { h=h%12;if(h==0){h=12;} }
        return h.format("%02d")+":"+clock.min.format("%02d");
    }
    function progressValue(now) {
        if(options["ProgressMetric"]==1) { return value("bb",now,21600); }
        if(options["ProgressMetric"]==2) { return value("stress",now,600); }
        return battery;
    }
    function progressValueText(v) {
        if(v==null) { return "--"; }
        return options["ProgressMetric"]==0?v.format("%.0f")+"%":v.format("%.0f");
    }
    function mipProgressTrackColor() {
        // Choose a MIP gray distinct from both the sky and the selected arc.
        var candidates=[0x000000,0x555555,0xAAAAAA,0xFFFFFF];
        var best=candidates[0];var bestScore=-1;
        for(var i=0;i<candidates.size();i++) {
            var c=candidates[i];var minDistance=200000;
            var reference=[colors["Background"],colors["ArcColor"]];
            for(var j=0;j<reference.size();j++) {
                var r=reference[j];
                var dr=((c>>16)&255)-((r>>16)&255);
                var dg=((c>>8)&255)-((r>>8)&255);
                var db=(c&255)-(r&255);
                var distance=dr*dr+dg*dg+db*db;
                if(distance<minDistance) { minDistance=distance; }
            }
            if(minDistance>bestScore) { bestScore=minDistance;best=c; }
        }
        return best;
    }
    function progressIcon() {
        if(options["ProgressMetric"]==1) { return progressBodyBatteryIcon; }
        if(options["ProgressMetric"]==2) { return progressStressIcon; }
        return progressBatteryIcon;
    }
    function drawProgressIcon(dc,icon,x,y,color) {
        if(icon==null) { return; }
        try {
            var size=p(12);
            if(Graphics has :AffineTransform) {
                var transform=new Graphics.AffineTransform();
                transform.scale(size/24.0,size/24.0);
                dc.drawBitmap2(x-size/2,y-size/2,icon,{:tintColor=>color,:transform=>transform});
            } else { dc.drawBitmap(x-icon.getWidth()/2,y-icon.getHeight()/2,icon); }
        } catch(e) {}
    }
    function drawProgressValue(dc,now) {
        var text=progressValueText(progressValue(now));
        var icon=progressIcon(); var iconSize=p(14); var gap=p(3);
        var progressFont=statusLatinFont!=null?statusLatinFont:fonts[6];
        var textWidth=dc.getTextWidthInPixels(text,progressFont);
        var left=(width-iconSize-gap-textWidth)/2;
        drawProgressIcon(dc,icon,left+iconSize/2,p(29),colors["ProgressValueColor"]);
        dc.setColor(colors["ProgressValueColor"],Graphics.COLOR_TRANSPARENT);
        dc.drawText(left+iconSize+gap,p(23),progressFont,text,Graphics.TEXT_JUSTIFY_LEFT);
    }
    function drawAod(dc,clock,date) {
        if(sharedAod==null) { sharedAod=new SharedAod(); }
        var ds=date.month.format("%02d")+"/"+date.day.format("%02d");
        var simple=SharedAodFields.setting("LowPowerStyle",0)==1;
        var fields=SharedAodFields.collect(simple,[0,5,0],ds,date.day_of_week,battery);
        sharedAod.draw(dc,clock.hour*60+clock.min,timeString(clock),ds,fields);
    }
    function onUpdate(dc) {
        var clock=System.getClockTime();var now=Time.now().value();var date=Gregorian.info(Time.now(),Time.FORMAT_SHORT);
        var low=asleep;
        if (isAmoled() && (System has :getDisplayMode)) { low=low || System.getDisplayMode()==System.DISPLAY_MODE_LOW_POWER; }
        if(isAmoled() && low) { drawAod(dc,clock,date);return; }
        var dayKey=date.year*10000+date.month*100+date.day;
        // Only the first bright frame reuses initialized same-day data. Keep
        // drawing the full frame; due reads run on the next regular callback.
        var deferWakeRefresh=wakeFramePending && dataChecked>=0 && now>=dataChecked && cache["day"]==dayKey;
        wakeFramePending=false;
        if(!deferWakeRefresh) { refresh(now); }
        else if(needsSun()) { updateSunState(now); }
        dc.setColor(colors["Background"],colors["Background"]);dc.clear();
        drawSkyRegion(dc,0,0,width,width);
        var progress=progressValue(now);
        var n=progress==null?0:Math.ceil(progress/20.0).toNumber();
        dc.setColor(colors["ArcColor"],Graphics.COLOR_TRANSPARENT);
        var activePen=p(3);if(activePen<1) { activePen=1; }
        var inactivePen=p(1);if(inactivePen<1) { inactivePen=1; }
        if(!isAmoled()) {
            activePen=p(4);
            dc.setPenWidth(activePen);
            dc.setColor(mipProgressTrackColor(),Graphics.COLOR_TRANSPARENT);
            var trackRadius=p(132)+(p(3)/2).toNumber()-((activePen-1)/2).toNumber();
            for(var track=0;track<5;track++) {
                dc.drawArc(width/2,width/2,trackRadius,Graphics.ARC_CLOCKWISE,128-track*16,116-track*16);
            }
            dc.setColor(colors["ArcColor"],Graphics.COLOR_TRANSPARENT);
        }
        for(var i=0;i<5;i++) {
            var penWidth=i<n?activePen:inactivePen;
            dc.setPenWidth(penWidth);
            if(isAmoled()) {
                var radius=p(132)+Math.ceil((activePen-penWidth)/2.0).toNumber();
                dc.drawArc(width/2,width/2,radius,Graphics.ARC_CLOCKWISE,128-i*16,116-i*16);
            } else {
                // Fill the final segment proportionally over the full track.
                var fill=progress==null?0:progress/20.0-i;
                if(fill<=0) { continue; }
                if(fill>1) { fill=1; }
                // Match the track's radius and width so it cannot show as a
                // second, jagged edge beside the active arc.
                dc.setPenWidth(activePen);
                var outerRadius=p(132)+(p(3)/2).toNumber();
                var radius=outerRadius-((activePen-1)/2).toNumber();
                dc.drawArc(width/2,width/2,radius,Graphics.ARC_CLOCKWISE,128-i*16,128-i*16-12*fill);
            }
        }
        drawProgressValue(dc,now);
        // At this height the circular display ends before the rectangular canvas;
        // keep date text inside the visible chord rather than the full width.
        var dateText=dateLine(date);
        var dateFont=fittedDateFont(dc,dateText,p(200));
        dateText=fitTag(dc,dateText,dateFont,p(200));
        dc.setColor(colors["DateColor"],Graphics.COLOR_TRANSPARENT);
        var dateY=isFr255?40:50;
        dc.drawText(p(40),p(dateY),dateFont,dateText,Graphics.TEXT_JUSTIFY_LEFT);
        var tf=options["TimeStyle"]==0 && timeCondensedFont!=null?timeCondensedFont:fonts[0];
        dc.setColor(colors["TimeColor"],Graphics.COLOR_TRANSPARENT);
        var timeY=isAmoled()?(isInstinct3?69:58):(isFr255?64:60);
        dc.drawText(p(24),p(timeY),tf,timeString(clock),Graphics.TEXT_JUSTIFY_LEFT);
        if(options["ShowSecondsActive"] && !low) {
            var secondsX=p(164);
            dc.setColor(colors["SecondsColor"],Graphics.COLOR_TRANSPARENT);
            dc.drawText(secondsX,p(73),statusLatinFont!=null?statusLatinFont:fonts[6],clock.sec.format("%02d"),Graphics.TEXT_JUSTIFY_LEFT);
        }
        var tag=options["CustomText"];
        var tagFont=customTextIsLatin?(customTextLatinFont!=null?customTextLatinFont:fonts[1]):(customTextCjkFont!=null?customTextCjkFont:fonts[4]);
        // Reserve a separate AM/PM row below the visible time and caption.
        // Vector font line height includes padding below the visible digits.
        var tagY=p(121)-dc.getFontHeight(tagFont);
        if(isInstinct3) { tagY+=p(4); }
        dc.setColor(colors["CustomColor"],Graphics.COLOR_TRANSPARENT);
        dc.drawText(p(isInstinct3?(isInstinct3Large?205:195):((isFr255)?190:164)),tagY,tagFont,tag,Graphics.TEXT_JUSTIFY_LEFT);
        var ampmY=isFr255?111:118;
        if(!System.getDeviceSettings().is24Hour) { drawText(dc,24,ampmY,clock.hour<12?"AM":"PM",colors["DateColor"],true,30,Graphics.TEXT_JUSTIFY_LEFT); }
        // Keep the field block legible when the larger CJK glyphs reach the terrain.
        drawLandscape(dc,now);
        // Fixed columns shared by all four rows.
        var fieldOffset=isAmoled()?0:-3;
        var bounds=[p(24)+fieldOffset,p(252)+fieldOffset];
        var labelLeft=bounds[0]+3;
        var labelRight=p(140)+fieldOffset;
        for(var row=0;row<4;row++) {
            var id=options["Field"+(row+1)];
            if(id>=1 && id<EN_LABELS.size()) {
                var fieldY=fieldStart()+row*22;
                var label=fieldLabel(id,now);
                var labelFont=latin(label)?(dataLatinFont!=null?dataLatinFont:fonts[1]):(dataCjkFont!=null?dataCjkFont:fonts[4]);
                if(dc.getTextWidthInPixels(label,labelFont)>labelRight-labelLeft) { labelFont=latin(label)?(smallLatinFont!=null?smallLatinFont:fonts[2]):(smallCjkFont!=null?smallCjkFont:fonts[5]); }
                label=fitTag(dc,label,labelFont,labelRight-labelLeft);
                dc.setColor(colors["LabelColor"],Graphics.COLOR_TRANSPARENT);
                dc.drawText(labelLeft,p(fieldY+10),labelFont,label,Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
                drawFieldValue(dc,fieldY,fieldText(id,now),id,bounds);
            }
        }
    }
    function polygon(dc,pts,color) {
        for(var i=0;i<pts.size();i++) { pts[i]=[p(pts[i][0]),p(pts[i][1])]; }
        dc.setColor(color,Graphics.COLOR_TRANSPARENT);dc.fillPolygon(pts);
    }
    function landscapeLayer(dc,path,color,compact,shift) {
        var points=[];
        for(var i=0;i<path.size();i++) {
            var y=compact?235+(path[i][1]-202)*0.57:path[i][1];
            points.add([p(path[i][0]),p(y+shift)]);
        }
        dc.setColor(color,Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(points);
    }
    function drawSkyRegion(dc,x,y,w,h) {
        var count=options["SkyColorCount"];
        if(count<1 || count>3) { count=1; }
        var first=options["SkyBoundary1"];
        var second=options["SkyBoundary2"];
        var firstY=first==0?p(202+(isInstinct3?16:0)):(width*(first<1?1:(first>99?99:first))/100).toNumber();
        var secondY=(width*(second<1?1:(second>99?99:second))/100).toNumber();
        if(count==3 && secondY<firstY) { var swap=firstY;firstY=secondY;secondY=swap; }
        var edges=[0,count==1?width:firstY,count<3?width:secondY,width];
        var keys=["Background","Sky","SkyThird"];
        for(var i=0;i<count;i++) {
            var top=y>edges[i]?y:edges[i];var bottom=y+h<edges[i+1]?y+h:edges[i+1];
            if(bottom>top) {
                dc.setColor(colors[keys[i]],Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(x,top,w,bottom-top);
            }
        }
    }
    function solarInfoText(now) {
        if(nextSun==null) { return cn()?"日出/日落 --":"SUNRISE/SET --"; }
        var label=cn()?(nextSun[1]?"日出":"日落"):(nextSun[1]?"SUNRISE":"SUNSET");
        if(options["SolarDisplay"]==1) {
            var mins=Math.ceil((nextSun[0]-now)/60.0).toNumber();
            if(mins<0) { mins=0; }
            var hours=(mins/60).toNumber();
            var duration=cn()?(hours>0?hours+"小时":"")+(mins%60)+"分":(hours>0?hours+"H ":"")+(mins%60)+"M";
            return cn()?"距"+label+" "+duration:label+" IN "+duration;
        }
        var t=Gregorian.info(new Time.Moment(nextSun[0]),Time.FORMAT_SHORT);
        var today=Gregorian.info(new Time.Moment(now),Time.FORMAT_SHORT);
        if(t.year!=today.year || t.month!=today.month || t.day!=today.day) { label=t.month.format("%02d")+"/"+t.day.format("%02d")+" "+label; }
        return label+" "+t.hour.format("%02d")+":"+t.min.format("%02d");
    }
    function drawLandscape(dc,now) {
        var shift=isInstinct3?16:0;
        var compact=options["SolarDisplay"]!=2;
        landscapeLayer(dc,LANDSCAPE_FAR,colors["Dots"],compact,shift);
        landscapeLayer(dc,LANDSCAPE_NEAR,colors["Ridge"],compact,shift);
        landscapeLayer(dc,LANDSCAPE_FACE,colors["Foreground"],compact,shift);
        landscapeLayer(dc,LANDSCAPE_TREES,colors["Foreground"],compact,shift);
        if(!compact) { return; }
        var text=solarInfoText(now);
        var f=latin(text)?(smallLatinFont!=null?smallLatinFont:fonts[2]):(smallCjkFont!=null?smallCjkFont:fonts[5]);
        var center=p(225+shift);var height=dc.getFontHeight(f);
        var bounds=solarPanelBounds(center,height);
        var iconWidth=nextSun!=null?p(25):0;
        text=fitTag(dc,text,f,bounds[1]-bounds[0]-iconWidth);
        var tw=dc.getTextWidthInPixels(text,f);
        var sx=(width-tw-iconWidth)/2;
        drawSkyRegion(dc,sx-p(4),center-height/2,tw+iconWidth+p(8),height);
        if(nextSun!=null) {
            var rise=nextSun[1];
            var ix=sx+p(9); var iy=p(225+shift);
            dc.setColor(colors["Sun"],Graphics.COLOR_TRANSPARENT);dc.setPenWidth((p(1)<1?1:p(1)));
            dc.drawArc(ix,iy,p(5),Graphics.ARC_COUNTER_CLOCKWISE,0,180);
            dc.drawLine(ix-p(8),iy,ix+p(8),iy);
            dc.drawLine(ix,iy-p(9),ix,iy-p(7));
            dc.drawLine(ix-p(7),iy-p(6),ix-p(5),iy-p(4));
            dc.drawLine(ix+p(7),iy-p(6),ix+p(5),iy-p(4));
            var ay=iy+p(4);
            dc.drawLine(ix,ay-p(2),ix,ay+p(2));
            var tip=rise?ay-p(2):ay+p(2);var tail=rise?ay:ay;
            dc.drawLine(ix,tip,ix-p(2),tail);dc.drawLine(ix,tip,ix+p(2),tail);
        }
        dc.setColor(colors["EventColor"],Graphics.COLOR_TRANSPARENT);
        dc.drawText(sx+iconWidth,center,f,text,Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
    }
    function complicationTypeForField(id) {
        if(id==1) { return Complications.COMPLICATION_TYPE_WEEKLY_RUN_DISTANCE; }
        if(id==3) { return Complications.COMPLICATION_TYPE_BODY_BATTERY; }
        if(id==4) { return Complications.COMPLICATION_TYPE_STRESS; }
        if(id==5) { return Complications.COMPLICATION_TYPE_STEPS; }
        if(id==6) { return Complications.COMPLICATION_TYPE_HEART_RATE; }
        if(id==7) { return Complications.COMPLICATION_TYPE_ALTITUDE; }
        if(id==8) { return Complications.COMPLICATION_TYPE_BATTERY; }
        if(id==10) { return Complications.COMPLICATION_TYPE_FLOORS_CLIMBED; }
        if(id==12) { return Complications.COMPLICATION_TYPE_CALORIES; }
        if(id==13) { return Complications.COMPLICATION_TYPE_INTENSITY_MINUTES; }
        if(id==17) { return Complications.COMPLICATION_TYPE_SUNRISE; }
        if(id==18) { return Complications.COMPLICATION_TYPE_SUNSET; }
        if(id==21 || id==22) { return Complications.COMPLICATION_TYPE_HIGH_LOW_TEMPERATURE; }
        if(id==23 || id==24 || id==25 || id==27) { return Complications.COMPLICATION_TYPE_CURRENT_WEATHER; }
        if(id==26) { return Complications.COMPLICATION_TYPE_RECOVERY_TIME; }
        if(id==31) { return Complications.COMPLICATION_TYPE_WEEKLY_BIKE_DISTANCE; }
        if(id==33 || id==47) { return Complications.COMPLICATION_TYPE_INTENSITY_MINUTES; }
        if(id==34) { return Complications.COMPLICATION_TYPE_STEPS; }
        if(id==35) { return Complications.COMPLICATION_TYPE_HEART_RATE; }
        if(id==36) { return Complications.COMPLICATION_TYPE_PULSE_OX; }
        if(id==37) { return Complications.COMPLICATION_TYPE_RESPIRATION_RATE; }
        if(id==38) { return Complications.COMPLICATION_TYPE_VO2MAX_RUN; }
        if(id==39) { return Complications.COMPLICATION_TYPE_VO2MAX_BIKE; }
        if(id==40) { return Complications.COMPLICATION_TYPE_NOTIFICATION_COUNT; }
        if(id==41) { return 42; }
        if(id==42) { return Complications.COMPLICATION_TYPE_FLOORS_CLIMBED; }
        if(id==43) { return Complications.COMPLICATION_TYPE_BATTERY; }
        if(id==44) { return Complications.COMPLICATION_TYPE_SEA_LEVEL_PRESSURE; }
        if(id==45) { return Complications.COMPLICATION_TYPE_SOLAR_INPUT; }
        if(id==49) { return Complications.COMPLICATION_TYPE_TRAINING_STATUS; }
        if(id>=50 && id<=52) { return 9+id-50; }
        if(id==53) { return Complications.COMPLICATION_TYPE_CALENDAR_EVENTS; }
        if(id==54) { return 41; }
        if(id==55) { return Complications.COMPLICATION_TYPE_CURRENT_WEATHER; }
        return null;
    }
    function handleFieldLongPress(px,py) {
        var firstRow=fieldStart()-1;
        if(asleep || py<p(firstRow) || py>=p(firstRow+88)) { return false; }
        var row=-1;
        for(var i=0;i<4;i++) {
            if(py>=p(firstRow+i*22) && py<p(firstRow+(i+1)*22)) { row=i;break; }
        }
        if(row<0) { return false; }
        var field=options["Field"+(row+1)];
        var complicationType=complicationTypeForField(field);
        if(complicationType==null || !(Complications has :exitTo)) { return false; }
        try {
            var id=new Complications.Id(complicationType);
            if(Complications.getComplication(id)==null) { return false; }
            Complications.exitTo(id);
            return true;
        } catch(e) { return false; }
    }
}

// Storage cannot retain a Weather.Conditions object directly, so keep only
// the scalar values used by this face and rebuild a compatible object at boot.
class SolStoredWeather {
    var temperature;
    var condition;
    var highTemperature;
    var lowTemperature;
    var feelsLikeTemperature;
    var relativeHumidity;
    var precipitationChance;
    var observationLocationPosition;
    var observationLocationName;
}
