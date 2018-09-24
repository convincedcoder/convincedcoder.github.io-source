---
layout: post
title: Optimistic and pessimistic locking with SQL
tags: concurrency sql
toc: true
---

This post explains the optimistic and pessimistic locking strategies with a focus on their application in systems interacting with relational databases. Regardless of the focus on SQL, the main concepts discussed here are not SQL-specific and are also applicable in other areas.

## Why locking?

In order to explain why you would need locking, I will provide some examples of undesirable situations that you can prevent using locking.

- Your application lets users manage items. Each item has a long description. One of your users starts editing the description of item A at 10:00 and saves his changes at 10:02. Meanwhile, another user starts editing the same item's description at 10:01 and saves it at 10:03. Because the original description that the second user started from did not yet contain the changes made by the first user, the changes made by the first user are lost without either user being notified about it.
- Your application communicates with the database through an ORM using the common approach where you retrieve the current version of an object, make some changes to it and then save the resulting object to the database. Some user or process changes the same object right after you retrieved it, so the object you are saving does not contain those changes. This leads to your application overwriting the changes with stale data.
- Your application allows linking items to a group, but only if the group has status "Active". This restriction is not enforced at the database-level. Before linking an item to a group, you verify that the group has the correct status. However, just before you save the item, another user or process changes the status of the group to "Inactive". Once you commit, the item is now linked to an inactive group.

As you may have deduced from these examples, locking is primarily relevant in dealing with conflicts caused by multiple users or processes concurrently interacting with your application or database.

## Locking strategies

There are two main types of locking: optimistic and pessimistic.

### Optimistic locking

The optimistic locking strategy performs most of an operation's logic under the assumption that no conflict has occurred (which explains the name "optimistic"). Then, when actually saving/committing your changes, you verify that indeed no conflict has occurred. If you detect that there was actually a conflict, you abort your operation.

When interacting with a relational database, checking if a conflict has occurred is typically done by either comparing the actual data for an object to the data you based yourself on or by checking a version number or timestamp that you update every time a change is made to the object. It seems that the approach with the version number is the most commonly used one.

The typical use case for optimistic locking is retrieving an object, making some changes to it (possibly done by a user) and then saving the result while verifying that no other changes have been made in the meantime. However, it also allows you to lock objects that you need to stay unchanged until after you complete your operation. You can achieve this by simply saving the object as you retrieved it. If this doesn't yield a conflict, you know that the object hasn't changed in the meantime. This strategy could be applicable to our example with items being linked to a group.

#### Benefits and drawbacks

A big benefit of optimistic locking is the flexibility it offers. You don't have to care about when and where the "base version" of your object was retrieved. There's no need for it to be retrieved inside the same transaction where you save the object. This is especially desirable when you need to wait for user input to make the changes, like in our example with users editing descriptions. In such a case, it would be very impractical to keep a database transaction open while a users edits an item. Typically, the user will make separate calls to retrieve the item and to save it, which may even be handled by different instances of your application in a cluster.

Some sources claim that, when using optimistic locking, deadlocks are not possible because it never issues any database-level locks. Further down this post, I will show that this is not true and that optimistic locking (combined with the common transaction isolation level Read Committed) actually acquires a database-level lock from when you save data until your transaction is committed. However, the flexibility of optimistic locking makes it straightforward to prevent deadlocks by always saving objects in the same order (and thus always acquiring database-level locks in the same order).

An important drawback of optimistic locking is that, if a conflict does occur, you need to deal with your operation being aborted. If your operation simply retrieves an object and immediately changes and saves it, it can make sense to retry your entire operation (retrieve current version, change and save it). However, in our example with users concurrently editing descriptions, that wouldn't make any sense. It would just lead to users unknowingly overwriting each other's changes again. Instead, the best option would probably be to alert the user of the conflict and ideally allow him to merge his changes with the other changes.

### Pessimistic locking

Pessimistic locking, as the name implies, uses a less optimistic approach. It assumes that conflicts will occur and it actively blocks anything that could possibly cause a conflict.

