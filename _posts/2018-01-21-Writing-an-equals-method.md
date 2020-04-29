---
layout: post
title: Writing an equals method - how hard can it be?
tags: java
toc: true
new_url: /java/equals/
new_title: Equals (Java)
---

If you've ever had to write or test an `equals` method, you may have gotten a feel for how complex this can get. This post will explain a number of things that can go wrong, offer solutions, and explain how a library called [EqualsVerifier](http://jqno.nl/equalsverifier/) can help you prevent unexpected behavior regarding object equality testing.

## Why override the default `equals` method anyway?

By default, every Java object has an `equals(Object o)` method which is inherited from the `Object` class. The implementation of this `equals` method compares objects using their memory locations, meaning that two objects are only considered equal if they actually point to the exact same memory location and are thus really one and the same object.

```java
@Test
public void test() {
    Object object1 = new Object();
    Object sameObject = object1;
    Object object2 = new Object();

    assertTrue(object1.equals(sameObject)); // this succeeds
    assertTrue(object1.equals(object2)); // this fails
}
```

If you want to define equality in such a way that two objects can be considered equal even if they don't point to the exact same memory location, you will need a custom `equals` implementation.

## The requirements for a good `equals` method

- Reflexivity: every object is equal to itself
- Symmetry: if a is equal to b, then b is also equal to a
- Transitivity: if a is equal to b and b is equal to c, then a is also equal to c
- Consistency: if a is equal to b right now, then a is always equal to b as long as none of their state that is used in the `equals` method has been modified
- Non-nullity: an actual object is never equal to `null`

## Introducing the `Point` class

The `Point` class is the class we will be using as an example throughout this post. It is a simple class representing a point on a two-dimensional grid by means of an x coordinate and a y coordinate. 

```java
public class Point {
    private int x;
    private int y;

    public Point(int x, int y) {
        this.x = x;
        this.y = y;
    }

    // getters and setters for x and y here
}
```

We want to consider two `Point` objects to be equal if and only if they have the same x coordinate and the same y coordinate. Therefore, we will attempt to write an equals method that accomplishes this.

## The journey to a "perfect" `equals` method

### Attempt #1

Well, our class is simple, so let's write a simple `equals` method. We add this method to our `Point` class:

```java
public boolean equals(Point other) {
    return (this.x == other.x && this.y == other.y);
}
```

Seems simple enough. Now, let's test our `equals` method:

```java
@Test
public void test() {
    Point point1 = new Point(1, 1);
    Point point2 = new Point(1, 1);
    List<Point> points = Arrays.asList(point1);
                
    assertTrue(point1.equals(point2)); // this succeeds
    assertTrue(points.contains(point2)); // this fails
}
```

What happened? Even though the `List` internally calls `equals` to check equality, it somehow doesn't consider `point1` and `point2` to be equal. 

One important thing to note is that the `contains` method takes an `Object` as its argument, which means that `point2` is passed as an `Object`. The following test shows that our current `equals` method doesn't handle this very well.

```java
@Test
public void test() {
    Point point1 = new Point(1, 1);
    Object pointObject = new Point(1, 1);
                
    assertTrue(point1.equals(pointObject)); // this fails
    assertTrue(pointObject.equals(point1)); // also fails
}
```

#### Short aside: method overloading and overriding rules in Java

When calling methods, Java determines the exact method to call in a way that can be confusing at first. There are basically two steps:

1. At compile time, the number and compile-time types of the arguments are used to determine the exact *signature* of the method that will be invoked.
2. At runtime, if the method to be invoked is an instance method, the actual method to invoke will be determined using dynamic method lookup based on the actual run time type of the object and the structure of the inheritance hierarchy.

For more info, check the post on [Java overloading, overriding and method hiding]({% post_url 2018-12-08-Java-overloading-overriding-method-hiding %}).

In the code above, we have two classes: `Object`, which has a method `equals(Object)`, and the class `Point`, which has a method `equals(Point)` and also inherits the `equals(Object)` method from `Object`. What happens in the code is the following:

- In the first assertion, we are calling a method with signature `equals(Object)` on an object with compile-time type `Point`. As `Point` does not implement a method with that signature, the best match is the `equals(Object)` method inherited from `Object`.
- In the second assertion, we are calling a method with signature `equals(Point)` on an object with compile-time type `Object`. As `Object` does not have an `equals(Point)` method, the best match at compile time is its `equals(Object)` method. And, beause `Point` (the run-time type of `pointObject`) does not override that method, the actual implementation that gets called is still the one defined in `Object`.

In both cases, `Object`'s `equals(Object o)` method tells us that `point1` and `pointObject` are not equal because they do not point to the exact same memory location.

### Attempt #2: actually overriding the default `equals(Object o)` method

Ok, so let's properly override `Object`'s `equals(Object)` method:

```java
@Override
public boolean equals(Object o) {
    if (o == null || o.getClass() != this.getClass()) {
        return false;
    }
    
    Point other = (Point) o;
    return (this.x == other.x && this.y == other.y);
}
```

Our tests from the previous attempt will now succeed. However, a new issue arises:

```java
@Test
public void test() {        
    Point point1 = new Point(1, 1);
    Point point2 = new Point(1, 1);
    Set<Point> points = new HashSet<Point>();
    points.add(point1);
            
    assertTrue(points.contains(point2)); // this fails
}
```
The issue here is that, while we did override the default `equals` method, we didn't override the default `hashCode` method as well. When our `HashSet` looks for `point2`, it only looks in the hash bucket that corresponds to `point2`'s hash code. Therefore, if two objects are considered equal, we must guarantee that their hash code will also be the same (`hashcode` needs to be consistent with `equals`). Note that it is ok for two different objects to have the same hash code, although it is better to avoid this as it can negatively impact the performance of data strucures that rely on hash codes.

### Attempt #3: overriding `hashCode` as well

Ok, let's add a `hashCode` method that is consistent with our `equals` method (this method was actually generated automatically by my IDE):

```java
@Override
public int hashCode() {
    final int prime = 31;
    int result = 1;
    result = prime * result + x;
    result = prime * result + y;
    return result;
}
```

The previous tests now pass, but we are still not quite there:

```java
@Test
public void test() {    
    Point point1 = new Point(1, 1);
    Set<Point> points = new HashSet<Point>();
    points.add(point1);
    
    point1.setX(2);
            
    assertTrue(points.contains(point1)); // this fails
}
```

This means that, although `point1` is the actual object we put in the set, the set doesn't seem to contain `point1` anymore. When we added `point1` to the set, it got assigned to a hash bucket based on its hash code. However, by changing the point's x coordinate, we have also changed its hash code. The `contains` method looks in the bucket corresponding to the new hash code and will not find our point there because it sits in the bucket corresponding to its original hash code.

### Attempt #4: making instance variables final

Ok, let's solve the previous issue by making the x and y coordinate `final`. This yields the following definition for our `Point` class:

```java
public class Point {
    private final int x;
    private final int y;

    public Point(int x, int y) {
        this.x = x;
        this.y = y;
    }

    // getters for x and y here
    
    @Override
    public boolean equals(Object o) {
        if (o == null || o.getClass() != this.getClass()) {
            return false;
        }
        
        Point other = (Point) o;
        return (this.x == other.x && this.y == other.y);
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + x;
        result = prime * result + y;
        return result;
    }    
}
```

Our current `equals` method is functionally equivalent to the one that my IDE generates automatically (using the default settings) and our `hashCode` method was already generated by my IDE. Therefore, if I let my IDE do the work for me, this is what I'm going to get by default. But is it enough?

Well, it is enough if we don't have to care about subclasses. If there are subclasses involved, things get a bit more interesting.

```java
@Test
public void test() {    
    Point point1 = new Point(1, 1);
    Point point2 = new Point(1, 1) {};

    assertTrue(point1.equals(point2)); // this fails
}
```

