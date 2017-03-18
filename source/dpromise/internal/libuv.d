module dpromise.internal.libuv;

import deimos.libuv.uv;

package(dpromise):

package(dpromise) {
  uv_loop_t* localLoop;
}

static this() {
  localLoop = castMalloc!(uv_loop_t);
  uv_loop_init(localLoop);
}

static ~this() {
  uv_loop_close(localLoop);
}


@nogc nothrow T* castMalloc(T)() {
  import core.stdc.stdlib : malloc;
  return cast(T*)malloc(T.sizeof);
}

struct DataContainer(T) {
  uv_errno_t error;
  T data;
}

nothrow Exception factory(uv_errno_t err, string file = __FILE__, size_t line = __LINE__) {
  if(err == 0) return null;

  import std.string : fromStringz;
  import std.format : format;
  try {
    auto msg = format("%s:%s", uv_err_name(err).fromStringz, uv_strerror(err).fromStringz);
    return new IOException(msg, file, line);
  } catch(Exception e) {
    return e;
  }
}

/++
Errors thrown when libuv error.
+/
public final class IOException : Exception {
  /// Creates a new instance of $(D IOException).
  pure nothrow @nogc @safe this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
    super(msg, file, line, next);
  }
}




