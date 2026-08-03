if .isCached
then "skipping .#checks.\($system).\(.attr) = \(.drvPath) as already built\n" | stderr | empty
end
| .requiredSystemFeatures - ($features_str / " ") as $missing_features
| if $missing_features != []
  then "skipping .#checks.\($system).\(.attr) = \(.drvPath) as missing features \($missing_features | join(", "))\n" | stderr | empty
  end
| if ($github != "") and (.meta.buildOnGitHub == false)
  then "skipping .#checks.\($system).\(.attr) = \(.drvPath) as buildOnGitHub is false\n" | stderr | empty
  end
| ("will build .#checks.\($system).\(.attr) = \(.drvPath)\n" | stderr | empty),
  .drvPath