In this test, `point2` is an instance of an anonymous subclass of `Point` that adds no additional behavior or state. Here, `point2` has the exact same x and y coordinate as `point1` (it actually even has exactly identical state and behavior). However, they are not considered to be equal at all. This violates the contract for our `equals` method on `Point`, which we defined as "two `Point`s are equal if and only if they have the same x coordinate and the same y coordinate".

The reason why this test fails is that the `equals` method uses `getClass()` to verify if both objects belong to the same class and `getClass()` will actually return a different class for `point1` and `point2`.

Although you will probably not create a lot of trivial anonymous subclasses in real life, you may sometimes want to subclass a class that you defined a custom `equals` method for and allow objects of the subclass to equal objects of the superclass. Fortunately, we can provide this behavior by using `instanceof` instead of `getClass()`.

### Attempt #5: using `instanceof` instead of `getClass()`

```java
@Override
public boolean equals(Object o) {
    if (!(o instanceof Point)) {
        return false;
    }
    
    Point other = (Point) o;
    return (this.x == other.x && this.y == other.y);
}
```

This implementation's behavior is equivalent to that of the implementation generated by my IDE if I choose the option to use `instanceof` instead of `getClass()`. It passes all of our previous tests. In fact, as long as no subclass of `Point` ever overrides our `equals` (or `hashCode`) method, this will work just fine. This means that, when letting my IDE generate my `equals` and `hashCode` methods for me, I actually get a good implementation as long as I choose the right options.

One additional thing that the version generated by my IDE does is that it starts by checking for actual identity. This is a very inexpensive test, making this a good optimization if it is common for equal objects to also be identical.

```java
@Override
public boolean equals(Object o) {
    if (this == o) {
        return true;
    }

    if (!(o instanceof Point)) {
        return false;
    }
    
    Point other = (Point) o;
    return (this.x == other.x && this.y == other.y);
}
```

### What if a subclass needs to include additional state in `equals`?

Things get more complicated if a subclass is going to add state and we want to include this state in its `equals` method. For example, let's assume that we have an enum called `Color` and we create a class `ColorPoint` that extends the `Point` class with a specific color for a point.

```java
public enum Color {
    BLUE, RED, YELLOW, GREEN;
}

public class ColorPoint extends Point {
    private final Color color;

    public ColorPoint(int x, int y, Color color) {
        super(x, y);
        this.color = color;
    }
    
    // getter for color
}
```

