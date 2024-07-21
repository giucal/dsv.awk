$0 == "---" || /^#/ { next }

TEST {
    VS = ";"
    VQ = "`"

    i = index($0, ":")
    nf = substr($0, 1, i-1)
    $0 = substr($0, i+1)

    dsv_read_fields()
    dsv_quote_fields(VS)

    VS = ","
    VQ = "\""

    want = nf ":" $0
    if (GOT != want) {
        print "failed: got [" GOT "]; expected [" want "]" >"/dev/stderr"
    }

    TEST = 0
    next
}