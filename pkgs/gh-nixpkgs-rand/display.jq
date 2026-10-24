def fmtutcdate:
  strptime("%Y-%m-%dT%H:%M:%SZ") |
  mktime |
  strftime("%a %e %b %Y %H:%M UTC");
def typestr:
  if .pull_request then
    if .draft then
      "Draft PR"
    else
      "PR"
    end
  else
    "Issue"
  end;
"[\(typestr)] \(.title)",
"Created: \(.created_at | fmtutcdate)",
"Last update: \(.updated_at | fmtutcdate)",
if .labels != [] then
  "Labels: \(.labels | join(", "))"
else
  empty
end,
.html_url
