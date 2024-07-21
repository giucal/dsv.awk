# For debugging dsv.akw.

BEGIN {
    OFS = ";"
}

{
    print "#" NR " = [" $0 "] (NF = " NF ")"
}