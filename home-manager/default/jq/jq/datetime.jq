# Format a UTC date in a more human readable format.  This seems to have some
# odd handling of timezones that I've never managed (or needed) to unpick, so
# it enforces the string ending in "Z" to ensure we're really getting something
# in UTC (or at least we're deliberately lying).
#
# jq 'map(fmtutcdate)'
#    ["2023-08-24T12:47:12Z", "20000101T0000Z"]
# => ["Thu 24 Aug 2023 13:47:12", "Sat 1 Jan 2000 00:00"]
def fmtutcdate: gsub("[-:]"; "")
                | if test("T\\d{6}")
                  then strptime("%Y%m%dT%H%M%SZ")
                       | mktime
                       | strftime("%a %e %b %Y %H:%M:%S UTC")
                  else strptime("%Y%m%dT%H%MZ")
                       | mktime
                       | strftime("%a %e %b %Y %H:%M UTC")
                  end
                | sub("  *"; " ")
                ;
def fmtlocaldate: gsub("[-:]"; "")
                  | if test("T\\d{6}")
                    then strptime("%Y%m%dT%H%M%SZ")
                         | mktime
                         | strflocaltime("%a %e %b %Y %H:%M:%S")
                    else strptime("%Y%m%dT%H%MZ")
                         | mktime
                         | strflocaltime("%a %e %b %Y %H:%M")
                    end
                  | sub("  *"; " ")
                  ;

# vim: et ts=8 ft=jq
