# Compile.fnl

**Table of contents**

- [`compile-buffer`](#compile-buffer)
- [`compile-file`](#compile-file)
- [`compile-module`](#compile-module)
- [`compile-range`](#compile-range)
- [`compile-selection`](#compile-selection)
- [`compile-string`](#compile-string)

## `compile-buffer`
Function signature:

```
(compile-buffer buf ?options)
```

Read the contents of `buf` and compile into lua, returns `true lua` or
  `false error`. Accepts an optional `options` table as described by Fennels
  API documentation.

## `compile-file`
Function signature:

```
(compile-file fnl-path ?options)
```

Read contents of `fnl-path` and compile into lua, returns `true lua` or
  `false error`. Will raise if file does not exist. Accepts an optional
  `options` table as described by Fennels API documentation.

## `compile-module`
Function signature:

```
(compile-module modname ?options)
```

Use hotpots module searcher to find `modname` and compile it into lua code,
  returns `true fnl-code` or `false error`. Accepts an optional `options` table
  as described by Fennels API documentation.

## `compile-range`
Function signature:

```
(compile-range buf start-pos stop-pos ?options)
```

Read `buf` from `start-pos` to `end-pos` and compile into lua, returns `true
  lua` or `false error`. Positions can be `line-nr` or `[line-nr col]`. Accepts
  an optional `options` table as described by Fennels API documentation.

## `compile-selection`
Function signature:

```
(compile-selection ?options)
```

Read the current selection and compile into lua, returns `true lua` or
  `false error`. Accepts an optional `options` table as described by Fennels
  API documentation.

## `compile-string`
Function signature:

```
(compile-string str ?options)
```

Compile given `str` into lua, returns `true lua` or `false error`. Accepts
  an optional `options` table as described by Fennels API documentation.


<!-- Generated with Fenneldoc v0.1.9
     https://gitlab.com/andreyorst/fenneldoc -->
