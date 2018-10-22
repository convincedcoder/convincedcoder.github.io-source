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
public abstract class Animal {    
    public abstract void makeSound();
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
public class AnimalWrapper <T extends Animal> {    
    private T wrappedAnimal;
    
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

## Type erasure

