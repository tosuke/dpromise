///
module dpromise.utils.timer;

import core.time;
import dpromise.promise;
import deimos.libuv.uv, dpromise.internal.libuv;


/++
Sleep in asynchronous while $(D dur).

Params:
  dur = Duration of sleep

See_Also: core.thread.Thread.sleep
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
Sleep in asynchronous while $(D dur) and after call $(D callback).

Params:
  dur = Duration of sleep
  callback = function call after sleep
+/
nothrow @safe @nogc void sleepAsyncWithCallback(Duration dur, void function(Exception) nothrow callback)
in {
  assert(callback !is null);
} body {
  extern(C) nothrow @trusted static void systemCallback(uv_timer_t* handle) {
    auto data = *cast(DataContainer!(typeof(callback))*)handle.data;
    auto callback = data.data;
    auto e = factory(data.error);
    callback(e);

    scope(exit) {
      import core.stdc.stdlib : free;
      free(handle.data);
      free(handle);
    }
  }
  asyncTimerBase(dur, Duration.zero, &systemCallback, cast(void*)callback);
}

///
@safe unittest {
  import dpromise.utils : runEventloop;
  import std.datetime : Clock, UTC;

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
static import std.datetime;
private std.datetime.SysTime startTime;


/// ditto
nothrow @safe void sleepAsyncWithCallback(Duration dur, void delegate(Exception) nothrow callback)
in {
  assert(callback !is null);
} body {
  extern(C) @trusted nothrow static void systemCallback(uv_timer_t* handle) {
    auto data = *cast(DataContainer!(typeof(callback))*)handle.data;
    auto callback = data.data;
    auto e = factory(data.error);
    callback(e);

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

///
@safe unittest {
  import dpromise.utils : runEventloop;
  import std.datetime : Clock, UTC;

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
