module dpromise.internal.libuv;

import deimos.libuv.uv;

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


package(dpromise):
@nogc nothrow T* castMalloc(T)() {
  import core.stdc.stdlib : malloc;
  return cast(T*)malloc(T.sizeof);
}


struct DataContainer(T) {
  uv_errno_t error;
  T data;
}



