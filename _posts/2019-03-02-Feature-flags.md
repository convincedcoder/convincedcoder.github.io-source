---
layout: post
title: Feature flags
tags: software-development
toc: true
---

Feature flags are a way to build flexibility into your codebase, allowing some features or alternate code paths to be toggled on or off at will. This post explains a bit more about what they are and how to use them.

## So, what exactly are feature flags?

As I said above, feature flags (also known as *feature toggles*) are a way to introduce flexibility into your code. The most basic form of a feature flag is a simple if-statement.

```javascript
function calculateTotal() {
    if (newAlgorithmEnabled) {
        return calculateTotalUsingNewSummationAlgorithm();
    } else {
        return calculateTotalUsingOldSummationAlgorithm();
    }
}
```

The point where we decide which behavior to invoke based on the state of a feature flag is called the *toggle point*.

The state of the flag could be determined in a couple of ways. In the most basic and least flexible case, it could be a variable that is either `true` or `false` depending on which code you (un)comment. In that case, the state of the flag is hard-coded. Typically, however, there is a *toggle router* which determines the state of the flag in a more dynamic way.

```javascript
function calculateTotal() {
    if (featureIsEnabled("use-new-calculation-algorithms")) {
    // ...  
```

When using a toggle router, the state of the flag could potentially be changed from within the code by making a call to the toggle router. This can be useful for testing purposes. The toggle router could also get the state of the flag from a configuration file, toggle settings configured through some kind of admin UI, or even determine the state of the flag dynamically based on the actual user making the request.

## Feature flag use cases

- Decoupling deployment from release: Feature flags allow a team to deploy a new version of the codebase, containing some code for an unfinished new feature, without that new feature affecting the users yet. This is particularly useful when practicing [Trunk Based Development]({% post_url 2019-02-16-Trunk-based-development %}).
- Incremental releasing: Using feature flags that are toggled on or off dynamically based on the user, it is possible to turn a feature on for a small percentage of the users and monitor its effect before rolling out the feature to all users. This is called a *canary release* or *percentage deploy*. It is essentially a way to test in production, with real user behavior and real data, while limiting risk. There is also a technique called *ring deploys*. The mechanism is the same, but the difference is that the users are not selected randomly but are rather chosen based on risk. You could start with internal users, then add a very small *canary group* of randomly selected real users, then include registered beta testers, etc.
- A/B testing: When deciding between two approaches (or whether or not to change something or keep it), you can use feature flags to enable approach A for a group of users and approach B for another group of users. Monitoring of the different groups should then help you decide which approach to choose.
- Kill switches: Feature flags can be used to temporarily switch off resource-heavy features when the system is under heavy load (think of an e-commerce website on Black Friday).
- Plan management: Some services use feature flags to offer a different feature set to different users based on how expensive their subscription is.
- Incremental infrastructure migrations: Feature flags can be used to perform infrastructure migrations on production in small steps (each toggled by a flag) that can be rolled back if needed by turning off the flag. After each step, the team can verify that the system still works correctly.

## Categorizing feature flags

### Lifetime

Some flags, like flags used for A/B testing, will only exist for a relatively short period before they are thrown out of the codebase. Others, like kill switches or flags for plan management, can exist for years and may even never be thrown out. The longer the lifetime of a flag, the more careful you need to be about choosing the location of its toggle point(s) and ideally making sure there is only a single toggle point that decides what to do based on the flag.

### Dynamic nature

Some flags will be relatively static, only changing through actual code changes or configuration file changes. Others, like for example kill switches, should allow their value to be changed at runtime (for example from some kind of admin UI). The most dynamic flags are the flags whose state depends on the current user, like flags used for A/B testing. The more dynamic a flag is, the more complex the toggle router will need to be.

### Flags changing throughout their lifetime

During its lifetime, the same flag could fulfill different kinds of use cases and potentially need to be implemented and managed in different ways. For example, let's say that our team is building a feature that recommends products to customers based on what other similar customers have bought. During development of the feature, it is possible that the unfinished code for the feature is already deployed but is disabled in production through a static feature flag in a config file. Once the feature is finished, we could decide to only release it to a small percentage of our customers at first and check how it affects their buying behavior. This means our flag now needs to be on or off depending on the specific user. If the feature has a positive effect, we decide to enable it for all customers. However, as it is a performance-intensive feature, we could still keep the flag as a kill switch which can be toggled at runtime. 

In the different phases of its lifetime, it could also make sense for the flag to be managed by different teams (development team, sales team, ops team, ...).

## Implementation techniques

### Basic flag check

Let's start from the basic feature flag implementation we saw above:

```javascript
function calculateTotal() {
    if (featureIsEnabled("use-new-calculation-algorithms")) {
    // ...  
```

There are some potential issues here. First of all, using a magic string seems kind of brittle. Secondly, this single flag could toggle multiple algorithms in multiple places. In this case, that knowledge is spread across the actual toggle points.

### Additional layer of decision logic

