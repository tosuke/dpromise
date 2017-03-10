module dpromise.promise;

import std.traits;
import std.variant : Algebraic, tryVisit, visit;

private template ResolveFunc(T) {
  static if(!is(T == void)) {
    alias ResolveFunc = void delegate(T) @safe nothrow;
  }else {
    alias ResolveFunc = void delegate() @safe nothrow;
  }
}
private alias RejectFunc(T) = void delegate(Exception) @safe nothrow;
public Promise!T promise(T)(void delegate(ResolveFunc!T resolve, RejectFunc!T reject) @safe executer) @safe nothrow
if(!is(Unqual!T : Exception) && !is(Unqual!T : Promise!K, K)) {
return new Promise!T((ret) @safe nothrow {

  static if(!is(T == void)) {
    void resolve(T v) @trusted nothrow {
      Either!T a = v;
      ret(a);
    }
  }else {
    void resolve() @safe nothrow {
      ret(Either!T.init);
    }
  }
  void reject(Exception e) @trusted nothrow {
    Either!T a = e;
    ret(a);
  }

  try{
    executer(&resolve, &reject);
  }catch(Exception e) {
    reject(e);
  }
});}


private alias Either(T) = Algebraic!(T, Exception);

public abstract class Awaiter {
  abstract @property @safe /*@nogc*/ nothrow {
    bool isPending() const nothrow;
    bool isFulfilled() const nothrow;
    bool isRejected() const nothrow;
  }

  abstract public Awaiter then(void delegate() @safe onFulfillment, void delegate(Exception) @safe onRejection) @safe nothrow;
}

public final class Promise(T) : Awaiter if(!is(Unqual!T : Exception) && !is(Unqual!T : Promise!K, K)) {
  protected {
    Either!T _value;
    static if(is(T == void)) bool _isPending = true;
    void delegate() @safe nothrow next;
  }

  @property @trusted /*@nogc*/ {
    override bool isPending() const nothrow {
      static if(!is(T == void)) {
        return !_value.hasValue;
      }else {
        return !_value.hasValue && this._isPending;
      }
    }

    override bool isFulfilled() const nothrow {
      return !this.isPending && _value.type !is typeid(Exception);
    }

    override bool isRejected() const nothrow {
      return !this.isPending && _value.type is typeid(Exception);
    }
    static if(!is(T == void))
    inout(Unqual!T) value() inout {
      if(this.isFulfilled) {
        return _value.get!(Unqual!T);
      }else {
        assert(0);
      }
    }

    inout(Exception) exception() inout {
      if(this.isRejected) {
        return _value.get!Exception;
      }else {
        assert(0);
      }
    }
  }

  private this() @safe nothrow {
    this.next = (){};
  }

  package this(void delegate(void delegate(Either!T) @safe nothrow) @safe nothrow executer) @safe nothrow {
    void ret(Either!T v) @trusted nothrow {
      if(!this.isPending) return;
      try {
        this._value = v;
      }catch(Exception e){} //例外は発生しない
      static if(is(T == void)) this._isPending = false;
      this.next();
    }
    this();
    executer(&ret);
  }

  private template Flatten(S) {
    static if(is(Unqual!S : Promise!U, U)) {
      alias Flatten = U;
    }else {
      alias Flatten = S;
    }
  }

  override Promise!void then(void delegate() @safe onFulfillment, void delegate(Exception) @safe onRejection) @safe nothrow {
    return thenImpl(onFulfillment, onRejection);
  }

  static if(!is(T == void)) {
    public Promise!(Flatten!S) then(S, U)(
      S delegate(T) @safe onFulfillment,
      U delegate(Exception) @safe onRejection = cast(S delegate(Exception) @safe)null
    ) @safe nothrow if(is(Flatten!S == Flatten!U))
    in {
      assert(onFulfillment !is null);
    }body {
      if(onRejection is null) {
        onRejection = (e){ throw e; };
      }
      return thenImpl(
        () @safe {
          return onFulfillment(this.value);
        },
        onRejection
      );
    }
  }

  public Promise!(Flatten!S) then(S, U)(
    S delegate() @safe onFulfillment,
    U delegate(Exception) @safe onRejection = cast(S delegate(Exception) @safe)null
  ) @safe nothrow if(is(Flatten!S == Flatten!U))
  in {
    assert(onFulfillment !is null);
  }body {

    if(onRejection is null) {
      onRejection = (e){ throw e; };
    }
    return thenImpl(
      onFulfillment, onRejection
    );
  }

  public Promise!T fail(T delegate(Exception) @safe onRejection) @safe nothrow {
    if(onRejection is null) {
      onRejection = (e){ throw e; };
    }
    return thenImpl(
      () @safe {
        static if(!is(T == void)) return this.value;
      },
      onRejection
    );
  }

  private Promise!(Flatten!S) thenImpl(S, U)(
    S delegate() @safe onFulfillment,
    U delegate(Exception) @safe onRejection
  ) @safe nothrow if(is(Flatten!S == Flatten!U))
  in {
    assert(onFulfillment !is null);
    assert(onRejection !is null);
  }body {
    auto child = new Promise!(Flatten!S)();
    this.next = () @trusted nothrow {
      void fulfill() @trusted {
        static if(!is(S : Promise!K, K)) {
          static if(!is(Flatten!S == void)) {
            child._value = onFulfillment();
          }else {
            onFulfillment();
            child._isPending = false;
          }
          child.next();
        }else {
          static if(!is(Flatten!S == void)) {
            static assert(0);
          }else {
            static assert(0);
          }
        }
      }

      void reject(Exception e) @trusted {
        static if(!is(U : Promise!K, K)) {
          static if(!is(Flatten!U == void)) {
            child._value = onRejection(e);
          }else {
            onRejection(e);
            child._isPending = false;
          }
          child.next();
        }else {
          static if(!is(Flatten!U == void)) {
            static assert(0);
          }else {
            static assert(0);
          }
        }
      }

      try {
        this._value.tryVisit!(
          (Exception e) => reject(e),
          () => fulfill()
        );
      }catch(Exception e) {
        try{
          child._value = e;
        }catch(Exception e){} //例外は発生しない
        child.next();
      }
    };

    if(!this.isPending) this.next();

    return child;
  }
}
