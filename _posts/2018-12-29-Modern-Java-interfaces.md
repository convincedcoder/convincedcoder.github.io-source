---
layout: post
title: Modern Java interfaces
tags: java
toc: true
---

This post is a review of interfaces in Java, including modern interfaces in Java 8 and later.

## The idea behind interfaces

Interfaces have been around since the first version of Java. The main idea behind interfaces is that they are a way to specify the contract between supplier(s) of certain functionality and client code which uses that functionality.

The most common use case for interfaces is to define an interface declaring one or more abstract methods (without implementation). There may be several classes actually implementing the interface (and specifying concrete implementations for the methods). Client code can then require an object that conforms to a certain interface, without having to care about which implementing class the object is an instance of.

Initially, Java interfaces could only contain two kinds of members: public static constants and public abstract methods.

```java
public interface Interface {    
    public static final int CONSTANT = 1;    
    public abstract void doSomething();
}
```

In version 2, it became possible to include nested classes and interfaces as well (although this is often not considered good practice). Java 5 introduced generics and the new enum an annotation types. This meant that interfaces could then also be parameterized with type parameters and that they could contain nested enums and annotations.

If we forget about nested classes, interfaces, enums and annotations for a moment (they are not used very often anyway), not much had changed since the first version. Interfaces were still all about declaring public static constants and public abstract methods. This all changed in Java 8 and later versions.

## Interfaces in modern Java

Java 8 introduced streams. This means that, starting from Java 8, every class implementing the `Collection` interface now has a `.stream()` method that provides powerful tools for processing and transforming the collection and its contents. Now, if that method would have been added to the `Collection` interface as an abstract method, this would have meant that all of the custom `Collection` classes that people had implemented would fail to compile until their authors added that `.stream()` method. Additionally, if such a class was supplied in a JAR file (for example, a  reusable library) that was compiled with an earlier version of Java, the class would still load successfully but users would suddenly get runtime errors on calling the `.stream()` method.

This was one of the reasons for the introduction of *default methods* in Java 8 interfaces. A default method is a method defined in an interface that specifies an actual implementation. A class implementing the interface can choose to either use that implementation (this is the case by default) or override it with custom code.

In Java 8, the `.stream()` method was added to the  `Collection` interface as a default method. This means that classes that don't specify anything regarding the `.stream()` method will still continue to work without any changes. They will just use the default implementation of `.stream()` that is specified in the interface.

```java
public interface Collection<E> extends Iterable<E> {
    // ...    
    
    default Stream<E> stream() { 
        // default implementation
    }

    //...
}
```

Default methods are also a clean alternative to the widespread pattern of declaring an interface (with only abstract methods) and then offering an abstract companion class providing default implementations for most of the methods. An example of that pattern is the `Collection` interface, for which there is an `AbstractCollection` class providing default implementations.

In addition to default methods, modern Java now also allows interfaces to specify static methods and private methods (introduced in Java 9). Static methods in interfaces can be useful as factory methods. We will see examples of this in an upcoming article on lambda expressions. Private methods are useful as helper methods for the default methods specified in the interface.

## Abstract classes vs. interfaces

As interfaces have become more powerful, they have become more similar to abstract classes. Therefore, it can be interesting to have a look at the remaining differences between the two in order to get a feel for when to use which.

One big limitation (by design) of interfaces is that they cannot be instantiated. Every object, although it could conform to one or more interfaces and could even be casted to the type of those interfaces, has to be an instance of an actual class. This also means that, unlike abstract classes, interfaces cannot have any instance variables or constructors. Interfaces are made for specifying behavior, not for encapsulating state.

Another limitation of interfaces is that the static variables they can declare will always be `final` (constant). This means that nothing, including the interface's own static methods, can modify them.

An important feature of interfaces is that, while a class can only extend at most one class, a class can implement any number of interfaces. This makes sense, as an interface is intended to specify a contract and a class could potentially conform to multiple contracts.

## Default methods and inheritance

As we saw above, a class can implement multiple interfaces. Before version 8 of Java, this was straightforward: as interfaces could not contain any kind of implementation code, it was impossible for implementation code from different interfaces to conflict.

Since default methods were introduced, this is no longer the case. Now, let's say that we have class that implements two interfaces, both of which contain a default method `doSomething()`. At that point, it becomes unclear which implementation should be used if the class does not specify its own implementation. This is known as the [diamond problem](https://en.wikipedia.org/wiki/Multiple_inheritance#The_diamond_problem).

The Java team has chosen to play it safe: if two interfaces that a class implements specify a method with the same signature and at least one of them specifies a default implementation for that method, the class must specify its own implementation. Even if only one of the interfaces provides a default implementation, the compiler forces you to be explicit about the specific implementation to be used. If one of the default methods already specifies the behavior you want, your implementation can simply delegate to it.

```java
public interface InterfaceA {    
    public abstract void doSomething();
}

public interface InterfaceB {    
    public default void doSomething() {
        System.out.println("test");
    };
}

public class Class implements InterfaceA, InterfaceB {
    // compiler forces us to provide an implementation
    @Override
    public void doSomething() {
        // delegate to behavior specified in InterfaceB
        InterfaceB.super.doSomething();
    }
}
```

Now, what if a class inherits from a superclass specifying a method `doSomething()` but also implements an interface that specifies a default `doSomething()` method? Here, the answer is simple: classes always win. In this case, Java will use the implementation defined in the superclass and simply ignore the default method implementation. This rule makes sure that default methods don't suddenly change the behavior of code that was written before Java 8.

Also, remember that there cannot possibly be a conflict between method implementations from two superclasses, because a class can still only inherit from at most one superclass.

## Resources

- Core Java SE 9 for the Impatient (book by Cay S. Horstmann)
- [Evolution of Interfaces in History of Java](https://dzone.com/articles/evolution-of-interface-in-history-of-java)
- [Difference between Abstract Class and Interface in Java](https://www.geeksforgeeks.org/difference-between-abstract-class-and-interface-in-java/)
- [The diamond problem](https://en.wikipedia.org/wiki/Multiple_inheritance#The_diamond_problem)