---
layout: post
title: Software architecture and boundaries
tags: software-architecture
toc: true
---

This post covers some general ideas on software architecture, with a specific focus on the boundaries between different parts of the system.

## Architecture is about boundaries

In essence, a system's architecture is what defines the shape of the system. More specifically, a system's architecture defines how the system is divided into components, how those components are arranged, what of kinds boundaries exist between different components and how the components communicate across those boundaries. Basically, it's all about the way we are using boundaries to separate parts of the system that shouldn't know too much about each other.

The purpose of this kind of separation is to make it easier to develop, deploy and maintain the system. Especially the maintenance part is critical, because this is typically the most risky and expensive part. Often, the first version of a system making it to production is only the start, and most of the work will happen after that. Additional requirements will be added, existing functionality will need to be changed, etc. Adequate boundaries will provide the necessary flexibility to make this kind of maintenance possible, allowing the system to grow without exponentially increasing the work needed to add or adjust a piece of functionality.

## Boundaries allow for change

Boundaries between different parts of the system allow us to create independence between these parts, reducing coupling. For example, we could create our boundaries in such a way that our main business logic is completely separated from the persistence logic. Decoupling different parts of the system like this is what allows flexibility. If the business logic doesn't have any idea about the database we use (or potentially even the fact that we use a database), this means we have the flexibility to change the database that our system depends on without having to make any kind of changes to the main business logic. Or, if we need to make changes to the main business logic that do not influence the kind of data that needs to be persisted, we can make those changes without the persistence code having to know anything about them.

The creation of boundaries in our system allows us to group together things that change at the same rate and for the same reasons, while separating things that change at different rates and for different reasons. We can use boundaries to separate high level policy (the main business logic of our application) from low-level details like the communication with the user and other systems. We could also separate different functional parts of the application so they can be changed independently. Boundaries can also allow different parts of the system to be developed by different teams while keeping the required amount of coordination between teams manageable.

Boundaries also allow you to delay decisions until the last possible moment. As an example, you could potentially build all of the business logic without connecting to a database, simply writing code against some persistence interfaces describing what kind of data you will need to store and retrieve, and thus delay the decision of which kind of database to use. If you need some kind of persistence to get a working system, for example so you are able to show progress to management and gather valuable feedback from users, you could foresee dummy implementations of those persistence interfaces using in-memory storage or you could use a simple database which may not be robust or scalable enough for production. Then, when the time comes to really decide on a database, you already know a lot more about the system and its persistence needs. And, if you keep the clear separation you created between business logic and persistence, you can still change your decision afterwards without creating a significant impact on the business logic. Boundaries allow you to keep options open.

The flexibility created by boundaries is important. For almost every software system, change is inevitable. During initial development, we typically already see a lot of changes in requirements. And once the system is in production, the requirements keep evolving, which means that the system needs to keep evolving as well. This means that it's very important for our system to allow changes. This flexibility, the ability to change, is essentially what makes software soft.

## Different kinds of boundaries

### Horizontal versus vertical separation

When looking at different kinds of boundaries, we can start by comparing boundaries creating horizontal or vertical separation.

*Horizontal slicing* creates boundaries between different technical areas of the system. This can result in a layer for the UI, a layer for application-specific business rules (use cases), a layer for the the core business rules (domain entities) and a layer for communicating with the database. Horizontal boundaries can help in organizing a system's source code. However, if the boundaries between different parts of the system are also boundaries between different teams, horizontal slicing is often not the best option. Adding or changing features often requires changes in multiple layers of the technical stack. If these different layers are managed by different teams, even something as simple as adding a single field could require coordination between several teams, increasing the complexity of the development process.

On the other hand, *vertical slicing* creates boundaries between different functional areas of the system. For instance, functionality for managing customers can be separated from functionality for placing orders. One particular example of vertical slicing is the microservices approach, where different small teams each maintain one or more microservices that encapsulate a certain functional area across several layers of the technical stack, even down to the database. This means that changes within a single functional domain can happen within a single team and coordination with other teams is only required if the communication with other functional domains needs changes as well.

As said before, boundaries are useful for scaling teams, allowing the system to be developed by several small teams with efficient internal communication rather than one single huge team with a lot of internal coordination overhead. An interesting idea regarding the division into teams is *Conway's Law*. This "law" states that an organization designing a system will almost inevitably design a system with a structure that matches the organization's communication structure. It also makes sense to design it that way: if changes within a single part of the system can happen within a single team, it's way easier to plan and execute these changes. The idea behind Conway's Law also means that, if there is a mismatch between the team structure within your organization and the architecture of the application you're working on, building the application is likely to be a struggle. You can use Conway's Law to your advantage by structuring your application (and thus your teams) in such a way that changes to the system are pretty likely to be confined to a single part of the application. In practice, it seems that vertical slicing is typically the best way to do that.

### Separation mechanisms

Boundaries separate different parts of the system. There are several ways to perform this separation, each with their own benefits and drawbacks:

#### Source-level boundaries

The lowest-level boundaries sit at the level of the source code. They use interfaces (or other abstraction mechanisms provided by the programming language) to allow different parts of the system to talk to each other without having to know anything about each other. They can also use the Dependency Inversion Principle (from the [SOLID principles]({% post_url 2019-04-13-SOLID-principles %})) to control the direction of the dependency. For example, if the business logic calls persistence code, we could let the business logic part specify the interface that the persistence code must implement. This way, while the business logic is calling the persistence code, it is the persistence code that is dependent on the business logic part of the system.