```javascript
// shared features config
const features = {
    useNewSummationAlgorithm() {
        return featureIsEnabled("use-new-calculation-algorithms");
    }
}

// toggle point
function calculateTotal() {
    if (features.useNewSummationAlgorithm()) {
    // ...  
```

Here, we add an additional layer of decision logic, keeping track of the relationship between flags and specific functionality. This is an improvement, but `calculateTotal` still needs to know about feature toggles, making it hard to test in isolation.

### Injecting decisions

```javascript
function calculateTotal(config) {
    if (config.useNewSummationAlgorithm) {
    // ...  
```

Now, `calculateTotal` has no idea that feature toggles exist. The only thing it knows is that its behavior can change, for whatever reason, based on the config object it receives. Here, that config object is passed as an argument, but it could also be passed when constructing the enclosing object.

### Injecting strategies

As an even more flexible and maintainable alternative, we can use the Strategy pattern to inject the summation algorithm into the method or the enclosing object. This way, the method itself doesn't need to have any idea that its behavior can be changed dynamically. This is a good way to keep toggling out of generic, reusable code. Additionally, if there are multiple places where summation is affected by the feature flag, there can now be a single toggle point (at a higher level) that instantiates the correct summation algorithm to use.

```javascript
function calculateTotal(summationAlgorithm) {
    const sumOfItems = summationAlgorithm(items);
    // ...  
```

## Where to put toggle points

Often, it is practical to put toggle points at the edge of the system. The point where API requests enter the system is typically the point where we have the most knowledge about the actual user making the call, which is vital for dynamic flags. Keeping toggling logic out of the core can also help with maintainability. Toggle points could also be put at the level of the user interface, for example deciding whether or not to show a button triggering certain functionality. In this case, an unfinished feature could already be exposed as an API in the back end, but users will never call that API as long as the button for triggering the feature is not shown.

Sometimes, it makes sense to put toggle points in the core of the system, close to the functionality they toggle. This could be the case for technical flags toggling how something is implemented internally. Do note that this means that the core of your system needs to know about the feature flags or at least the fact that different modes of operation are possible, which could make maintenance and testing of the core a bit more challenging. Additionally, the core doesn't always have the necessary context (for example, full info about the current user) to make the decision. Of course, in that case, it is still possible to make the actual on/off decision at the edge of the system and then pass it down to the core.

## Feature flag configuration

There are several ways of managing feature flag configuration, some allowing for more flexibility than others. That flexibility is especially important for feature flags that need to change configuration often or need to be able to change their configuration instantly (for example kill switches). Do note that the fact that a fag is dynamic, in the sense that it has different values for different users, does not necessarily mean that the flag's configuration will change often. For example, the rules for which users see a plan management feature flag as "on" could even be hard-coded.

An overview of some approaches for managing feature flag configuration:
- Hard-coded or baked in: In this case, the feature flag configuration is stored in the actual code. Some teams may also set the value of the flag as part of the build process. This approach can work for flags guarding unfinished features, where we never want those features to be enabled in production.
- Command line variables, environment variables or config files: This approach could be useful the value of a flag should be able to change without having to rebuild the application. However, a restart is often needed in order to use the new configuration. With this approach, it may also be challenging to keep flag configuration consistent across multiple servers or processes.
- App database: Storing feature flag configuration in the app database means that there is a single source of truth that is potentially shared across multiple servers. This approach typically also allows the configuration to be changed at runtime, often through some kind of admin UI. There may be some limitations imposed on which users can change the configuration for certain flags.
- Feature management system: When the (typically home-grown) solution of putting configuration in the app database starts feeling a bit limited or brittle, teams often upgrade to a dedicated system specifically aimed at managing feature flag configuration. They provide a UI for managing the configuration, including limitations on who can change what. There may even be an audit log tracking when changes were made and by who. Often, feature management systems provide mechanisms to ensure that any changes made to the configuration are propagated quickly to all systems that need to know about them. They may also provide tools that help with integrating knowledge about flag configuration and certain application metrics, helping to analyze the effect of turning a certain flag on or off.
- Configuration overrides: In some cases, it makes sense to allow feature flag configuration to be overridden, for example by passing a special cookie, query parameter or HTTP header.

Whatever approach to configuration you choose, try to keep a clear separation between feature flag configuration and other kinds of configuration. Additionally, try to include some documentation or metadata (owner, purpose, ...) with the feature flag configuration if your approach allows it.

Regardless of the approach used, try to foresee a very straightforward way for checking the current flag configuration for a running system. Some of the above approaches already provide this through a UI. It can also help to just foresee a simple API that returns the current configuration.

## Feature flags and testing

Feature flags determine the behavior of your application. This means that they make it a bit more challenging to properly test the application.

It can help to keep toggle points outside the core of your system where possible. In that case, you can already test the core without having to worry about feature flags.

