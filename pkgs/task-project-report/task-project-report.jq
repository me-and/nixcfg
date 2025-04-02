# Pad a string on the left so it is at least the given number of characters.
# If specified, use the given padding character; if not, use space.
def lpad(n; s): s * (n - length) + .;
def lpad(n): lpad(n; " ");

def csi: "\u001b[";
def sgr(attrs): csi + ([attrs] | join(";")) + "m";
def colour(c): sgr(c) + . + sgr(0);
def red: colour(31);
def green: colour(32);
def yellow: colour(33);
def blue: colour(34);
def magenta: colour(35);
def cyan: colour(36);
def bwhite: colour(97);
def bold: sgr(1) + . + sgr(22);

def task_ident:
        if (.id // 0) == 0
        then .uuid[:8]
        else .id | tostring
        end;

def parse_date: strptime("%Y%m%dT%H%M%SZ");

def fix_dst: mktime | localtime;
def fix_dst_and_round_up_end_of_day:
        (mktime | localtime) as $fixed
        | if $fixed[3:6] == [23, 59, 59]
          then mktime + 1 | localtime
          else $fixed
          end;

def format_date:
        if .[3:6] == [0, 0, 0]
        then strftime("%a %-e %b %Y")
        else strftime("%a %-e %b %Y %R")
        end;

def format_urgency:
        ((.urgency * 10) | round) / 10
        | tostring
        | if contains(".") | not
          then . + ".0"
          end
        | lpad(4);
def format_tags:
        if has("tags")
        then .tags
             | map("+" + .)
             | join(" ")
             | cyan
        else ""
        end;
def format_due:
        if has("due")
        then .due | parse_date | fix_dst_and_round_up_end_of_day | format_date | red
        else ""
        end;
def format_wait:
        if has("wait")
        then .wait
             | parse_date
             | if mktime < now
               then ""
               else fix_dst | format_date | green
               end
        else ""
        end;
def format_annotations:
        if has("annotations")
        then .annotations | "[\(length)]"
        else ""
        end;
def format_dep(by_uuid):
        by_uuid[.] // {ident: .[:8]}
        | if has("description")
          then .result = .ident + " " + .description
          else .result = .ident
          end
        | if .status == "completed" or .status == "deleted"
          then .result | green
          elif .status == "pending"
          then .result | yellow
          else .result | red
          end;
def format_deps(by_uuid):
        if has("depends")
        then "["
             + (.depends
                | map(by_uuid[.] // {ident: .[:8]}
                      | if has("description")
                        then .result = .ident + " " + .description
                        else .result = .ident
                        end
                      | if .status == "completed" or .status == "deleted"
                        then .result |= green | .sortorder = 2
                        elif .status == "pending"
                        then .result |= yellow | .sortorder = 1
                        else .result |= red | .sortorder = 0
                        end
                      )
                | sort_by(.sortorder)
                | map(.result)
                | join("; "))
             + "]"
        else ""
        end;
def format_ident:
        if .tags // [] | contains(["project"])
        then .ident | lpad(10) | bwhite
        else .ident | lpad(10) | green
        end;
def format_description:
        if .priority == null
        then .
        elif .priority == "L"
        then .description |= blue
        elif .priority == "M"
        then .description |= yellow
        elif .priority == "H"
        then .description |= red
        else error("Unexpected priority \(.priority)")
        end
        | if .tags // [] | contains(["next"])
          then .description | bold
          else .description
          end;


(. / "\u0000")
| (.[1]
   | fromjson
   | map(.ident = task_ident)
   | ((group_by(.ident)
       | map(select(length > 1) | .[0].ident)
       | if length > 1
         then error("\(length) duplicate task idents")
         else empty
         end
       ),
      .
     )
   | INDEX(.[]; .uuid)
   ) as $by_uuid
| .[0] / "\n"
| map(select(length > 0)
      | $by_uuid[.]
      | {project: (.project // "No project"),
         project_task: (.tags // []) | contains(["project"]),
         ident_length: .ident | length,
         description: [format_ident,
                       format_urgency,
                       format_description,
                       format_annotations,
                       format_tags,
                       format_wait,
                       format_due,
                       format_deps($by_uuid)
                       ]
                      | map(select(length > 0))
                      | join(" "),
         sort: (if (.id // 0) != 0 then .id else .uuid end)
        }
      )
| group_by(.project)
| .[]
| sort_by(.sort)
| [(.[0].project | bwhite),
   (map(select(.project_task))
    | if length > 1
      then error("Too many project tasks")
      elif length == 1
      then .[0].description
      else ""
      end
    )
   ]
   + map(select(.project_task | not).description)
| map(select(length > 0) | . + "\n")
| join("")

# vim: et ts=8 ft=jq