If the abstraction introduced by a full-fledged source-level boundary would be too much, it may be interesting to consider the [Facade pattern](https://en.wikipedia.org/wiki/Facade_pattern) as an alternative. When using the Facade pattern, you take a complex subsystem and put it behind a class that exposes a nice interface to that subsystem. This does not provide the same amount of separation as the use of abstractions and does not allow you to control the direction of dependencies, but it could help with managing complexity and potentially prepare for the creation of a full boundary.

Communication across source-level boundaries happens through simple method calls, which means we don't have to worry too much about the amount of communication passing the boundaries.

Source-level boundaries are not visible at deployment time, but they are still important. When set up correctly, they can still help to isolate different parts of the system from each other in order to facilitate independent development by multiple persons or teams. For monolith systems, these are the only boundaries in the system.

#### Dynamically-linked deployable components

Here, the parts separated by the boundaries are separately developable and deployable components. An example of these are DLL or JAR files. They are deployed independently, but they still run in the same address space. This also means that communication can still happen through simple and efficient method calls.

When different components are developed independently from each other, it is typically necessary to set up some kind of versioning and release management system that allows developers depending on a component to decide if and when to upgrade to its next version. Dependencies between components also need to be managed carefully in order to prevent dependency cycles. Again, the Dependency Inversion Principle can be used to control the direction of dependencies between components.

#### Local processes

Separate parts deployed as local processes still live on the same machine, but they do not share the same address space (although there may be some memory sharing involved). If the processes are not communicating through shared memory, they can use sockets or potentially some OS-specific ways of interprocess communication. The context switching between processes (and potential marshalling and unmarshalling) means that the communication between processes has more overhead than just simple method calls. Where possible, unnecessary back-and-forth should be avoided.

#### Services

Services, for example in a microservices architecture, form the strongest, highest-level boundary. Different services are assumed to live on different machines and communicate only over the network. This also means that communication between services is expensive from a performance point of view.

When working with services, each of those services is typically developed and operated by a separate team that takes ownership of he service, including its tech stack and data. Sharing of a database between services is generally considered back practice. When a service links to data from another service, it will likely store its own snapshot of that data rather than referring to it. All of this means that changes to a service, except for its communication with other services, do not have any effect on other services. This gives the team maintaining a service a lot if freedom and flexibility.

While services provide a lot of decoupling, they do not magically get rid of all possible coupling. The fact that services communicate with each other means that services will still depend on each other to some extent. If your service needs customer data, there are scenarios where a change to the Customer service could impact you. As always, these dependencies should be carefully managed.

### Combining different kinds of boundaries

There is no need to choose only one kind of boundary. Different kinds of boundaries can be useful at different levels of your architecture. 

For example, you could have a set of microservices which you have obtained using vertical slicing. However, each of those microservices could have a layered architecture using horizontal slicing to separate different technical parts, either through source-level boundaries or as separately deployable components.

## Boundaries come at a cost

While boundaries in your system have important benefits, these benefits do not come for free. Boundaries can have some performance impact, but the most costly impact is their impact on development effort. While boundaries can help with productivity by providing flexibility and independence, they also need to be developed and maintained and the abstraction they provide typically increases the complexity of the system as a whole. As is often the case in software development, "it depends" and you have to make a tradeoff between the benefits and costs of each boundary instead of just blindly introducing boundaries and abstraction everywhere.

If you have five teams working on a system, they will likely benefit from having five clearly separated parts with stable interfaces connecting them. The same architecture could be harmful to productivity if there is only a single small team working on the system. The experience and knowledge of different team members also plays a part. When in doubt, keep it simple. If there is no clear need for a boundary, it is likely that adding the boundary would be a case of over-engineering. There are already plenty of horror stories about systems with so many layers of abstraction that it is almost impossible to figure out where certain logic sits in the codebase or where a certain new feature should be implemented. This is not an indication of good architecture.

## Evolving boundaries

Boundaries are expensive. Introducing a new boundary which was not there before is typically also expensive. This means that deciding about the initial boundaries in the system requires careful consideration. Even then, it is impossible to know everything beforehand when building a system. For example, the context and requirements for the system are likely to change throughout its lifetime. This means that the architecture of the system and the boundaries defining it will need to evolve along with the system itself.

One thing that may have to change is the location of the boundaries. It's possible that, as the system and the team grows, additional boundaries are needed to be able to maintain productivity. On the other hand, the cost of maintaining certain boundaries may no longer outweigh the benefits they bring.

The separation mechanism used by a boundary may have to change as well. An application could start as a monolith with some well-placed source-level boundaries, but over time it could make sense to start breaking up different parts into separate components or even separate services. Ideally, a boundary should allow you to move to a higher (or lower) level of separation without the majority of the code having to know anything about the change.

A good architect will keep on watching the system for signs of parts that need additional separation or boundaries that have become less relevant. They will then make the necessary adjustments, taking into account both the benefits and costs associated with changing boundaries. This way, the architecture of the system will keep on evolving to suit the needs of the system and team.

## Resources

- Clean Architecture (book by Robert C. Martin)
- Building Evoluationary Architectures (book by Neal Ford, Rebecca Parsons and Patrick Kua) ([summary slides](https://www.slideshare.net/thekua/building-evolutionary-architectures))