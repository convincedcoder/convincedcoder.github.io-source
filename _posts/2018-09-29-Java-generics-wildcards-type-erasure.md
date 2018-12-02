---
layout: post
title: Java generics, wildcards and type erasure
tags: java
toc: true
---

This post contains a high-level review of Java generics.

## Introducing the Animal and Dog class

This post will assume that we have two extremely simple classes, `Animal` and `Dog`, where the latter is a subclass of the former.

```java
public class Animal {    
    public void makeSound() {
        System.out.println("I'm an animal!");
    };
}
```

```java
public class Dog extends Animal {
    @Override
    public void makeSound() {
        System.out.println("Woof!");
    }
}
```

## Generics basics

Java generics allow to define classes, interfaces and methods that work with different types. This happens by adding one or more type parameters. 

A simple example of a generic interface is the List interface, which allows to specify the type of objects in the list.

```java
List<Dog> dogList = new ArrayList<Dog>();
dogList.add(new Dog());
Dog dog = dogList.get(0);
dogList.add(new Object()); // compiler error
```

The following is an example of a simple generic method.

```java
public <T extends Animal> T getFirstAnimal(List<T> animals) {
    return animals.get(0);
}
```

The above example also shows an example of a *type bound*: it allows `T` to be the `Animal` class or any of its subclasses. The same mechanism can be used for the type parameters of generic classes. Also note that the type parameter can be used inside the class.

```java
public class AnimalWrapper<T extends Animal> {    
    private T wrappedAnimal;

    public AnimalWrapper(T wrappedAnimal) {
        this.wrappedAnimal = wrappedAnimal;
    }
    
    public T getWrappedAnimal() {
        return this.wrappedAnimal;
    }
}
```

## Wildcards

Suppose that you need a list of `Animal`s for something and you define it as a `List<Animal>`. Can you just pass a `List<Dog>` in that case?

```java
List<Dog> dogList = new ArrayList<Dog>();
List<Animal> animalList = dogList; // compiler error
```

The reason why this fails is that a proper `List<Animal>` allows adding any `Animal`, while a `List<Dog>` should only allow adding `Dog`s. This means that the two types are not compatible. However, if we only care about the fact that our List contains some kind of `Animal`s, we can use type wildcards to define this.

```java
List<Dog> dogList = new ArrayList<Dog>();
List<? extends Animal> extendsAnimalList = dogList; // works
```

If we define our List as a `List<? extends Animal>`, we specify that this is a List of `Animal` or one of its subclasses. This means that each element in the list is some kind of `Animal`. Note that this does not allow us to add any kind of `Animal` to the list, because as for all we know, the List might be a `List<Dog>` or a List of some other subclass of `Animal`. 

`? extends Animal` is called a *subtype wildcard*. Another type of wildcard is the *supertype wildcard*, for example `? super Dog`. If we define a `List<? super Dog>`, we know that we have a List of `Dog` or one of its supertypes. This means that, whatever the specific type of the List is, the list will always allow us to add a `Dog` object to it. However, we cannot make any assumptions regarding the types of objects in the list.

```java
List<Dog> dogList = new ArrayList<Dog>();

List<? extends Animal> extendsAnimalList = dogList;
Animal animal = extendsAnimalList.get(0); // works
extendsAnimalList.add(new Dog()); // compiler error

List<? super Dog> superDogList = dogList;
Animal animal2 = superDogList.get(0); // compiler error
superDogList.add(new Dog()); // works
```

You could also use a wildcard without bounds when you are doing something very generic and don't care at all about the value of the type parameter.

## Generics in the Java Virtual Machine

In order to get a better understanding of how generics behave in Java, it helps to take a look at what's happening under the hood.

### Type erasure

Java only added generics in version 1.5. Before that, instead of the generic `ArrayList<T>`, there was just the class `ArrayList`. When introducing generics, the Java team decided to maintain compatibility by actually erasing the generic type information at compile time, meaning that the byte code running in the Java Virtual Machine does not know anything about generics.

As an example, consider let's go back to our `AnimalWrapper` class.

```java
public class AnimalWrapper<T extends Animal> {    
    private T wrappedAnimal;

    public AnimalWrapper(T wrappedAnimal) {
        this.wrappedAnimal = wrappedAnimal;
    }
    
    public T getWrappedAnimal() {
        return this.wrappedAnimal;
    }
}
```

This generic type is compiled into the follow *raw* type:

