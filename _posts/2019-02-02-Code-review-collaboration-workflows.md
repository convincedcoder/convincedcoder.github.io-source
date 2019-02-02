---
layout: post
title: Code review and collaboration workflows
tags: software-development
toc: true
---

When writing code alone, it is sometimes easy to make mistakes or forget to take something into account. Therefore, the quality of your code as a team can greatly improve if developers collaborate on writing code. This post talks about some ways to handle code review and collaboration when writing code in a team.

## Instant review (pair programming)

The first type of review, instant review, means that all code is instantly reviewed as it is being written. This is what happens when doing pair programming. One programmer, the driver, writes the actual code. The other programmer, the navigator, reviews the code immediately. While the driver and navigator will be switching roles pretty often, the fact remains that there will always be someone writing the code and someone instantly reviewing it. Often, for teams that require code to be reviewed, a pairing partner counts as reviewer. This means that, if only one reviewer's approval is needed, a pair can commit code without further review.

### Advantages of pair programming

Pairing is a good way to create joint ownership of the code, preventing the very dangerous situation where there are parts of the codebase that only one developer is willing, allowed or able to maintain. Because all code was written jointly by at least two people, you have at least two people who know the idea behind the code and the details about how it works. By mixing up the pairs frequently, this knowledge gets spread across the team.

Another advantage of pair programming is that it helps with focus. While there is a lot of interaction within a pair, this interaction does not require context switching because both members of the pair are already working on the same thing. The pair can also keep each other on track and prevent each other from slacking off or being tempted to write quick-and-dirty code.

The fact that there is a driver and navigator also means that you have different levels of overview. When you are writing code alone, it is sometimes hard to keep an overview of what you are doing when you are deep into some specific part of the code. In pair programming, there is always someone (the navigator) who can help the driver keep track of the bigger picture. The roles also switch frequently, which means that both members of the pair have experienced the process of writing the code from different levels of overview.

Classical pair programming (with a driver and a navigator) works well when you need to write some code solving a complex business problem with lots of possible scenarios. While the driver codes, the navigator can provide guidance and help with making sure that all scenarios and edge cases are taken into account.

### Pair programming and junior developers

The advantages mentioned above apply especially to pairs consisting of relatively experienced people with a similar level of experience.

Pairing a senior with a junior can work, but changes the dynamic of the pair to be more focused on mentoring. Typically, the junior developer will be the driver most of the time and the senior will help the junior keep track of the different cases to handle and provide instant help when the junior is stuck. This can be a very good way to get the junior developer up to speed quickly. In order for the junior to learn, the senior developer should try not to give too much guidance or tell the junior exactly how to tackle the problem. Instead, the senior can give some hints or ask some questions to the junior, allowing the junior to figure out what to do. Sometimes, it can even make sense to let the junior wander down a path that the senior knows to be a dead end. The basic idea is that the junior should be allowed to make mistakes, while the senior can then help the junior to learn from those mistakes by really understanding what went wrong and why.

For a senior developer, mentoring a junior in this way can be exhausting and sometimes frustrating. However, pairing with a junior also provides benefits for the senior. Junior developers typically spend a lot of time learning, and in doing so they might have picked up on something that benefits the senior as well. Additionally, the questions asked by the junior developer force the senior to be explicit about the reasoning behind certain best practices, the way the codebase was designed, the approaches used for certain problems, ... Sometimes, being forced to be explain things that are obvious to you can be a learning experience in itself, and it can help expose some potential gaps in your knowledge or even flaws in the design that went unnoticed. Despite these benefits, junior-senior pairing is likely still exhausting to the senior, so it probably helps to switch things up after a while.

Pairing two junior developers is more risky. While there is a chance that they can fill in the gaps in each other's knowledge and reasoning, there is also a big chance that you will just have two people being stuck for hours on a problem that could have been solved quickly with a bit of guidance from a senior developer. Forbidding less experienced developers to pair with each other is a bit harsh, but it should be the responsibility of the team to make sure that pairs of less experienced devs receive sufficient guidance. The team should help them estimate how much time they should allow themselves to spend on a task and how quickly they should ask for help.

### Mobbing

Mobbing is similar to pair programming, but involves more people. Some types of mobbing:

- Code jam: This is basically pairing, but with more navigators. The driver still switches frequently. Often, code jams are time-boxed sessions dedicated to solving a specifically hairy challenge.
- Randori: Here, you have one regular pair (driver + navigator, switching roles often). The rest of the people just observe. However, every so often, one of the observers replaces one member of the pair.
- Mob programming: This is similar to a code jam. However, instead of having time-boxed sessions, the team sees this type of collaboration as their main way of working. Teams using this approach say it helps with learning, quick decision making, communication, preventing technical debt, etc. If you want to know more about this, you could have a look at this video:  [Mob Programming, A Whole Team Approach - Woody Zuill](https://vimeo.com/131643015).

### When not to use pair programming

While pair programming has a lot of benefits, it can be intense and exhausting if done all the time. Additionally, there are situations where it would be way more productive to have people do (some of) their work separately instead of looking at the same screen together.

One example where pair programming doesn't really make sense is solving a technical problem requiring lots of research, exploration and experimentation. Googling stuff, playing around and building small experiments or quick proof of concepts works way better if developers work on their own machine. Of course, this doesn't mean that they can't check in regularly to discuss their findings.

## Synchronous review

Synchronous review is an approach were you first create something (code, design, ...) on your own and then call someone over in order to get feedback. It's called synchronous because it requires both you and your reviewer to be looking at your work at the same time. We will later compare this to asynchronous review, where that is not the case.

### Advantages of synchronous review

Synchronous review is helpful if the reviewer is not very familiar with the problem you are solving, because direct communication is a convenient way of explaining the context of the problem.

Direct communication is also very helpful if there is the need to have a real discussion about the code instead of just receiving a few remarks.

Another benefit of synchronous review, when compared to pair programming, is that you still get the chance to work on something separately, explore and make your own mistakes.

### Synchronous review and pairing

Synchronous review is clearly different from classical pair programming where a driver and navigator sit together to write the code. However, even when working in pairs, synchronous review can be helpful for situations where classical pair programming doesn't make sense or when you and your pairing partner need a break from the constant interaction for a while.

One way of using synchronous review with your pairing partner is the "divide and conquer" strategy. Instead of solving a problem together as a driver and navigator, you divide the problem into some smaller tasks and divide them amongst the two of you. Each person works separately on their tasks, but you are there to support each other where needed and you frequently sit together to review what you have done and attempt to improve each other's work. This approach can be a good idea when doing some research and experimentation.

An alternative is "supported soloing". This is similar so "divide and conquer", except for the fact that you are now working on completely separate things. However, you are still regularly providing each other with support and feedback. This can work well for seniors working together, a senior supporting a junior or even a small number of seniors supporting a pool of juniors. In this case, it's very important to actually be available for providing feedback and support.

Finally, even when doing classical pair programming, synchronous review can be used if the pair needs some support from the rest of the team to solve a particularly hairy problem or make an important decision.

### Drawbacks of synchronous review

Synchronous review means that both you and your reviewer need to be looking at the work at the same time. While this is sometimes very valuable, it has the drawback of requiring context switches. At the point in time when you would like some feedback, your teammate may fully focused on another problem. This means that you either need to break your colleague's focus, or wait until the colleague is free (and at that moment, you may actually be fully focused on something). Context switches and interruptions can have a huge effect on productivity, especially for tasks that require deep focus and concentration. 

Another drawback of synchronous review is that it does not allow the reviewer to have a look at the code or the problem before actually coming over to review. Without being able to take some time to have good look at the code and let it sink in, the reviewer may fail to spot some potential problems.

## Asynchronous review

Asynchronous review is very similar to synchronous review, in the sense that you still first create something (code, design, ...) on your own and then ask for feedback. The big difference is that asynchronous review does not require you and the reviewer to be looking at the code at the same moment.

Asynchronous review processes typically use some sort of technology that allows you to make your work available for people to review and allows reviewers to provide feedback. A very popular form of this are the pull requests provided by tools as GitHub and Bitbucket. You can push a branch and attach a description of what the goal of your change is, why you made certain decisions, and so on. You and your reviewers can then discuss (parts of) your code through the tool. The pull request also tracks additional changes you make in response to feedback.

### Advantages of asynchronous review

A big advantage of asynchronous review is the fact that it is asynchronous. You can finish and push your code when it is convenient for you, while your reviewer can look at it when it's convenient for them. This also allows the reviewer to have a proper look at the code, taking as much time as needed to really understand what the code does, how it handles certain situations and how it could affect the rest of the system.

Another advantage is that asynchronous review makes it easier to check the readability of the code. With nobody being there to talk the reviewer through the code, they will immediately experience how easy it is to understand what the code is actually doing without additional explanation. And, if the person who wrote the code has actually provided some documentation and explanation when submitting their code, this means there is actually some written documentation which can help future maintainers of the code as well. In fact, most processes involving pull requests are set up in such a way that you can easily find the relevant pull request (including additional documentation) that introduced a certain piece of code into the codebase.

### Asynchronous review and pairing

When applying the pairing strategies described in the section on synchronous review, asynchronous review could be used instead of synchronous review if there is a need or desire to handle things in an asynchronous fashion.

### Drawbacks of asynchronous review

In an asynchronous reviewing process, you may have to wait a while for feedback from you reviewer(s). This means that you will likely need to start working on something different and later switch back to the code that was awaiting review. This is a form of context switching, although you can wait to process the feedback until a time that is convenient for you. For the reviewer, the situation is similar: there is still some context switching going on, but at least they are not interrupted during moments of deep focus.

Deciding what to do while waiting for feedback can sometimes be challenging. The simplest option is often to work on something unrelated to your code change, like other issues, documentation, learning, ... However, if you are keeping commits and issues small (which is typically a good thing), you may run into the situation where the only thing that makes sense to work on is something that depends directly on the code awaiting feedback. This means that, if you later need to make significant changes to your earlier code because of the feedback you received, your new code may need significant changes as well. In this case, it's probably not a good idea to submit your new code as long as the initial code has not been properly reviewed and approved yet. If you come to the point where you would like to submit your new changes but you have still not received proper feedback on the changes they depend on, it may be right time to start asking your colleagues for a synchronous review of the original changes and potentially the new code as well.

In general, the team should make sure that code and comments are reviewed and processed fairly quickly, meaning that the feedback loop stays relatively short. Otherwise, asynchronous review will negatively affect the productivity of the team. The longer the feedback loop gets, the harder it is for a committer or reviewer to switch contexts when they receive feedback on their code or comments. A longer feedback loop  also increases the chance that other changes in the codebase will conflict with the code under review. 

When doing asynchronous review, you should specifically look out for excessive back-and-forth discussion. If it is taking a long time and a lot of discussion to review a piece of code, it is probably a better idea to look at the code together (synchronous review) and possibly even do some pair programming. Some companies also have guidelines asking you to just accept the changes if the code is reasonable and to offer your ideas for improvement as suggestions for new changes rather than reasons for rejecting the current changes.

## Review after the fact

Review after the fact means that code is reviewed after it is committed or pulled into the main branch. One example is a mob review where the entire team sits together to have a look at a piece of code in order to share knowledge and possibly get suggestions for further improvement. It is also an option that developers are notified when commits are made to the main branch and can then have a look at the code and potentially suggest some improvements.

While it is often not ideal to have this as the only kind of review, it could be useful to combine this with some other way of reviewing. For example, you could set up a process where code can be pushed directly to the main branch by a pair, but other developers can check the changes afterwards and suggest additional improvements or request a knowledge sharing session. Review after the fact can also make sense if the current availability of qualified reviewers would not allow for timely review of changes. In that case, it is probably a good idea to explicitly make the team aware that the code has not been reviewed yet.

## Automated review

This one is a bit different, in the sense that there are no humans involved here. Automated review is a great addition to any reviewing process. Some examples are automated code formatting, a linter enforcing a certain coding style and forbidding some bad practices, a script that automatically checks dependencies for security vulnerabilities and licensing issues, ... The more checks you can perform automatically, the more time and energy developers can spend thinking about the actual behavior of the code.

## Resources

- [4 Types Of Code Reviews Any Professional Developer Should Know About](https://dzone.com/articles/4-types-of-code-reviews-any-professional-developer)
- [Pairing with Junior Developers](https://madeintandem.com/blog/2015-1-pairing-with-junior-developers/)
- [Mob Programming, A Whole Team Approach - Woody Zuill](https://vimeo.com/131643015)
- [Why Code Reviews Hurt Your Code Quality and Team Productivity](https://simpleprogrammer.com/code-review-trunk-based-development/)
- [Pairing, Are You Doing it Wrong?](https://www.thoughtworks.com/insights/blog/pairing-are-you-doing-it-wrong)
- [What should a developer do while waiting for a pull request review?](https://dev.to/itsjoekent/what-should-a-developer-do-while-waiting-for-a-pull-request-review)
- [The Art of Pull Requests](https://hackernoon.com/the-art-of-pull-requests-6f0f099850f9)