At some point, you will have to test the system at a level where it is affected by feature flags. In theory, each feature flag means an exponential increase in possible configurations to test. However, in practice, a lot of feature flags will not interfere with each other because they toggle completely unrelated functionality.

A pragmatic approach to testing could be the following:
- Follow the best-practice convention that a toggle in "on" position means "new behavior" and a toggle in "off" position means "old behavior"
- Test with current prod config + the flags you intend to turn on
- Test the fallback configuration (just current prod config, without the flags you intend to turn on)
- Potentially also test with all flags in "on" position. This can help prevent surprises in the future by detecting regressions in some features that we don't intend to turn on yet.

## Database changes using the Expand-Contract pattern

Sometimes, changes in your code require changes to the structure of the data in the database. In a system without feature flags, one of these simple approaches could suffice:
- Code-first change: First deploy the new code, which is compatible with both the old and new database structure, then change the database
- Database-first change: Start by changing the database in a way which is compatible with both the old and new code, then deploy the new code
- Big bang: Take the system offline, change both the code and the database structure, then start the system again

If the changes are toggled through a feature flag, things become a bit more challenging. The flag may change state multiple times, both from "off" to "on" and from "on" to "off". One pattern for handling this situation is called *Expand-Contract migration*. The idea is that the database structure will first be expanded in order to support both states of the flag. Then, if the flag is removed, we contract the structure of the database by removing what is not needed anymore. This pattern could also be useful for making non-flagged changes in an incremental way without creating downtimes.

As an example, assume that we currently have a database of orders and that the Order table has some columns storing address information. We now want to start experimenting with a feature that allows customers to explicitly manage their shipping addresses. In a first version, we want to store the shipping addresses a customer has used in the past and present these to the customer when they make an order. This feature needs a situation where we store addresses in an Address table and then refer to the correct address from each Order instead of storing address information in the Order table itself. However, as this feature is behind a flag, we also need to support the old approach. We could make this change in the following way:

1. Perform a database-first change that adds a nullable column to the Order table that references the Address table. The current code will ignore this column.
2. Change the code so it still fills the old address information columns on Order but also creates Address records and links to them from Order. This concept is called *Duplicate Writes*.
3. Perform a one-time data migration, using the existing data in the address information columns to link each Order to an Address. Once this migration is done, the reference from Order to Address can be made non-nullable.
4. At this point, we can support both states of the feature flag.
5. Once the feature has been permanently turned on, we can remove the old address information columns from Order (and the code writing to them) as they are not used anymore.

When performing a complex migration like this, it could be useful to use *Dark Reads*. This means that, when reading data (getting address info for a specific order), you read from both places where the data is available. If the read data is not identical, the team needs to investigate what went wrong.

## Managing the number of flags

While feature flags are very powerful, they do come at the cost of additional complexity, testing effort, etc. Therefore, it is wise to limit the number of feature flags in your system. When considering to use a feature flag, remember that there may be other possibilities. Ideally, you could design the feature in such a way that even its first version already has some value or at least has no negative impact on customer experience.

For existing feature flags, it is useful to make sure each flag has an owner who is responsible for making sure the flag is removed at an appropriate time. It can help to add an expiry date to the flag's metadata and to create a backlog issue for removing the flag. Some teams even use the expiry date to create time bombs, making sure tests fail if a flag is still in the system after its expiry date. A team can also put a hard limit on the number of feature flags in the system, requiring some old flag to be removed before adding a new one.

Some feature management systems can help with the detection of obsolete flags by looking for flags that have been either 100% on or 100% off for a long amount of time.

## General best practices

- Clear scope: The name of a flag should indicate what part of the system it affects, what the purpose of the feature it and ideally also at which layer the feature sits. An example naming convention is `section-purpose-layer`.
- Maintain consistency: Whenever possible, try to present the user with a consistent experience. This means consistency in which flags are turned on for the user. When doing percentage deploys and increasing the percentage, make sure that users for which the feature flag was previously in the "on" state still have the flag turned on. In some systems (like e-commerce applications), consistency becomes a bit more challenging because users start using the application before logging in. In that case, it may make sense to store a cookie with a visitor ID, use the visitor ID to determine which features are turned on for the user, and keep using that same visitor ID after the user has logged in.
- Server-side decisions: Try to keep decisions regarding whether or not a feature is enabled on the server side. This makes it a lot easier to manage feature flag states and keep them up to date. It also prevents tech-savvy users from playing with flag state themselves.
- Integrate monitoring with feature flagging: Feature flags can have an effect on business metrics like conversion rates, but also on technical metrics like CPU use. Take care to make sure that you can link changes in these metrics to changes in feature flags so you can properly analyze the effect of a flag. It may make sense to store some feature flag information with analytics events.

## Resources

- [Feature Toggles (aka Feature Flags)](https://martinfowler.com/articles/feature-toggles.html)
- [Effective Feature Management ebook](https://launchdarkly.com/effective-feature-management-ebook/)
- [Feature Flag Best Practices ebook](https://try.split.io/oreilly-feature-flag-best-practices)