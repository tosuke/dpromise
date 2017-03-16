module dpromise.internal.libuv;

import deimos.libuv.uv;

package(dpromise) {
  uv_loop_t* localLoop;
}

static this() {
  localLoop = uv_loop_new();
  uv_loop_init(localLoop);
}

/*static ~this() {
  uv_loop_delete(localLoop);
}*/

package(dpromise) @nogc nothrow T* castMalloc(T)() {
  import core.stdc.stdlib : malloc;
  return cast(T*)malloc(T.sizeof);
}


package(dpromise) struct DelegateHandler {
  alias handler this;
  void delegate() handler;

  @safe nothrow @nogc this(void delegate() dg) {
    handler = dg;
  }

  void opCall() {
    handler();
  }
}