When interacting with a relational database, this is done by actively locking database rows or even database tables when you retrieve the data you will operate on. The locks will be held until your transaction completes. There are generally two types of locks: shared locks (read locks) and exclusive locks (write locks). Shared locks are used for reading data that you simply need to stay the same until your operation completes. A shared lock allows others to take a shared lock as well (you still allow others to read the object as this does not create a conflict). Exclusive locks are used for reading and updating data that you want to change. Exclusive locks do not allow anyone else to take a lock on the same data. Any attempts to obtain a lock when it's not allowed at the time will block until the conflicting locks are released.

#### Benefits and drawbacks

The main benefit of pessimistic locking is that you can completely prevent conflicts from occurring, meaning that you don't have to deal with the situation where you have a conflict. This can also make it the best-performing strategy in high-concurrency environments where the chance of having conflicts is high.

A drawback of pessimistic locking is that you miss the flexibility of optimistic locking: when using pessimistic locking, everything needs to happen inside a single database transaction. This makes it less applicable to situations where you need to wait for user input or an expensive operation between retrieving and saving an object. It can also limit your options for organizing your code.

Pessimistic locking may also unnecessarily limit concurrency, preventing possibly conflicting operations from occurring concurrently even if there is a very low chance that there will actually be a conflict.

When using pessimistic locking, you need to take special care to prevent deadlocks. First of all, you typically acquire database-level locks at the start of your operation and you keep them until the operation completes, making for a relatively large time window for deadlocks to occur. Additionally, when retrieving multiple objects, the actual objects to retrieve may depend on objects retrieved earlier. This means that you have less flexibility regarding the order in which you obtain locks. It may be tempting to "solve" this by first retrieving an object without any locking and later retrieving it again with the required lock. However, in that case, you need to check for changes made in the meantime, which is basically optimistic locking and introduces the possibility of conflicts occurring.

Additionally, if you use pessimistic locking in situations where you need to wait for user input, you need to deal with situations in which the user doesn't provide that input in a timely fashion (e.g., the user goes for lunch or forgets about what he was doing, blocking other users while nothing is happening).

## Combining different strategies

Note that it is possible for different locking strategies to exist at different levels in your application. As an example, let's take the application where users can edit items and their descriptions. A possible approach could be to require users to "check out" items before editing them, blocking other users from editing those items while they are checked out. The system would use an additional table to store which item is checked out by which user. This is a form of pessimistic locking. However, at the level of the communication with the database, conflicts caused by users concurrently trying to check out the same item could be dealt with using optimistic locking.

## Implementation using SQL

Note: for my comments regarding database-level locking in this section, I am assuming a transaction isolation level of Read Committed, which is the default level in several popular relational databases (and even the lowest available level for some). For SQL that differs between databases, I am using the PostgreSQL dialect here.

### Optimistic locking using WHERE

One way of implementing optimistic locking when updating an objects is by using a WHERE clause including the data you need to check for conflicts (in this case, the version number of the version you base yourself on). Such an UPDATE statement normally returns the number of affected rows. If that number is 0, we know that a conflict has occurred and we can roll back our transaction.

If you use this strategy, it actually acquires a database-level lock on the row you update. As stated above, this could lead to deadlocks if you are not careful. For example, consider the two transactions below.

```sql
--Transaction A                 -- Transaction B
BEGIN TRANSACTION               BEGIN TRANSACTION

UPDATE items                    UPDATE items 
SET name = 'newNameA',          SET name = 'newNameB',
    version = version + 1          version = version + 1
WHERE id = 1 AND version = 1    WHERE id = 2 AND version = 1

UPDATE items                    UPDATE items 
SET name = 'newNameD',          SET name = 'newNameC',
    version = version + 1          version = version + 1
WHERE id = 2 AND version = 1    WHERE id = 1 AND version = 1

COMMIT TRANSACTION              COMMIT TRANSACTION
```

Let's assume that these transactions execute concurrently and that both have executed their first UPDATE statement. If transaction A then executes its second update statement, it will block and wait for transaction B to either commit or roll back (the result of the statement depends on uncommitted changes made by transaction B). If transaction B then executes its second update statement, we have a deadlock. Fortunately, the flexibility of optimistic locking makes it easy to prevent deadlocks by always locking rows in the same order.

### Optimistic locking using OUTPUT/RETURNING or a separate SELECT query

