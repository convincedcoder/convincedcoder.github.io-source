---
layout: post
title: Java overloading, overriding and method hiding
tags: java
toc: true
---

This is a post about the way Java determines the exact method to call for a method invocation, which can sometimes seem confusing at first.

## Overloading

Method overloading means that a class has several methods with the same name but different number or types of parameters and that Java chooses which one to call based on the arguments you pass.

As a simple example, consider the following class. It has two methods with the same name but different parameter types.

```java
class OverloadingTest {
    public void testMethod(Object object) {
        System.out.println("object");
    }
    
    public void testMethod(String string) {
        System.out.println("string");
    }
}
```

Now, let's write some code to get a feel for how overloading works.

```java
OverloadingTest test = new OverloadingTest();
Object testObject = new Object();
String testString = "testString";

test.testMethod(testObject); // object
test.testMethod(testString); // string
```

So far, things are pretty straightforward. But wat if we get a little bit more creative?

```java
Object testStringAsObject = testString;
```

Here, we are taking a `String` but giving it a compile-time type of `Object`. What happens if we call our method on this?

```java
test.testMethod(testStringAsObject); // object
```

Although we know that `stringAsObject` is actually a `String`, we see that method overloading only looks at its compile-time type. This is generally true: Java's method overloading determines the exact signature of the method to call at compile time, using compile-time type information.

## Overriding

Method overriding means that a subclass overrides an instance method of a direct or indirect superclass by providing its own implementation. The following code provides a simple example.

```java
class OverridingTestSuper {
    public void testMethod(Object object) {
        System.out.println("super");
    }
}

class OverridingTestSub extends OverridingTestSuper {
    @Override
    public void testMethod(Object object) {
        System.out.println("sub");
    }
}
```

Note how we used the `@Override` annotation to make it clear that the method `testMethod` of `OverridingTestSub` overrides a supertype method. Java will actually check this and throw an error if you use this annotation on a method that does not really override a supertype method. This helps prevent method name typos and it makes sure you notice if the supertype method you are overriding is removed from the code at some point.

```java
OverridingTestSuper testSuper = new OverridingTestSuper();
OverridingTestSub testSub = new OverridingTestSub();
Object testObject = new Object();

testSuper.testMethod(testObject); // super
testSub.testMethod(testObject); // sub
```

We clearly see that the actual implementation that is invoked depends on whether we invoke it on the supertype or the subtype.

Now, what if we start playing around with compile-time types?

```java
OverridingTestSuper testSubAsSuper = testSub;
```

Here, we are taking a `OverridingTestSub` but giving it a compile-time type of `OverridingTestSuper`. What happens if we call its `testMethod` method?

```java
testSubAsSuper.testMethod(testObject); // sub
```

As you can see, which implementation is invoked depends on the actual runtime type of the object.

## Combining overloading and overriding 

Quick recap of how Java determines which implementation to call for an instance method:
- The exact *signature* of the method to be invoked is determined at *compile time* based on the number and compile-time types of arguments.
- For instance methods, the exact *implementation* of the method to be invoked is determined at *runtime* based on the actual runtime type of the object and the structure of the inheritance hierarchy.

Now, let's combine the two of them in a more complex example.

```java
class CombinedTestSuper {
    public void testMethod(Object object) {
        System.out.println("super object");
    }
}

class CombinedTestSub extends CombinedTestSuper {
    @Override
    public void testMethod(Object object) {
        System.out.println("sub object");
    }
    
    public void testMethod(String string) {
        System.out.println("sub string");
    }
}
```

```java
CombinedTestSuper testSuper = new CombinedTestSuper();
CombinedTestSub testSub = new CombinedTestSub();
CombinedTestSuper testSubAsSuper = testSub;

String testString = "testString";
Object testStringAsObject = testString;
```

So, what will happen if we pass `testString` and `testStringAsObject` as parameters to `testMethod` on `testSuper`, `testSub` and `testSubAsSuper`?

```java
testSuper.testMethod(testString); // super object
testSuper.testMethod(testStringAsObject); // super object

testSub.testMethod(testString); // sub string
testSub.testMethod(testStringAsObject); // sub object

testSubAsSuper.testMethod(testString); // sub object
testSubAsSuper.testMethod(testStringAsObject); // sub object
```

The results of the calls on `testSuper` should not be surprising: it has only one method. The results for `testSub` show method overloading at work: even though we are actually passing the same object instance twice, its compile-time type determines the actual signature of the method that is called.

The method calls on `testSubAsSuper` are a bit more interesting. We see that, because `testSubAsSuper` is actually a `CombinedTestSub` instance, the method implementations that are invoked are the ones in `CombinedTestSub`. However, even though that class uses method overloading to change its behavior based on the compile-time type passed to `testMethod`, we see that the same implementation is called twice. How is this possible?

Remember that `testSubAsSuper` has a compile-time type of `CombinedTestSuper`. If we call its `testMethod` method on `testString` (with compile-time type `String`), the Java compiler uses these compile-time types to determine the exact signature of the method to invoke. Because `CombinedTestSuper` only has a definition of `testMethod` with a parameter of type `Object`, the compiler determines that the signature of the method to invoke is `testMethod(Object)`.

At runtime, the actual implementation to use is determined based on the runtime type of `testSubAsSuper`, which is `CombinedTestSub`. However, Java only considers implementations which match the signature determined at compile time. Because that signature is `testMethod(Object)`, Java executes the `testMethod(Object)` implementation on `CombinedTestSub`, even though it also has a `testMethod(String)`.

## Method hiding

The parts above focused on instance methods. What about static methods?

Static methods use the same concept of method overloading to determine the exact signature of the method to call based on the compile-time types of the passed arguments.

Now, what happens if a subclass and superclass both implement a static method with the same signature?

```java
class CombinedTestSuper {
    public static void testStaticMethod(Object object) {
        System.out.println("super");
    }
}

class CombinedTestSub extends CombinedTestSuper {
    public static void testStaticMethod(Object object) {
        System.out.println("sub");
    }
}
```

If we call the static method directly on the class, we invoke the implementation of that particular class.

```java
Object testObject = new Object();
		
StaticSuper.testStaticMethod(testObject); // super
StaticSub.testStaticMethod(testObject); // sub
```

What if we try the same with instances of the classes?

```java
StaticSuper staticSuper = new StaticSuper();
StaticSub staticSub = new StaticSub();
StaticSuper staticSubAsSuper = staticSub;

staticSuper.testStaticMethod(testObject); // super
staticSub.testStaticMethod(testObject);	// sub
staticSubAsSuper.testStaticMethod(testObject);	// super
```

If the method we were calling was an instance method, we would have seen method overriding at work and the result of the last call would have been `"sub"` instead of `"super"`. However, because the method is static, the actual implementation that is called depends on the compile-time type of the object.

All in all, that behavior can be pretty confusing. This is why Java actually warns you when calling static methods on class instances, telling you that you should rather call static methods directly on the class.

## Resources

- [Overloading in the Java Language Specification](https://docs.oracle.com/javase/specs/jls/se10/html/jls-8.html#jls-8.4.9)
- [Java Method Hiding and Overriding](https://crunchify.com/java-method-hiding-and-overriding-override-static-method-in-java/9)