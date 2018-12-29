---
layout: post
title: Lambda expressions in Java
tags: java
toc: true
---

In this post, we cover the lambda expressions which were added to the Java language in version 8.

## Lambda expressions?

Before diving into the specifics of lambda expressions in Java, it's probably not a bad idea to have a look at lambda expressions. What exactly is such a lambda expression?

A *lambda expression* is a general concept in programming that is a synonym for *anonymous function*. This indicates a function (a piece of code that accepts input, does something with it and potentially returns a result) that is not explicitly named. These anonymous functions are very useful for passing them around to be used as input for other functions that operate on functions. For example, let's say we have an anonymous function comparing two strings and returning a number indicating their relative order. You could then pass that as input to another function that sorts a list of strings according the order specified by the anonymous function.

Anonymous functions were first described in a paper by Alonzo Church, written in 1936, before electronic computers even existed. In that paper, the parameters for the anonymous systems were marked using the letter λ (lambda). He picked this letter because the classic work *Principia Mathematica*, a very important work in the field of mathematics released about 20 years earlier, used the ^ accent to mark function parameters, which kind of looked like an uppercase lambda (Λ).

## How Java supports lambda expressions

Instead of diving deeper into the history of computer programming, let's fast-forward to modern Java and the way it supports the use of lambda expressions since version 8.

Let's have a first look at lambda expressions with a simple example.

```java
(String first, String second) -> first.length() - second.length()
```

As you can see, it simply consist of some code to execute (the body of the expression), together with the input parameters. You don't need to specify the return type of the body: Java automatically infers it. If the body doesn't fit on one line, simply create a block for it.

```java
(String first, String second) -> {
    if (first.length() < second.length()) {
        return -1;
    } else if (first.length() > second.length()) {
        return 1;
    } else {
        return 0;
    }
}
```

The lambda expression we just described take two Strings as parameters and return an integer. This means that they conform to the `Comparator<String>` interface. By specifying this, Java can infer the types of the parameters and you don't need to specify them explicitly anymore.

```java
public static int compareStrings(Comparator<String> comp) {
    return comp.compare("string1", "string2");
}

public static int test() {
    return compareStrings((first, second) ->
        first.length() - second.length());
}
```

If there is only a single argument with an inferred type, we can even omit the parentheses around that argument.

## Functional interfaces in Java

In the last example, we really saw lambda expressions in action: we have a `compareStrings`
function taking a `Comparator<String>` and we invoke it by passing an anonymous function conforming to that interface. We cannot do this for just any interface. The special thing about the `Comparator<String>` interface is that it has a single abstract method (`compare` in this case). Such an interface is called a *functional interface*. Whenever a piece of code needs an object conforming to a functional interface, you can pass a lambda expression implementing the single abstract method of that interface.

