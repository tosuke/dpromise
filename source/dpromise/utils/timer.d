/// Provides implementation of asynchronous timer.
module dpromise.utils.timer;

import core.time;
import dpromise.promise;
import deimos.libuv.uv, dpromise.internal.libuv;


/++
Sleep in asynchronous while $(D dur).

If an error occurred, promise will be rejected.

Params:
  dur = Duration of sleep.

See_Also: $(HTTP https://dlang.org/phobos/core_thread.html#.Thread.sleep, core.thread.Thread.sleep)
+/
nothrow Promise!void sleepAsync(Duration dur) {
  return promise!void((res, rej) {
    nothrow void f(Exception e) {
      e is null ? res() : rej(e);
    }

    sleepAsyncWithCallback(dur, &f);
  });
}

///
@system unittest {
  import dpromise.utils : runEventloop;
  import std.datetime : Clock, SysTime, UTC;

  auto startTime = Clock.currTime(UTC());

  sleepAsync(100.msecs).then({
    auto dur = Clock.currTime(UTC()) - startTime;
    assert(dur + 4.msecs > 100.msecs);
    assert(dur - 4.msecs < 100.msecs);
  });

  runEventloop();
}


/++
Sleep in asynchronous while $(D dur) then calls the $(D callback) function.

If an error occurred, the $(D callback) function will be called with the error.

Params:
  dur = Duration of sleep.
  callback = a function called when operation finished or an error occurred.
+/
nothrow @safe void sleepAsyncWithCallback(Duration dur, void delegate(Exception) nothrow callback)
in {
  assert(callback !is null);
} body {
  struct Data {
    int err;
    void delegate(Exception) nothrow callback;
  }

  extern(C) nothrow @trusted static void ret(uv_timer_t* tm) {
    auto data = cast(Data*)tm.data;
    auto callback = data.callback;
    callback(factory(data.err));

    scope(exit) {
      import core.memory : GC;
      import core.stdc.stdlib : free;
      GC.removeRoot(callback.ptr);
      free(tm.data);
      free(tm);
    }
  }

  extern(C) nothrow @trusted static void onTimeout(uv_timer_t* tm) {
    ret(tm);
  }

  () @trusted nothrow {
    import core.time : Duration, TickDuration, to;
    auto timeout = to!("msecs", ulong)(cast(TickDuration)dur);

    import core.memory : GC;
    auto timer = castMalloc!uv_timer_t;
    uv_timer_init(localLoop, timer);

    auto data = castMalloc!Data;
    GC.addRoot(callback.ptr);
    data.callback = callback;
    timer.data = data;

    data.err = uv_timer_start(timer, &onTimeout, timeout, 0);
    if(data.err != 0) ret(timer);
  }();
}
///
@safe unittest {
  import dpromise.utils : runEventloop;
  import std.datetime : Clock, UTC;

  auto startTime = Clock.currTime(UTC());
  sleepAsyncWithCallback(100.msecs, (e) nothrow {
    try {
      auto dur = Clock.currTime(UTC()) - startTime;
      assert(dur + 4.msecs > 100.msecs);
      assert(dur - 4.msecs < 100.msecs);
    } catch(Exception e) {}
  });

  runEventloop();
}
