---
layout: post
title: Creating boundaries to decouple parts of your system
tags: software-architecture
toc: true
new_url: /architecture-design/architectural-boundaries/
new_title: Architectural boundaries
---

As we saw in the previous post, software architecture is all about decoupling different parts of your system through boundaries. This post presents some ideas for actually creating these boundaries.

## Source-level boundaries

This section talks about some ways to introduce boundaries at the level of the source code, using the mechanisms the programming language provides.

### Abstraction

They can also use the Dependency Inversion Principle (from the [SOLID principles]({% post_url 2019-04-13-SOLID-principles %})) to control the direction of the dependency. For example, if the business logic calls persistence code, we could let the business logic part specify the interface that the persistence code must implement. This way, while the business logic is calling the persistence code, it is the persistence code that is dependent on the business logic part of the system.

If the abstraction introduced by a full-fledged source-level boundary would be too much, it may be interesting to consider the [Facade pattern](https://en.wikipedia.org/wiki/Facade_pattern) as an alternative. When using the Facade pattern, you take a complex subsystem and put it behind a class that exposes a nice interface to that subsystem. This does not provide the same amount of separation as the use of abstractions and does not allow you to control the direction of dependencies, but it could help with managing complexity and potentially prepare for the creation of a full boundary.

### Encapsulation



### Data transfer objects



### Combining the above building blocks

strongest boundary will use all of them!

## Decoupling and the the database

### Boundaries between the domain and the database

In most applications, it makes sense to draw a boundary between the actual domain logic and the database (unless, of course, your application is a thin layer around the database that doesn't really have any domain logic).

One widespread convention is the *Repository* pattern. Here, all interaction with the database is encapsulated inside Repository classes. The domain logic then interacts with these classes. This helps to keep any database-specific stuff out of the domain logic.

```typescript
interface UserRepository {
    getUsers(): Promise<User[]>;
    getUser(id: string): Promise<User>;
    saveUser(user: User): Promise<void>;
    deleteUser(id: string): Promise<void>;
}

class SqlServerUserRepository implements UserRepository {
    // implement UserRepository methods by talking to SQL Server
}

class UserService {
    constructor(private repository: UserRepository) { }

    async updateName(id: string, newName: string) {
        const user = await this.repository.getUser(id);
        user.setName(newName);
        await this.repository.saveUser(user);
    }
}
```

If the domain logic is using the repository interface, then it also becomes easy to swap out the `SqlServerUserRepository` for a different implementation, for example an in-memory repository for testing purposes.

```typescript
class InMemoryUserRepository implements UserRepository {
    // implement UserRepository methods using in-memory storage
}
```

### Separation at the database level

For larger systems, it can make sense to separate different parts of the application down to the database level. Each part uses different tables or a different database, with no links between data belonging to different parts. This kind of separation is considered good practice when setting up a microservices architecture. You can also do this in monolithic applications, potentially as a stepping stone towards a feature microservices architecture.

Separation at the database level makes it easier to reason about separate parts of the application without having to think about other parts. It also provides more flexibility to change the schema or database technology for a certain part o the system.

When drawing boundaries down to the database level, some data that is relevant to two parts of the system might exist on both sides of the boundary between them. The last part of this post covers that situation in a bit more detail.

## Decoupling and the web

### Decoupling the domain from the web

One boundary that almost always makes sense to draw is the separation between your domain and the actual user interface that the user interacts with. Is it typical to see `Controller` classes (some other terms are used as well) that take care of the interaction with the user and delegate all real work to the code implementing the actual business logic. In principle, none of your business logic should be aware of how it is shown to the user, including whether or not the UI is a web UI.

### Different representations of objects

As different parts of the system have different goals, they may also need different representations of the same object. When doing server-side rendering, it often makes sense to have a separate view model that simply holds the data to be shown. Data in the view model could be a transformed version of the data obtained from the domain model (e.g. formatting a date) or could aggregate data from several domain objects. 

In the same way, data returned from the API could have a different format or structure than the actual domain objects inside the business logic part of the application. Ideally, the data returned from APIs (or expected by APIs) will be aligned with what the consumers of the API care about.

Even then, if your frontend is a single-page application getting data from the backend over an API, feel free to create separate representations of that data that are more comfortable for the rest of the frontend to work with.

### Micro frontends

When thinking of microservices, people typically think about large backend systems made up of several small services. When a call is made to the backend, those services collaborate to process the call. But what about the frontend?

What often happens is that the frontend sitting on top of such a microservices architecture is a single, large and feature-rich single-page app cutting across all of the functional areas represented by the backend microservices. The problem is that this frontend can become so big that it's difficult to maintain. It is often also developed by a separate team, meaning that that team needs to coordinate with the backend teams when building functionality.

There is, however, an alternative approach called *Micro Frontends*. Here, the frontend is split into different parts in the same way that the backend is. Doing this allows teams to be responsible for their functional part of the application across the entire stack, from the database up to the frontend. The actual frontend that the user interacts with is then stitched together from the functional part developed by different teams. If you want to investigate this in a bit more detail, you can look [here](https://micro-frontends.org/) and [here](https://medium.com/@tomsoderlund/micro-frontends-a-microservice-approach-to-front-end-web-development-f325ebdadc16).

## Decoupling from frameworks and libraries

When using a framework or library, you should take care not to let too much of your code depend on it. External dependencies evolve in a way you do not control. Their newest version including some critical bugfixes may introduce breaking changes in an API you use or even remove the functionality you use. They may stop being properly maintained. These kinds of changes, as well as changes in your own requirements, can force you to change the way you use the dependency or even replace it with another dependency.

If you introduce a new dependency to the system, consider creating a boundary around it that decouples the rest of the system from it. The public interface of that boundary should be written in terms of what your system needs from the dependency, while the logic inside the boundary will be specific to the interaction with that particular dependency. This way, if the API of the dependency changes or you replace it, the boundary protects you from having to change all code that used the dependency. As long as you can fulfill the contract specified by the public interface of the boundary, no code outside of the boundary has to be aware of the change.

Your can also use the boundary to create some automated test for the specific functionality that your system needs to get from the boundary. By testing against the boundary, you don't have to change your tests in order to be able to test a new version of the dependency or even a replacement.

Having this kind of boundary is especially important if you consider the dependency to be a temporary solution that is sufficient for now but will most likely need to change in the future. By putting the boundary in place, you can make that change will be a non-event instead of something that requires changes to all code that used that particular dependency's API or, even worse, depended on some concepts specific to that dependency. The boundary allows you to avoid premature complexity by going for a simple solution, while keeping your options open regarding the upgrade to a more complex solution.

Be extra careful when dealing with frameworks. Frameworks tend to dictate the structure of your application and may even ask you to base your domain objects on the abstractions they provide. If you allow this, it will be very difficult to get the framework out afterwards. One thing that could help here is to let the framework operate on some kind of separate representation of you domain objects instead of the domain objects themselves. Your boundary could then take care of performing the necessary translations between that separate representation and the actual domain objects.

## Decoupling tech stacks

In an architecture with (micro)services, the service boundaries decouple the services down to the level of their tech stack. Different services should only be coupled through the API calls or events they use to communicate with each others. Sharing anything else, including the database, is considered best practice. This has the advantage that the team maintaining a service has the freedom to choose or change the technology used by the service based on what makes most sense for the service. Some service may use a relational database while another one uses a document store. A service providing information about the relationships between different users could switch to a graph database without any other service being affected by the change. A service performing very heavy calculations could switch to a different, more low-level programming language.

While there is definitely some value in this freedom regarding the tech stack, a system composed of microservices that are all using wildly different technologies could make it difficult to move developers between services if needed. Depending on how separated the different teams really are (maybe each team does its own hiring? what about operations?), it could be a good idea to align across teams regarding certain aspects of the technical stack.

## Boundaries and duplication

### False duplication

Sometimes, the fear of violating DRY (Don't Repeat Yourself) by having duplication in your system can lead to unnecessary coupling. You should especially watch out for *false duplication*. Real duplication, which is what the DRY principle wants you to avoid, means that the duplicates always have to change together. If different "copies" may need to change at different times or for different reasons, we are not talking about real duplication anymore. The fact that two things are the same at this moment does not necessarily mean that they are real duplicates and that that apparent duplication is a bad thing. Attempts to get rid of false duplication tend to lead to unnecessary coupling through shared code, which will then come back to bite you when the "duplicates" suddenly need to change independently of each other.

False duplication is common when applying vertical slicing, where certain functionalities may start out looking similar but end up diverging significantly. It can also appear when applying horizontal slicing. For example, the apparent duplication between a database row and the corresponding structure we send to the UI will likely be false duplication. It may be tempting to pass the database row directly to the UI, and in some cases this can be a good idea, but it isn't hard to imagine that the structure of the data to show in the UI or the structure of the data in the DB could have to change independently of each other.

### Data duplication and bounded contexts

When different functional parts of the system are separated from each other down to the level of using separate databases, it is possible that there will be some duplication of data at both sides of the boundary. This is common when dealing with microservices. Different services may store data regarding the same thing, for a variety of reasons. Often, however, the data that different services store for that same thing will depend on what the specific service needs. The same domain concept may have completely different representations on different sides of the boundary. In that case, you could argue that this is again a case of false duplication, especially because data on different sides of the boundary will not necessarily change the same time and for the same reasons. Each side of the boundary is, in Domain-Driven-Design terms, a [Bounded Context](https://www.martinfowler.com/bliki/BoundedContext.html). 

As an example, consider an e-commerce system using a microservices architecture. Suppose that we have a Customer service which manages a whole lot of data about each customer, including their shipping address. Let's say we also have an Order service, which maintains orders and needs the shipping address of the customer. One thing the Order service could do is store a customer ID with each Order. Then, whenever all information for an order needs to be retrieved, it could retrieve the customer's address from the Customer service. This approach has some drawbacks. First of all, if the Customer service is unavailable or the customer has been deleted, the Order service has no idea which address to use for the order. Additionally, if the customer's address changes, the current shipping address for a customer may not be the address that a certain order was shipped to. A better approach might be to let the Order service store not only the customer ID but also the customer's shipping address. If the order is retrieved from the Order service later on, the service will use the shipping address that it has stored.

Some services may even be entirely focused on aggregating bits of data from other services. Going back to the e-commerce site, let's say we need to be able to view some general info about the most recent orders of customers, allowing to filter customers by some key attributes. It can make sense to put this functionality in a separate Insights service. That service can gather data from the Customer and Order services (ideally with Customer and Order pushing updates through API calls or events) and then store it in a format that includes exactly the required information. Then, when the Insights service retrieves a request, it can gather the required data directly from its own database.

## Resources

- Clean Architecture (book by Robert C. Martin)
- [Micro Frontends](https://micro-frontends.org/)
- [Micro frontends—a microservice approach to front-end web development](https://medium.com/@tomsoderlund/micro-frontends-a-microservice-approach-to-front-end-web-development-f325ebdadc16)
- [Our Software Dependency Problem](https://research.swtch.com/deps)
- [BoundedContext](https://www.martinfowler.com/bliki/BoundedContext.html)
- [Pattern: Database per service](https://microservices.io/patterns/data/database-per-service.html)
- [How to keep relationship integrity with Microservice Architecture](https://softwareengineering.stackexchange.com/questions/381279/how-to-keep-relationship-integrity-with-microservice-architecture)