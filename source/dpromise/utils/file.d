/// Provides implementation of file operation with asynchronous IO.
module dpromise.utils.file;

import dpromise.promise;
import std.range.primitives, std.traits;
import std.file;
import deimos.libuv.uv, dpromise.internal.libuv;


/**
Writes $(D buffer) to file $(D path) with asynchronous IO.

Creates a new file if it is not already exist.
If an error occurred, the promise will be rejected.

Params:
  path = string repreesenting file path.
  buffer = data to be written to file.

See_Also: $(HTTP https://dlang.org/phobos/std_file.html#.write, std.file.write)
*/
nothrow Promise!void writeAsync(string path, in void[] buffer) {
  return promise!void((res, rej) {
    writeAsyncWithCallback(path, buffer, (e) nothrow {
      e is null ? res() : rej(e);
    });
  });
}

///
@system unittest {
  import std.file : exists, readText, remove;
  import dpromise.utils : runEventloop;

  writeAsync("hoge.txt", "hogehogepiyopiyo").then({
    assert(exists("hoge.txt"));
    assert(readText("hoge.txt") == "hogehogepiyopiyo");
    remove("hoge.txt");
  });

  runEventloop();
}


/**
Writes $(D buffer) to file $(D path) then calls the $(D callback) function with data as untyped array.

Creates a new file if it is not already exist.
If an error occurred, the $(D callback) function will be called with the error.

Params:
 path = string repreesenting file path.
 buffer = data to be written to file.
 callback = a fuction called when operation finished or an error occurred.
*/
nothrow @safe void writeAsyncWithCallback(string path, in void[] buffer, void delegate(Exception) nothrow callback)
in {
  assert(callback !is null);
} body {
  struct Data {
    int err;
    int handle;
    void delegate(Exception) nothrow callback;
    void[] buf;
  }

  extern(C) @trusted nothrow static void ret(uv_fs_t* req) {
    auto data = cast(Data*)req.data;
    auto callback = data.callback;
    callback(factory(data.err));

    scope(exit) {
      uv_fs_req_cleanup(req);
      import core.memory : GC;
      import core.stdc.stdlib : free;
      GC.removeRoot(callback.ptr);
      free(req.data);
      free(req);
    }
  }

  extern(C) @trusted nothrow static void on_close(uv_fs_t* req) {
    auto result = cast(int)req.result;
    auto data = cast(Data*)req.data;
    if(result < 0) {
      data.err = result;
    }
    ret(req);
  }

  extern(C) @trusted nothrow static void on_write(uv_fs_t* req) {
    auto result = cast(int)req.result;
    auto data = cast(Data*)req.data;
    if(result < 0) {
      data.err = result;
      ret(req);
      return;
    }

    uv_fs_req_cleanup(req);

    data.err = uv_fs_close(localLoop, req, data.handle, &on_close);
    if(data.err != 0) ret(req);
  }

  extern(C) @trusted nothrow static void on_open(uv_fs_t* req) {
    auto result = cast(int)req.result;
    auto data = cast(Data*)req.data;
    if(result < 0) {
      data.err = result;
      ret(req);
      return;
    } else {
      data.handle = result;
    }

    uv_fs_req_cleanup(req);

    auto iov = uv_buf_init(cast(char*)(data.buf.ptr), cast(uint)data.buf.length);
    data.err = uv_fs_write(localLoop, req, data.handle, &iov, 1, 0, &on_write);
    if(data.err != 0) ret(req);
  }

  () @trusted nothrow {
    import core.memory : GC;
    import std.string : toStringz;
    auto req = castMalloc!(uv_fs_t);
    auto data = castMalloc!Data;
    GC.addRoot(callback.ptr);
    data.callback = callback;
    data.buf = cast(void[])buffer;
    req.data = data;

    data.err = uv_fs_open(localLoop, req, path.toStringz, O_WRONLY|O_CREAT, S_IRUSR|S_IWUSR | S_IRGRP | S_IROTH, &on_open);
    if(data.err != 0) ret(req);
  }();
}