With the introduction of lambda expressions, Java also supplied a collection of new predefined functional interfaces in the [java.util.function](https://docs.oracle.com/javase/8/docs/api/java/util/function/package-summary.html) package. These are some general interfaces specifically intended to describe common signatures for lambda expressions. The interfaces use the `@FunctionalInterface` annotation to indicate that they are indeed functional interfaces.

An example of such an interface is the `Predicate<T>` interface, which takes an object of type `T` and returns a boolean value. Because it is a functional interface, it has a single abstract method. However, like several other functional interfaces, it has some (static or non-static) non-abstract methods intended for creating and combining functions. For example, if we have two `Predicate` instances `predicate1` and `predicate2`, we can combine them into a new `Predicate` as `predicate1.and(predicate2)`. The `Predicate` interface also offers a static factory method `isEqual(other)` which returning a `Predicate` that compares its parameter to the `other` object using its `equals` method (but doesn't throw a `NullPointerException` if `other` is null).

```java
Predicate<String> testPred = Predicate.isEqual(null);
System.out.println(testPred.test("test")); // false
System.out.println(testPred.test(null)); // true
```

There are also several other interfaces in the Java standard library which are functional interfaces. Examples are `java.util.Comparator`, which we saw above, and `java.lang.Runnable`. These specific ones are also marked with `@FunctionalInterface`, but note that that is not required to make an interface an actual interface. Any interface with a single abstract method is a functional interface. The only thing the `@FunctionalInterface` annotation does is that it makes this explicit (also in generated documentation) and causes the compiler to check if there is indeed only a single abstract method.

Although it is considered good practice to use existing functional interfaces where possible, you can also define your own functional interfaces. This is mostly useful if you need to accept lambda expressions with some uncommon signature. An example of this is an expression taking two `int` values and returning an instance of a custom `Color` class. You could in principle use the `BiFunction<Integer, Integer, Color>` interface, but you can avoid automatic boxing ad unboxing between `int` and `Integer` by specifying your own function interface. Another use case could be an expression taking a String and potentially throwing a checked exception, which should then be declared on the abstract method of the functional interface.

## Lambda expression scope

As we already saw, lambda expressions take inputs in the form of parameters. However, a lambda expression's parameters are not the only way to pass data to it. 

The body of a lambda expression has the same scope as a nested block (say, for example, the block of an if-statement). This means that, inside a lambda expression, you cannot declare a variable with the same name as a variable in the enclosing scope. It also means that, if you use the `this` keyword inside a lambda expression, it denotes the `this` reference of the method creating the lambda. One consequence is that lambda expressions cannot call default methods of the interface they implement.

```java
public class Test {    
    private int instanceVariable = 1;
    
    public Predicate<String> getPredicate() {
        int localVariable = 10;
        
        return string -> {
            int localVariable = 5; // compiler error
            System.out.println(localVariable); // 10
            System.out.println(this.instanceVariable); // 1
            return string.length() > localVariable;
        };
    }
}
```

As demonstrated in the above example, lambda expressions allow you to access variables from the enclosing scope (the method creating the lambda expression). This may seem obvious, but something special is going on there. Our lambda expression will be executed when the `getPredicate()` method creating it has already completed and the local variables inside that method are gone. How does this work?

Well, we saw that a lambda expression consists of a block of code and parameters for that block of code. In addition to that, the lambda expression that is passed around also contains values for the *free variables* (variables that are not parameters and are not defined inside the lambda expression's code). When storing a lambda expression in a variable, the object representing the lambda expression also includes the values of these free variables. Such a combination of a block of code together with the values of free variables is called a *closure*.

In Java, the capturing of free variables has an important restriction: you can only capture variables that are *effectively final*. This means that the variables don't change; either they are declared `final` or they could have been declared `final`. This also means that it is not possible to reassign captured variables from the lambda expression.

```java
int localVariable = 10;

for (int i = 0; i < 10; i++) {
    predicates.add(string -> {
        localVariable++; // compiler error
        return string.length() > i; // compiler error
        return string.length() > localVariable; // ok
    });
}
```

This restriction on captured variables is specific to Java. For example, closures in JavaScript do allow changing variables in the enclosing code.

Note that, while you cannot change the values of captured variables, you can still call methods on them if they are objects. It can also be interesting to know that the variable of an enhanced `for` loop is effectively final because its scope is limited to a singe iteration of the loop.

```java
List<Integer> integers;
List<Integer> processedIntegers;

for (Integer integer: integers) {
    predicates.add(string -> {
        processedIntegers.add(integer);
        return string.length() > integer;
    });
}
```

## Java as a (somewhat) functional language

With the introduction of lambda expressions and functional interfaces, Java gains some capabilities that are typical for functional programming languages.

Lambda expressions and functional interfaces can be seen as a way to treat functions as first-class objects, allowing to store functions in variables or pass them around to functions.

This way, Java supports the creation of *higher-order functions*, which are methods/functions that process or return other functions (although, in reality, those functions are just objects of classes implementing a functional interface). An example of this would be a static method that accepts a boolean indicating a direction and returns a `Comparator` based on the input. We could also have a method that takes a `Comparator` and returns a new `Comparator` reversing the order of the initial `Comparator` (the `Comparator` interface actually has a default method `reversed()` which reverses the current `Comparator`).

Java now also has a powerful mechanism to pass regular methods around as objects, which is essentially a shorthand for writing lambda expressions invoking the same methods. This is the mechanism of *method references*. There are three variations here:

- *Class::staticMethod*: a reference to a static method of a class
- *Class::instanceMethod*: a reference to an instance method of a class. The fist argument specifies the object on which the instance method is invoked.
- *object::instanceMethod*: a reference to an instance method of a class which will be invoked an a specific object.

```java
public class Test {    
    public static void staticMethod(String input) {
        System.out.println("static:" + input);
    }
    
    public void instanceMethod(String input) {
        System.out.println("instance:" + input);
    }
}
```

```java
// method reference
Test::staticMethod
// equivalent lambda expression
input -> Test.staticMethod(input)

// method reference
Test::instanceMethod
// equivalent lambda expression (2 parameters!)
(instance, input) -> instance.instanceMethod(input)

Test testInstance = new Test();
// method reference
testInstance::instanceMethod
// equivalent lambda expression
input -> testInstance.instanceMethod(input)
```

Some more realistic examples:

```java
List<String> list = new ArrayList<String>();
        
// Class::staticMethod
list.removeIf(Objects::isNull);
// Class::instanceMethod
list.sort(String::compareToIgnoreCase);
// object::instanceMethod
list.forEach(System.out::println);
```

As another practical example, consider the `Comparator.comparing` method. This method takes a method reference that extract the value to compare. This allows for easy construction of custom `Comparator` instances.

```java
personList.sort(Comparator
    .comparing(Person::getLastName)
    .thenComparing(Person::getFirstName))
```

There is also a similar mechanism, *constructor references*, for passing around constructors. This uses the syntax *Class::new*. If there are multiple constructors, the compiler will infer which constructor to use from the context.

```java
public class Dog {    
    private final String name;
    
    public Dog() {
        this.name = "Max";
    }

    public Dog(String name) {
        this.name = name;
    }
}
```

```java
// no-argument constructor
Supplier<Dog> dogSupplier = Dog::new;

// String argument constructor
Function<String, Dog> nameToDog = Dog::new;
```

You can also use constructor references to construct arrays. In that case, the array size is determined by the single parameter passed to the constructor reference.

## Alternatives to lambda expressions

Before the introduction of lambda expressions, Java already had a concise way to define a class implementing an interface. The way to do this was to use local or anonymous classes.

A *local class* is a class defined inside a method. A typical use case is if you want to provide an object conforming to an interface and it doesn't really matter what the implementing class is.

```java
int localVariable = 10;
        
class LengthPredicate implements Predicate<String> {
    @Override
    public boolean test(String string) {
        return string.length() > localVariable;
    }
}

Predicate<String> predicate = new LengthPredicate();
```

If you use your local class only once, it makes more sense to remove the name and to define it as an *anonymous class*.

```java
int localVariable = 10;        

Predicate<String> predicate = new Predicate<String>() {
    @Override
    public boolean test(String string) {
        return string.length() > localVariable;
    }
};
```

Just like with lambda expressions, the code in local and anonymous classes can access local variables defined in their enclosing scope. Also just like with lambda expressions, this is only allowed if those local variables are effectively final.

There are, however, some important differences between lambda expressions and local/anonymous classes.

First of all, you can use local/anonymous classes to implement interfaces with more than one abstract method. You are not restricted to functional interfaces.

```java
public interface TwoMethodInterface {
    public void methodA();
    public void methodB();
}
```

```java
TwoMethodInterface twoMethodInterface = new TwoMethodInterface() {
    @Override
    public void methodA() {
        System.out.println("methodA");
    }

    @Override
    public void methodB() {
        System.out.println("methodB");
    }
};
```

A second difference is that local/anonymous classes actually allow you to define local variables with the same name as local variables in the enclosing scope. This hides the variable in the enclosing scope from the code in the local/anonymous class (this is called *shadowing*). Lambda expressions forbid this.

```java
int localVariable = 10;        

Predicate<String> predicate = new Predicate<String>() {
    @Override
    public boolean test(String string) {
        System.out.println(localVariable); // 10
        int localVariable = 1;    
        System.out.println(localVariable); // 1
        return string.length() > localVariable;
    }
};
```

Another important thing to note is that local/anonymous classes are actual classes. Unlike lambda expressions, they can define and access their own instance variables. This also means that, if you use the `this` keyword in a method of a local/anonymous class, it refers to the instance of the class itself and not to the `this` reference of the method creating the local/anonymous class. You can also call default methods on the interface that you are implementing.

```java
public interface InterfaceA {    
    public abstract void doSomething();
    
    public default void logCount(int count) {
        System.out.println(count);
    }
}
```

```java
InterfaceA interfaceA = new InterfaceA() {
    private int count = 0;
    
    @Override
    public void doSomething() {
        this.count++;
        this.logCount(this.count);
    }
};
```

While this can be useful, it does make it harder to access the `this` reference of the enclosing method. However, we can still access that `this` reference by using local variables.

```java
public class Test {    
    private int instanceVariable = 0;
    
    public int getInstanceVariable() {
        return this.instanceVariable;
    }
    
    public void test() {
        // using method reference
        IntSupplier supplier = this::getInstanceVariable;
        // using a local variable referring to this
        Test outer = this;
        // available from Java 10
        // also works if outer class is anonymous
        var outer2 = this;
        
        InterfaceA interfaceA = new InterfaceA() {            
            @Override
            public void doSomething() {
                int outerInstanceVariable = supplier.getAsInt();
                outer.instanceVariable++;
            }
        };
        
        interfaceA.doSomething();
    }
}
```

## Functional interfaces and instantiation

Lambda expressions can be used as the value for variables or parameters that have a functional interface as a type. So, does this mean that lambda expressions violate the rule that interfaces cannot be directly instantiated?

Well, not quite. When you write a lambda expression, Java uses that to create an instance of some class that implements the relevant functional interface. This is similar to what happens when using an anonymous class. The way these objects and classes are managed depends on the specific Java implementation and can be highly optimized.

In order to see this in action, let's use a lambda expression and an anonymous function to fill a variable that has a functional interface as its type.

```java
Predicate<String> pred1 = (string -> string.length() > 1);

Predicate<String> pred2 = new Predicate<String>() {
    @Override
    public boolean test(String string) {
        return string.length() > 1;
    }
};

// class misc.Main$$Lambda$1/834600351
System.out.println(pred1.getClass()); 

// class misc.Main$4
System.out.println(pred2.getClass());
```

## Resources

- Core Java SE 9 for the Impatient (book by Cay S. Horstmann)
- [Anonymous function](https://en.wikipedia.org/wiki/Anonymous_function)
- [Package java.util.function](https://docs.oracle.com/javase/8/docs/api/java/util/function/package-summary.html)
- [Java 8 Functional interfaces (not the ones listed in java.util.function)](https://stackoverflow.com/questions/42942351/do-you-have-a-list-of-java-8-functional-interfaces-not-the-ones-listed-in-java)
- [Java 8 Lambdas vs Anonymous classes](https://stackoverflow.com/questions/22637900/java8-lambdas-vs-anonymous-classes)
- [Access method of outer anonymous class from inner anonymous class](https://stackoverflow.com/questions/53211917/access-method-of-outer-anonymous-class-from-inner-anonymous-class)