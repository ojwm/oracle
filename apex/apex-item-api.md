# APEX Item API

<https://docs.oracle.com/en/database/oracle/apex/24.1/aexjs/apex.item.html>.

## `getValue`

Returns the current value of an Oracle APEX item as either a single string value or array of string values if the item supports multiple values.

Shorthand:

* `$v` returns the current value as a single string value or a colon separated list of values.
* `$v2` is direct shorthand for `getValue`.

## `setValue`

Sets the Oracle APEX item value.

`$s` is shorthand for `setValue`.

## `isItem` and `$x`

* `isItem` returns true if and only if there is a DOM element that has had an item interface created for it with `apex.item.create`.
* `$x` returns a DOM node if the element is on the page, or returns false if it is not.
