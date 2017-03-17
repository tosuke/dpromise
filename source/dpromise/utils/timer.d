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
  import std.datetime : Clock, SysTime, UTC;
  import dpromise.utils : runEventloop;

  auto startTime = Clock.currTime(UTC());

  sleepAsync(100.msecs).then({
    auto dur = Clock.currTime(UTC()) - startTime;
    assert(dur + 4.msecs > 100.msecs);
    assert(dur - 4.msecs < 100.msecs);
  });

  runEventloop();
}


nothrow @safe @nogc void sleepAsyncWithCallback(Duration dur, void function() nothrow callback)
in {
  assert(callback !is null);
} body {
  extern(C) nothrow static void systemCallback(uv_timer_t* handle) {
    auto data = *cast(DataContainer!(typeof(callback))*)handle.data;
    auto callback = data.data;
    callback();

    scope(exit) {
      import core.stdc.stdlib : free;
      free(handle.data);
      free(handle);
    }
  }
  asyncTimerBase(dur, Duration.zero, &systemCallback, cast(void*)callback);
}

static import std.datetime;
private std.datetime.SysTime startTime;
unittest {
  import std.datetime : Clock, UTC;
  import dpromise.utils;

  startTime = Clock.currTime(UTC());

  sleepAsyncWithCallback(100.msecs,() nothrow {
    try {
      auto dur = Clock.currTime(UTC()) - startTime;
      assert(dur + 4.msecs > 100.msecs);
      assert(dur - 4.msecs < 100.msecs);
    } catch(Exception e) {}
  });

  runEventloop();
}


nothrow @safe @nogc void sleepAsyncWithCallback(Duration dur, void delegate() nothrow callback)
in {
  assert(callback !is null);
} body {
  extern(C) nothrow static void systemCallback(uv_timer_t* handle) {
    auto data = *cast(DataContainer!(typeof(callback))*)handle.data;
    auto callback = data.data;
    callback();

    scope(exit) {
      import core.memory : GC;
      import core.stdc.stdlib : free;
      GC.removeRoot(callback.ptr);
      free(handle.data);
      free(handle);
    }
  }

  () @trusted nothrow {
    import core.memory : GC;
    GC.addRoot(callback.ptr);
  }();

  asyncTimerBase(dur, Duration.zero, &systemCallback, callback);
}

unittest {
  import std.datetime : Clock, UTC;
  import dpromise.utils;

  auto startTime = Clock.currTime(UTC());

  sleepAsyncWithCallback(100.msecs, () nothrow {
    try {
      auto dur = Clock.currTime(UTC()) - startTime;
      assert(dur + 4.msecs > 100.msecs);
      assert(dur - 4.msecs < 100.msecs);
    } catch(Exception e) {}
  });

  runEventloop();
}



private nothrow @safe @nogc void asyncTimerBase(T)(Duration timeout, Duration interval, uv_timer_cb callback, T data)
in {
  assert(callback !is null);
} body {
  auto timeout_msec = to!("msecs", ulong)(cast(TickDuration)timeout);
  auto interval_msec = to!("msecs", ulong)(cast(TickDuration)interval);

  () @trusted nothrow {
    import core.memory : GC;
    auto timer = castMalloc!(uv_timer_t);
    uv_timer_init(localLoop, timer);
    auto e = uv_timer_start(timer, callback, timeout_msec, interval_msec);
    auto pdata = castMalloc!(DataContainer!T);
    pdata.error = cast(uv_errno_t)e;
    pdata.data = data;
    timer.data = pdata;
  }();
}
