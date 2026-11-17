---
layout: post
title: The Necessary Details That Aren’t Shown in Your Azure BI Architecture Diagram
---
## Or, How the difference between direct query, live connect, and import impact data infastructure.

When we talk about Azure architectures for data warehousing or analytics, we usually show a diagram that looks like the below.
>*The Modern Data Warehouse Architecture<p style="text-align: center;">![The Microsoft Standard Azure Data Architecture Diagram](https://github.com/savoy9/AlexsPublicPowerBIStuff/blob/master/Azure%20Diagram/2019-02-18%2020_13_23-Modern%20data%20warehouse.png?raw=true "Modern DW Diagram")
[https://azure.microsoft.com/en-us/solutions/architecture/modern-data-warehouse/](https://azure.microsoft.com/en-us/solutions/architecture/modern-data-warehouse/)</p>*


Megan Longoria recently wrote a post, [The Necessary Extras That Aren’t Shown in Your Azure BI Architecture Diagram](https://datasavvy.me/2019/01/11/the-necessary-extras-that-arent-shown-in-your-azure-bi-architecture-diagram/), resonated with something I had been trying to explain to people at work. I figure its worth writing about it for everyone. Like Megan, I'm going to expand on the above diagram. But instead of filling in around the edges, I'm going to focus on the business end of the chart for us Power BI fans and flesh out what's missing and why that might lead the uninitated to build an architecture designed for failure.

## It's the part where Power BI connects to the Data Warehouse
![The Buiness End of the Diagram: Azure DW to AAS to PBI](https://github.com/savoy9/AlexsPublicPowerBIStuff/blob/master/Azure%20Diagram/2019-02-18%2020_28_28-Business-End.png?raw=true "The Business End")

This part of the diagram glosses over some very important choices that you will have to make. We're going to redraw the diagram, but first, let's talk about each of the pieces in the diagram.

**SQL**

**Analysis Services**
**Power BI**

1. Import: This is the standard mode for Power BI. 