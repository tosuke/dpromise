import dpromise.task, dpromise.utils;
import std.stdio;
import core.time;

void main() {
  auto t = task(() shared {
    import core.thread : Thread;
    Thread.sleep(2.seconds);
    return "2 seconds";
  }).then((a) {
    a.writeln;
  });

  "0.seconds".writeln;
  runEventloop(t);
}