///
@safe unittest {
  import std.file : exists, readText, remove;
  import dpromise.utils : runEventloop;
  writeAsyncWithCallback("hoge.txt", "hogehogepiyopiyo", (e) nothrow {
    try {
      assert(e is null);
      assert(exists("hoge.txt"));
      assert(readText("hoge.txt") == "hogehogepiyopiyo");

      scope(exit) {
        remove("hoge.txt");
      }
    } catch(Exception e) {}
  });

  runEventloop();
}


/**
Read file $(D path) with asynchronous IO and returns data read as a promise of untyped array.
If file size is larger than $(D up_to), only $(D up_to) bytes read.

If an error occurred, the promise will be rejected.

Params:
  path = string repreesenting file path.
  up_to = max buffer size. default value is $(D size_t.max).

Returns: Promise of untyped array of bytes read

See_Also: $(HTTP https://dlang.org/phobos/std_file.html#.read, std.file.read)
*/
nothrow Promise!(void[]) readAsync(string path, size_t up_to = size_t.max) {
  return promise!(void[])((res, rej) nothrow {
    readAsyncWithCallback(path, up_to, (data, e) nothrow {
      e is null ? res(data) : rej(e);
    });
  });
}

///
@system unittest {
  import std.file : write, remove;
  import dpromise.utils : runEventloop;

  write("hoge.txt", "hogehogepiyopiyo");
  scope(exit) remove("hoge.txt");

  readAsync("hoge.txt").then(
    (data) {
      assert(data !is null);
      assert(cast(string)data == "hogehogepiyopiyo");
    }
  );

  readAsync("hoge.txt", 8).then(
    (data) {
      assert(data !is null);
      assert(cast(string)data == "hogehoge");
    }
  );

  runEventloop();
}


/**
Read file $(D path) with asynchronous IO then calls the $(D callback) function.
If file size is larger than $(D up_to), only $(D up_to) bytes read.

If an error occurred, the $(D callback) function will be called with the error.

Params:
  path = string repreesenting file path.
  up_to = max buffer size. default value is $(D size_t.max).
  callback = a fuction called when operation finished or an error occurred.
*/
nothrow @safe void readAsyncWithCallback(string path, size_t up_to, void delegate(void[], Exception) nothrow callback)
in {
  assert(callback !is null);
} body {
  struct Data {
    int err;
    int handle;
    void delegate(void[], Exception) nothrow callback;
    size_t up_to;
    ubyte[] buf;
  }

  extern(C) nothrow @trusted static void ret(uv_fs_t* req) {
    auto data = cast(Data*)(req.data);
    auto e = factory(data.err);

    if(e !is null) data.buf = null;

    data.callback(cast(void[])(data.buf), e);

    scope(exit) {
      import core.memory : GC;
      import core.stdc.stdlib : free;
      GC.removeRoot(data.callback.ptr);
      uv_fs_req_cleanup(req);
      free(data);
      free(req);
    }
  }

  extern(C) nothrow @trusted static void on_read(uv_fs_t* req) {
    auto result = cast(int)req.result;
    auto data = cast(Data*)req.data;
    if(result < 0) {
      data.err = result;
      ret(req);
      return;
    }

    uv_fs_req_cleanup(req);

    data.err = uv_fs_close(localLoop, req, data.handle, &ret);
    if(data.err != 0) ret(req);
  }

  extern(C) nothrow @trusted static void on_stat(uv_fs_t* req) {
    auto result = cast(int)req.result;
    auto data = cast(Data*)req.data;
    immutable size = req.statbuf.st_size;
    if(result < 0) {
      data.err = result;
      ret(req);
      return;
    }

    uv_fs_req_cleanup(req);

    auto buf = new ubyte[](data.up_to < size ? data.up_to : size);
    data.buf = buf;
    auto iov = uv_buf_init(cast(char*)(buf.ptr), cast(uint)buf.length);

    data.err = uv_fs_read(localLoop, req, data.handle, &iov, 1, 0, &on_read);
    if(data.err != 0) ret(req);
  }

  extern(C) nothrow @trusted static void on_open(uv_fs_t* req) {
    auto result = cast(int)req.result;
    auto data = cast(Data*)req.data;
    if(result >= 0) {
      data.handle = result;
    } else {
      data.err = result;
      ret(req);
      return;
    }

    uv_fs_req_cleanup(req);

    data.err = uv_fs_fstat(localLoop, req, data.handle, &on_stat);
    if(data.err != 0) ret(req);
  }

  () @trusted nothrow {
    import core.memory : GC;
    GC.addRoot(callback.ptr);
    auto data = castMalloc!Data;
    data.callback = callback;
    data.up_to = up_to;
    data.buf = null;

    auto req = castMalloc!uv_fs_t;
    req.data = data;
    import std.string : toStringz;
    data.err = uv_fs_open(localLoop, req, path.toStringz, O_RDONLY, 0, &on_open);
    if(data.err != 0) ret(req);
  }();
}

