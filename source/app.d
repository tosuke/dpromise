import std.stdio;
import std.datetime, core.time;
import eventcore.core;

import dpromise.async;
import dpromise.promise;
import dpromise.utils;

void main() {
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

  runEventloop({
    await(sleepAsync(1.seconds));
    "hoge".writeln;
    await(sleepAsync(1.seconds));
    "piyo".writeln;
  });
}

Promise!void sleepAsync(in Duration dur) @safe nothrow { return promise!void((res, rej) {
  auto tm = eventDriver.timers.create();
  eventDriver.timers.wait(tm, (tm) @safe nothrow {
    eventDriver.timers.releaseRef(tm);
    res();
  });
  eventDriver.timers.set(tm, dur, dur);
});}


