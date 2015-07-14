---
title: ng-contextmenu
date: 2014-06-21 16:10:35
tags:
layout: post.jade
---
[angularjs]: http://angularjs.org
[bootstrap]: http://getbootstrap.com
[ng-contextmenu]: https://github.com/ds82/ng-contextmenu


I published a first (beta) version of my [angularjs]() module [ng-contextmenu](), yesterday. This module uses the [bootstrap]()'s dropdown menu's to add angular.js powered contextmenus to arbitary HTML Elements.

See in in action:

<a class="jsbin-embed" href="http://jsbin.com/hodul/embed?output">JS Bin</a><script src="http://static.jsbin.com/js/embed.js"></script>

It's really easy to use. Just add the angular module and the css file to your page and load the module into your angular app like this:

```js
var app = angular.module('app', [
  'io.dennis.contextmenu'
]);
```
Then use the directives ***contextmenu***, ***contextmenu-container*** and ***contextmenu-item*** in your templates:

```js
<!-- contextmenu -->
<div contextmenu="meta.contextmenu" class="dropdown contextmenu">
  <ul class="dropdown-menu" role="menu">
    <li ng-bind="meta.contextmenu.$item.foo"></li>
    <li>
      <a href ng-click="do( meta.contextmenu.$item )">
        do!
      </a>
    </li>
  </ul>
</div>
```

```js
<table class="table" contextmenu-container="meta.contextmenu">
  <tr>
    <th>Col1</th>
    <th>Col2</th>
  </tr>
  <tr ng-repeat="row in list" contextmenu-item="row">
    <td>{{row.foo}}</td>
    <td>{{row.bar}}</td>
  </tr>
</table>
```

No extra JS code required at all. [ng-contextmenu] only uses directives to link items to actions defined in your controller. *None* of the directives use isolated scopes what makes them really leightweight and fast.