Another way of implementing optimistic locking is by obtaining the resulting version number after the update. If it's more than one higher than the original version, you know there has been another change in the meantime. This strategy can be implemented using the OUTPUT (SQL Server) or RETURNING (PostgreSQL) statement that allows an UPDATE statement to return the updated data. Note that not all relational databases offer this kind of statement. Here is an example of such a statement.

```sql
UPDATE items
SET name = 'newName', version = version + 1
WHERE id = 1
RETURNING version
```

In this case, the update returns the actual version resulting from the update and your application can check if this matches the expected new version number. Just like the first implementation, this locks the updated rows until the end of the transaction.

For databases not supporting the OUTPUT or RETURNING clause, a separate SELECT statement can be used. Note that, even without the RETURNING statement, the above query locks the row until the end of the transaction.

### Pessimistic locking

Pessimistic locking is usually performed at the row-level, although similar locks can be obtained for an entire table (if you are only interested in some specific rows, use row-level locking so you don't unnecessarily limit concurrency).

The following statement retrieves a row and obtains a shared lock on it until the end of the current transaction. Other transactions can still obtain a shared lock on the row, but transactions attempting to obtain an exclusive lock will be blocked until no transaction is locking the row anymore.

```sql
SELECT description
FROM the_table 
WHERE id = 1
FOR SHARE
```

The following statement retrieves a row and obtains an exclusive lock on it until the end of the current transaction. No other transaction will be able to obtain a lock on the row until this transaction is either committed or rolled back.

```sql
SELECT description
FROM the_table 
WHERE id = 1
FOR UPDATE
```

## Locking rows versus locking objects

This post mostly assumed an object to correspond to a single row in the database. However, objects can be more complex than that.

For example, let's assume that we have an order that contains several order lines. Each order line corresponds to a row in the `order_line` table with an order id, item and price. Each order corresponds to a row in the `order` table with a total price for the entire order (probably not the best design, but it makes for a simple example). Now, we need to implement a functionality to add an order line to an order, also immediately updating the total price for the order.

If this can happen concurrently, we need some form of locking. Otherwise, it can happen that we we retrieve an order with its order lines, then another user adds an order line and updates the total price, and then we add an order line as well but calculate the total price based on what we retrieved initially (so without the other user's order line).

We could solve this using optimistic locking by assigning a version number to each order, always updating an order (including order lines) as a whole and incrementing the version number when we do so.

Another approach could be to use pessimistic locking. The simplest option is to take an exclusive lock on an order row whenever we update the order or its order lines. That makes sense for this functionality, because we update the order row anyway. Explicitly locking the order's order lines is also possible, but in that case, we need to lock the entire `order_line` table. For the order lines, row-level locks are not sufficient because we also need to prevent new order lines from being added.

## Alternatives

### Atomic updates and database-level restrictions

One alternative to optimistic and pessimistic locking is to structure your data and application in such a way that all of your updates are made using atomic UPDATE statements that only update the actually changed data. If an item has both a code and a name, you could foresee separate calls to update either one of them and implement those using simple UPDATE statements that update only the new code or name. This could be a good solution for concurrency issues encountered in a simple CRUD application where the typical retrieve-modify-save approach of ORMs can lead to data being lost. Do note, however, that this may get tricky when relations are involved. There may also be situations where the new value to save depends on other existing values.

This approach could also be applicable when the validity of an update depends on the status of a related object, but only if we move the checks for that to the database. For example, if we want to update an item's group and be entirely sure that we don't link to an inactive group, we could foresee a separate table with the IDs of active groups and link items to that table.

An important remark is that this approach does not solve the problem of data being lost if multiple users concurrently edit the description for the same item based on the same initial version.

### Transaction isolation levels

Up until now, this post assumed a transaction isolation level of Read Committed. As already stated above, this is a commonly used transaction isolation level and is the default one in several popular relational databases. The Read Committed isolation level forbids the occurrence of *dirty reads*, where a transaction sees data that has not yet been committed. The SQL standard defines two more restrictive isolation levels: Repeatable Read and Serializable. These more restrictive transaction isolation levels could, to some extent, be an alternative to optimistic and pessimistic locking implemented through SQL as in the above examples. 

For this to work, everything you do as part of an operation needs to happens inside the same database transaction (as is the case with pessimistic locking). Additionally, when relying on transaction isolation levels, you lose some control over what exactly is locked and when. This increases the likelihood of deadlocks if database-level locking is used.

Also note that the behavior of more restrictive transaction isolation levels varies widely between database vendors and sometimes even between different versions of the same database. Therefore, they are probably not the best option for applications that need to support multiple databases.

Finally, note that these transaction levels do not solve the problem of lost updates in the example with multiple users concurrently editing the same item's description.

#### Repeatable Read

The Repeatable Read isolation level is more restrictive than the Read Committed isolation level. In addition to *dirty reads*, it also forbids *non-repeatable reads*, where a transaction rereads data it has read before and finds that that data has changed. Note that this restriction only applies to the contents of rows that were previously read. The Repeatable Read isolation as defined in the SQL standard does not forbid *phantom reads*, where a transaction repeats a query with certain search criteria (e.g., all `order_line` rows belonging to a certain `order`) and finds that the set of returned rows has changed (new order line inserted by another transaction).

In SQL Server, the Repeatable Read isolation level is implemented using locking. If you read a row, you obtain a shared lock on that row, causing other transactions attempting to update the row to block until you commit or roll back your transaction. This behavior is very similar to pessimistic locking.

In PostgreSQL, the Repeatable Read isolation level behaves quite differently. Your transaction sees a snapshot of the database taken at the start of your transaction (also preventing *phantom reads*). However, this does not guarantee that the data has not changed in the meantime. Let's say that transaction A reads a row and transaction B then updates that row. This update is not blocked. If transaction A now reads the row again, it will still see the original data (before transaction B changed it). However, if transaction A then tries to make a change to that row, transaction A will fail. This behavior is similar to optimistic locking, but only if transaction A actually tries to update the row.

Note that SQL Server also offers a Snapshot isolation level which behaves similarly to the PostgreSQL Repeatable Read isolation level.

#### Serializable

The Serializable transaction isolation level is the most restrictive level. It forbids *dirty reads*, *non-repeatable reads* and *phantom reads*. Additionally, it requires concurrent transactions to behave in a serializable fashion. This means that, when a set of transactions execute concurrently, there must be some possible sequential execution of the transactions that yields the same results as the results of the concurrent execution. This is a very strong guarantee, which essentially prevents all phenomena caused by concurrent execution.

In SQL Server, this isolation level is implemented using locks. As simple row locks are not sufficient for preventing *phantom reads*, it can also acquire *key-range locks* which are specifically aimed at preventing the insertion of rows that would match a query previously executed by an active Serializable transaction. Again, this behavior is very similar to pessimistic locking and it is more powerful than Repeatable read. For example, if a Serializable transaction queries for an order and its order lines, the database will prevent other transactions from inserting order lines for the order until the transaction is completed.

In PostgreSQL, the Serializable isolation level is similar to its Repeatable Read isolation level. However, it now checks for all situations that prevent the results of the executed transactions to match some sequential order of execution. If such a situation is detected, the transaction fails. Note that, when using this isolation level, even the results of SELECT queries are not guaranteed to be valid until the transaction is successfully committed. As an alternative, a Serializable Read-only Deferrable transaction can be used. In that case, SELECT statements block until they can return a result that is guaranteed to be valid.

## Resources

- [Concurrency Control](https://en.wikipedia.org/wiki/Concurrency_control)
- [PostgreSQL Returning Data From Modified Rows](https://www.postgresql.org/docs/current/static/dml-returning.html)
- [PostgreSQL Transaction Isolation](https://www.postgresql.org/docs/current/static/transaction-iso.html)
- [PostgreSQL Explicit Locking](https://www.postgresql.org/docs/current/static/explicit-locking.html)
- [SQL Server SET TRANSACTION ISOLATION LEVEL](https://docs.microsoft.com/en-us/sql/t-sql/statements/set-transaction-isolation-level-transact-sql?view=sql-server-2017)
- [SQL Server Transaction Locking and Row Versioning Guide](https://docs.microsoft.com/en-us/sql/relational-databases/sql-server-transaction-locking-and-row-versioning-guide?view=sql-server-2017)