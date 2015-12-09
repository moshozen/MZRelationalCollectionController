# MZRelationalCollectionController

[![CI Status](http://img.shields.io/travis/moshozen/MZRelationalCollectionController.svg?style=flat)](https://travis-ci.org/moshozen/MZRelationalCollectionController)
[![Version](https://img.shields.io/cocoapods/v/MZRelationalCollectionController.svg?style=flat)](http://cocoapods.org/pods/MZRelationalCollectionController)
[![License](https://img.shields.io/cocoapods/l/MZRelationalCollectionController.svg?style=flat)](http://cocoapods.org/pods/MZRelationalCollectionController)
[![Platform](https://img.shields.io/cocoapods/p/MZRelationalCollectionController.svg?style=flat)](http://cocoapods.org/pods/MZRelationalCollectionController)

## Overview

MZRelationalCollectionController makes it easy to write data-driven iOS apps.
It manages KVO on a named relation of an object, providing delegate notification
on various changes to the content of the relation as well as on changes to
specified attributes of the objects in the relation collection. It's designed to
handle the data management component of table and collection style view
controllers quickly and easily, helping you keep the size of your controllers
down and letting you focus on the actual intent of your application instead of
managing data and keeping your UI up to date.

## Usage

An `MZRelationalCollectionController` instance is constructed as in the following example:


    [MZRelationalCollectionController collectionControllerForRelation:@"albums"
                                                             onObject:artist
                                                           filteredBy:[NSPredicate predicateWithFormat:@"liveAlbum == NO"]
                                                             sortedBy:@[[NSSortDescriptor sortDescriptorWithKey:@"releaseDate" ascending:YES]]
                                               observingChildKeyPaths:@[@"title"]
                                                             delegate:self];

After initialization, this controller's `collection` object will contain all studio albums by the specified artist ordered by release date. In addition,
the controller's delegate (if specified) will receive relevant messages when objects enter, leave, or move around within the collection (subject to the
filtering predicate, if specified). In addition, the delegate will receive a message when any of the collection's objects change any of their values specified
in the `observingChildKeyPaths` parameter.

All of this amounts to a very simple way to write table and collection view controllers that automatically stay up to date with changes in their 
underlying collections. Typically you will create a new `MZRelationalCollectionController` instance whenever your controller's main data object changes 
(see `-[MZArtistTableViewController setArtist]` in the example project). The `MZRelationalCollectionControllerDelegate` methods map directly to corresponding 
methods on `UITableView` and `UICollectionView`, so the plumbing to keep your view up to date is very striaghtforward and easy to write (in fact, it's basically boilerplate in most cases).

MZRelationalCollectionController is designed to navigate a collection that is accessed through a property on an existing model object (such as 
navigating through an artist's albums or the tracks within a given album). It doesn't try to 
handle the case at the top level of an application, where the list of objects is usually global
(e.g. a complete list of artists). In practice this often isn't a problem since many applications
have an implicit 'top-level' object such as the current user or an application-wide Library. In 
these cases the application's top-level navigation list is in fact a collection off of an existing 
model object (even if the user doesn't see this top-level object).

There are some places where MZRelationalCollectionController isn't very well suited. In particular,
it maintains several data structures in-memory that are O(*n*) in the size of the collection. This 
isn't generally a problem for smaller collection (less than several hundred in size, say), however 
collections which are larger than that may not be the best fit for MZRelationalCollectionController.

## Example App & Tests

The example app provides a comprehensive introduction to MZRelationalCollectionController. 
It manages a catalog of music, organized in a hierarchy by artist, album, and tracks. The
controllers themselves are standard-issue table view controllers, and use `MZRelationalCollectionController`
instances to source their data and automatically update the table when the underlying data changes. A complete test suite is also included.

To run the example project simply clone the repo, open the
`Example/MZRelationalCollectionController.xcworkspace` workspace, and go to
town.

## Known Issues

* Support for replacement operations on `NSArray` collections (ie: `- replaceObjectAtIndex:withObject:` and its ilk) aren't supported. Replacement
calls are tricky in general for a number of reasons, though support can be added if anyone
needs it. In 'typical' use (i.e.: on top of Core Data) this isn't a problem since all relations
are `NSSet` collections anyway.

* There is limited support for `NSArray` collections with no explicitly specified
sort descriptors. In principle they should work, however there are a number of likely
edge cases which are not well tested.

* There is no support for filtering, sorting, or observing on nested to-many keypaths (for example,
it's not possible for a controller on an `Artist`'s `albums` relation to observe the total duration 
of the songs on each of the albums in the collection). This is a KVO limitation, and is [documented here](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/KeyValueObserving/Articles/KVODependentKeys.html#//apple_ref/doc/uid/20002179-SW5)

## Requirements

MZRelationalCollectionController requires a KVO/KVC compliant model layer (such as
Core Data). We also require ARC.

## Installation

MZRelationalCollectionController is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "MZRelationalCollectionController"
```

## Author

Mat Trudel, mat@geeky.net

## License

MZRelationalCollectionController is available under the MIT license. See the LICENSE file for more info.
