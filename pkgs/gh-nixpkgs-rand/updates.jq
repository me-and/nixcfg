INDEX($updates[]; .number) as $index |
map(
  $index[.number | tostring] as $update |
  if $update != null then
    if $update.state == "closed" then
      empty
    else
      $update
    end
  end
) |
map(.number) as $known_numbers |
(
  . + (
    $updates |
    map(
      select(.state != "closed") |
      select(
        [.number] |
        inside($known_numbers) |
        not
      )
    )
  )
) |
.[]
