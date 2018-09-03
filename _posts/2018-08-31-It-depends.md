---
layout: post
title: It depends - the best answer to most software development questions
tags: software-development
toc: true
---

I think I have finally discovered the best answer to most software development questions. It goes like this: *"It depends"*.

- Should I use Java or Node.js? *It depends*
- Should I use SQL Server or MongoDB? *It depends*
- Should I really have more unit than integration tests? *It depends*
- Should I apply DDD when building this large application? *It depends*

Of course, this answer in itself doesn't get you anywhere. However, I do believe that almost every decision you make when developing or designing software is a trade-off. There are a lot of areas to consider, including development effort, maintenance effort, correctness, performance, usability, etc. Not only are most of these hard to quantify at the moment when you make the decision, but typically we also need to make tradeoffs within those areas. We may trade development time right now for development time when we are adding features. We may trade performance in handling use case A for performance in handling use case B.

## Stop looking for perfect solutions

When you are facing a challenge, it is very tempting to go looking for the perfect solution. I also regularly catch myself attempting to find *The Best Solution®* or to do something *The Right Way™*. The problem with this is that you are looking for something which probably doesn't exist. Any approach you choose will likely have some drawbacks or limitations that some other approach doesn't have. However, that other approach will likely have some drawbacks or limitations of its own. Everything is a tradeoff.

This is what makes software development so interesting. It's also what can make software development extremely frustrating at times.

## Start looking for good solutions and flexibility

What should we look for, if we shouldn't look for perfect solutions? I think we should be looking for two things:

- Good solutions that make sense and for which we don't see an alternative that is clearly much better
- Flexibility through good architecture and coding practices

If you are facing a challenge, there are likely several good solutions that will work well. After you've spent a reasonable amount of time thinking of solutions and researching existing ones, you will probably have a set of alternatives to choose from. If there is one solution that stands out, for example because its drawbacks are less relevant to your specific challenge than the drawbacks of the others, simply go with that solution. If you have a hard time choosing between a set of alternative solutions, the best course of action is probably to just choose one of them. The harder it is to decide between alternative solutions, the more likely it is that all of them are equally good. Just choosing one of them and implementing it will provide you with (hopefully) a working solution as well as a better understanding of both the challenge you are facing and the approach you have currently chosen.

The application of good architecture and coding practices should provide you with some degree of flexibility, making it relatively easy to make changes to your software. These changes can include switching to a different solution from your set of alternatives, either because you discovered some new benefits or drawbacks of an approach or because your specific situation has changed. Do note, however, that the question of how much flexibility you need is also best answered using *"It depends"*. Additional flexibility typically comes a the expense of additional layers of abstraction, which may or may not be overkill for your application and team.

## What about best practices?

Best practices are widely accepted as good solutions, but that doesn't mean they are perfect. Most best practices come with a warning label stating that there are probably some situations where you would want to use another option. This means that it is perfectly possible that you know a best practice, understand its benefits, but still choose to use a different solution. It's not even that unusual that there are different best practice solutions to the same problem that use a completely different approach. If you see two schools of thought vehemently arguing over which is best, it is likely that they both have a good approach that will work.

Then again, if there is one clear best practice approach regarding your problem and you don't see a significant reason not to use it, you are probably better off going with that approach.

## Documentation of the decision process

When I am trying to find a good solution for a problem I'm facing, I find it helpful to document the benefits and drawbacks of the different alternatives, along with the reasons why I chose a particular one of them. If you need to reevaluate your approach at some point in time, you can use this documentation as a starting point for your analysis.

## Moving to a different solution

What if, for some reason, you are convinced that the approach you are currently using is clearly inferior to some other approach? Even if your architecture and code are flexible, there are some costs and risks associated with making the change. The benefits of switching to the other approach may or may not outweigh those costs and risks. So, should you make the change? *It depends.*