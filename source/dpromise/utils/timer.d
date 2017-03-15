module dpromise.utils.timer;

import core.time : Duration;
import dpromise.promise;
import eventcore.core, eventcore.driver;


Promise!void sleepAsync(in Duration dur) nothrow {
  return promise!void((res, rej) {
    auto tm = eventDriver.timers.create();
    eventDriver.timers.wait(tm, (tm) @trusted nothrow {
      res();
    });
    eventDriver.timers.set(tm, dur, dur);
  });
}
