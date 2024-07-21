# dsv.awk -- read delimiter-separated values
#
# This program instructs Awk to read records of delimiter-separated values in
# the vein of RFC4180. It reads values into field variables and is meant as a
# preamble for other Awk programs.
#
# Written in 2024 by Giuseppe Calabrese <author@giucal.it>
#
# This software is free to copy and distribute, with or without modification.
# It is offered as-is, without any warranty.

# The default setup reads CSV.
BEGIN {
    # Value separator. (FS is ignored.)
    if (!VS)
        VS = ","
    # Value quote character.
    if (!VQ)
        VQ = "\""
}

# Reads a DSV record into field variables.
#
# A record is a sequence of values separated by VS which ends at RS or EOF.
#
#   record         = value [ VS value ] ... ( RS | EOF )
#
# A value can be either quoted or literal. A literal value can contain
# anything except VS, RS, and VQ (see below).
#
#   value          = literal-value | quoted-value
#   literal-value  = anything except: VS, VQ, RS
#
# A quoted value is preceded and followed by VQ, and can contain VS and RS.
# VQ must appear in the escaped form VQ VQ.
#
#   quoted-value   = VQ ( literal-value | VQ VQ | VS | RS ) VQ
#
# A quoted value will be unquoted and de-escaped upon reading. To re-quote
# and re-escape it, use the dsv_quote() or dsv_quote_fields() function.
function dsv_read_fields(_, rec, i, q, c, val, more)
{
    if (length(VS) != 1) {
        print "VS must be a single character" >"/dev/stderr"
        exit 1
    }
    if (length(VQ) != 1) {
        print "VQ must be a single character" >"/dev/stderr"
        exit 1
    }
    if (VS == VQ || VS == RS || VQ == RS) {
        print "VS, VQ and RS must be different characters" >"/dev/stderr"
        exit 1
    }

    rec = $0
    $0 = ""

    # There is at least one field.
    NF = i = 1

    while (length(rec))
    {
        q = index(rec, VQ)

        if (q == 1)
        {
            val = substr(rec, q+1)

            while (q = index(val, VQ)) {
                if (substr(val, q+1, 1) != VQ)
                    # Closing quote.
                    break
                # Commit partial value.
                $i = $i substr(val, 1, q)
                val = substr(val, q+2)
            }

            if (!q)
            {
                if (1 > getline more) {
                    print "truncated value: " $i val >"/dev/stderr"
                    exit 1
                }
                NR--

                # Re-enter the q == 1 branch with the remaining input.
                rec = VQ val RS more
                continue
            }

            $i = $i substr(val, 1, q-1)
 
            if (length(val) == q)
                break

            if (substr(val, q+1, 1) != VS) {
                print "expected separator after quote: " rec >"/dev/stderr"
                exit 1
            }

            rec = substr(val, q+2)
            $(++i) = ""
            continue
        }

        c = index(rec, VS)

        if (q && q < c) {
            print "unquoted value contains VQ: " rec >"/dev/stderr"
            exit 1
        }

        if (!c) {
            $i = rec
            break
        }
        $i = substr(rec, 1, c-1)
        rec = substr(rec, c+1)
        $(++i) = ""
    }

    return NF
}

# Quotes a value if needed, and escapes inner quotes.
#
# val = the value to quote
# ovs = the value separator (empty or not given = quote always)
# ovq = the quote character (empty or not given = VQ)
function dsv_quote(val, ovs, ovq, _, q, esc)
{
    if (!ovq) ovq = VQ

    if (ovs && !index(val, ovs) && !index(val, ovq) && !index(val, RS))
        return val

    while (q = index(val, ovq)) {
        esc = esc substr(val, 1, q) ovq
        val = substr(val, q+1)
    }

    return ovq esc val ovq
}

# Quotes all fields whenever needed.
# See dsv_quote().
function dsv_quote_fields(ovs, ovq, _, i)
{
    for (i = 1; i <= NF; i++)
        $i = dsv_quote($i, ovs, ovq)
}

{
    dsv_read_fields()
}
