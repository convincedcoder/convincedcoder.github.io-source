---
layout: post
title: TypeScript basics
tags: typescript javascript
toc: true
---

TypeScript is an open source programming language created and maintained by Microsoft. It is based on JavaScript and it extends the JavaScript language with static typing, classes, generics, etc.

TypeScript's syntax is a strict superset of JavaScript, meaning that any valid JavaScript syntax is in principle also valid TypeScript syntax. Note, however, that this does not mean that TypeScript's compiler will be happy with every piece of valid JavaScript. As an example, see the section on `type inference` below. TypeScript puts some restrictions on the way your code deals with types, with the goal of preventing mistakes and unexpected behavior.

Instead of requiring a separate interpreter, Typescript compiles into plain JavaScript which can be executed by browsers, Node.js, or other JavaScript engines. Note that syntactically valid TypeScript code with compiler errors can still be compiled to JavaScript. The Typescript compiler is only warning us that we will likely see some unexpected behavior.

## Most important features

### Type annotations

Let's start from a simple piece of JavaScript where a function `greet` takes a string `person` and shows a message greeting the person.

```typescript
function greet(person) {
    alert('Hello, ' + person);
}

let user = 'user';

greet(user); // shows message saying "Hello, user"
```

This `greet` function works when we pass it a string, but nothing prevents us from making a mistake and passing something else, yielding unexpected results.

```typescript
let user = { name: 'visitor' };

greet(user); // shows message saying "Hello, [object Object]"
```

Using TypeScript's type annotations, we can actually enforce that the `person` parameter should be a string.

```typescript
function greet(person: string) {
    alert('Hello, ' + person);
}

let user = { name: 'visitor' };

greet(user); // typescript compiler error (type mismatch)
```

### Type inference

When you declare a variable, TypeScript will infer the variable's type and perform type checking based on that.

```typescript
let user = 'test';

// some other code

user = { name: 'test' }; // typescript compiler error
```

Here, TypeScript infers that the type of the `user` variable is `string`. It then prevents you from assigning values of another type to that variable, as that is typically a source of errors and is generally considered bad practice. JavaScript is not able to enforce these kinds of restrictions.

You can also explicitly specify the type of a variable.

```typescript
let user: string = 'test';
```

### Interfaces

Interfaces allow you to describe what an object should look like. In the following example, we are defining `Person` as an object that has a firstName and lastName property (both strings).

```typescript
interface Person {
    firstName: string;
    lastName: string;
}

function greetPerson(person: Person) {
    alert('Hello, ' + person.firstName + ' ' + person.lastName);
}

let user = { firstName: 'Test', lastName: 'User' };

greetPerson(user);
```

We don't need to make it explicit that `user` is a `Person` when we declare it. When we pass `user` to the `greet` function, TypeScript will automatically check if it has the right structure.

### Classes

TypeScript supports class-based object-oriented programming.

Let's look at an example of what a class definition looks like.

```typescript
class Student {
    public firstName: string;
    public lastName: string;
    public fullName: string;

    constructor(firstName: string, lastName: string) {
        this.firstName = firstName;
        this.lastName = lastName;

        this.fullName = firstName + ' ' + lastName;
    }
}

let user = new Student('Jane', 'User');
```

The `Student` class defines some name properties and a constructor for creating new instances.

If you don't like the repetition in the properties and constructor, TypeScript also allows you to explicitly declare properties in the constructor parameters. They are then called `parameter properties`. The following code is equivalent to the code above:

```typescript
class Student {
    public fullName: string;

    constructor(public firstName: string,
            public lastName: string) {
        this.fullName = firstName + ' ' + lastName;
    }
}

let user = new Student('Jane', 'User');
```

Note that classes and interfaces play well together. Because a `Student` has a `firstName` and `lastName`, we can pass it to a function expecting a `Person` (like for example our `greetPerson` function).

### Access modifiers and readonly

Class members (properties, constructors and methods) are `public` by default but can also be marked `private` (cannot be accessed from outside the class) and `protected` (like `private`, but can also be accessed from deriving classes).

Properties can also be made `readonly`, meaning that they cannot be changed and they must be initialized at their declaration or from the constructor.

### Classes implementing interfaces

Classes can implement interfaces. This way, an interface can enforce that a class meets a particular contract.

```typescript
interface Person {
    firstName: string;
    lastName: string;
}

class Student implements Person {
    public fullName: string;

    constructor(public firstName: string,
            public lastName: string) {
        this.fullName = firstName + ' ' + lastName;
    }
}
```

Interfaces can also describe methods that a class should implement. Note that interfaces only describe the public contract of a class, you cannot use them to constrain the internal implementation of a class.

### Inheritance

TypeScript provides inheritance for interfaces and classes using the `extends` keyword.

The following code provides an example of interface inheritance.

```typescript
interface Person {
    firstName: string;
    lastName: string;
}

interface Employee extends Person {
    company: string;
}

let employee: Employee = { company: 'ACME'} // compiler error
```

The code yields a compiler error because the object literal we are passing has no `firstName` and `lastName`.

Class inheritance lets you inherit and override methods.

```typescript
class Animal {
    makeNoise() {
        console.log(`Hello there!`);
    }
}

class Dog extends Animal {
    makeNoise() {
        console.log('Woof! Woof!');
        super.makeNoise();
    }
}

let dog = new Dog();

dog.makeNoise();
// Woof! Woof!
// Hello there!
```

### Generics

TypeScript provides generics that you can use to create reusable components.

```typescript
class Wrapper<T> {
    constructor(public wrapped: T) {}

    public replaceWrapped(newWrapped: T) {
        this.wrapped = newWrapped;
    }
}

let wrapper = new Wrapper('test');
wrapper.replaceWrapped(1); // error: type mismatch
```

## Getting started

The [TypeScript quickstart page](https://www.typescriptlang.org/samples/index.html) contains some resources to get you started, including frameworks like Angular that use TypeScript.

If you are just looking for a quick way to play around with the language, you can use the [Playground](https://www.typescriptlang.org/play/index.html).

I only gave a very basic overview of the most important features here. For more details regarding the language, you can take a look at the [Handbook](https://www.typescriptlang.org/docs/handbook/basic-types.html).