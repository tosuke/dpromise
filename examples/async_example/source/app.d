import dpromise.async, dpromise.utils, dpromise.utils.timer;
import std.stdio;
import core.time;

void main() {
  runEventloop(async({
     "0 seconds".writeln;
     await(sleepAsync(1.seconds));
     "1.secods".writeln;
     await(async({ //nest
      await(sleepAsync(1.seconds));
      "2.seconds".writeln;
     }));
  }));
}
