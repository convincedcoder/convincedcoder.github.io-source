---
layout: post
title: Java exception handling best practices and testing
tags: java
toc: true
---

This post explains some best practices for exception handling in Java (note that most of them are applicable to other languages as well). I also show some examples of how to test exceptions thrown by methods using JUnit.

## Checked versus unchecked exceptions

Checked exceptions are intended for cases when there is a reasonable way of recovering from the failure during the execution of the program. An example is a call to open a file and write to it, which can fail if the file does not exist. A reasonable way of recovering from this is trying a different filename. If the code for opening the file throws a checked exception if the file does not exist, the compiler forces you to to decide what to do in that case. This prevents the caller from forgetting that this kind of failure can actually happen.

Unchecked exceptions are intended to be used for programming errors. A simple example is `NullPointerException`: this is something that will never happen in ideal bug-free code.

There is a popular school of thought that uses slightly different guidelines:
- Use checked exceptions if there is a reasonable way of recovering from the failure during the execution of the program **and** the possibility for failure is unavoidable (an example is a missing file: even if you checked for its existence before, the file can still have disappeared in the meantime).
- Use unchecked exceptions in all other cases.
- Evaluate these conditions at every level in the call chain.

Then, there is a different and popular school of thought, which uses the following guidelines:
- Always use unchecked exceptions (unless you are maybe writing a very critical library).

This last school of thought is advertised in, amongst others, the *Clean Code* book by Robert C. Martin. The reasoning behind this is that checked exceptions come at a high cost. This cost is the fact that, if you throw a checked exception from your code and the appropriate handler sits three levels higher in the call chain, you must declare the exception on every method in between. This means that a single change to a small method somewhere deep in the program can require the signature of several higher-level methods to change. This breaks encapsulation and couples the handler of the exception to the code that generates it. This negates a large benefit of exceptions, which is that you can decouple the code detecting a failure from the code handling the failure.

The people arguing this also argue that the benefits of checked exceptions do not outweigh these costs. The main benefit of checked exceptions is robustness, but it is perfectly possible to write robust software in other languages (like C#) that do not offer checked exceptions.

## Throw early, catch late

A general best practice regarding exceptions is "Throw early, catch late". This can roughly be translated to "Don't catch an exception unless you are in the best position to do something useful with it".

For example, if an exception occurs because there is no file at a specific path, it often makes sense to propagate the exception to the level where the path to use is determined.

In general, you should try to only catch exceptions if:

- You can perform a useful action on the exception (possibly just logging) and then rethrow it.
- You can wrap the exception into a new exception that makes more sense to your caller and throw that new exception.
- You can make a final decision on what is the appropriate code to be executed in order to fully handle the exception.

## Providing context with exceptions

Although exceptions contain a stack trace that shows the call chain at the time the exception occurred, it is often advisable to pass additional context. Typically, you should at least provide a meaningful message explaining the intent of the operation that failed and the reason for failure. When defining custom exception classes, you can also foresee additional data being stored with the exception. If your application has logging, your exception (including stack trace) should contain enough information for creating a meaningful log message.

## Client-first design for exception classes

When designing which and how many exception classes you need, try to consider the point of view of the caller. It is possible that things can go wrong because of different reasons but the caller only has one reasonable way of handling failures, independent of the specific reason. In that case, a good approach is typically to foresee a single exception class, potentially using exception chaining to pass on more details. You only need different error classes if the client needs to handle them differently.

If you are using a class with methods that can throw lots of different exception types, consider wrapping it in a class that delegates actual functionality to the wrapped class but catches a set of specific errors and wraps these into a single, more general error class. This is one of the techniques you can use to transform a library's interface into an interface that makes more sense to your application.

```java
public void open() {
    try {
        this.wrapped.open();
    } catch (Type1 | Type2 | Type3 ex) {
        throw new WrappedException(ex);
    }
}
```

### Dealing with `NullPointerException`

One of the most dreaded Java exception types is the infamous `NullPointerException`. This is an unchecked exception indicating a programming error (we called a method on something that is potentially a null reference). The best way of dealing with `NullPointerException` is to avoid it.

You can make failure with a `NullPointerException` less likely by using the following set of rules for your code:
- Don't return null from methods. Wherever possible, return a special case object (e.g. an empty list or even a dedicated subclass of the return type that is intended for these cases).
- Don't pass null as a method parameter. In some other languages (e.g. TypeScript) the compiler can actually help you enforce this.

The `Objects` class has some convenient methods for preventing problems with null pointers. These can be used for checking arguments or preventing passing null.
- `Objects.requireNonNull()` throws a `NullPointerException` if the argument is null ad returns the argument itself otherwise. This does not prevent the `NullPointerException` from being thrown. However, the benefit here is that we throw it where the source of the problem lies (`null` being passed where it should not happen) instead of at some later point in the code where we try to invoke a method on a null reference.
- `Objects.requireNonNullElse()` returns either the first parameter or, if the first parameter is null, it returns the second parameter. It is quite similar to the `COALESCE` function in SQL.

```java
public static void test(String name, String nickName) {
    name = Objects.requireNonNull(name);
    nickName = Objects.requireNonNullElse(nickName, "nick");
}
```

Something else that can help is the `Optional` type, which will likely be discussed in a later blog post.

## Testing thrown exceptions

TODO

TODO

TODO

TODO

TODO

TODO

TODO

TODO

TODO

TODO

TODO

TODO

TODO

TODO

TODO

TODO

https://github.com/junit-team/junit4/wiki/exception-testing
https://github.com/Codearte/catch-exception

## Resources

- Core Java SE 9 for the Impatient (book by Cay S. Horstmann)
- Clean Code (book by Robert C. Martin)
- [Unchecked Exceptions — The Controversy](https://docs.oracle.com/javase/tutorial/essential/exceptions/runtime.html)
- [When to choose checked and unchecked exceptions](https://stackoverflow.com/questions/27578/when-to-choose-checked-and-unchecked-exceptions)
- [Exceptions: Why throw early? Why catch late?](https://softwareengineering.stackexchange.com/questions/231057/exceptions-why-throw-early-why-catch-late)
- [Exception testing](https://github.com/junit-team/junit4/wiki/exception-testing)
- [catch-exception](https://github.com/Codearte/catch-exception)
