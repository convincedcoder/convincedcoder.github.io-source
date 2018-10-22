---
layout: post
title: SQL, NoSQL and NewSQL
tags: sql nosql newsql
toc: true
---

This post is my attempt at providing a very high-level overview of the data store landscape, covering relational databases (SQL), NoSQL and NewSQL data stores.

## Relational databases (SQL)

Relational databases have been around for several decades. The first commercial relational database management system (RDBMS) was Oracle and became available in 1979, almost 40 years ago at the time of writing. Today, an enormous number of applications use an RDBMS as their main data storage. Popular RDBMSes include Oracle, MySQL, Microsoft SQL Server and PostgreSQL. 

Today's relational databases are mature systems and there are lots of developers and database administrators that have several years of experience in dealing with them. This means that there is a wealth of knowledge available on best practices, how to tackle certain issues, etc.

Although there is an SQL standard describing the query language and behavior of relational databases, different databases typically provide a different dialect of that query language and they may differ significantly in their behavior in some cases (although possibly all within the bounds of the standard).

### Tables, rows, relationships and schemas

In relational databases, data is stored in tables (actually called relations in relational terminology). Each table has a set of columns, each of a certain type, that can hold data for the rows in the table. Typically, each table has a subset of columns, the table's primary key (PK), that uniquely identifies each row in the table. There may also be other subsets of columns uniquely identifying each row in the table , known as alternate keys (AK). Indexes can be defined on columns or sets of columns. The columns in an index may or may not form a key.

Rows and different tables can be linked to each other through relationships. A table can link to another table by including the column(s) of that table's primary Key. This is called a foreign key (FK). This way, it is possible to link rows in a table to rows in another table, forming one-to-one relationships and one-to-many relationships. It is also possible to represent many-to-many relationships by using an intermediate table to store foreign keys to both tables in the relationship.

All of the tables, columns, keys, relationships, etc. are defined in the database schema. The database actively enforces the schema and forbids data that doesn't match it (incorrect data type for a column, foreign key linking to a row that doesn't exist, ...).

### SQL

All popular relational databases use SQL (Structured Query Language), a declarative language that allows performing CRUD operations on the data and the database schema as SQL queries. The fact that SQL is declarative means that you specify *what* you want your query to do instead of *how* to do it. The database system itself figures out a how exactly the query will be performed. This can simplify things, but it can also make it challenging to optimize queries that get executed in a sub-optimal way.

### ACID properties

An important feature of RDBMSes is that they provide transactions. A transaction is a set of database operations that act as a single operation. Transactions have four main characteristics (also known as the ACID properties):

- *Atomicity*: A transaction is treated as a single unit that either succeeds completely or fails completely. If some operation fails as part of a transaction, the entire transaction is rolled back, including the changes that other operations may have performed. The system must guarantee this in every situation, even if the system crashes right after a transaction is successfully committed.
- *Consistency*: The execution of the transaction must bring the database to a valid state, respecting the database's schema.
- *Isolation*: Isolation means that, although multiple transactions may be running concurrently, their effects on each other's execution are limited. Relational database systems typically provide multiple isolation levels, where higher levels protect against more concurrency-induced phenomena than lower levels. The highest level, *Serializable*, guarantees that the effect of multiple transactions executing concurrently is the same as the effect of some possible sequential execution of those transactions. My post about optimistic and pessimistic locking using SQL contains some more info regarding transaction levels. Note that the behavior of isolation levels may vary widely across relational database systems.
- *Durability*: Once a transaction has been successfully committed, it will remain so, even if the system crashes, power is shut off, etc. right after the transaction has completed.

These ACID properties provide guarantees that come in very handy when developing applications that perform concurrent operations on the database. For example, no matter how many concurrent transactions are executing, you will never be able to set a foreign key from a row to another row that does not exist (but maybe did exist when you retrieved your data).

### Normalization

In designing the schema of a relational database, normalization is something to take into account. I won't go into detail here, but basically normalization boils down to preventing the existence of redundant data in your database as it is a source of possible inconsistencies. The way to get rid of this redundant data is generally to introduce a new table.

As an example, consider you have a table with of items with item id, description, manufacturer name and manufacturer country. In this case, storing the manufacturer's country in every row is a form of redundant data: if we know the manufacturer, we also know the country. And what if we change the manufacturer for a row but forget to change the country? The solution here is to create a separate table for manufacturers, with their country, and refer to that table from the items table.

## NoSQL

NoSQL databases became popular in the early twenty-first century, mainly because of the limitations in the scalability of relational databases.

When you need to scale up because your current setup has trouble handling its load, your generally have two options:
- Vertical scaling: make your machines more powerful by adding CPU power, memory, faster disks, etc.
- Horizontal scaling: add more machines and distribute the load between them

