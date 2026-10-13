import Toybox.Test;

(:test) function solarTransitions(logger) {
    var e=[[100,true],[200,false],[300,true]];
    Test.assertEqual(Solar.nextEvent(50,e)[0],100);
    Test.assertEqual(Solar.nextEvent(100,e)[0],200);
    Test.assertEqual(Solar.nextEvent(200,e)[0],300);
    Test.assertEqual(Solar.nextEvent(250,e)[1],true);
    Test.assertEqual(Solar.nextEvent(300,e),null);
    Test.assertEqual(Solar.nextEvent(50,[]),null);
    Test.assertEqual(Solar.nextEvent(50,[[null,true],[40,false]]),null);
    Test.assertEqual(Solar.nextEvent(50,[[300,true],[200,false]])[0],200);
    return true;
}
