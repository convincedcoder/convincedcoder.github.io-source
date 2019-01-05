---
layout: post
title: Java streams
tags: java
toc: true
---

Java 8 introduced the concept of *streams* into the language. Streams offer a powerful way to process sequences of values using clear and concise syntax. This post will highlight some useful features of streams and provide examples of how to use them.

## Streams versus simple iteration

In order to get a feel for how streams compare to iteration, let's look at a simple example of iteration. Suppose we have a simple list of words:

```java
List<String> words = Arrays.asList("this", "is", "an", "example");
```

Now, let's count all of the words in the list that are longer than 3 characters.

```java
long numberLongWords = 0;

for (String word: words) {
    if (word.length() > 3) {
        numberLongWords++;
    }
}
```

This is classic *imperative* programming: we give Java detailed instructions of exactly what to do when in order to count the long words in the list. A reader of the code will pretty quickly understand what this simple code does, as this is a common pattern. However, you can already see that the intent of the code (*what* the code does) gets a bit buried under the implementation (*how* the code does it).

Streams provide a more *declarative* way to specify operations like these. The stream syntax focuses mostly on what to do, not how to do it. The following code performs the same operation as above, but this time using streams:

```java
numberLongWords = words.stream()
        .filter(word -> word.length() > 3)
        .count();
```

Because we are specifying what to do rather than how to do it, it becomes easier to change the exact way that the calculation is performed. For example, if we simply use the `parallelStream()` method instead of the `stream()` method, the filtering and counting happens in parallel (using multiple threads).

Here, we obtained a stream from a collection, and you may get the idea that streams are very similar to collections. However, there are some significant differences between streams on the one hand and collections on the other:

- A stream does not necessarily store its elements. They can also be generated on demand. There are even situations when storing all of the elements would be impossible. An example of this are *infinite* streams, which do not have a finite number of elements.
- Operations on a stream don't change the stream itself. Instead, they generate a new altered stream.
- Stream operations are `lazy` when possible. This means results are only calculated when needed. For example, if you have a stream expression that filters a list of words to only keep the long words and then takes the first five words, the filter will only be executed until the first five matching words are found. This also makes it possible to perform finite operations on infinite streams.

A stream expression is typically composed of three stages:
- Creating the stream
- *Intermediate operations* that transform the stream into new streams
- A *terminal operation* that turns a stream into a non-stream result. Because this is the part that determines what result we need, this is also the part that determines exactly which lazy operations are executed.

## Creating streams

We already saw how to obtain a stream from a collection.

If you want to create a stream from an array, you can use the static `Stream.of()` method and pass the array to it. That method has a varargs parameter, so instead of an actual array you can also pass it a variable number of arguments that will make up the stream. If you already have an array but want a stream representing only a part of it, you can use the method `Arrays.stream(array, from, to)` to get such a stream.

Sometimes, you may need an empty stream. You can easily create such an empty stream by calling `Stream.empty()`.

Above, we talked about infinite streams. The first way to create such a stream is to use the `Stream.generate()` method, which takes a `Supplier<T>` that generates the actual values. Whenever a new value must be generated for the stream, that supplier function is used.

```java
Stream.generate(() -> "constant"); // infinite constant stream
Stream.generate(Math::random); // infinite stream of random values
```

There are also situations where the next value of a stream needs to depend on the previous value. As an example, see the following code that produces an infinite list of powers of 2.

```java
Stream<Integer> powersOfTwo = 
        Stream.iterate(2, n -> n * 2);
```

Since Java 9, there is also an overload for this method that takes 3 arguments instead of 2. The added argument (in the middle, not at the end) is a `Predicate` that specifies when the generation of new elements should finish. If the `Predicate` fails for a newly generated element, that element is not added to the stream and the generation of new elements is stopped.

```java
Stream<Integer> powersOfTwo = 
        Stream.iterate(2, n -> n < 500, n -> n * 2);
```

## Intermediate operations

As we said before, intermediate operations are operations that take streams and turn them into new streams. One example we saw of such an intermediate method is the `filter` method that turns a stream into a new stream that only contains elements matching a certain `Predicate`.

// also include extracting substreams etc.

## Collecting stream results

## Transforming streams into Maps

## Grouping, partitioning and downstream collectors

## The `reduce` method

## Streams of primitive types

## Parallel streams

## Should you suddenly replace all of your loops with streams?

see second resource

## Resources

- Core Java SE 9 for the Impatient (book by Cay S. Horstmann)
- [3 Reasons why You Shouldn’t Replace Your for-loops by Stream.forEach()](https://blog.jooq.org/2015/12/08/3-reasons-why-you-shouldnt-replace-your-for-loops-by-stream-foreach/)