Now, what if we want to include the color in the `equals` method so that a `ColorPoint(1, 1, Color.RED)` is not equal to a `ColorPoint(1, 1, Color.BLUE)`? Well, there is a way to accomplish this. It is also described in [this article](http://www.artima.com/lejava/articles/equality.html).

An important remark is that, in this solution, a `Point` will never be able to be equal to a `ColorPoint`. The reason for this is that we need our `equals` method to be transitive. If we would follow the contract we envisioned for the `equals` method of `Point` (two `Point`s are equal if and only if they have the same x coordinate and the same y coordinate), this would mean that a `Point(1, 1)` is equal to a `ColorPoint(1, 1, Color.RED)` and to a `ColorPoint(1, 1, Color.BLUE)`. However, transitivity would then imply that a `ColorPoint(1, 1, Color.RED)` and a `ColorPoint(1, 1, Color.BLUE)` must be equal to each other, which is exactly what we didn't want.

Because of this, this solution could cause unexpected behavior in code that depends on the contract that "two `Point`s are equal if and only if they have the same x coordinate and the same y coordinate".

The solution involves introducing a `canEqual` method and letting custom `equals` methods call that method on the *other* object.

```java
public class Point {
    // ...
    
    @Override
    public boolean equals(Object o) {
        if (!(o instanceof Point)) {
            return false;
        }
        
        Point other = (Point) o;
        
        if (!other.canEqual(this)) {
            return false;
        }
        
        return (this.x == other.x && this.y == other.y);
    }
    
    public boolean canEqual(Object o) {
        return (o instanceof Point);
    }    
    
    // ...
}

public class ColorPoint extends Point {
    // ...

    @Override
    public boolean equals(Object o) {
        if (!(o instanceof ColorPoint)) {
            return false;
        }
        
        ColorPoint other = (ColorPoint) o;
        
        if (!other.canEqual(this)) {
            return false;
        }
        
        return (this.color == other.color 
                && super.equals(other));
    }
    
    public boolean canEqual(Object o) {
        return (o instanceof ColorPoint);
    }
    
    // ...
}
```

The `Point` and `ColorPoint` classes both satisfy all of the previous tests. If we would create a new subclass of `Point` or `ColorPoint` without overriding `equals`, `canEqual` or `hashCode`, instances oft the subclass can still be equal to instances of the superclass. If we want to create a new subclass of `Point` or `ColorPoint` that adds additional state and includes this state in its `equals` method, we need to override both `equals` and `canEqual`.

As stated before, the only big drawback of this approach is the fact that it breaks our original contract saying that "two `Point`s are equal if and only if they have the same x coordinate and the same y coordinate". A piece of code operating on `Point` instances can not longer make the assumption that, if two `Point`s are not equal to each other, there must be some difference in their x or y coordinates. Indeed, this assumption no longer holds if some of the instances are `ColorPoint` instances. This is essentially a violation of the [Liskov substitution principle](https://en.wikipedia.org/wiki/Liskov_substitution_principle), although the article linked above doesn't seem to agree.

```java
@Test
public void test() {
    Point point1 = new Point(1, 1);
    Point point2 = new ColorPoint(1, 1, Color.BLUE);
            
    assertTrue(point1.getX() == point2.getX());
    assertTrue(point1.getY() == point2.getY());
    assertTrue(point1.equals(point2)); // this fails
}
```

### A simpler solution for subclasses that include additional state in `equals`

The previous approach is relatively complex, mostly because we wanted to allow subclass objects to be equal to superclass objects as long as they don't need to include additional state in their equals method. 

If we're okay with subclass objects never being equal to superclass objects, we can just go ahead and use the `getClass()` approach.

## How to handle this in practice

In practice, the approach that you'll typically want to follow is this:

1. Let your IDE generate your `equals` (and `hashCode`) methods for you, using `instanceof` instead of `getClass()`.
2. Either make your class `final` or make your `equals` and `hashCode` methods `final`.

Note that the two options outlined in step 2 have different effects:

-  Making your class `final` prevents any issues with subclasses by simply not allowing subclasses for your class.
- Making your `equals` and `hashCode` methods `final` prevents subclasses from overriding your `equals` and `hashCode` methods and including additional state in them.

In cases where this is not sufficient (you want subclasses to include additional state in their `equals` method), consider using the solution involving the `canEqual` method or the simpler solution if you're ok with subclass instances never being equal to superclass instances.

## Testing your `equals` methods

Testing an `equals` method by hand is a tedious task that will likely lead to pages and pages of error-prone testing code. Fortunately, there is a better solution: the [EqualsVerifier](http://jqno.nl/equalsverifier/) library by Jan Ouwens. Using it is simple:

```java
@Test
public void equalsContract() {
    EqualsVerifier.forClass(Point.class).verify();
}
```

It uses reflection to inspect your class and test its `equals` and `hashCode` methods with 100% coverage. It recognizes all of the possible issues that were outlined in this article (and some others as well). If you're confused by an error message it produces, have a look at [this overview](http://jqno.nl/equalsverifier/errormessages/). If you understand why EqualsVerifier complains about a certain issue but you need it to be less restrictive, you can pass it an additional option to make it ignore that issue. This library should be able to make hand-written `equals` tests a thing of the past.

## Resources

- [EqualsVerifier](http://jqno.nl/equalsverifier/)
- [How to Write an Equality Method in Java](http://www.artima.com/lejava/articles/equality.html)
- Core Java SE 9 for the Impatient (book by Cay S. Horstmann)
- [Overloading in the Java Language Specification](https://docs.oracle.com/javase/specs/jls/se10/html/jls-8.html#jls-8.4.9)