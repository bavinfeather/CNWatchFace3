import Toybox.Application;
import Toybox.WatchUi;

class SolApp extends Application.AppBase {
    var view;
    function initialize() { AppBase.initialize(); }
    function getInitialView() { view = new SolView(); return [view,new SolDelegate(view)]; }
    function getSettingsView() {
        var menu = new SolSettingsMenu();
        return [menu, new SolSettingsDelegate(menu)];
    }
    function onSettingsChanged() {
        if (view != null) { view.loadSettings(); }
        WatchUi.requestUpdate();
    }
    function onStop(state) { if (view != null) { view.saveCache(); } }
}
