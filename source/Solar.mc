import Toybox.Time;

// Select only future events. Independent of timezone and event ordering.
module Solar {
    function nextEvent(now, events) {
        var best = null;
        for (var i = 0; i < events.size(); i++) {
            var e = events[i];
            if (e[0] != null && e[0] > now && (best == null || e[0] < best[0])) { best = e; }
        }
        return best;
    }
}
