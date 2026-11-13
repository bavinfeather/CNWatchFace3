import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.System;

class SolSettingsMenu extends WatchUi.Menu2 {
    var rows as Array;
    var items as Array = [];
    function initialize() {
        Menu2.initialize({:title=>language()==1?"SOL 设置":"SOL settings"});
        rows=SolSettingsData.rows(language());
        for(var i=0;i<rows.size();i++) {
            var item=new WatchUi.MenuItem(title(rows[i]),null,i,null);
            items.add(item);addItem(item);
        }
        refresh(null);
    }
    function isSection(row) { return row[0].length()>=7 && row[0].substring(0,7).equals("Section"); }
    function language() {
        var systemLanguage=System.getDeviceSettings().systemLanguage;
        return systemLanguage==System.LANGUAGE_CHS || systemLanguage==System.LANGUAGE_CHT?1:0;
    }
    function title(row) { return isSection(row)?"—— "+row[1]+" ——":row[1]; }
    function option(choices, index) { return SolSettingsData.option(choices,index); }
    function hiddenText() { return language()==1?"（隐藏）":"(Hidden)"; }
    function currentText() { return language()==1?"当前":"Current"; }
    function refresh(key) {
        for(var i=0;i<rows.size();i++) {
            var row=rows[i];
            if(key!=null && !row[0].equals(key)) { continue; }
            if(isSection(row)) { items[i].setSubLabel(null); continue; }
            var value=Application.Properties.getValue(row[0]);
            var label=value==null?"":value.toString();
            if(row[2]) { label=SolSettingsData.label(row[0],value,language()); }
            items[i].setSubLabel(label.length()==0?hiddenText():label);
        }
    }
}

class SolSettingsDelegate extends WatchUi.Menu2InputDelegate {
    var menu;
    function initialize(m) { Menu2InputDelegate.initialize();menu=m; }
    function onSelect(item) {
        var row=menu.rows[item.getId()];
        if(menu.isSection(row)) { return; }
        if(!row[2]) {
            WatchUi.pushView(new WatchUi.TextPicker(Application.Properties.getValue(row[0])),new SolTextDelegate(menu,row[0]),WatchUi.SLIDE_IMMEDIATE);
            return;
        }
        var choices=SolSettingsData.choices(row[0],menu.language());
        var sub=new WatchUi.Menu2({:title=>menu.title(row)});
        var current=Application.Properties.getValue(row[0]);
        for(var i=0;i<choices.size()/2;i++) {
            sub.addItem(new WatchUi.MenuItem(menu.option(choices,i),choices[i*2]==current?menu.currentText():null,i,null));
        }
        WatchUi.pushView(sub,new SolOptionDelegate(menu,row,choices),WatchUi.SLIDE_IMMEDIATE);
    }
    function onBack() { WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); }
}

class SolOptionDelegate extends WatchUi.Menu2InputDelegate {
    var menu;var row;var choices;
    function initialize(m,r,c) { Menu2InputDelegate.initialize();menu=m;row=r;choices=c; }
    function onSelect(item) {
        Application.Properties.setValue(row[0],choices[(item.getId() as Number)*2]);
        Application.getApp().onSettingsChanged();menu.refresh(row[0]);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
    function onBack() { WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); }
}

class SolTextDelegate extends WatchUi.TextPickerDelegate {
    var menu;var key;
    function initialize(m,k) { TextPickerDelegate.initialize();menu=m;key=k; }
    function onTextEntered(text,changed) {
        if(changed) {
            Application.Properties.setValue(key,text);
            Application.getApp().onSettingsChanged();menu.refresh(key);
        }
        return true;
    }
    function onCancel() { return true; }
}

