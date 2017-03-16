module dpromise.utils.timer;

import core.time;
import dpromise.promise;
import deimos.libuv.uv, dpromise.internal.libuv;


Promise!void sleepAsync(Duration dur) {
  return promise!void((res, rej) {
    sleepAsyncWithCallback(dur, res);
  });
}

unittest {
  import std.stdio : writeln;
  import dpromise.utils : runEventloop;

  sleepAsync(1.seconds).then({
    try {
      "hog".writeln;
    } catch(Exception){}
  });

  runEventloop();
}


nothrow @safe @nogc void sleepAsyncWithCallback(Duration dur, void function() nothrow callback)
in {
  assert(callback !is null);
} body {
  extern(C) nothrow static void systemCallback(uv_timer_t* handle) {
    auto callback = cast(typeof(callback))handle.data;
    callback();

    scope(exit) {
      import core.stdc.stdlib : free;
      free(handle);
    }
  }
  asyncTimerBase(dur, Duration.zero, &systemCallback, cast(void*)callback);
}


nothrow @safe @nogc void sleepAsyncWithCallback(Duration dur, void delegate() nothrow callback)
in {
  assert(callback !is null);
} body {
  extern(C) nothrow static void systemCallback(uv_timer_t* handle) {
    auto callback = *cast(typeof(&callback))handle.data;
    callback();

    scope(exit) {
      import core.memory : GC;
      import core.stdc.stdlib : free;
      GC.removeRoot(callback.ptr);
      free(handle.data);
      free(handle);
    }
  }

  void* data;
  () @trusted nothrow {
    import core.memory : GC;
    GC.addRoot(callback.ptr);

    auto dg = castMalloc!(typeof(callback));
    *dg = callback;
    data = dg;
  }();

  asyncTimerBase(dur, Duration.zero, &systemCallback, data);
}


nothrow @safe @nogc void asyncTimerBase(Duration timeout, Duration interval, uv_timer_cb callback, void* data)
in {
  assert(callback !is null);
} body {
  auto timeout_msec = to!("msecs", ulong)(cast(TickDuration)timeout);
  auto interval_msec = to!("msecs", ulong)(cast(TickDuration)interval);

  () @trusted nothrow {
    import core.memory : GC;
    auto timer = castMalloc!(uv_timer_t);
    uv_timer_init(localLoop, timer);
    timer.data = data;
    uv_timer_start(timer, callback, timeout_msec, interval_msec);
  }();
}

nothrow @safe @nogc void sleepAsyncWithCallback(Duration dur, void delegate() callback)
in {
  assert(callback !is null);
} body {
  extern(C) static void systemCallback(uv_timer_t* handle) {
    auto callback = *(cast(typeof(&callback))handle.data);
    callback();
    scope(exit) {
      import core.stdc.stdlib : free;
      import core.memory : GC;
      GC.removeRoot(callback.ptr);
      free(handle.data);
      free(cast(void*)handle);
    }
  }

  auto msecs = to!("msecs", ulong)(cast(TickDuration)dur);

  () @trusted {
    import core.stdc.stdlib : malloc;
    import core.memory : GC;
    uv_timer_t* timer = castMalloc!uv_timer_t;
    uv_timer_init(localLoop, timer);

    GC.addRoot(cast(void*)callback.ptr);
    auto dg = castMalloc!(void delegate());
    *dg = callback;
    timer.data = dg;

    uv_timer_start(timer, &systemCallback, msecs, 0);
  }();
}


unittest {
  import std.stdio;
  import dpromise.utils;

  sleepAsyncWithCallback(1.seconds, {
    "piyo".writeln;
  });

  runEventloop();
}

/+
Promise!void sleepAsync(in Duration dur) nothrow {
  return promise!void((res, rej) {
    auto tm = eventDriver.timers.create();
    eventDriver.timers.wait(tm, (tm) @trusted nothrow {
      res();
    });
    eventDriver.timers.set(tm, dur, dur);
  });
}
+/
