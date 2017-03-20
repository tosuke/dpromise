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

nothrow Exception factory(int err, string file = __FILE__, size_t line = __LINE__) {
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

version (X86) {
  enum O_CREAT        = 0x40;     // octal     0100
  enum O_EXCL         = 0x80;     // octal     0200
  enum O_NOCTTY       = 0x100;    // octal     0400
  enum O_TRUNC        = 0x200;    // octal    01000

  enum O_APPEND       = 0x400;    // octal    02000
  enum O_NONBLOCK     = 0x800;    // octal    04000
  enum O_SYNC         = 0x101000; // octal 04010000
  enum O_DSYNC        = 0x1000;   // octal   010000
  enum O_RSYNC        = O_SYNC;
} else version (X86_64) {
  enum O_CREAT        = 0x40;     // octal     0100
  enum O_EXCL         = 0x80;     // octal     0200
  enum O_NOCTTY       = 0x100;    // octal     0400
  enum O_TRUNC        = 0x200;    // octal    01000

  enum O_APPEND       = 0x400;    // octal    02000
  enum O_NONBLOCK     = 0x800;    // octal    04000
  enum O_SYNC         = 0x101000; // octal 04010000
  enum O_DSYNC        = 0x1000;   // octal   010000
  enum O_RSYNC        = O_SYNC;
} else version (MIPS32) {
  enum O_CREAT        = 0x0100;
  enum O_EXCL         = 0x0400;
  enum O_NOCTTY       = 0x0800;
  enum O_TRUNC        = 0x0200;

  enum O_APPEND       = 0x0008;
  enum O_DSYNC        = O_SYNC;
  enum O_NONBLOCK     = 0x0080;
  enum O_RSYNC        = O_SYNC;
  enum O_SYNC         = 0x0010;
} else version (MIPS64) {
  enum O_CREAT        = 0x0100;
  enum O_EXCL         = 0x0400;
  enum O_NOCTTY       = 0x0800;
  enum O_TRUNC        = 0x0200;

  enum O_APPEND       = 0x0008;
  enum O_DSYNC        = 0x0010;
  enum O_NONBLOCK     = 0x0080;
  enum O_RSYNC        = O_SYNC;
  enum O_SYNC         = 0x4010;
} else version (PPC) {
  enum O_CREAT        = 0x40;     // octal     0100
  enum O_EXCL         = 0x80;     // octal     0200
  enum O_NOCTTY       = 0x100;    // octal     0400
  enum O_TRUNC        = 0x200;    // octal    01000

  enum O_APPEND       = 0x400;    // octal    02000
  enum O_NONBLOCK     = 0x800;    // octal    04000
  enum O_SYNC         = 0x101000; // octal 04010000
  enum O_DSYNC        = 0x1000;   // octal   010000
  enum O_RSYNC        = O_SYNC;
} else version (PPC64) {
  enum O_CREAT        = 0x40;     // octal     0100
  enum O_EXCL         = 0x80;     // octal     0200
  enum O_NOCTTY       = 0x100;    // octal     0400
  enum O_TRUNC        = 0x200;    // octal    010

  enum O_APPEND       = 0x400;    // octal    02000
  enum O_NONBLOCK     = 0x800;    // octal    04000
  enum O_SYNC         = 0x101000; // octal 04010000
  enum O_DSYNC        = 0x1000;   // octal   010000
  enum O_RSYNC        = O_SYNC;
} else version (ARM) {
  enum O_CREAT        = 0x40;     // octal     0100
  enum O_EXCL         = 0x80;     // octal     0200
  enum O_NOCTTY       = 0x100;    // octal     0400
  enum O_TRUNC        = 0x200;    // octal    01000

  enum O_APPEND       = 0x400;    // octal    02000
  enum O_NONBLOCK     = 0x800;    // octal    04000
  enum O_SYNC         = 0x101000; // octal 04010000
  enum O_DSYNC        = 0x1000;   // octal   010000
  enum O_RSYNC        = O_SYNC;
} else version (AArch64) {
  enum O_CREAT        = 0x40;     // octal     0100
  enum O_EXCL         = 0x80;     // octal     0200
  enum O_NOCTTY       = 0x100;    // octal     0400
  enum O_TRUNC        = 0x200;    // octal    01000

  enum O_APPEND       = 0x400;    // octal    02000
  enum O_NONBLOCK     = 0x800;    // octal    04000
  enum O_SYNC         = 0x101000; // octal 04010000
  enum O_DSYNC        = 0x1000;   // octal   010000
  enum O_RSYNC        = O_SYNC;
} else version (SystemZ) {
  enum O_CREAT        = 0x40;     // octal     0100
  enum O_EXCL         = 0x80;     // octal     0200
  enum O_NOCTTY       = 0x100;    // octal     0400
  enum O_TRUNC        = 0x200;    // octal    01000

  enum O_APPEND       = 0x400;    // octal    02000
  enum O_NONBLOCK     = 0x800;    // octal    04000
  enum O_SYNC         = 0x101000; // octal 04010000
  enum O_DSYNC        = 0x1000;   // octal   010000
  enum O_RSYNC        = O_SYNC;
} else static assert(0, "unimplemented");

enum O_ACCMODE      = 0x3;
enum O_RDONLY       = 0x0;
enum O_WRONLY       = 0x1;
enum O_RDWR         = 0x2;


enum S_IRUSR    = 0x100; // octal 0400
enum S_IWUSR    = 0x080; // octal 0200
enum S_IXUSR    = 0x040; // octal 0100
enum S_IRWXU    = S_IRUSR | S_IWUSR | S_IXUSR;

enum S_IRGRP    = S_IRUSR >> 3;
enum S_IWGRP    = S_IWUSR >> 3;
enum S_IXGRP    = S_IXUSR >> 3;
enum S_IRWXG    = S_IRWXU >> 3;

enum S_IROTH    = S_IRGRP >> 3;
enum S_IWOTH    = S_IWGRP >> 3;
enum S_IXOTH    = S_IXGRP >> 3;
enum S_IRWXO    = S_IRWXG >> 3;

enum S_ISUID    = 0x800; // octal 04000
enum S_ISGID    = 0x400; // octal 02000
enum S_ISVTX = 0x200; // octal 01000
