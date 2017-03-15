module dpromise.utils;

import dpromise.promise, dpromise.async;
import eventcore.core;
import std.datetime, core.time;

ExitReason runEventloop(in Duration timeout = Duration.max) @safe nothrow {
  ExitReason er;
  do {
    er = eventDriver.core.processEvents(timeout);
  }while(er == ExitReason.idle);
  return er;
}

ExitReason runEventloop(Promise!void entryPoint, in Duration timeout = Duration.max)
in {
  assert(entryPoint !is null);
}body {
  Exception exception;
  entryPoint.then(
    () {
      eventDriver.core.exit;
    },
    (e) {
      exception = e;
      eventDriver.core.exit;
    }
  );

  auto er = runEventloop(timeout);
  if(exception !is null) throw exception;
  return er;
}

ExitReason runEventloop(in void delegate() entryPoint, in Duration timeout = Duration.max)
in {
  assert(entryPoint !is null);
}body {
  return runEventloop(async(entryPoint));
}