///
@system unittest {
  import std.file : write, remove;
  import dpromise.utils : runEventloop;
  write("hoge.txt", "hogehogepiyopiyo");
  scope(exit) remove("hoge.txt");

  readAsyncWithCallback("hoge.txt", size_t.max, (data, e) nothrow {
    try {
      assert(e is null);
      assert(data !is null);

      assert(cast(string)data == "hogehogepiyopiyo");
    } catch(Exception e) {}
  });

  readAsyncWithCallback("hoge.txt", 8, (data, e) nothrow {
    try {
      assert(e is null);
      assert(data !is null);

      assert(cast(string)data == "hogehoge");
    } catch(Exception e) {}
  });

  runEventloop();
}

///ditto
nothrow @safe void readAsyncWithCallback(string path, void delegate(void[], Exception) nothrow callback) {
  readAsyncWithCallback(path, size_t.max, callback);
}

///
@system unittest {
  import std.file : write, remove;
  import dpromise.utils : runEventloop;

  write("hoge.txt", "hogehogepiyopiyo");
  scope(exit) remove("hoge.txt");

  readAsyncWithCallback("hoge.txt", (data, e) nothrow {
    try {
      assert(e is null);
      assert(data !is null);

      assert(cast(string)data == "hogehogepiyopiyo");
    } catch(Exception e) {}
  });

  runEventloop();
}


/**
Read file $(D path) with asynchronous IO and return data read as a promise of string(validate with $(HTTP https://dlang.org/phobos/std_utf.html#.validate, std.utf.validate))

If an error occurred, the promise will be rejected.

Params:
  path = string representing file path.

Returns: A promise of string read.

See_Also: $(HTTP https://dlang.org/phobos/std_file.html#.readText, std.file.readText)
*/
nothrow Promise!S readTextAsync(S = string)(string path) if(isSomeString!S) {
  return promise!S((res, rej) nothrow {
    readTextAsyncWithCallback!S(path, (s, e) {
      e is null ? res(s) : rej(e);
    });
  });
}

///
@system unittest {
  import std.file : write, remove;
  import dpromise.utils : runEventloop;

  write("hoge.txt", "hogehogepiyopiyo");
  scope(exit) remove("hoge.txt");

  readTextAsync("hoge.txt").then(
    (s) {
      assert(s == "hogehogepiyopiyo");
    }
  );

  runEventloop();
}


/**
Read file $(D path) with asynchronous IO then calls the $(D callback) function with data as string(validate with $(HTTP https://dlang.org/phobos/std_utf.html#.validate, std.utf.validate)).

If an error occurred, the $(D callback) function will be called with the error.

Params:
  path = string representing file path.
  callback = a fuction called when operation finished or an error occurred.
*/
nothrow @safe void readTextAsyncWithCallback(S = string)(string path, void delegate(S, Exception) nothrow callback)
if(isSomeString!S)
in {
  assert(callback !is null);
} body {
  readAsyncWithCallback(path, (data, err) nothrow {
    try {
      if(err !is null) throw err;

      import std.utf : validate;
      auto result = cast(S)data;
      validate(result);
      callback(result, null);
    } catch(Exception e) {
      callback(null, e);
    }
  });
}

///
@safe unittest {
  import std.file : write, remove;
  import dpromise.utils : runEventloop;

  write("hoge.txt", "hogehogepiyopiyo");
  scope(exit) remove("hoge.txt");

  readTextAsyncWithCallback!string("hoge.txt", (s, e) nothrow {
    assert(e is null);
    assert(s == "hogehogepiyopiyo");
  });

  runEventloop();
}
