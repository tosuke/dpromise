module dpromise.task;

import dpromise.promise;
import std.concurrency;
import std.parallelism : totalCPUs;
import std.traits;


/+
Promise!T task(T)(T delegate() shared executer) nothrow
if(!is(Unqual!T : Exception) && !is(Unqual!T : Awaiter))
in {
  assert(executer !is null);
} body {

  return new Promise!T((ret) nothrow {
    try {
      auto eid = eventDriver.events.create();
      eventDriver.events.wait(eid, (eid) @trusted {
        try {
          import core.time : seconds;
          static if(!is(T == void)) {
            receiveTimeout(0.seconds,
              (Shared!T v) {
                Either!T a = cast()v;
                ret(a);
              },
              (shared(Exception) e) {
                Either!T a = cast()e;
                ret(a);
              }
            );
          }else {
            receiveTimeout(0.seconds,
              (None v) {
                ret(Either!T.init);
              },
              (shared(Exception) e) {
                Either!T a = cast()e;
                ret(a);
              }
            );
          }
        } catch(Exception e) {
          Either!T a = e;
          ret(a);
        }
      });

      spawn((T delegate() shared executer, shared(EventDriverEvents) s_evts, EventID eid){
        static if(!is(T == void)) {
          Shared!T value;
        }
        shared(Exception) exception;
        try {
          static if(!is(T == void)) {
            static if(hasAliasing!T) {
              value = cast(shared)executer();
            } else {
              value = executer();
            }
            send(ownerTid, value);
          }else {
            executer();
            send(ownerTid, None.init);
          }
        } catch(Exception e) {
          exception = cast(shared)e;
          send(ownerTid, exception);
        }
        s_evts.trigger(eid, false);
      }, executer, cast(shared)eventDriver.events, eid);
    } catch(Exception e) {
      Either!T a = e;
      ret(a);
    }
  });
}


private struct None{}

template Shared(T) {
  static if(hasAliasing!T) {
    alias Shared = shared(T);
  } else {
    alias Shared = T;
  }
}
+/
