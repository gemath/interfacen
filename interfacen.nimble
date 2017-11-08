# Package

version       = "0.2.0"
author        = "Gerd Mathar"
description   = "Interfaces for Nim, implicit (Go-like) and explicit."
license       = "Apache License 2.0"
skipDirs = @["tests"]

# Dependencies

requires "nim >= 0.17.2"
requires "explicitconcepts"

#Tasks

task test, "run the tests":
  --path: "../"
 #--d: release
  --run
setCommand "c", "tests/testrunner.nim"
