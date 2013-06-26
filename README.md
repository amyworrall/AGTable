AGTable
=======

AGTable is a library that can function as the data source and delegate of a UITableView.

The original motivation for writing AGTable was to make it easier to make static table views (for menus or settings screens), but to enable the visibility of rows to be toggled on and off. Thus, the app author could define all the possible rows up-front, and then choose not to display ones that were currently inappropriate (e.g. ones relating to premium features of your app).

AGTable was originally developed by Agant Ltd., and is used in apps such as [UK Train Times](https://itunes.apple.com/gb/app/uk-train-times/id306687757?mt=8). It is being made available as an open source library with Agant's permission, but this open sourced version is not owned or supported by Agant.

Status
======

AGTable is used in a number of shipping products. However, since it is only just (as of June 26, 2013) being released publicly, it probably has  idiosyncrasies or undocumented assumptions that may not be explicit. I'm not yet ready to provide any support to users of AGTable: it is being provided as-is.

There are various parts of AGTable that may need work. The mechanisms for animating changes to the UITableView are particularly in need of some tender loving care. 

Aside from some comments in the headers, AGTable is not yet documented.

Requirements
============

AGTable currently requires iOS 5. To use bindings, it requires iOS 6.

Contributing
============

I'm not actively seeking contributions for AGTable. It may take me a while to respond to pull requests, especially ones that make large changes, due to the need to ensure the library continues to work with existing apps that use it. Pull requests that come with unit tests are more likely to be considered.


Building AGTable
================

AGTable is built as a static framework. Doing this requires modifying your Xcode installation using [this script](https://github.com/kstenerud/iOS-Universal-Framework).

Getting started
===============

An AGTableDataController takes over the delegate and data source responsibilities for a single UITableView. You can make one directly, using the initWithTableView: method, or alternatively you can use the AGTableViewController class, which is simply a UITableViewController subclass automatically set up to use a table data controller.

Populate your table data controller by adding sections and rows (use methods such as appendNewSectionWithTitle:, and AGTableSection's appendNewRowWithCellClass:). This should be done once, before the table view is first displayed (I usually do it in loadView, being sure to call [super loadView] first of all). The philosophy behind AGTableDataController is that you don't add and delete AGTableRow or AGTableSection objects once the table has been displayed. You can however toggle their visibility, refresh them to show different things, or use the dynamic rows functionality to populate your table view from an array of model objects.

License
=======

AGTable is MIT licensed. See the LICENSE file for details.