Once you reach a certain scale, horizontal scaling becomes cheaper than vertical scaling (cheaper to have several modest machines than to have one extremely powerful machine). Additionally, horizontal scaling allows you to easily scale up further by adding additional machines. Unfortunately, horizontal scaling is not something that traditional relational database are good at.

The term NoSQL encompasses lots of different data stores with different concepts, approaches, query languages, etc. that offer a solution to some problem for which relational databases are maybe not an ideal solution. However, in order to achieve this, they generally need to make compromises in terms of features and the guarantees offered by the data store. This could lead to you having to implement some things on the application side that would just be handled by the database if you were using an RDBMS.

### The CAP theorem

NoSQL databases are often deployed in a distributed fashion, either for horizontal scalability or for high availability (failure of a few instances doesn't bring the entire system down). A well-known concept in the world of distributed data stores is the CAP theorem. It is centered around three properties:

- *Consistency*: Every read returns either the relevant value as it was written by the latest successful write or an error.
- *Availability*: Every request receives a non-error response.
- *Partition tolerance*: The system keeps working, even if any number of messages is dropped or delayed by the network that connects the different instances. Consider for example the effect of a network partition, where sections of the network get cut off from each other.

The CAP theorem states that, for a distributed data store, it is not possible to provide more than two out of the above three properties. Because no network is safe from failures, a distributed system typically has no other choice than to be partition tolerant to some extent. This means that a choice should be made between availability and consistency.

Different NoSQL data stores focus on different properties regarding their distributed deployment. A CP system will behave in a consistent fashion but stop working if there is a network partition. An AP system will always keep working (as long as some active nodes survive) but may behave in an inconsistent fashion (e.g., returning stale data because the most recent write was not yet replicated to the node(s) answering your query).

#### CAP consistency vs. ACID consistency

Note that CAP's consistency is not the same as ACID's consistency. In fact, when relational databases are deployed in a distributed fashion, there are typically different modes available that have an impact on CAP consistency. For example, when settings up a high-availability cluster for Microsoft SQL Server, you have the choice between the availability modes *synchronous commit* and *asynchronous commit*. Synchronous commit waits to return for a transaction until it has effectively been synchronized to other instances. Keeping instances synchronized means that no data is lost if the primary instance crashes and another instance takes over, but a transaction may not be able to complete if there are network failures that hinder the synchronization. On the other hand, asynchronous commit does not wait for other instances to catch up. This means that freshly-committed data may be lost if the primary instance crashes before the secondary instances have caught up.

#### NoSQL vs. ACID

NoSQL systems differ in what they offer in terms of the ACID guarantees that relational databases provide. Some NoSQL systems may not even provide any form of transactions at all. Others may only provide transactional integrity at the level of a single entry (which may contain structured data or an array of values). When having to deal with a lack of transactional support, here are a couple of possible strategies:

- Redesign your data model so you don't need more transactional support than what the system offers
- Perform the required concurrency control at the level of your application
- Tolerate the possible concurrency issues caused by not having transactions and adjust your application and possibly your users' expectations to this

People that are used to working with a non-distributed relational database should be especially careful when working with a system that decided to limit CAP consistency. Depending on the system and maybe its configuration, the system may introduce the possibility for inconsistencies in areas where you took consistency for granted.

### Types of NoSQL data stores

This section includes some well-known types of NoSQL data stores. This is not intended to be complete list of all possible types.

#### Document store

Document stores may be the first thing you think about when you think about NoSQL. They are typically the main candidate for storing your application's domain data if you don't want to store that data in a relational database. A very well-known example of a document store is MongoDB.

In a document store, your data is stored as documents containing structured data (think something JSON-like). When performing queries, you can typically retrieve or filter on data inside the documents.

A document store can be a good fit for data that has a hierarchical structure, as you can just put the entire structure in a document. This works well for one-to-one and one-to-many relationships, but many-to-many relationships can be hard to model in a document database. Suppose, for example, that you want to store information on actors, movies and which actors played in which movies. One option is to include the data regarding actors inside the documents for the movies or vice versa. This is denormalization (see also normalization in the SQL part) and will lead to duplicate data and the possibility for inconsistencies. Another approach is to have documents for actors, documents for movies, and storing references to movies inside actors. This is similar to the concept of foreign keys in relational databases. However, document stores often do not offer real foreign key constraints, so there is nothing on the database level preventing you from deleting an actor that a movie still refers to.

Often, document stores are schemaless, meaning that the database does not enforce a certain structure of the documents you store in it. Typically, this does not mean that there is no schema for the data, but it means that that schema is either implicitly or explicitly defined by your application rather than at the database level. A schemaless database offers more flexibility in the face of changes to the structure of your data. Specifically, it allows data with the old structure to sit next to data with the new structure, without forcing you to migrate the old data to the new structure (yet). The drawback of this is that your application needs to be able to handle the different structures and that the existence of documents of the same type with different structures can make maintenance difficult if you don't take care to document the changes to the data's structure and migrate old data when it makes sense.

One more thing to note with regards to document stores is that some relational databases actually offer document store capabilities. For example, newer versions of PostgreSQL allows storing JSON data and performing queries based on the contents of that JSON data. This can be a good option if some of your data is hierarchical in nature but you still want ACID capabilities. If you don't need to query based on the actual contents of the structured data, you can even just use any relational database and store the data as text in a column.

#### Key-value store

A key-value store is made for storing data as a dictionary. This means that all the data is stored in the database as a value with a unique key identifying that value. Values for different keys can have different data types. Data types offered by a key-value store may include strings, lists of strings, sets of strings and even key-value maps. It is up to the application to determine what the keys look like. For example, if you want to store data for users, you may use the key `user:1` for the user with id 1.

A popular use case for key-value stores is setting up clusters of key-value stores that store data in-memory and using them as a very fast distributed cache for often-retrieved data.

#### Graph database

Graph databases are a good fit when your data can naturally be represented as a network of nodes connected by edges that represent relationships between nodes. An example of this are people on a social network site and their friends. If you model this as each person being a node and each friendship being an edge connecting nodes, storing the data in a graph database hep you recommend friends of friends, identify clusters of people that are all friends of each other, etc.

A well-known example of a graph database is Neo4j. It is also interesting to know that there actually exist extensions to RDBMSes (for example PostgreSQL) that offer graph database capabilities as well.

#### Time-series database

Time-series databases are aimed at storing values that change throughout time. An obvious use case for this is storing data obtained from sensors that are constantly measuring values like temperature, humidity, etc. Time-series databases have storage engines and query languages that are optimized for storing time-series data, making it easy and efficient to perform time-based queries. An example would be to take a year's worth of temperature measurements (one measurement each minute) and then retrieve the maximum and minimum measured temperature per week.

Some example of time-series databases are InfluxDB and SiriDB. Also note that there exist extensions to RDBMSes that offer time-series database capabilities. A example of this is Timescale, which builds upon PostgreSQL.

## NewSQL

NewSQL systems are a class of relational database management systems that aim at providing the ACID guarantees of relational databases with the horizontal scalability of NoSQL databases. There are several categories of NewSQL databases:

- Completely new systems, often built from scratch with distributed deployment being a major focus. They often use techniques that are similar to the techniques used by NoSQL databases. Examples include Google Spanner and CockroachDB. These systems typically have some limitations with regards to the features they support or the extent to which they provide true ACID guarantees.
- SQL storage engines optimized for horizontal scalability, replacing the default storage engines of relational databases. These storage engines may have some limitations that are not present in the database's default storage engine.
- Middleware that sits on top of a cluster of relational database instances. An example is Vitess. Note that these systems may not offer ACID guarantees.

## Which one to use?

As is often the case, choosing which data store to use is a tradeoff and their is likely no "wrong" or "right" choice. Your choice will likely depend on the kind of data you need to store, the scalability you need, the consistency you need, the knowledge of your team, etc.

Also note that there is no rule stating that you should use either SQL, NoSQL or NewSQL. For example, it is very common to use a relational database for your application's domain data but use a key-value store for caching purposes. Additionally, it could be a good idea to store parts of your domain data in a relational database and other parts in a document database, depending on which one is a better fit for which part of the data. Of course, using multiple systems also means having to keep multiple systems running smoothly.

## Hosted data stores

When you are evaluating data stores for your project, it is a good idea to also consider the hosted data stores that are offered by cloud providers like AWS or Microsoft Azure. These hosted data stores include SQL, NoSQL and NewSQL data stores and using one of them could save you the headaches involved in managing your own data store or data store cluster.

## Resources

- [Relational database](https://en.wikipedia.org/wiki/Relational_database)
- [ACID (computer science)](https://en.wikipedia.org/wiki/ACID_(computer_science))
- [Database normalization](https://en.wikipedia.org/wiki/Database_normalization)
- [NoSQL](https://en.wikipedia.org/wiki/NoSQL)
- [CAP theorem](https://en.wikipedia.org/wiki/CAP_theorem)
- [SQL Server Availability Modes](https://docs.microsoft.com/en-us/sql/database-engine/availability-groups/windows/availability-modes-always-on-availability-groups?view=sql-server-2017)
- [Living Without Transactions](https://stackoverflow.com/a/39210371)
- [Patterns for Schema Changes in Document Databases](https://stackoverflow.com/questions/5029580/patterns-for-schema-changes-in-document-databases)
- [NewSQL](https://en.wikipedia.org/wiki/NewSQL)