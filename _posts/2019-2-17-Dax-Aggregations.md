---
layout: post
title: Dax Aggregations Part 1
---
**Aggregations** are one of my favorite new features added to Power BI in 2018. [Adam thinks so too](https://twitter.com/GuyInACube/status/1073693688155529216). The quick summary is that if you have two tables about the same facts at different levels of detail, Power BI can intelligently choose which one to use for each query to get the best performance. This article is about aggregations. If you don’t already know about them, you should learn more about them [here](https://docs.microsoft.com/en-us/power-bi/desktop-aggregations) and [here](https://www.youtube.com/watch?v=RdHSo43LkQg) and [lots](http://radacad.com/power-bi-fast-and-furious-with-aggregations) [of](radacad.com/power-bi-aggregation-step-1-create-the-aggregated-table
) [other](http://radacad.com/dual-storage-mode-the-most-important-configuration-for-aggregations-step-2-power-bi-aggregations) [places](radacad.com/power-bi-aggregations-step-3-configure-aggregation-functions-and-test-aggregations-in-action) first.

This article isn’t about using Aggregations. It’s about how you can…not use them. I’m going to explain how to create “aggregations” without using the Aggregations feature.

Using Dax. 

Of course.

I’m also going to tell you why you might want to do that.

In the article its going to be important to have a clear distinct between the Aggregations feature, configured in the UI and the Dax Measures that use the pattern described below. I’m going to call these measures DAX Aggregations. In contrast with UI Aggregations.

Why
--

I can think of four reasons to use this pattern.
1. No plans have been announced for UI Aggregations to be available in Analysis Services.
2. Currently, you cannot set up a [UI Aggregation over a table in Import storage mode](https://docs.microsoft.com/en-us/power-bi/desktop-aggregations#validations).
![No Aggs over Import Tables PBI Desktop Error Message](https://github.com/savoy9/AlexsPublicPowerBIStuff/blob/master/Manual%20Aggregations/DQ%20Required.png?raw=true "DQ Required")

1. Currently, you cannot use [row level security with UI Aggregations](https://docs.microsoft.com/en-us/power-bi/desktop-aggregations#validations).
2. Doing things you probably shouldn’t using [DAX is fun](https://twitter.com/philseamark?lang=en).

Reasons two and three should be addressed by the time the feature goes GA. And there are also no plans I've seen for Analysis Services to support Composite models, which really make aggregations shine.
RLS is how I came upon this topic. I needed to secure different granularities differently. Which is a great capability and has nothing to do with something as amorphous as performance.

There are many different ways you might want to control granularity security so I expect this technique to still be valuable even when RLS and UI Aggs work together. Which is why I'm writing about it. Also because doing things you probably shouldn't using DAX is fun.

How
--

You use [IsFiltered()](https://dax.guide/isfiltered/). That’s all there is to it. Move along.
<br>
…
<br>
Ok, there is a *little* more to it than just that.

Just like a UI Aggregation, to set up a Dax Aggregation, you need a data model with two tables about the same facts. For this article, we’re going to be using the [Wide World Importers](https://docs.microsoft.com/en-us/sql/samples/wide-world-importers-what-is?view=sql-server-2017) sample Data Warehouse available from Microsoft. Not the OLTP DB. I don’t know anything about OLTP. 

For this example, we'll use the ‘Fact Sale’ table and all its related dimensions. I’ve also created  an aggregate table, ‘Fact Sale Agg’ that excludes Invoice Date, Delivery Customer (as distinct from Bill To Customer), and Employee ID as dimensions, as well as grouped away the row specific degenerate dimensions in fact table.

![Relationship Diagram of Example Data Model](https://github.com/savoy9/AlexsPublicPowerBIStuff/blob/master/Manual%20Aggregations/WWI%20Agg%20Model%20Example.png?raw=true "Relationship Diagram")

Now that we have a model to talk about, let's get back to what an Aggregation does. At the simplest level, it asks the following question: 
*Does a given query include any columns that are below the granularity of the aggregated fact table*
If the answer to that question is yes, then the query must be evaluated against the un-aggregated fact table in order to return the correct result. Conversely, if the answer is no, the aggregated fact table may be used without issue.

The aggregation feature uses the information you provide in relationships and the group by options in the UI to determine the answer to that question. Then it uses the answer to that question to switch the column refrenced by any measure using the specified operations to the correct column in the aggregated table automatically.

Let's try to do that in DAX. For a single column, it might look like this:

>Dax&nbsp;Aggregation&nbsp;Measure&nbsp;:=<br><span class="Keyword" style="color:#0070FF">IF</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span><br><span class="indent4">&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="Keyword" style="color:#0070FF">ISFILTERED</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span>&nbsp;table[Column]&nbsp;<span class="Parenthesis" style="color:#969696">)</span>,<br><span class="indent4">&nbsp;&nbsp;&nbsp;&nbsp;</span>[Detail&nbsp;Table&nbsp;Measure],<br><span class="indent4">&nbsp;&nbsp;&nbsp;&nbsp;</span>[Aggregated&nbsp;Table&nbsp;Measure]<br><span class="Parenthesis" style="color:#969696">)</span><br>
![Daxformater.com Badge](https://www.daxformatter.com/wp-content/themes/daxformatter/images/daxformatter-embed.png "Daxformater.com")

Thats easy enough. How would we expand this pattern to more columns? By using way too many OR() statements. Except, we don’t want to use [OR()](https://dax.guide/or/) because it only takes two arguments. Instead, we want to use the Or Operator, [\|\|](https://dax.guide/op/or/) because it expands to n arguments. And we're going to need n arguments.

 >[ISFILTERED()](https://dax.guide/isfiltered/)
 *Returns true when there are direct filters on the specified column.*

As a result we need to list every single column that filters the detail table that we’ve excluded from Aggregate Table. Like this:

>Dax&nbsp;Aggregation&nbsp;Measure&nbsp;:=<br><span class="Keyword" style="color:#0070FF">IF</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span><br><span class="indent4">&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="Keyword" style="color:#0070FF">ISFILTERED</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span>&nbsp;'table&nbsp;1'[Column1]&nbsp;<span class="Parenthesis" style="color:#969696">)<br></span><span class="indent8">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;||&nbsp;<span class="Keyword" style="color:#0070FF">ISFILTERED</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span>&nbsp;'table&nbsp;1'[Column&nbsp;2]&nbsp;<span class="Parenthesis" style="color:#969696">)</span><br><span class="indent8">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>||&nbsp;<span class="Keyword" style="color:#0070FF">ISFILTERED</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span>&nbsp;'table&nbsp;2'[Column&nbsp;3]&nbsp;<span class="Parenthesis" style="color:#969696">)</span><br><span class="indent8">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;...<br><span class="indent8">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>||&nbsp;<span class="Keyword" style="color:#0070FF">ISFILTERED</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span>&nbsp;'table&nbsp;n'[Column&nbsp;m]&nbsp;<span class="Parenthesis" style="color:#969696">)</span>,<br><span class="indent4">&nbsp;&nbsp;&nbsp;&nbsp;</span>[Detail&nbsp;Table&nbsp;Measure],<br><span class="indent4">&nbsp;&nbsp;&nbsp;&nbsp;</span>[Aggregated&nbsp;Table&nbsp;Measure]<br><span class="Parenthesis" style="color:#969696">)</span><br> 
![Daxformater.com Badge](https://www.daxformatter.com/wp-content/themes/daxformatter/images/daxformatter-embed.png "Daxformater.com")

Applied to our example model, this pattern becomes:

>Total&nbsp;Sales&nbsp;DAX&nbsp;Agg&nbsp;:=<br><span class="Keyword" style="color:#0070FF">IF</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span><br><span class="indent4">&nbsp;&nbsp;&nbsp;&nbsp;</span><span class="Keyword" style="color:#0070FF">ISFILTERED</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span>&nbsp;'Dimension&nbsp;Employee'[Employee]&nbsp;<span class="Parenthesis" style="color:#969696">)</span><br><span class="indent8">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>||&nbsp;<span class="Keyword" style="color:#0070FF">ISFILTERED</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span>&nbsp;'Dimension&nbsp;Employee'[Employee&nbsp;Key]&nbsp;<span class="Parenthesis" style="color:#969696">)</span><br><span class="indent8">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>||&nbsp;<span class="Keyword" style="color:#0070FF">ISFILTERED</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span>&nbsp;'Dimension&nbsp;Employee'[Employee]&nbsp;<span class="Parenthesis" style="color:#969696">)</span><br><span class="indent8">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>||&nbsp;<span class="Keyword" style="color:#0070FF">ISFILTERED</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span>&nbsp;'Dimension&nbsp;Employee'[Is&nbsp;Salesperson]&nbsp;<span class="Parenthesis" style="color:#969696">)</span><br><span class="indent8">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>||&nbsp;<span class="Keyword" style="color:#0070FF">ISFILTERED</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span>&nbsp;'Dimension&nbsp;Employee'[Preferred&nbsp;Name]&nbsp;<span class="Parenthesis" style="color:#969696">)</span><br><span class="indent8">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>||&nbsp;<span class="Keyword" style="color:#0070FF">ISFILTERED</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span>&nbsp;'Dimension&nbsp;Invoice&nbsp;Date'[Date]&nbsp;<span class="Parenthesis" style="color:#969696">)</span><br><span class="indent8">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>||&nbsp;<span class="Keyword" style="color:#0070FF">ISFILTERED</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span>&nbsp;'Dimension&nbsp;Invoice&nbsp;Date'[Calendar&nbsp;Month&nbsp;Label]&nbsp;<span class="Parenthesis" style="color:#969696">)</span><br><span class="indent8">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>||&nbsp;<span class="Keyword" style="color:#0070FF">ISFILTERED</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span>&nbsp;'Dimension&nbsp;Invoice&nbsp;Date'[Calendar&nbsp;Year&nbsp;Label]&nbsp;<span class="Parenthesis" style="color:#969696">)</span><br><span class="indent8">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>||&nbsp;<span class="Keyword" style="color:#0070FF">ISFILTERED</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span>&nbsp;'Dimension&nbsp;Invoice&nbsp;Date'[Fiscal&nbsp;Month&nbsp;Label]&nbsp;<span class="Parenthesis" style="color:#969696">)</span><br><span class="indent8">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>||&nbsp;<span class="Keyword" style="color:#0070FF">ISFILTERED</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span>&nbsp;'Dimension&nbsp;Invoice&nbsp;Date'[Fiscal&nbsp;Year&nbsp;Label]&nbsp;<span class="Parenthesis" style="color:#969696">)</span><br><span class="indent8">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>||&nbsp;<span class="Keyword" style="color:#0070FF">ISFILTERED</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span>&nbsp;'Dimension&nbsp;Invoice&nbsp;Date'[ISO&nbsp;Week&nbsp;Number]&nbsp;<span class="Parenthesis" style="color:#969696">)</span><br><span class="indent8">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>||&nbsp;<span class="Keyword" style="color:#0070FF">ISFILTERED</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span>&nbsp;'Dimension&nbsp;Invoice&nbsp;Date'[Month]&nbsp;<span class="Parenthesis" style="color:#969696">)</span><br><span class="indent8">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>||&nbsp;<span class="Keyword" style="color:#0070FF">ISFILTERED</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span>&nbsp;'Dimension&nbsp;Invoice&nbsp;Date'[Short&nbsp;Month]&nbsp;<span class="Parenthesis" style="color:#969696">)</span><br><span class="indent8">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>||&nbsp;<span class="Keyword" style="color:#0070FF">ISFILTERED</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span>&nbsp;'Dimension&nbsp;Invoice&nbsp;Date'[Day]&nbsp;<span class="Parenthesis" style="color:#969696">)</span><br><span class="indent8">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>||&nbsp;<span class="Keyword" style="color:#0070FF">ISFILTERED</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span>&nbsp;'Fact&nbsp;Sale'[Description]&nbsp;<span class="Parenthesis" style="color:#969696">)</span><br><span class="indent8">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>||&nbsp;<span class="Keyword" style="color:#0070FF">ISFILTERED</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span>&nbsp;'Fact&nbsp;Sale'[Package]&nbsp;<span class="Parenthesis" style="color:#969696">)</span><br><span class="indent8">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>||&nbsp;<span class="Keyword" style="color:#0070FF">ISFILTERED</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span>&nbsp;'Fact&nbsp;Sale'[Salesperson&nbsp;Key]&nbsp;<span class="Parenthesis" style="color:#969696">)</span><br><span class="indent8">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>||&nbsp;<span class="Keyword" style="color:#0070FF">ISFILTERED</span><span class="Parenthesis" style="color:#969696">&nbsp;(</span>&nbsp;'Fact&nbsp;Sale'[Delivery&nbsp;Date&nbsp;Key]&nbsp;<span class="Parenthesis" style="color:#969696">)</span>,<br><span class="indent4">&nbsp;&nbsp;&nbsp;&nbsp;</span>[Total&nbsp;Sales&nbsp;Detail],<br><span class="indent4">&nbsp;&nbsp;&nbsp;&nbsp;</span>[Total&nbsp;Sales&nbsp;Agg]<br><span class="Parenthesis" style="color:#969696">)</span><br>
![Daxformater.com Badge](https://www.daxformatter.com/wp-content/themes/daxformatter/images/daxformatter-embed.png "Daxformater.com")

What a mess of code. And that’s with a relatively small number of excluded dimensions.

Can we simplify it? Maybe. There is no equivalent IsTableFiltered() function which returns true if any of the columns in the table are explicitly filtered. We could compare the number of rows in COUNTROWS(Table) with CALCULATE(COUNTROWS(Table),ALL(Table)). I haven’t tested it, but that doesn’t sound very fast.

We might also be able to use IsCrossFiltered(). However, this is where the big caveat comes in. IsCrossFiltered() “Returns TRUE when any column of the table specified or another column a related table is being filtered. Otherwise returns FALSE.” We’re going to have to think hard any bidirectional relationships or measures that invoke the Crossfilter() function involved, or it’s going to mess us up. I haven’t tested this either.

For now, at least, we’ve got a whole mess of Dax. Remind me, why this is a good idea?

Should
--

Should this be considered an acceptable solution? The main downside is complexity. You have to set up a measure with dozens of lines for every fact in your Agg table. Also, while I haven't tested this explicitly, my understanding is the If(IsFiltered()) pattern is Formula Engine territory, so you aren't going to want to nest your Dax Agg function inside an iterator. If you have any measures using sumx or the like, you'll want to setup separate Dax Aggregation measures for them too.

Measuring performance is complicated. There are a lot variables that can change your results and I've ignored most of them, so your mileage may vary considerably. 

For this article, I tested the query times of SUM('Fact Sale'[Total Excluding Tax]). I performed my test in three filter contexts and repeated the test 3 times. I only tested relationship-based UI aggregations and I didn’t test DQ for the Agg table. The direct query source was the [World Wide Importers DW](https://docs.microsoft.com/en-us/sql/samples/wide-world-importers-dw-install-configure?view=sql-server-2017) sample with the [Large Sale table](https://docs.microsoft.com/en-us/sql/samples/wide-world-importers-generate-data?view=sql-server-2017#generate-data-in-wideworldimportersdw-for-performance-testing) populated running on a dedicated [P1 Azure SQL DB](https://azure.microsoft.com/en-us/pricing/details/sql-database/single/) with no other users. The aggregated table had 27x fewer rows than the unaggregated table.  The employee row context is not included in the agg table granularity and so isn’t able to generate an agg hit. Complete results along with a copy of the .pbix are available on [my github](https://github.com/savoy9/AlexsPublicPowerBIStuff/tree/master/Manual%20Aggregations).

![Testing Results Screenshot](https://github.com/savoy9/AlexsPublicPowerBIStuff/blob/master/Manual%20Aggregations/Testing%20Summary.png?raw=true "query response times in milliseconds")
- Both types of aggregations have an overhead over just querying an imported table. 
- Both aggregation types are significantly faster than direct query against the large ‘Fact Sale’ table. 
- Performance over an imported but unaggregated ‘Fact Sale’ was better but not wildly better. However, 12 million rows is a pedestrian fact table and a simple sum the simplest of measures. Increased complexity will probably favor the agg pattern.
- In my tests, Dax Aggregations outperformed UI Aggregations. However, I don’t think this data is even close to enough to say that this is usually, or even often the case. Once again, my tests are very simple compared to all the cases you’re likely to encounter. None the less, it is very interesting.

The bottom line is that a Dax Aggregation does not result in a slower query. They definitely improve query times over not setting up any aggregation. Power BI is very fast at determining row context.

There are still lots of reasons not to use Dax Aggerations
- There is a perfectly good UI feature for most cases
- These measures create development overhead for every model change
As a result, I would recommend using this technique only if UI Aggregations are not permitted against your model. However, if you're trying to control security by granularity, then Dax Aggregations may be just the thing (at least until more details about how UI Aggs and RLS work together is available).

Also, DAX is fun.

**Part 2**, on applying RLS and this pattern together in the WWI sample model is coming soon.

>Disclaimer: I work for Microsoft. More specifically, I work for Microsoft Advertising. We sell the ads that are served on Microsoft websites. Mostly Bing. Much to my chagrin, I don’t have any of that [sweet sweet inside information](https://twitter.com/GuyInACube/status/1073692665571655681) about Power BI. Views are my own.