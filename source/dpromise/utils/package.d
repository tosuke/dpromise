///
module dpromise.utils;

import dpromise.promise, dpromise.async;
import deimos.libuv.uv;
import dpromise.internal.libuv;


void runEventloop() @safe nothrow {
  () @trusted {
    uv_run(localLoop, uv_run_mode.UV_RUN_DEFAULT);
  }();
}


T runEventloop(T)(scope Promise!T promise) @safe
in {
  assert(promise !is null);
} body {
  static if(!is(T == void)) {
    T value;
    Exception exception;

    promise.then(
      (v) {
        value = v;
        stopEventloop();
      },
      (e) {
        exception = e;
        stopEventloop();
      }
    );
  } else {
    Exception exception;

    promise.then(
      () => stopEventloop(),
      (e) {
        exception = e;
        stopEventloop();
      }
    );
  }

  runEventloop();
  if(exception !is null) throw exception;
  static if(!is(T == void)) {
    return value;
  }
}


T runEventloop(T)(T delegate() dg)
in {
  assert(dg !is null);
} body {
  return runEventloop(async(dg));
}


void stopEventloop() @safe nothrow {
  () @trusted {
    uv_stop(localLoop);
  }();
}
