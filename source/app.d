import std.file;
import dpromise.utils;
import dpromise.utils.file;

void main() {
  import dpromise.utils : runEventloop;
  write("hoge.txt", "hogehogepiyopiyo");
  readAsyncWithCallback("hoge.txt", (data, e) nothrow {
    try {
      assert(e is null);
      assert(data !is null);
      import std.stdio;
      data.writeln;
      //e.msg.writeln;
    } catch(Exception e) {}
  });

  runEventloop();
}
