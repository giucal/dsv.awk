# Delimiter-separated values support for Awk

`dsv.awk` is a preamble for Awk programs that reads [delimiter-separated
values][DSV] into field variables.

[DSV]: https://en.wikipedia.org/wiki/Delimiter-separated_values

It defaults to CSV, but can be instructed to read any DSV variant that, whenever
it does, quotes fields and escapes characters as described in [RFC4180].

The following variables affect parsing:

| Variable | Description             | Default    | Example alternatives |
| -------- | ----------------------- | ---------- | -------------------- |
| `VS`     | Value separator         | `,`        | `;`, HT (as in TSV)  |
| `VQ`     | Value-quoting character | `"`        | `'`, `` ` ``         |
| `RS`     | Record separator        | Awk's (LF) | CRLF                 |

Awk's special variable `FS` is ignored in favor of `VS`. Unlike `FS`, `VS` is a
literal string, not a regular expression.

    BEGIN { VS = "." } 1

| Input   | Output  |
| ------- | ------- |
| `a.b.c` | `a b c` |
| `a-b-c` | `a-b-c` |

Also, whitespace is never trimmed:

    BEGIN { VS = " "; OFS = "," } 1

| Input                         | Output      |
| ----------------------------- | ----------- |
| `a b c`                       | `a,b,c`     |
| SP `a` SP SP `b` SP SP `c` SP | `,a,,b,,c,` |

Since LF is commonplace as record separator, it's preferred over CRLF as the
default `RS`.

The following limitations are inherited from Awk (although they're compatible
with [RFC4180]):

- Characters are in fact _bytes_.
- The NUL character is not supported, neither in values nor as delimiter.

## Usage

You can use `dsv.awk` as a template for new Awk programs. Or you can combine it
with existing programs:

    awk -f dsv.awk -f script.awk ...      # at runtime with awk's own -f option
    cat dsv.awk script.awk | awk -f- ...  # by concatenation

You can put actions both before and after `dsv.awk`:

    awk -f before.awk \
        -f dsv.awk \
        -f after.awk

Actions before `dsv.awk` will pre-process the input. Actions after `dsv.awk`
will receive the unquoted and de-escaped parsed values.

## Example record

This record:

    x,"Quoted field. Can contain commas, ""double quotes""

    and line feeds.",y

will be read as:

    $1 = "x"
    $2 = "Quoted field. Can contain commas, " \
         "\"double quotes\"\n\n" \
         "and line feeds."
    $3 = "y"

## Utility functions

`dsv.awk` also includes a couple routines for helping with the conversion from a
DSV format to another.

### `dsv_quote(v [, ovs = "" [, ovq = VQ [, ors = RS]]])`

Quotes and escapes `v` if necessary, i.e. if it contains `ovs`, `ovq` or `ors`.
If `ovs == ""` or isn't given, `v` is quoted regardless of its content.

### `dsv_quote_fields([, ovs = "" [, ovq = VQ [, ors = RS]]])`

Quotes and escapes all field variables in-place where necessary.

### `dsv_read_fields()`

Reads a DSV record into field variables. **This operation is implicit in
`dsv.awk`.**

It consumes a full DSV record at a time, not necessarily a single line.

## Example programs

To skip the header line, assuming there is one, append:

    NR == 1 { next }

To ignore empty lines and comment lines, _prepend_:

    # Skip empty lines and lines starting with '#'.
    $0 == "" || /^#/ { next }

Normally, all lines are records. Empty records contain one empty field. This
change requires that records with one empty field be encoded as `""`.

To ensure that all records are the same length, append:

    {
        # RL keeps track of the previous record length.
        if (RL && RL != NF) {
            print "error: record length is " NF "; expected " RL >"/dev/stderr"
            exit 1
        }
        RL = NF
    }

To sloppily convert TSV to CSV:

    BEGIN { VS = "\t"
            OFS = "," }
    1  # cute but never quotes values

To properly convert TSV to CSV using `dsv_quote_fields()`:

    BEGIN { VS = "\t"
            OFS = "," }
    {
        dsv_quote_fields(OFS)  # re-quote when necessary
        print
    }

| Input             | Output    |
| ----------------- | --------- |
| `a` HT `b` HT `c` | `a,b,c`   |
| `,` HT `,`        | `",",","` |
| `"` HT `"`        | HT        |
| `""""`            | `""""`    |

To force-quote all values of a CSV record:

    BEGIN { OFS = VS }
    {
        dsv_quote_fields()  # no output separator given; will quote any value
        print
    }

| Input   | Output        |
| ------- | ------------- |
| empty   | `""`          |
| `,`     | `"",""`       |
| `a,b,c` | `"a","b","c"` |

### Setting variables

The cleanest way to set variables is inside `BEGIN` blocks, because they go with
your program. Awk will run all `BEGIN` blocks before other actions, in the order
they appear in the source.

Another way is the `-v` option:

    awk -v VS=: -f dsv.awk ...

Yet another are assignment arguments:

    awk -f dsv.awk ... VS=: ...

See the [awk(1)] manual for details.

[awk(1)]:
  https://pubs.opengroup.org/onlinepubs/9699919799.2018edition/utilities/awk.html

## References

[RFC4180]: https://www.rfc-editor.org/rfc/rfc4180.html

CSV, TSV and other DSV formats are found in many slightly incompatible variants,
but [RFC4180] is usually cited as a "reference" for CSV. And rightly so, as it's
general and unambiguous.

## Copying

The code in this repository is free to copy, modify and distribute but comes
with no warranties. Credit is appreciated although not required. See
[COPYING](./COPYING).
