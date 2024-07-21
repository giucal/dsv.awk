BEGIN { OFS = ";" }

{
    dsv_quote_fields(OFS, "`")

    GOT = NF ":" $0
    TEST = 1
}