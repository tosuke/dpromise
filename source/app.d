import std.stdio;
import std.datetime, core.time;
import eventcore.core;

import dpromise.promise;

void main() {
  sleepAsync(1.seconds).then({
    "hoge".writeln;
    eventDriver.core.exit;
  });

  promise!int((res, rej) {
    res(10);
  }).then((a){
    a.writeln;
  });

  promise!string((res, rej) {
    rej(new Exception("hoge"));
  }).fail((e){
    return e.msg;
  }).then((a){
    a.writeln;
  });

  //eventDriver.core.exit;
  ExitReason er;
  do {
    er = eventDriver.core.processEvents(Duration.max);
  }while(er == ExitReason.idle);
}

Promise!void sleepAsync(in Duration dur) @safe nothrow { return promise!void((res, rej) {
  auto tm = eventDriver.timers.create();
  eventDriver.timers.wait(tm, (tm) @safe nothrow {
    eventDriver.timers.releaseRef(tm);
    res();
  });
  eventDriver.timers.set(tm, dur, dur);
});}

