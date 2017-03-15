import dpromise.promise;
import std.stdio;

void main() {
  promise!int((resolve, reject) {
    resolve(10);
  }).then((int integer) {
    integer.writeln;
    return integer + 3; //13
  }).then((a) {
    return promise!int((res, rej) { //Return promise
      a.writeln;
      res(a + 3);
    });
  }).then((a) {
    a.writeln;
  });

  //Error handling
  promise!string((resolve, reject) {
    throw new Exception("test");
  }).fail((e) {
    return e.msg;
  }).then((a) {
    a.writeln;
  });
}
