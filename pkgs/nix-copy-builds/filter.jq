.derivations[]
| if has("structuredAttrs")
  then
    .structuredAttrs
    | {
        allowSubstitutes:
          if has("allowSubstitutes")
          then .allowSubstitutes
          else true
          end,
        preferLocalBuild:
          if has("preferLocalBuild")
          then .preferLocalBuild
          else false
          end
      }
  else
    .env
    | {
        allowSubstitutes:
          if has("allowSubstitutes")
          then .allowSubstitutes == "1"
          else true
          end,
        preferLocalBuild:
          if has("prefelLocalBuild")
          then .preferLocalBuild == "1"
          else false
          end
      }
  end
| (.allowSubstitutes and (.preferLocalBuild | not))
