import Toybox.Test;
import Toybox.Time;
import Toybox.Time.Gregorian;

(:test) function fieldUnitsAndPunctuation(logger) {
    var view=new SolView();
    var samples=[["123456步",5,"123456","步"],["12345.6英里",29,"12345.6","英里"],
        ["-123米",7,"-123","米"],["-5度",20,"-5","度"],["99%",8,"99","%"],
        ["72次/分",6,"72","次/分"],["--",6,"--",""],["10/04",15,"10/04",""],
        ["06:12",17,"06:12",""],["10:00 AM",53,"10:00 AM",""],
        ["123 GOLF RD",55,"123 GOLF RD",""],["多云有雨",27,"多云有雨",""]];
    for(var i=0;i<samples.size();i++) {
        var parts=view.fieldValueParts(samples[i][0],samples[i][1]);
        Test.assertEqual(parts[0],samples[i][2]);Test.assertEqual(parts[1],samples[i][3]);
    }
    return true;
}

(:test) function solarMeaningAndRollover(logger) {
    var view=new SolView();var now=Time.now().value();
    view.options["Language"]=1;view.options["SolarDisplay"]=1;
    view.nextSun=[now+3601,false];
    Test.assertEqual(view.solarInfoText(now),"距日落 1小时1分");
    Test.assertEqual(view.fieldLabel(19,now),"下次日落");
    view.nextSun=[now+1,true];
    Test.assertEqual(view.solarInfoText(now),"距日出 1分");
    view.options["Language"]=0;view.nextSun=[now+3601,false];
    Test.assertEqual(view.solarInfoText(now),"SUNSET IN 1H 1M");
    view.options["SolarDisplay"]=0;view.nextSun=[now+172800,true];
    var t=Gregorian.info(new Time.Moment(now+172800),Time.FORMAT_SHORT);
    Test.assertEqual(view.solarInfoText(now),t.month.format("%02d")+"/"+t.day.format("%02d")+" SUNRISE "+t.hour.format("%02d")+":"+t.min.format("%02d"));
    view.nextSun=null;
    Test.assertEqual(view.solarInfoText(now),"SUNRISE/SET --");
    view.options["Language"]=1;
    Test.assertEqual(view.solarInfoText(now),"日出/日落 --");
    return true;
}

(:test) function solarPanelBoundsAndScreenColors(logger) {
    var view=new SolView();
    var widths=[240,260,280,360,390,416,454,466];
    for(var i=0;i<widths.size();i++) {
        view.width=widths[i];view.scale=widths[i]/280.0;
        for(var shift=0;shift<=16;shift+=16) {
            var center=view.p(225+shift);var height=view.p(19);
            var bounds=view.solarPanelBounds(center,height);
            Test.assert(bounds[0]<view.p(100));Test.assert(bounds[1]>view.p(180));
            var radius=widths[i]/2.0;
            for(var side=0;side<2;side++) {
                var dx=bounds[side]-radius;
                var dy=center+height/2.0-radius;
                Test.assert(dx*dx+dy*dy<radius*radius);
            }
        }
    }
    Test.assertEqual(view.displayColor(0x4A6A7A),view.isAmoled()?0x4A6A7A:0x5555AA);
    return true;
}
