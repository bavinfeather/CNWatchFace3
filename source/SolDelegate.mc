import Toybox.Lang;
import Toybox.WatchUi;

class SolDelegate extends WatchUi.WatchFaceDelegate {
    var view as SolView;
    function initialize(face as SolView) {
        WatchFaceDelegate.initialize();
        view=face;
    }
    function onPress(clickEvent) as Lang.Boolean {
        var coordinates=clickEvent.getCoordinates();
        if(coordinates==null || coordinates.size()<2) { return false; }
        return view.handleFieldLongPress(coordinates[0],coordinates[1]);
    }
}