```java
public class AnimalWrapper {    
    private Animal wrappedAnimal;

    public AnimalWrapper(Animal wrappedAnimal) {
        this.wrappedAnimal = wrappedAnimal;
    }
    
    public Animal getWrappedAnimal() {
        return this.wrappedAnimal;
    }
}
```

Note that the wrappedAnimal has now become an `Animal` after type erasure. This makes sense: our type bound restricted the type T to be `Animal` or one of its subclasses. Type parameters without type bounds are erased to `Object`.

Before erasing the types, the compiler checks for errors involving generic types. For example, it will forbid wrapping an `Animal` in an `AnimalWrapper<Dog>`. This means that, although the types are erased later on, we know that the type variables are respected.

### Cast insertion

Although the compiler checks for generic type mismatches, that this in itself is not always enough. An example is the following code:

```java  
List<Dog> dogList = new ArrayList<Dog>();        
List rawList = dogList;        
Animal animal = new Animal();
rawList.add(animal);
```

The code will generate compiler warnings, but if you ignore those, it can compile and run without issues. This is strange, because we now have an `Animal` object sitting in a `List<Dog>`. This is known as *heap pollution*. What about type safety?

Well, the way this is handled in Java is that the compiler inserts a cast whenever the code *reads* from an expression with erased type. This means that, while we can add the `Animal` to our `List<Dog>`, we will get a `ClassCastException` if we try to retrieve that `Animal` as a `Dog`.

```java
List<Dog> dogList = new ArrayList<Dog>();  
List rawList = dogList;
Animal animal = new Animal();
rawList.add(animal);

Animal retrievedAnimal = dogList.get(0); // works
Dog retrievedDog = dogList.get(0); // ClassCastException
```

The behavior of the above code can be explained by looking at the compiled code, which is equivalent to the code below.

```java
List dogList = new ArrayList();  
List rawList = dogList;
Animal animal = new Animal();
rawList.add(animal);

// note that the erased List.get() method returns an Object
// cast insertion generates casts based on target type
Animal retrievedAnimal = (Animal) dogList.get(0); // works
Dog retrievedDog = (Dog) dogList.get(0); // ClassCastException
```

Note that we don't get an exception when we try to retrieve the `Animal` as an actual `Animal`. Also note that, when we get the `ClassCastException` on the last line, that does not help us to find the actual source of the problem (which is the code where we inserted an `Animal` inside a `List<Dog>`). When debugging such problem, it can be useful to use a checked view of the `List`. This checks the type of inserted objects as they are inserted.

```java
List<Dog> dogList = 
    Collections.checkedList(new ArrayList<Dog>(), Dog.class);

List rawList = dogList;
Animal animal = new Animal();
rawList.add(animal); // ClassCastException
```

Note the use of `Dog.class`, a `Class<Dog>` instance which is needed to know the actual value of the type parameter for the `List`. We will revisit the `Class<T>` class further down this post.

### Bridge methods

In some cases, basic type erasure would lead to problems with method overriding. In order to prevent this, the Java compiler sometimes generates *bridge methods*. As an example, consider the class `GoodBoyList`.

```java
public class GoodBoyList extends ArrayList<Dog>{
    @Override
    public boolean add(Dog dog) {
        dog.pet():
        return super.add(dog);
    }
}
```

Now, let's say we use this class in the following way:

```java
GoodBoyList goodBoyList = new GoodBoyList();
ArrayList<Dog> dogList = goodBoyList;
dogList.add(new Dog());
```

After erasure, the last line calls the erased `add(Object)` method on the `ArrayList` class. We would expect the `add(Dog)` method on `GoodBoyList` to override that method, but the problem is that the method signatures are different.

The compiler solves this by inserting a bridge method `add(Object)` into the `GoodBoyList` class. That method looks like this:

```java
// overrides ArrayList.add(Object)
public boolean add(Object dog) { 
    return this.add((Dog) dog); // calls add(Dog) 
}
```

After erasure, it is the bridge method that actually overrides the `ArrayList.add(Object)` method. It then calls the `GoodBoyList.add(Dog)` method.

Bridge methods can also be used when the return type varies. For example, imagine that our `GoodBoyList` also overrides the `get(int)` method.

```java
public class GoodBoyList extends ArrayList<Dog>{
    @Override
    public Dog get(int i) {
        Dog dog = super.get(i);
        dog.pet():
        return dog;
    }
}
```

After erasure, we need a bridge method to make overriding work here. This way, we get two `get` methods in `GoodBoyList`:

- `Dog get(int)`: this is the actual method as defined in `GoodBoyList`
- `Object get(int)`: this is a generated bridge method that overrides the `Object get(int)` method in `ArrayList`.

