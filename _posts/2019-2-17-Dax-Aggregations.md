---
layout: post
title: Dax Aggregations Part 1
---


>Disclaimer: I work for Microsoft. More specifically, I work for Microsoft Advertising. We sell the ads that are served on Microsoft websites. Mostly Bing. Much to my chagrin, I don’t have any of that [sweet sweet inside information](https://twitter.com/GuyInACube/status/1073692665571655681) about Power BI. Views are my own.

**Aggregations** are one of my favorite new features added to Power BI in 2018. Adam thinks so too. The quick summary is that if you have two tables about the same facts at different levels of detail, Power BI can intelligently choose which one to use for each query to get the best performance. This article is about aggregations. If you don’t already know about them, you should read more about them here and here and lots of other places.

This article isn’t about using Aggregations. It’s about how you can…not use them. I’m going to explain how to create “aggregations” without using the Aggregations feature.

Using Dax.

Of course.

I’m also going to tell you why you might want to do that.

BelowIt might get a little confusing, so I’m going to call these new measures DAX Aggregations. In contrast with UI Aggregations.

Why
========