# Eval.fnl

**Table of contents**

- [`eval-buffer`](#eval-buffer)
- [`eval-file`](#eval-file)
- [`eval-module`](#eval-module)
- [`eval-operator`](#eval-operator)
- [`eval-operator-bang`](#eval-operator-bang)
- [`eval-range`](#eval-range)
- [`eval-selection`](#eval-selection)
- [`eval-string`](#eval-string)
- [`eval_operator`](#evaloperator)
- [`fnl`](#fnl)
- [`fnldo`](#fnldo)
- [`fnlfile`](#fnlfile)

## `eval-buffer`
Function signature:

```
(eval-buffer buf ?options)
```

Evaluate the given `buf` and return the result, or raise an error. Accepts
  an optional `options` table as described by Fennels API documentation.

## `eval-file`
Function signature:

```
(eval-file fnl-file ?options)
```

Read contents of `fnl-path` and evaluate the contents, returns the result or
  raises an error. Accepts an optional `options` table as described by Fennels
  API documentation.

## `eval-module`
Function signature:

```
(eval-module modname ?options)
```

Use hotpots module searcher to find the *file* for `modname`, load and
  evaluate its contents then return the result or raises an error. Accepts an
  optional `options` table as described by Fennels API documentation.

## `eval-operator`
Function signature:

```
(eval-operator)
```

**Undocumented**

## `eval-operator-bang`
Function signature:

```
(eval-operator-bang)
```

**Undocumented**

## `eval-range`
Function signature:

```
(eval-range buf start-pos stop-pos ?options)
```

Evaluate `buf` from `start-pos` to `end-pos` and return the results, or
  raise on error. Accepts an optional `options` table as described by Fennels
  API documentation.

## `eval-selection`
Function signature:

```
(eval-selection ?options)
```

Evaluate the current selection and return the result, or raise an error.
  Accepts an optional `options` table as described by Fennels API
  documentation.

## `eval-string`
Function signature:

```
(eval-string code ?options)
```

Evaluate given fennel `code` and return the results, or raise on error.
  Accepts an optional `options` table as described by Fennels API
  documentation.

## `eval_operator`
Function signature:

```
(eval_operator)
```

**Undocumented**

## `fnl`
Function signature:

```
(fnl start stop code)
```

**Undocumented**

## `fnldo`
Function signature:

```
(fnldo start stop code)
```

**Undocumented**

## `fnlfile`
Function signature:

```
(fnlfile file)
```

**Undocumented**


<!-- Generated with Fenneldoc v0.1.9
     https://gitlab.com/andreyorst/fenneldoc -->