This may seem strange, because the compiler would never allow you to write a class with two methods with the same name taking the same number and type of arguments. However, inside the Java Virtual Machine, a method is defined by its name, the number and types of its arguments *and* by its return type. This is why the bridge method is needed, and also why it is allowed to exist.

The compiler takes care of the generation of bridge methods, so in principle you don't have to worry about them. However, they may show up in stack traces or explain why the compiler complains about certain pieces of code.

## The Class class

The Java language has a `Class<T>` class. A `Class<T>` object represent the class `T`. This class object can directly be obtained from the class `T`. It is also possible to to get a `Class` object from an instance of a class, but in that case you are getting the actual run-time type of that instance, which may be a subclass of its compile-time type.

```java
Class<Dog> test = Dog.class; // ok
Class<Dog> test2 = new Dog().getClass(); // error
Class<? extends Dog> test3 = new Dog().getClass(); // ok
```

You can use the `Class` class to get more information regarding the value of a type variable at run-time (so after type erasure). As an example, the below code for the `Test` class forces you to pass a `Class<T>` object where `T` is exactly value of the type variable of class `Test`. Even though the generic type information is erased during compilation, you can still determine the type of objects you are dealing with by looking at the `Class` instance.

```java
public class Test<T> {    
    Test(T object, Class<T> objectClass) {}
}

public class Main {
    public static void main(String[] args) {            
        Dog dog = new Dog();
        new Test<Animal>(dog, Animal.class);
    }
}
```

Note that the `Class` object we receive is the exact class of the type parameter's value, but it is not necessarily the exact class of the object that we receive. That object may be an instance of a subclass.

The `Class<T>` object is also very useful when using reflection. For example, it can help you access the constructor(s) for the class.

## Generics restrictions

### Type arguments cannot be primitives

A type parameter must always be `Object` or a subclass of `Object`. This means that, for example, it is not possible to define an `ArrayList<int>`.

### At runtime, all types are raw

Type erasure means that, at runtime, all types are raw. Therefore, something like `if (object instanceof ArrayList<Dog>)` will not compile because this check is impossible to execute at runtime.

The `Class` instances that you get are also always raw types. There is no `ArrayList<Dog>.class`, only `ArrayList.class`.

### Type variables cannot be instantiated

If you have a type variable `T`, you cannot do `new T(...)` or `new T[...]` (array). This is forbidden because of type erasure (you would be instantiating the erased value for `T`, not `T` itself).

If you want to construct objects of type `T` or arrays of type `T` inside a generic method, you will have to ask the caller for the right object or array constructor or for a `Class` object.

Note that, while you cannot instantiate an array of type `T`, you can easily create an `ArrayList<T>`. This is because `ArrayList` is a generic type itself, while in order to create an array of type `T` we would need the exact type `T` at runtime.

### It's impossible to create arrays of parameterized types

Although you can declare arrays of a parameterized type (e.g. `AnimalWrapper<Dog>[]`), it is not possible to instantiate an array of that type. This is because, after erasure, we would just get an `AnimalWrapper[]` array that allows any kind of `AnimalWrapper` without throwing an `ArrayStoreException`. If that is what you want, you can create an `AnimalWrapper[]` and then cast it to `AnimalWrapper<Dog>[]` (this will generate compiler warnings though).

The simplest solution is often to just create an `ArrayList<AnimalWrapper<Dog>>` instead.

### Class type variables are not valid in static contexts

Type variables defined at the level of the class cannot be used in static contexts (static variables and static methods). For example, if you have a class with type parameter `T`, you cannot have a static variable of type `T`. This makes sense: you can use a class multiple times with different values for `T` but a static variable only exists once (on the raw type), so it's impossible to have a static variable with the exact type `T` for each of those values.

Remember that you can still use type variables in static contexts if they are not defined at the level of the class. For example, you can have a static method parameterized with type `T` if that type parameter is declared at the level of the method.

### Methods may not clash after erasure

You are not allowed to declare methods that would clash after erasure (meaning that, after erasure, there would be two methods with the same signature).

Note that this includes bridge methods! If you get a compiler error about methods clashing after erasure, it's possible that the clash is generated by the bridge methods generated by the compiler. This is why it's important to have some understanding of what these bridge methods are.

### Exceptions and generics

It's not possible to throw objects of a generic class. This makes sense, because catching instances of a generic class with a specific type parameter would require information that is not available at runtime.

However, it is allowed to have a type variable in your `throws` declaration, as this is checked by the compiler.

## Resources

- Core Java SE 9 for the Impatient (book by Cay S. Horstmann)