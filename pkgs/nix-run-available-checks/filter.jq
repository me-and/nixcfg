if .isCached
then "skipping .#checks.\($system).\(.attr) as already built\n" | stderr | empty
end
| .requiredSystemFeatures - ($features_str / " ") as $missing_features
| if $missing_features != []
  then "skipping .#checks.\($system).\(.attr) as missing features \($missing_features | join(", "))\n" | stderr | empty
  end
| ("will build .#checks.\($system).\(.attr)\n" | stderr | empty),
  .drvPath
