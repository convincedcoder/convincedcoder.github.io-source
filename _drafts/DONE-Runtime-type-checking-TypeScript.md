---
layout: post
title: Runtime type checking for TypeScript applications
tags: typescript javascript
toc: true
---

This post will discuss some possibilities for adding runtime type checking to TypeScript applications.

## Isn't TypeScript enough?

You might wonder why it's even needed to add additional type checking if you're already using TypeScript. Isn't type checking exactly what TypeScript is about? Well, TypeScript only performs static type checking at compile time. The generated JavaScript, which is what actually runs when you run your code, does not know anything about the types. While this works fine for type checking within your codebase, it doesn't provide any kind of protection against malformed input.

An example is an API that you expose. Even though you can use TypeScript to describe the input structure that your code should expect, TypeScript itself doesn't provide any way to check that the input that is provided at runtime actually matches that structure. This is by design: the TypeScript team has limited their scope to compile-time checking only. Therefore, if you receive any kind of input from the outside world, it is typically a good idea to use additional runtime type checking.

As an example to use throughout this post, let's say we have a simple API accepting a person with the following structure:

```typescript
interface Person {
    firstName: string;
    lastName: string;
    age: number;
}
```

## Manual checks in custom code

An obvious approach here would be to manually write code that checks the input for the existence of the required properties and checks their type as well. However, writing such code can be tedious and error-prone. There is also a possibility for the error-checking code to get out of sync with your static types as changes are made to the codebase.

## Manually generating JSON Schemas

JSON Schemas are a standard way of constraining the format of JSON input that you receive. Several non-TypeScript applications already use this approach to validate received input.

A very simple JSON Schema describing our input could be the following:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "required": [
    "firstName",
    "lastName",
    "age"
  ],
  "properties": {
    "firstName": {
      "type": "string"
    },
    "lastName": {
      "type": "string"
    },
    "age": {
      "type": "integer",
      "minimum": 0
    }
  }
}
```

You may have noticed that this JSON Schema is actually stricter than our original TypeScript type, as we are now requiring `age` to be an integer with at least a value of zero. This is perfectly fine: as long as our runtime type checking is at least as restrictive as our static type checking, we are sure that the data we receive fits the static type and the static type checking within our codebase is sufficient to prevent further type errors. This does not work if the runtime type checking is less strict than the static checking. For example, if our JSON Schema allows `firstName` to be anything, some of our code that depends on it being a string may fail.

Using JSON Schemas definitely has some advantages. There are lots of libraries that you can use to validate input based on the schema. Because the schema itself is JSON, it's also easy to store or share.

A drawback of JSON Schemas is that they can become very verbose and they can be tedious to generate by hand.

## Automatically generating JSON Schemas

There are libraries that automatically generate JSON Schemas for you based on your TypeScript code. One of those libraries is [typescript-json-schema](https://github.com/YousefED/typescript-json-schema). It works either programmatically or from the command line.

This library is intended to be run on some existing code containing the types to generate JSON Schemas for. That means that, if you are changing your code, you need to make sure that your JSON Schemas are generated again if needed.

As an alternative, there are also tools that automatically infer JSON Schemas from JSON input you provide. Of course, this doesn't use the type information you have already defined in your TypeScript code and can lead to errors if there is a mismatch between the input JSON you provide to the tool and the actual TypeScript type definitions.

## A transpilation approach

Using JSON Schemas is not the only way to check types at runtime. The [ts-runtime](https://github.com/fabiandev/ts-runtime) library uses a completely different approach. Like typescript-json-schema, it processes your existing TypeScript code. However, instead of generating some kind of schemas, it actually transpiles the code into equivalent code that contains runtime type checks.

Let's say that we start from the following TypeScript code:

```typescript
interface Person {
    firstName: string;
    lastName: string;
    age: number;
}

const test: Person = {
    firstName: "Foo",
    lastName: "Bar",
    age: 55
}
```

If we run ts-runtime on this code, we get the following transpiled code:

```typescript
import t from "ts-runtime/lib";

const Person = t.type(
    "Person",
    t.object(
        t.property("firstName", t.string()),
        t.property("lastName", t.string()),
        t.property("age", t.number())
    )
);

const test = t.ref(Person).assert({
    firstName: "Foo",
    lastName: "Bar",
    age: 55
});
```

A drawback of this approach is that you have no control over the locations where the type checking happens: every type check is converted into a runtime type check. This is typically overkill, as you also need runtime type checking at the boundaries of your program to check input structure.

Also note that this library is currently still in an experimental stage and not recommended for production use.

## Combining runtime and static type assertion using io-ts

Where ts-runtime generates runtime type checks based on static ones, [io-ts](https://github.com/gcanti/io-ts) takes the opposite approach. You use this library to define runtime type checks, which look very similar to the ones generated by ts-runtime, and the library actually allows TypeScript to infer the corresponding static types automatically.

This is what our `Person` type looks like in io-ts:

```typescript
import t from "io-ts";

const PersonType = t.type({
  firstName: t.string,
  lastName: t.string,
  age: t.refinement(t.number, n => n >= 0, 'Positive')
})
```

Note that, like in our JSON Schemas example, we added the restriction that the person's age should be at least zero.

In our code, we can use this runtime type to check input against the `Person` type. Once we have defined this runtime type, we can also extract the corresponding static type from it.

```typescript
interface Person extends t.TypeOf<typeof PersonType> {}
```

The above code is equivalent to our regular interface definition:

```typescript
interface Person {
    firstName: string;
    lastName: string;
    age: number;
}
```

This is a very nice approach for working with interfaces. Because the static types are inferred from the runtime types, both kinds of types do not get out of sync when you are changing your code. The library also allows for a lot of flexibility when defining types, including the definition of recursive types.

A drawback of io-ts is that it requires you to define your types as io-ts runtime types, which does not work when you are defining classes. One way to handle this could be to define an interface using io-ts and then make the class implement the interface. However, this means you need to make sure to update the io-ts type whenever you are adding properties to your class.

## A TypeScript alternative to Java's Bean Validation

As a final candidate, I am including the [class-validator](https://github.com/typestack/class-validator) library. This library uses decorators on class properties, making it very similar to Java's JSR-380 Bean Validation 2.0 (implemented by, for example, Hibernate Validator). It is part of a family of libraries that also includes [typeorm](https://github.com/typeorm/typeorm) (ORM, similar to Java's JPA) and [routing-controllers](https://github.com/typestack/routing-controllers) (similar to Java's JAX-RS for defining APIs).

As an example, consider the following code:

```typescript
import { plainToClass } from "class-transformer";

import { 
    validate, IsString, IsInt, Min 
} from "class-validator";

class Person {
    @IsString()
    firstName: string;

    @IsString()
    lastName: string;

    @IsInt()
    @Min(0)
    age: number;
}

const input: any = {
    firstName: "Foo",
    age: -1
};

const inputAsClassInstance = plainToClass(
    Person, input as Person
);

validate(inputAsClassInstance).then(errors => {
    // handle errors if needed
});
```

Note that class-validator needs actual class instances to work on. Here, we used its sister library class-transformer to transform our plain input into an actual `Person` instance. That transformation in itself does not perform any kind of type checking.

This approach works well with classes, but setting up classes with the decorators that class-validator needs (an alternative is defining schemas manually) and converting the objects you receive to instances of those classes can feel like overkill if all you need to check is a simple interface.