module dpromise.utils.file;

import dpromise.promise;
import std.range.primitives, std.traits;
import std.file;
/+
/**
Write buffer to file path with asynchronous IO.

Creates the new file if it is not already exist.

Params:
  path = string representing file path
  buffer = data to be written to file

Throws: FileException on error.

See_Also: std.file.write
*/
Promise!void writeAsync(string path, const void[] buffer) nothrow {
  return promise!void((res, rej) {
    auto fid = eventDriver.files.open(path, FileOpenMode.createTrunc);
    eventDriver.files.write(fid, 0, cast(const(ubyte)[])buffer, IOMode.all, (id, status, size) @trusted nothrow {
      scope(exit) eventDriver.files.close(id);
      if(status == IOStatus.error) {
        try {
          rej(new FileException(path, "An error occured"));
        } catch(Exception e) {
          rej(e);
        }
      }
      res();
    });
  });
}

///
unittest {
  import dpromise.utils, dpromise.async;
  runEventloop({
    await(writeAsync("hoge.txt", "hogehogepiyopiyo"));
    scope(exit) remove("hoge.txt");
    assert(exists("hoge.txt"));
    assert(readText("hoge.txt") == "hogehogepiyopiyo");
  });
}


/**
Read file with asynchronous IO and returns data as untyped array.
If file size is larger then up_to, only up_to bytes read.

Params:
  path = string repesenting file path
  up_to = max buffer size

Returns: Untyped array promise of bytes read

Throws: FileException on error

Bugs: Probabry cause SEGV in unittest

Examples:
----------------------------------------------
import dpromise.utils, dpromise.async;

runEventloop({
  write("hoge.txt", "hogehogepiyopiyo");
  scope(exit) remove("hoge.txt");

  auto s = await(readAsync("hoge.txt"));
  assert(s == cast(void[])"hogehogepiyopiyo");
});
----------------------------------------------

See_Also: std.file.read
*/
Promise!(void[]) readAsync(string path, size_t up_to = size_t.max) nothrow {
  return promise!(void[])((res, rej) {
    const fid = eventDriver.files.open(path, FileOpenMode.read);
    const size = std.file.getSize(path);
    auto buffer = new ubyte[](size < up_to ? up_to : size);

    eventDriver.files.read(fid, 0, buffer, IOMode.all, (id, status, nbytes) @trusted nothrow {
      scope(exit) eventDriver.files.close(id);
      if(status == IOStatus.error) {
        try {
          rej(new FileException(path, "An error occured"));
        } catch(Exception e) {
          rej(e);
        }
      }
      res(cast(void[])buffer);
    });
  });
}


/**
Read file with asynchronous IO and returns data as string(validate with std.utf.validate)

Params:
  path = string representing file path

Returns: string promise read

Throws: FileException on error

Bugs: Probabry cause SEGV in unittest

Examples:
-------------------------------------------
import dpromise.utils, dpromise.async;

runEventloop({
  write("hoge.txt", "hogehogepiyopiyo");
  scope(exit) remove("hoge.txt");

  auto s = await(readTextAsync("hoge.txt"));
  assert(s == "hogehogepiyopiyo");
});
--------------------------------------------

See_Also: std.file.readText
*/
Promise!S readTextAsync(S = string)(string path) nothrow if(isSomeString!S) {
  return readAsync(path).then(
    (s) {
      import std.utf : validate;
      auto result = (() @trusted => cast(S)s)();
      validate(result);
      return result;
    }
  );
}
+/
